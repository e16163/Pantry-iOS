import SwiftData
import Testing
@testable import iOS_App

struct PhotoAndArtTests {
    @Test func cleanNormalizesDedupesAndSkipsPantry() {
        let names = IngredientDetector.clean(["Eggs", "  ", "Tomato", "eggs", "Garlic"], excluding: ["garlic"])
        #expect(names == ["egg", "tomato"])
    }

    @Test func recipeArtMatchesTitleBeforeIngredients() {
        #expect(RecipeArt.photo(title: "Tomato Pasta", ingredients: ["egg"]) == "dish-pasta")
        #expect(RecipeArt.photo(title: "Mystery Dish", ingredients: ["chicken"]) == "dish-chicken")
        #expect(RecipeArt.photo(title: "Mystery Dish", ingredients: []) == "dish-default")
    }

    @MainActor @Test func savedDeleteRemovesRecipe() throws {
        let container = try ModelContainer(for: PantryItem.self, SavedRecipe.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let detail = RecipeDetailViewModel(
            recipe: RecipeSuggestion(title: "Toast", minutes: 5, difficulty: "Easy", ingredients: ["bread"], steps: ["Toast it."]),
            context: container.mainContext)
        detail.toggleSave()
        let saved = SavedViewModel(context: container.mainContext)
        saved.load()
        #expect(saved.recipes.count == 1)
        saved.delete(saved.recipes[0])
        #expect(saved.recipes.isEmpty)
    }
}
