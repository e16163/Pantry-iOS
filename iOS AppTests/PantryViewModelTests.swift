import SwiftData
import Testing
@testable import iOS_App

struct PantryViewModelTests {
    let container: ModelContainer  // must outlive the view model's context
    let viewModel: PantryViewModel

    init() throws {
        container = try ModelContainer(
            for: PantryItem.self, SavedRecipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        viewModel = PantryViewModel(context: container.mainContext)
    }

    @Test func addNormalizesNameAndSetsCategory() {
        viewModel.newItemName = "  Eggs "
        viewModel.add()
        #expect(viewModel.items.map(\.name) == ["egg"])
        #expect(viewModel.items.first?.category == .protein)
        #expect(viewModel.newItemName == "")
    }

    @Test func addIgnoresBlankInput() {
        viewModel.newItemName = "   "
        viewModel.add()
        #expect(viewModel.items.isEmpty)
    }

    @Test func unknownIngredientGetsOtherCategory() {
        viewModel.newItemName = "dragon fruit"
        viewModel.add()
        #expect(viewModel.items.first?.category == .other)
    }

    @Test func deleteRemovesItem() {
        for name in ["egg", "rice"] {
            viewModel.newItemName = name
            viewModel.add()
        }
        viewModel.delete(at: [0])
        #expect(viewModel.items.map(\.name) == ["rice"])
    }
}
