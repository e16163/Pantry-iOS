import Foundation
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

    func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(items[index])
        }
        load()
    }
}
