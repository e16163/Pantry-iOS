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

    @Test func thumbnailFileNameIsSafe() {
        #expect(RecipeThumbnails.fileName(for: "Mac & Cheese / Deluxe") == "mac---cheese---deluxe.png")
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
