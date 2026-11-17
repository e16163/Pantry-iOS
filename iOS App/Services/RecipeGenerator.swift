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
    @Guide(description: "How much of each ingredient, in the same order as ingredients, like \"2 cups\", \"1 tbsp\" or \"3\"")
    var amounts: [String] = []
    @Guide(description: "5 to 8 detailed cooking steps in order, starting with prep. Each step is 1 to 3 sentences with the heat level, how long, and how to tell it's done, like \"Cook over medium heat for 3 to 4 minutes, until the edges set but the top is still glossy.\"")
    var steps: [String]
}

@Generable
private struct RecipeList {
    @Guide(.count(5))
    var recipes: [RecipeSuggestion]
}

/// Generates recipes from pantry ingredients with Apple's on-device model.
extension RecipeSuggestion {
    /// "1 cup" for spinach, or nil when the recipe didn't say.
    func amount(for ingredient: String) -> String? {
        guard let index = ingredients.firstIndex(of: ingredient), amounts.indices.contains(index),
              !amounts[index].isEmpty else { return nil }
        return amounts[index]
    }
}

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

    nonisolated static let safetyMessage = "That pantry tripped a safety filter. Try removing an ingredient."
    nonisolated static let busyMessage = "Too many requests. Wait a moment and try again."
    nonisolated static let tooLongMessage = "Too many ingredients at once. Try fewer."
    nonisolated static let genericMessage = "Couldn't come up with recipes right now. Try again."

    static func message(for error: Error) -> String {
        if #available(iOS 27, macOS 27, visionOS 27, *), let error = error as? LanguageModelError {
            switch error {
            case .guardrailViolation, .refusal: return safetyMessage
            case .rateLimited: return busyMessage
            case .contextSizeExceeded: return tooLongMessage
            default: return genericMessage
            }
        }
        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation, .refusal: return safetyMessage
            case .rateLimited: return busyMessage
            case .exceededContextWindowSize: return tooLongMessage
            default: return genericMessage
            }
        }
        return genericMessage
    }

    func recipes(from ingredients: [String], maxMinutes: Int? = nil,
                  excluding: [String] = []) async throws -> [RecipeSuggestion] {
        let timeRule = maxMinutes.map { " Each recipe must take at most \($0) minutes in total." } ?? ""
        // Last 30 titles only, to keep the prompt well inside the model's context window.
        let repeatRule = excluding.isEmpty ? "" : " Don't suggest these again: \(excluding.suffix(30).joined(separator: "; "))."
        let session = LanguageModelSession(instructions: """
            You are a home cook writing recipes for a cookbook. Use only the ingredients the user lists, \
            plus basic staples: salt, pepper, oil, and water. Never add other ingredients. \
            Name each ingredient exactly as it appears in the user's list. \
            Give an amount for every ingredient, for 2 servings. \
            Make the recipes clearly different from each other: mix cuisines (for example Italian, Mexican, \
            Asian, American, Mediterranean), meal types (breakfast, lunch, dinner, snack) and cooking methods \
            (pan-fried, baked, roasted, simmered, no-cook). \
            Write steps a beginner can follow without guessing: say how to cut things, the heat level, \
            how many minutes, and what it should look, smell or feel like when it's done.
            """)
        let response = try await session.respond(
            to: "My ingredients: \(ingredients.joined(separator: ", ")). Suggest 5 different recipes.\(timeRule)\(repeatRule)",
            generating: RecipeList.self
        )
        return response.content.recipes
    }
}
