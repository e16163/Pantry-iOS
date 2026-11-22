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

    @MainActor @Test func switchingToAShorterTimeHidesLongerRecipes() async {
        PantryViewModel.sample.forEach(pantry.add(suggestion:))
        suggest.maxMinutes = nil
        await suggest.generate()
        #expect(suggest.recipes.contains { $0.minutes > 15 })
        suggest.maxMinutes = 15
        #expect(!suggest.visibleRecipes.isEmpty || suggest.recipes.allSatisfy { $0.minutes > 15 })
        #expect(suggest.visibleRecipes.allSatisfy { $0.minutes <= 15 })
    }

    @Test func cannotGenerateWithEmptyPantry() {
        suggest.refreshPantry()
        #expect(suggest.pantryCount == 0)
        #expect(!suggest.canGenerate)
    }

    @Test func onHandCountsPantryItemsAndStaples() {
        pantry.add(suggestion: "egg")
        suggest.refreshPantry()
        #expect(suggest.onHandCount(for: recipe(minutes: 10, ingredients: ["egg", "salt", "bacon"])) == 2)
    }

    @Test func canGenerateAfterAddingIngredients() {
        pantry.add(suggestion: "egg")
        suggest.refreshPantry()
        #expect(suggest.pantryCount == 1)
        #expect(suggest.canGenerate)
    }

    @MainActor @Test func withoutAppleIntelligenceAnEmptyBookSaysWhatToDo() async {
        guard RecipeGenerator().unavailableMessage != nil else { return }  // only meaningful where the model is off
        pantry.add(suggestion: "saffron")
        await suggest.generate()
        #expect(suggest.recipes.isEmpty)
        #expect(suggest.errorMessage == SuggestViewModel.noBookMatchMessage)
        #expect(suggest.fallbackNotice == nil)
    }

    @MainActor @Test func withoutAppleIntelligenceBookRecipesGetAFriendlyNote() async {
        guard let reason = RecipeGenerator().unavailableMessage else { return }
        PantryViewModel.sample.forEach(pantry.add(suggestion:))
        await suggest.generate()
        #expect(!suggest.recipes.isEmpty)
        #expect(suggest.errorMessage == nil)
        #expect(suggest.fallbackNotice == reason)
        #expect(reason.contains("built-in recipe book"))
    }
}

extension SuggestViewModelTests {
    @MainActor @Test func shelvesGroupReadyAndQuickRecipes() async {
        PantryViewModel.sample.forEach(pantry.add(suggestion:))
        suggest.refreshPantry()
        suggest.maxMinutes = nil
        await suggest.generate()
        let titles = suggest.shelves.flatMap { $0.recipes.map(\.title) }
        #expect(Set(titles).count == titles.count)  // no recipe in two rows
        for shelf in suggest.shelves {
            #expect(shelf.recipes.count >= 2)
            if shelf.title == "Ready in 15 min" { #expect(shelf.recipes.allSatisfy { $0.minutes <= 15 }) }
            if shelf.title == "You have everything" {
                #expect(shelf.recipes.allSatisfy { suggest.onHandCount(for: $0) >= $0.ingredients.count })
            }
        }
        suggest.maxMinutes = 15
        #expect(!suggest.shelves.contains { $0.title == "Ready in 15 min" })
    }
}
