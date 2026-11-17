import CoreGraphics
import Foundation
import FoundationModels
import ImageIO

@Generable
private struct DetectedIngredients {
    @Guide(description: "Food ingredients visible in the photo, each a short lowercase name")
    var names: [String]
}

/// Spots ingredients in a photo with Apple's on-device model (needs iOS 27 vision support).
struct IngredientDetector {
    static var isAvailable: Bool {
        #if targetEnvironment(simulator)
        // The simulator reports the model as available, but inference fails with "Simulator is not supported".
        return false
        #else
        guard #available(iOS 27, macOS 27, visionOS 27, *) else { return false }
        let model = SystemLanguageModel.default
        return model.isAvailable && model.capabilities.contains(.vision)
        #endif
    }

    @available(iOS 27, macOS 27, visionOS 27, *)
    func ingredients(in image: CGImage) async throws -> [String] {
        let session = LanguageModelSession()
        let response = try await session.respond(generating: DetectedIngredients.self) {
            "List every food ingredient visible in this photo"
            Attachment(image)
        }
        return response.content.names
    }

    /// Normalized names in model order, without blanks, duplicates, or ones already in the pantry.
    static func clean(_ names: [String], excluding pantry: [String]) -> [String] {
        var seen = Set(pantry)
        return names.map(IngredientName.normalize).filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    /// Decodes photo data upright and scaled down, so the model gets a small, correctly oriented image.
    static func image(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1024,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }
}
