import CoreGraphics
import Foundation
import FoundationModels
import ImageIO
import Vision

@Generable
struct DetectedItem {
    @Guide(description: "Plain grocery name in the singular, lowercase, like \"egg\", \"bell pepper\" or \"cheddar cheese\"")
    var name: String
    @Guide(description: "How many separate pieces you can count, like 6 for six eggs. 0 if it isn't countable, like milk, rice or flour")
    var count: Int
}

@Generable
private struct DetectedIngredients {
    @Guide(description: "Every food ingredient visible in the photo")
    var items: [DetectedItem]
}

/// One thing spotted in a photo, which the user can fix before it goes in the pantry.
struct Detection: Identifiable, Equatable {
    let id = UUID()
    /// The scanned name (after known fixes), compared with `name` to learn from the user's edits.
    let detectedName: String
    var name: String
    var quantity: Double?
    var unit: QuantityUnit?
    var isSelected = true

    init(name: String, quantity: Double? = nil, unit: QuantityUnit? = nil) {
        detectedName = name
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
}

/// Spots ingredients in a photo: Gemini reads it (with counts) through Pantry's Worker; offline, or once the free
/// daily limit is used up, Apple Intelligence reads it on iOS 27, and Vision's built-in object labels matched to
/// the ingredient catalog always add whatever they find.
struct IngredientDetector {
    private let session: LanguageModelSession
    private let hints: [String]

    /// `hints` are the user's past fixes, so the model uses their names for things.
    init(hints: [String] = []) {
        self.hints = hints
        let fixes = hints.isEmpty ? "" : " This user has corrected past scans: \(hints.joined(separator: "; "))."
        session = LanguageModelSession(instructions: """
            You list the food ingredients you can see in a photo of a fridge, pantry, or kitchen counter. \
            Only list things you can actually see. Skip containers, brands, and non-food items. \
            Look at every shelf, drawer and door. Read labels on jars, cartons and cans to tell what's inside. \
            Use plain grocery names in the singular, like "egg", "bell pepper", "greek yogurt" or "soy sauce". \
            Count separate pieces when you can.\(fixes)
            """)
    }

    private static var modelCanSee: Bool {
        guard #available(iOS 27, macOS 27, visionOS 27, *) else { return false }
        return SystemLanguageModel.default.availability == .available
            && SystemLanguageModel.default.capabilities.contains(.vision)
    }

    /// Loads the model ahead of time, so the scan starts faster once the photo arrives.
    func prewarm() {
        if Self.modelCanSee { session.prewarm() }
    }

    func ingredients(in image: CGImage) async throws -> [DetectedItem] {
        var modelItems = (try? await onlineIngredients(in: image)) ?? []
        if modelItems.isEmpty, #available(iOS 27, macOS 27, visionOS 27, *), Self.modelCanSee {
            modelItems = (try? await modelIngredients(in: image)) ?? []
        }
        // Vision runs too, even with Apple Intelligence, to catch items the model skipped.
        // Needs a real device: the simulator can't run Vision's classifier.
        let labels = try? await ClassifyImageRequest().perform(on: image)
            .filter { $0.confidence >= 0.05 }
            .sorted { $0.confidence > $1.confidence }
            .map(\.identifier)
        if modelItems.isEmpty && labels == nil { throw CocoaError(.fileReadCorruptFile) }
        return modelItems + Self.catalogNames(fromLabels: labels ?? []).map { DetectedItem(name: $0, count: 0) }
    }

    /// Vision labels ("bell_pepper", "fruit", "eggs") kept only when they name a catalog ingredient.
    static func catalogNames(fromLabels labels: [String]) -> [String] {
        labels.map { IngredientName.normalize(visionAliases[$0] ?? $0.replacingOccurrences(of: "_", with: " ")) }
            .filter(known.contains)
    }

    /// Vision's generic labels that stand for one catalog ingredient. Only for photos, not typed names.
    private static let visionAliases = [
        "cheese": "cheddar cheese", "beef": "ground beef", "pepper_veggie": "bell pepper", "jalapeno": "jalapeño",
        "pita": "pita bread", "ramen": "ramen noodle", "shellfish": "shrimp", "tortilla": "flour tortilla",
        "tuna": "canned tuna", "white_bread": "bread", "sugar_cube": "sugar", "fries": "frozen french fry",
        "waffle": "frozen waffle", "dumpling": "frozen dumpling", "pizza": "frozen pizza",
        "scrambled_eggs": "egg", "fried_egg": "egg",
    ]

    private static let known = Set(IngredientCatalog.all.map(\.name))

    private func onlineIngredients(in image: CGImage) async throws -> [DetectedItem] {
        let jpeg = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpeg, "public.jpeg" as CFString, 1, nil) else { return [] }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return [] }
        var url = RecipeArt.server.appending(path: "scan")
        if !hints.isEmpty { url.append(queryItems: [URLQueryItem(name: "hints", value: hints.joined(separator: "; "))]) }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.upload(for: request, from: jpeg as Data)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        return try JSONDecoder().decode(OnlineScan.self, from: data).items.map { DetectedItem(name: $0.name, count: $0.count) }
    }

    private struct OnlineScan: Decodable {
        struct Item: Decodable { let name: String; let count: Int }
        let items: [Item]
    }

    @available(iOS 27, macOS 27, visionOS 27, *)
    private func modelIngredients(in image: CGImage) async throws -> [DetectedItem] {
        let response = try await session.respond(generating: DetectedIngredients.self,
                                                 options: GenerationOptions(samplingMode: .greedy)) {
            "List every food ingredient visible in this photo, with how many you can count."
            Attachment(image)
        }
        return response.content.items
    }

    /// Normalized, fixed-up detections with blanks, duplicates and anything already in the pantry removed, in order.
    /// When the model and Vision both name something, the first (the model's, with its count) wins.
    static func clean(_ items: [DetectedItem], excluding pantry: [String],
                      corrections: ScanCorrections) -> [Detection] {
        var seen = Set(pantry)
        return items.compactMap { item in
            let name = corrections.apply(IngredientName.normalize(item.name))
            guard !name.isEmpty, seen.insert(name).inserted else { return nil }
            return item.count > 0 ? Detection(name: name, quantity: Double(item.count), unit: .pieces) : Detection(name: name)
        }
    }
}
