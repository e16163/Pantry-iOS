/// Checks that a recipe only uses what's in the pantry, since the model sometimes invents ingredients.
enum PantryCheck {
    /// Always allowed, even if they're not in the pantry. Matches the generator's instructions.
    static let staples: Set<String> = ["salt", "pepper", "black pepper", "oil", "olive oil", "vegetable oil", "water"]

    /// True if every ingredient is a staple or covered by a pantry item.
    /// A general name is covered by a more specific pantry item ("cheese" by "cheddar cheese").
    static func usesOnlyPantry(_ recipe: RecipeSuggestion, pantry: [String]) -> Bool {
        let allowed = allowed(pantry)
        return recipe.ingredients.allSatisfy { isCovered($0, by: allowed) }
    }

    /// Fraction of the recipe's ingredients that the pantry (plus staples) covers, from 0 to 1.
    static func coverage(of recipe: RecipeSuggestion, pantry: [String]) -> Double {
        guard !recipe.ingredients.isEmpty else { return 0 }
        return Double(onHand(in: recipe, pantry: pantry).count) / Double(recipe.ingredients.count)
    }

    /// The recipe's ingredients that the pantry (plus staples) covers, spelled as in the recipe.
    static func onHand(in recipe: RecipeSuggestion, pantry: [String]) -> Set<String> {
        let allowed = allowed(pantry)
        return Set(recipe.ingredients.filter { isCovered($0, by: allowed) })
    }

    private static func allowed(_ pantry: [String]) -> Set<String> {
        staples.union(pantry.map(IngredientName.normalize))
    }

    private static func isCovered(_ ingredient: String, by allowed: Set<String>) -> Bool {
        let name = IngredientName.normalize(ingredient)
        return allowed.contains { " \($0) ".contains(" \(name) ") }
    }
}
