import Testing
@testable import iOS_App

struct FallbackRecipesTests {
    func recipe(_ title: String, minutes: Int = 10, _ ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(title: title, minutes: minutes, difficulty: "Easy", ingredients: ingredients, steps: [])
    }

    @Test func bundledRecipesLoadAndUseKnownIngredients() {
        #expect(FallbackRecipes.all.count >= 30)
        let known = Set(IngredientCatalog.all.map(\.name)).union(PantryCheck.staples)
        for recipe in FallbackRecipes.all {
            #expect(!recipe.steps.isEmpty, "\(recipe.title) has no steps")
            for ingredient in recipe.ingredients {
                #expect(known.contains(IngredientName.normalize(ingredient)), "\(recipe.title): \(ingredient)")
            }
        }
    }

    @Test func ranksByShareOfIngredientsOnHand() {
        let recipes = [
            recipe("Half", ["egg", "bacon"]),
            recipe("All", ["egg", "spinach"]),
            recipe("Third", ["egg", "bacon", "ham"]),
        ]
        let titles = FallbackRecipes.best(for: ["egg", "spinach"], maxMinutes: nil, from: recipes).map(\.title)
        #expect(titles == ["All", "Half"])
    }

    @Test func respectsTimeLimit() {
        let recipes = [recipe("Slow", minutes: 40, ["egg"]), recipe("Quick", minutes: 10, ["egg"])]
        #expect(FallbackRecipes.best(for: ["egg"], maxMinutes: 15, from: recipes).map(\.title) == ["Quick"])
    }

    @Test func skipsRecipesThePantryAddsNothingTo() {
        let recipes = [recipe("Staples", ["salt", "water", "spinach"])]
        #expect(FallbackRecipes.best(for: ["egg"], maxMinutes: nil, from: recipes).isEmpty)
    }

    @Test func findsBundledRecipesForATypicalPantry() {
        let best = FallbackRecipes.best(for: ["egg", "spinach", "cheddar cheese", "bread", "butter"], maxMinutes: 30)
        #expect(best.count == 3)
        #expect(best.first?.title == "Spinach & Cheddar Omelette")
    }
}
