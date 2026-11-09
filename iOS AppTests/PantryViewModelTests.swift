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

    @Test func addSkipsDuplicatesAfterNormalizing() {
        for name in ["egg", "Eggs", " EGG "] {
            viewModel.newItemName = name
            viewModel.add()
        }
        #expect(viewModel.items.map(\.name) == ["egg"])
        #expect(viewModel.newItemName == "")
    }

    @Test func suggestionsPutPrefixMatchesFirst() {
        viewModel.newItemName = "on"
        #expect(viewModel.suggestions.first == "onion")
        #expect(viewModel.suggestions.contains("green onion"))
    }

    @Test func suggestionsExcludePantryItemsAndCapAtFive() {
        viewModel.add(suggestion: "onion")
        viewModel.newItemName = "on"
        #expect(!viewModel.suggestions.contains("onion"))
        viewModel.newItemName = "a"
        #expect(viewModel.suggestions.count == 5)
    }

    @Test func noSuggestionsForBlankText() {
        viewModel.newItemName = "  "
        #expect(viewModel.suggestions.isEmpty)
    }

    @Test func addSuggestionAddsIt() {
        viewModel.newItemName = "garl"
        viewModel.add(suggestion: "garlic")
        #expect(viewModel.items.map(\.name) == ["garlic"])
        #expect(viewModel.newItemName == "")
    }

    @Test func sectionsGroupByCategoryInFixedOrder() {
        for name in ["rice", "egg", "spinach", "bacon", "dragon fruit"] {
            viewModel.add(suggestion: name)
        }
        #expect(viewModel.sections.map(\.category) == [.produce, .protein, .grains, .other])
        #expect(viewModel.sections[1].items.map(\.name) == ["bacon", "egg"])
    }

    @Test func noSectionsWhenEmpty() {
        #expect(viewModel.sections.isEmpty)
    }

    @Test func deleteRemovesItemFromItsSection() {
        for name in ["egg", "bacon", "rice"] {
            viewModel.add(suggestion: name)
        }
        viewModel.delete(at: [1], in: .protein)
        #expect(viewModel.items.map(\.name) == ["bacon", "rice"])
    }
}
