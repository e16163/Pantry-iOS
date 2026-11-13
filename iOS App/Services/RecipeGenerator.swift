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
    var unavailableMessage: String? {
        Self.message(for: SystemLanguageModel.default.availability)
    }

    static func message(for availability: SystemLanguageModel.Availability) -> String? {
        switch availability {
        case .available:
            nil
        case .unavailable(.deviceNotEligible):
            "This device doesn't support Apple Intelligence, so recipe ideas aren't available."
        case .unavailable(.appleIntelligenceNotEnabled):
            "Turn on Apple Intelligence in Settings to get recipe ideas."
        case .unavailable(.modelNotReady):
            "Apple Intelligence is still getting ready. Try again in a few minutes."
        case .unavailable:
            "Apple Intelligence isn't available on this device."
        }
    }

    func recipes(from ingredients: [String], maxMinutes: Int? = nil) async throws -> [RecipeSuggestion] {
        let timeRule = maxMinutes.map { " Each recipe must take at most \($0) minutes in total." } ?? ""
        let session = LanguageModelSession(instructions: """
            You suggest simple home recipes. Use only the ingredients the user lists, \
            plus basic staples: salt, pepper, oil, and water. Never add other ingredients. \
            Name each ingredient exactly as it appears in the user's list.
            """)
        let response = try await session.respond(
            to: "My ingredients: \(ingredients.joined(separator: ", ")). Suggest 3 different recipes.\(timeRule)",
            generating: RecipeList.self
        )
        return response.content.recipes
    }
}
