import SwiftData
import Testing
@testable import iOS_App

struct PhotoAndArtTests {
    @Test func cleanNormalizesDedupesAndSkipsPantry() {
        let names = IngredientDetector.clean(["Eggs", "  ", "Tomato", "eggs", "Garlic"], excluding: ["garlic"])
        #expect(names == ["egg", "tomato"])
    }

    @Test func recipePhotoOnlyWhenItShowsThatDish() {
        #expect(RecipeArt.photo(title: "Spinach & Cheddar Omelette") == "dish-eggs")
        #expect(RecipeArt.photo(title: "Tomato Basil Spaghetti") == "dish-pasta")
        #expect(RecipeArt.photo(title: "Classic Scrambled Eggs on Toast") == nil)
        #expect(RecipeArt.photo(title: "Garlic Butter Pasta") == nil)
        #expect(RecipeArt.photo(title: "Mystery Dish") == nil)
    }

    @Test func ingredientPhotoSlugMatchesSlicerScript() {
        #expect(FoodPhoto.slug("Jalapeño") == "jalapeno")
        #expect(FoodPhoto.slug("apple cider vinegar") == "apple-cider-vinegar")
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
