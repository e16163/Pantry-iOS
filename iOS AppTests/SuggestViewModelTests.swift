import SwiftData
import Testing
@testable import iOS_App

struct SuggestViewModelTests {
    let container: ModelContainer  // must outlive the view models' context
    let suggest: SuggestViewModel
    let pantry: PantryViewModel

    init() throws {
        container = try ModelContainer(
            for: PantryItem.self, SavedRecipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        suggest = SuggestViewModel(context: container.mainContext)
        pantry = PantryViewModel(context: container.mainContext)
    }

    func recipe(minutes: Int, ingredients: [String] = ["egg"]) -> RecipeSuggestion {
        RecipeSuggestion(title: "Test", minutes: minutes, difficulty: "Easy", ingredients: ingredients, steps: [])
    }

    @Test(arguments: [(10, true), (15, true), (16, false), (45, false)])
    func timeLimitIsEnforced(minutes: Int, usable: Bool) {
        #expect(SuggestViewModel.isUsable(recipe(minutes: minutes), pantry: ["egg"], maxMinutes: 15) == usable)
    }

    @Test func anyTimeAllowsLongRecipes() {
        #expect(SuggestViewModel.isUsable(recipe(minutes: 240), pantry: ["egg"], maxMinutes: nil))
    }

    @Test func pantryCheckStillApplies() {
        #expect(!SuggestViewModel.isUsable(recipe(minutes: 10, ingredients: ["bacon"]), pantry: ["egg"], maxMinutes: 15))
    }

    @Test func cannotGenerateWithEmptyPantry() {
        suggest.refreshPantry()
        #expect(suggest.pantryCount == 0)
        #expect(!suggest.canGenerate)
    }

    @Test func canGenerateAfterAddingIngredients() {
        pantry.add(suggestion: "egg")
        suggest.refreshPantry()
        #expect(suggest.pantryCount == 1)
        #expect(suggest.canGenerate)
    }
}
