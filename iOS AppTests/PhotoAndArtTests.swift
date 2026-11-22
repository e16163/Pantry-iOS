import Foundation
import SwiftData
import Testing
@testable import iOS_App

struct PhotoAndArtTests {
    @Test func cleanNormalizesDedupesSkipsPantryAndKeepsCounts() {
        let items = [("Eggs", 6), ("  ", 0), ("Tomato", 0), ("eggs", 2), ("Garlic", 1)].map { DetectedItem(name: $0, count: $1) }
        let found = IngredientDetector.clean(items, excluding: ["garlic"],
                                             corrections: ScanCorrections(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        #expect(found.map(\.name) == ["egg", "tomato"])
        #expect(found.map(\.quantity) == [6, nil])
        #expect(found[0].unit == .pieces)
    }

    @Test func correctionsIgnoreNoOpsAndBecomeHints() {
        var corrections = ScanCorrections(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        corrections.record(from: "egg", to: " Egg ")
        corrections.record(from: "lemon", to: "lime")
        #expect(corrections.fixes == ["lemon": "lime"])
        #expect(corrections.apply("lemon") == "lime")
        #expect(corrections.hints == ["what looks like \"lemon\" is \"lime\""])
    }

    @Test func quantityText() {
        #expect(QuantityUnit.text(3, .pieces) == "3")
        #expect(QuantityUnit.text(500, .grams) == "500 g")
        #expect(QuantityUnit.text(2, .cups) == "2 cups")
        #expect(QuantityUnit.text(0, .cups) == nil)
        #expect(QuantityUnit.text(nil, nil) == nil)
    }

    @Test func visionLabelsKeepOnlyCatalogIngredients() {
        #expect(IngredientDetector.catalogNames(fromLabels: ["food", "bell_pepper", "eggs", "kitchen", "banana", "cheese", "pepper_veggie", "shellfish"])
                == ["bell pepper", "egg", "banana", "cheddar cheese", "bell pepper", "shrimp"])
    }

    @Test func recipeArtOnlyMatchesTheSameDish() {
        #expect(RecipeArt.photo(title: "Spinach & Cheddar Omelette") == "dish-eggs")
        #expect(RecipeArt.photo(title: "Tomato Basil Spaghetti") == "dish-pasta")
        // A look-alike photo would be wrong, so these get none.
        #expect(RecipeArt.photo(title: "Classic Scrambled Eggs on Toast") == nil)
        #expect(RecipeArt.photo(title: "Pesto Pasta") == nil)
        #expect(RecipeArt.photo(title: "Mystery Dish") == nil)
        #expect(RecipeArt.photo(title: "Egg Curry") == nil)
        #expect(RecipeArt.photo(title: "Shrimp Fajitas") == nil)
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
