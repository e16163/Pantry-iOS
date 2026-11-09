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

    func add() {
        let name = newItemName.trimmingCharacters(in: .whitespaces).lowercased()
        guard !name.isEmpty else { return }
        let category = IngredientCatalog.all.first { $0.name == name }?.category ?? .other
        context.insert(PantryItem(name: name, category: category))
        newItemName = ""
        load()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(items[index])
        }
        load()
    }
}
