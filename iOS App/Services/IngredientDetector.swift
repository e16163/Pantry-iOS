import CoreGraphics
import FoundationModels
import Vision

@Generable
private struct DetectedIngredients {
    @Guide(description: "Food ingredients visible in the photo, each a short lowercase name like \"egg\" or \"cheddar cheese\"")
    var names: [String]
}

/// Spots ingredients in a photo: Apple Intelligence reads it on iOS 27, and anywhere that can't
/// (iOS 26, older phones, the simulator) Vision's built-in object labels are matched to the ingredient catalog.
struct IngredientDetector {
    func ingredients(in image: CGImage) async throws -> [String] {
        if #available(iOS 27, macOS 27, visionOS 27, *),
           SystemLanguageModel.default.availability == .available,
           SystemLanguageModel.default.capabilities.contains(.vision),
           let names = try? await modelIngredients(in: image), !names.isEmpty {
            return names
        }
        // Needs a real device: the simulator can't run Vision's classifier.
        let labels = try await ClassifyImageRequest().perform(on: image)
            .filter { $0.confidence >= 0.05 }
            .sorted { $0.confidence > $1.confidence }
            .map(\.identifier)
        return Self.catalogNames(fromLabels: labels)
    }

    /// Vision labels ("bell_pepper", "fruit", "eggs") kept only when they name a catalog ingredient.
    static func catalogNames(fromLabels labels: [String]) -> [String] {
        labels.map { IngredientName.normalize(visionAliases[$0] ?? $0.replacingOccurrences(of: "_", with: " ")) }
            .filter(known.contains)
    }

    /// Vision's generic labels that stand for one catalog ingredient. Only for photos, not typed names.
    private static let visionAliases = ["cheese": "cheddar cheese"]

    private static let known = Set(IngredientCatalog.all.map(\.name))

    @available(iOS 27, macOS 27, visionOS 27, *)
    private func modelIngredients(in image: CGImage) async throws -> [String] {
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
