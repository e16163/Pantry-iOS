import Foundation
import ImageIO
import Observation
import SwiftData

@Observable
@MainActor
final class PantryViewModel {
    private(set) var items: [PantryItem] = []
    var newItemName = ""

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        load()
    }

    func load() {
        items = (try? context.fetch(FetchDescriptor<PantryItem>(sortBy: [SortDescriptor(\.name)]))) ?? []
    }

    /// Up to 5 catalog ingredients matching the typed text, excluding ones already in the pantry.
    /// Ranked: name starts with the text, then a word starts with it ("green onion" for "on"), then contains it.
    var suggestions: [String] {
        let query = IngredientName.normalize(newItemName)
        guard !query.isEmpty else { return [] }
        let inPantry = Set(items.map(\.name))
        let candidates = IngredientCatalog.all.map(\.name).filter { !inPantry.contains($0) && $0.contains(query) }
        func rank(_ name: String) -> Int {
            if name.hasPrefix(query) { return 0 }
            if name.contains(" " + query) { return 1 }
            return 2
        }
        return Array(candidates.sorted { (rank($0), $0) < (rank($1), $1) }.prefix(5))
    }

    func add() {
        let name = IngredientName.normalize(newItemName)
        newItemName = ""
        guard !name.isEmpty, !items.contains(where: { $0.name == name }) else { return }
        let category = IngredientCatalog.all.first { $0.name == name }?.category ?? .other
        context.insert(PantryItem(name: name, category: category))
        load()
    }

    func add(suggestion: String) {
        newItemName = suggestion
        add()
    }

    /// A pantry that reliably gives good recipes, for demos and first-time users.
    static let sample = ["egg", "spinach", "cheddar cheese", "tomato", "bread", "butter", "pasta", "garlic"]

    func addSample() {
        Self.sample.forEach(add(suggestion:))
    }

    // MARK: Photo input

    var detected: [String] = []
    var selectedDetected: Set<String> = []
    private(set) var isDetecting = false
    private(set) var detectionError: String?

    /// Reads ingredients out of a photo (JPEG/HEIC data) and ticks all of them for review.
    func detect(photo data: Data) async {
        detected = []
        detectionError = nil
        isDetecting = true
        defer { isDetecting = false }
        // Downscale (and apply EXIF rotation) before handing it to the model.
        let options = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                       kCGImageSourceCreateThumbnailWithTransform: true,
                       kCGImageSourceThumbnailMaxPixelSize: 1024] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            detectionError = "Couldn't open that photo. Try another one."
            return
        }
        guard #available(iOS 27, macOS 27, visionOS 27, *) else {
            detectionError = IngredientDetector.unavailableText
            return
        }
        do {
            let names = try await IngredientDetector().ingredients(in: image)
            detected = IngredientDetector.clean(names, excluding: items.map(\.name))
            selectedDetected = Set(detected)
        } catch {
            detectionError = "Try a closer, brighter shot, or type the ingredients in instead."
        }
    }

    /// Adds the ticked detections the same way typed names are added.
    func addDetected() {
        detected.filter(selectedDetected.contains).forEach(add(suggestion:))
        detected = []
        selectedDetected = []
    }

    /// Pantry items grouped by category, in `IngredientCategory` order, skipping empty categories.
    var sections: [(category: IngredientCategory, items: [PantryItem])] {
        IngredientCategory.allCases.compactMap { category in
            let matching = items.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    func delete(at offsets: IndexSet, in category: IngredientCategory) {
        let matching = items.filter { $0.category == category }
        for index in offsets {
            context.delete(matching[index])
        }
        load()
    }
}
