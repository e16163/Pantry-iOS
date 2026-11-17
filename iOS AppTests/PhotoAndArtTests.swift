import SwiftData
import Testing
@testable import iOS_App

struct PhotoAndArtTests {
    @Test func cleanNormalizesDedupesAndSkipsPantry() {
        let names = IngredientDetector.clean(["Eggs", "  ", "Tomato", "eggs", "Garlic"], excluding: ["garlic"])
        #expect(names == ["egg", "tomato"])
    }

    @Test func recipeArtMatchesTitleBeforeIngredients() {
        #expect(RecipeArt.emoji(title: "Tomato Pasta", ingredients: ["egg"]) == "🍝")
        #expect(RecipeArt.emoji(title: "Mystery Dish", ingredients: ["chicken"]) == "🍗")
        #expect(RecipeArt.emoji(title: "Mystery Dish", ingredients: []) == "🍽️")
    }

    @Test func recipeArtColorIsStable() {
        #expect(RecipeArt.colorIndex(title: "Omelette") == RecipeArt.colorIndex(title: "Omelette"))
        #expect((0..<RecipeArt.palette.count).contains(RecipeArt.colorIndex(title: "Omelette")))
    }

    @Test func ingredientEmojiPrefersLongestMatch() {
        #expect(IngredientEmoji.emoji(for: "eggplant", category: .produce) == "🍆")
        #expect(IngredientEmoji.emoji(for: "peanut butter", category: .pantry) == "🥜")
        #expect(IngredientEmoji.emoji(for: "quinoa", category: .grains) == "🌾")
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
