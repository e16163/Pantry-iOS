import Foundation
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
        viewModel = PantryViewModel(context: container.mainContext, corrections: ScanCorrections(defaults: defaults))
    }

    /// Fresh, throwaway storage so learned scan fixes don't leak between tests.
    let defaults = UserDefaults(suiteName: UUID().uuidString)!

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

    @Test func sampleAddsKnownIngredientsOnce() {
        viewModel.addSample()
        viewModel.addSample()
        #expect(viewModel.items.count == PantryViewModel.sample.count)
        #expect(!viewModel.items.contains { $0.category == .other })
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

    @Test func addDetectedAddsOnlyTickedItemsWithAmounts() {
        var basil = Detection(name: "basil")
        basil.isSelected = false
        viewModel.detected = [Detection(name: "tomato", quantity: 3, unit: .pieces), basil, Detection(name: "egg")]
        viewModel.addDetected()
        #expect(viewModel.items.map(\.name).sorted() == ["egg", "tomato"])
        #expect(viewModel.items.first { $0.name == "tomato" }?.quantityText == "3")
        #expect(viewModel.detected.isEmpty)
    }

    @Test func fixedScanNamesAreRememberedForNextScan() {
        var lemon = Detection(name: "lemon")
        lemon.name = "lime"
        viewModel.detected = [lemon]
        viewModel.addDetected()
        #expect(viewModel.items.map(\.name) == ["lime"])

        let next = IngredientDetector.clean([DetectedItem(name: "Lemons", count: 2)], excluding: [],
                                            corrections: ScanCorrections(defaults: defaults))
        #expect(next.map(\.name) == ["lime"])
    }

    @Test func updateRenamesRecategorizesAndSetsAmount() {
        viewModel.add(suggestion: "egg")
        let item = viewModel.items[0]
        #expect(viewModel.update(item, name: "Tomatoes", quantity: 500, unit: .grams))
        #expect(item.name == "tomato")
        #expect(item.category == .produce)
        #expect(item.quantityText == "500 g")
    }

    @Test func updateRejectsDuplicateOrBlankNames() {
        viewModel.add(suggestion: "egg")
        viewModel.add(suggestion: "rice")
        let egg = viewModel.items.first { $0.name == "egg" }!
        #expect(!viewModel.update(egg, name: "rice", quantity: nil, unit: nil))
        #expect(!viewModel.update(egg, name: "  ", quantity: nil, unit: nil))
        #expect(egg.name == "egg")
    }

    @Test func clearingAmountClearsUnit() {
        viewModel.add(suggestion: "egg")
        let egg = viewModel.items[0]
        viewModel.update(egg, name: "egg", quantity: 0, unit: .pieces)
        #expect(egg.quantity == nil && egg.unit == nil)
    }

    @Test func undoPutsDeletedItemBack() {
        viewModel.add(suggestion: "egg")
        viewModel.update(viewModel.items[0], name: "egg", quantity: 6, unit: .pieces)
        viewModel.delete(viewModel.items[0])
        #expect(viewModel.items.isEmpty)
        viewModel.undoDelete()
        #expect(viewModel.items.map(\.name) == ["egg"])
        #expect(viewModel.items[0].quantityText == "6")
        #expect(viewModel.recentlyDeleted == nil)
    }
}
