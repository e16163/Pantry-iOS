/// Checks that a recipe only uses what's in the pantry, since the model sometimes invents ingredients.
enum PantryCheck {
    /// Always allowed, even if they're not in the pantry. Matches the generator's instructions.
    static let staples: Set<String> = ["salt", "pepper", "black pepper", "oil", "olive oil", "vegetable oil", "water"]

    /// True if every ingredient is a staple or covered by a pantry item.
    /// A general name is covered by a more specific pantry item ("cheese" by "cheddar cheese").
    static func usesOnlyPantry(_ recipe: RecipeSuggestion, pantry: [String]) -> Bool {
        let allowed = staples.union(pantry.map(IngredientName.normalize))
        return recipe.ingredients.allSatisfy { ingredient in
            let name = IngredientName.normalize(ingredient)
            return allowed.contains { " \($0) ".contains(" \(name) ") }
        }
    }
}
