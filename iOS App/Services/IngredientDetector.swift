import CoreGraphics
import FoundationModels

@Generable
private struct DetectedIngredients {
    @Guide(description: "Food ingredients visible in the photo, each a short lowercase name like \"egg\" or \"cheddar cheese\"")
    var names: [String]
}

/// Spots ingredients in a photo with Apple's on-device model (needs iOS 27 vision support).
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

    @available(iOS 27, macOS 27, visionOS 27, *)
    func ingredients(in image: CGImage) async throws -> [String] {
        let session = LanguageModelSession(instructions: """
            You list the food ingredients you can see in a photo of a fridge, pantry, or kitchen counter. \
            Only list things you can actually see. Skip containers, brands, and non-food items.
            """)
        let response = try await session.respond(generating: DetectedIngredients.self) {
            "List every food ingredient visible in this photo."
            Attachment(image)
        }
        return response.content.names
    }

    /// Normalized names with blanks, duplicates and anything already in the pantry removed, in original order.
    static func clean(_ names: [String], excluding pantry: [String]) -> [String] {
        var seen = Set(pantry)
        return names.map(IngredientName.normalize).filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
