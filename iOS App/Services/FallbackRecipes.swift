import Foundation

/// Bundled recipes from `fallback_recipes.json`, shown when the on-device model can't generate any.
enum FallbackRecipes {
    private struct Entry: Decodable {
        let title: String
        let minutes: Int
        let difficulty: String
        let ingredients: [String]
        let amounts: [String]?
        let steps: [String]
    }

    /// Decoded once, on first use.
    static let all: [RecipeSuggestion] = {
        let url = Bundle.main.url(forResource: "fallback_recipes", withExtension: "json")!
        return try! JSONDecoder().decode([Entry].self, from: Data(contentsOf: url)).map {
            RecipeSuggestion(title: $0.title, minutes: $0.minutes, difficulty: $0.difficulty,
                             ingredients: $0.ingredients, amounts: $0.amounts ?? [], steps: $0.steps)
        }
    }()

    /// The best `limit` recipes for this pantry: most ingredients on hand first, within the time limit.
    /// Recipes that use nothing beyond staples, or need more than half their ingredients bought, are skipped.
    static func best(for pantry: [String], maxMinutes: Int?, from recipes: [RecipeSuggestion] = all,
                     limit: Int = 6) -> [RecipeSuggestion] {
        let staplesOnly = Array(PantryCheck.staples)
        return recipes
            .filter { $0.minutes <= (maxMinutes ?? .max) }
            .map { (recipe: $0, score: PantryCheck.coverage(of: $0, pantry: pantry),
                    base: PantryCheck.coverage(of: $0, pantry: staplesOnly)) }
            .filter { $0.score >= 0.5 && $0.score > $0.base }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map(\.recipe)
    }
}
