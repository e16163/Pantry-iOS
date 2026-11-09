import FoundationModels

@Generable
struct RecipeSuggestion {
    @Guide(description: "Short, appetizing recipe name")
    var title: String
    @Guide(description: "Total time to make it, in minutes")
    var minutes: Int
    @Guide(.anyOf(["Easy", "Medium", "Hard"]))
    var difficulty: String
    @Guide(description: "Ingredients used, each a short lowercase name")
    var ingredients: [String]
    @Guide(description: "Cooking steps in order, one short sentence each")
    var steps: [String]
}

@Generable
private struct RecipeList {
    @Guide(.count(3))
    var recipes: [RecipeSuggestion]
}

/// Generates recipes from pantry ingredients with Apple's on-device model.
struct RecipeGenerator {
    var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func recipes(from ingredients: [String]) async throws -> [RecipeSuggestion] {
        let session = LanguageModelSession(instructions: """
            You suggest simple home recipes. Use only the ingredients the user lists, \
            plus basic staples: salt, pepper, oil, and water. Never add other ingredients.
            """)
        let response = try await session.respond(
            to: "My ingredients: \(ingredients.joined(separator: ", ")). Suggest 3 different recipes.",
            generating: RecipeList.self
        )
        return response.content.recipes
    }
}
