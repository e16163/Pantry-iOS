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
    private var corrections: ScanCorrections

    init(context: ModelContext, corrections: ScanCorrections = ScanCorrections()) {
        self.context = context
        self.corrections = corrections
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
        let name = newItemName
        newItemName = ""
        add(name: name)
    }

    private func add(name raw: String, quantity: Double? = nil, unit: QuantityUnit? = nil) {
        let name = IngredientName.normalize(raw)
        guard !name.isEmpty, !items.contains(where: { $0.name == name }) else { return }
        context.insert(PantryItem(name: name, category: Self.category(for: name), quantity: quantity, unit: unit))
        load()
    }

    private static func category(for name: String) -> IngredientCategory {
        IngredientCatalog.all.first { $0.name == name }?.category ?? .other
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

    var detected: [Detection] = []
    private(set) var isDetecting = false
    private(set) var detectionError: String?
    private var detector: IngredientDetector?

    var selectedDetectedCount: Int { detected.filter(\.isSelected).count }

    /// Called when the scan menu opens: loads the model while the user lines up the shot.
    func prepareScan() {
        let detector = IngredientDetector(hints: corrections.hints)
        detector.prewarm()
        self.detector = detector
    }

    /// Reads ingredients and counts out of a photo (JPEG/HEIC data); everything starts ticked for review.
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
        // A session holds its history, so each scan gets a fresh one.
        let detector = self.detector ?? IngredientDetector(hints: corrections.hints)
        self.detector = nil
        do {
            let found = try await detector.ingredients(in: image)
            detected = IngredientDetector.clean(found, excluding: items.map(\.name), corrections: corrections)
        } catch {
            detectionError = "Try a closer, brighter shot, or type the ingredients in instead."
        }
    }

    /// Adds the ticked detections, and remembers any name the user fixed for next time.
    func addDetected() {
        for detection in detected where detection.isSelected {
            corrections.record(from: detection.detectedName, to: detection.name)
            add(name: detection.name, quantity: detection.quantity, unit: detection.unit)
        }
        detected = []
    }

    // MARK: Editing

    /// Renames and/or sets the amount. Returns false (and changes nothing) if the new name is blank or already in the pantry.
    @discardableResult
    func update(_ item: PantryItem, name raw: String, quantity: Double?, unit: QuantityUnit?) -> Bool {
        let name = IngredientName.normalize(raw)
        guard !name.isEmpty, name == item.name || !items.contains(where: { $0.name == name }) else { return false }
        if name != item.name {
            item.name = name
            item.category = Self.category(for: name)
        }
        item.quantity = quantity.flatMap { $0 > 0 ? $0 : nil }
        item.unit = item.quantity == nil ? nil : (unit ?? .pieces)
        load()
        return true
    }

    /// The last removed item, kept briefly so it can be put back.
    private(set) var recentlyDeleted: (name: String, category: IngredientCategory, quantity: Double?, unit: QuantityUnit?)?

    func delete(_ item: PantryItem) {
        recentlyDeleted = (item.name, item.category, item.quantity, item.unit)
        context.delete(item)
        load()
    }

    func undoDelete() {
        guard let item = recentlyDeleted else { return }
        recentlyDeleted = nil
        context.insert(PantryItem(name: item.name, category: item.category, quantity: item.quantity, unit: item.unit))
        load()
    }

    func clearUndo() { recentlyDeleted = nil }

    /// Pantry items grouped by category, in `IngredientCategory` order, skipping empty categories.
    var sections: [(category: IngredientCategory, items: [PantryItem])] {
        IngredientCategory.allCases.compactMap { category in
            let matching = items.filter { $0.category == category }
            return matching.isEmpty ? nil : (category, matching)
        }
    }

    func delete(at offsets: IndexSet, in category: IngredientCategory) {
        let matching = items.filter { $0.category == category }
        offsets.map { matching[$0] }.forEach(delete)
    }
}
