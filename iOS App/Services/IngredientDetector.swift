import CoreGraphics
import Foundation
import FoundationModels
import ImageIO

@Generable
struct DetectedItem {
    @Guide(description: "Plain grocery name in the singular, lowercase, like \"egg\", \"bell pepper\" or \"cheddar cheese\"")
    var name: String
    @Guide(description: "How many separate pieces you can count, like 6 for six eggs. 0 if it isn't countable, like milk, rice or flour")
    var count: Int
    @Guide(description: "For things that aren't counted: the amount from the package size on the label, or your best guess of what's there, like 3.8 for a gallon of milk in L. 0 if you can't tell")
    var amount: Double
    @Guide(description: "Unit of amount", .anyOf(["g", "kg", "ml", "L", "lb", "oz", ""]))
    var unit: String
}

extension DetectedItem {
    init(name: String, count: Int) {
        self.init(name: name, count: count, amount: 0, unit: "")
    }
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
/// daily limit is used up, Apple Intelligence reads it on iOS 27.
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
        var items = (try? await onlineIngredients(in: image)) ?? []
        if items.isEmpty, #available(iOS 27, macOS 27, visionOS 27, *), Self.modelCanSee {
            items = (try? await modelIngredients(in: image)) ?? []
        }
        // No guessing past this point: Vision's labels called a block of cheese "mango", so a miss says "try again".
        if items.isEmpty { throw CocoaError(.fileReadCorruptFile) }
        return items
    }

    private func onlineIngredients(in image: CGImage) async throws -> [DetectedItem] {
        let jpeg = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpeg, "public.jpeg" as CFString, 1, nil) else { return [] }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.7] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return [] }
        var url = RecipeArt.server.appending(path: "scan")
        if !hints.isEmpty { url.append(queryItems: [URLQueryItem(name: "hints", value: hints.joined(separator: "; "))]) }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await URLSession.shared.upload(for: request, from: jpeg as Data)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        return try JSONDecoder().decode(OnlineScan.self, from: data).items.map {
            DetectedItem(name: $0.name, count: $0.count, amount: $0.amount ?? 0, unit: $0.unit ?? "")
        }
    }

    private struct OnlineScan: Decodable {
        struct Item: Decodable { let name: String; let count: Int; let amount: Double?; let unit: String? }
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
    static func clean(_ items: [DetectedItem], excluding pantry: [String],
                      corrections: ScanCorrections) -> [Detection] {
        var seen = Set(pantry)
        return items.compactMap { item in
            let name = corrections.apply(IngredientName.normalize(item.name))
            guard !name.isEmpty, seen.insert(name).inserted else { return nil }
            if item.count > 0 { return Detection(name: name, quantity: Double(item.count), unit: .pieces) }
            if item.amount > 0, let unit = QuantityUnit(rawValue: item.unit) { return Detection(name: name, quantity: item.amount, unit: unit) }
            return Detection(name: name)
        }
    }
}
