import CoreGraphics
import Foundation
import FoundationModels

@Generable
struct DetectedItem {
    @Guide(description: "Short lowercase ingredient name, like \"egg\" or \"cheddar cheese\"")
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

/// Spots ingredients and counts in a photo with Apple's on-device model (needs iOS 27 vision support).
struct IngredientDetector {
    static let unavailableText = "Spotting ingredients in photos needs Apple Intelligence on iOS 27 or later."

    /// Why detection can't run here, or nil when it can.
    static var unavailableMessage: String? {
        guard #available(iOS 27, macOS 27, visionOS 27, *),
              SystemLanguageModel.default.availability == .available,
              SystemLanguageModel.default.capabilities.contains(.vision)
        else { return unavailableText }
        return nil
    }

    private let session: LanguageModelSession

    /// `hints` are the user's past fixes, so the model uses their names for things.
    init(hints: [String] = []) {
        let fixes = hints.isEmpty ? "" : " This user has corrected past scans: \(hints.joined(separator: "; "))."
        session = LanguageModelSession(instructions: """
            You list the food ingredients you can see in a photo of a fridge, pantry, or kitchen counter. \
            Only list things you can actually see. Skip containers, brands, and non-food items. \
            Count separate pieces when you can.\(fixes)
            """)
    }

    /// Loads the model ahead of time, so the scan starts faster once the photo arrives.
    func prewarm() { session.prewarm() }

    @available(iOS 27, macOS 27, visionOS 27, *)
    func ingredients(in image: CGImage) async throws -> [DetectedItem] {
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
            return item.count > 0 ? Detection(name: name, quantity: Double(item.count), unit: .pieces) : Detection(name: name)
        }
    }
}
