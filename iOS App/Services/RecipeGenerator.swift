import Foundation
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
    @Guide(.count(3))
    var recipes: [RecipeSuggestion]
}

extension RecipeSuggestion {
    /// "1 cup" for spinach, or nil when the recipe didn't say.
    func amount(for ingredient: String) -> String? {
        guard let index = ingredients.firstIndex(of: ingredient), amounts.indices.contains(index),
              !amounts[index].isEmpty else { return nil }
        return amounts[index]
    }
}

@MainActor
final class RecipeGenerator {
    /// A session loaded ahead of time, so tapping Find recipes doesn't wait for the model to load.
    private var warmSession: LanguageModelSession?
    /// Asks Gemini through Pantry's Worker first (a few seconds); Apple Intelligence on device takes 30 s or more.
    private let online: Bool

    /// Tests pass `online: false` so they don't call the Worker.
    nonisolated init(online: Bool = true) {
        self.online = online
    }

    /// Call when the Suggest screen appears.
    func prewarm() {
        guard warmSession == nil, unavailableMessage == nil else { return }
        let session = Self.makeSession()
        session.prewarm()
        warmSession = session
    }

    var unavailableMessage: String? {
        Self.message(for: SystemLanguageModel.default.availability)
    }

    nonisolated static func message(for availability: SystemLanguageModel.Availability) -> String? {
        switch availability {
        case .available:
            nil
        case .unavailable(.deviceNotEligible):
            "This iPhone doesn't support Apple Intelligence, so these come from Pantry's built-in recipe book. They all match what's in your pantry."
        case .unavailable(.appleIntelligenceNotEnabled):
            "These come from Pantry's built-in recipe book. Turn on Apple Intelligence in Settings to also get new recipes written for your pantry."
        case .unavailable(.modelNotReady):
            "Apple Intelligence is still getting ready, so these come from Pantry's built-in recipe book for now."
        case .unavailable:
            "Apple Intelligence isn't available right now, so these come from Pantry's built-in recipe book."
        }
    }

    nonisolated static let safetyMessage = "The AI's safety filter blocked these ingredients. Try removing one."
    nonisolated static let busyMessage = "Too many requests. Wait a moment and try again."
    nonisolated static let tooLongMessage = "Too many ingredients at once. Try fewer."
    nonisolated static let genericMessage = "Couldn't come up with recipes right now. Try again."

    nonisolated static func message(for error: Error) -> String {
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
        if online, let fresh = try? await Self.onlineRecipes(from: ingredients, maxMinutes: maxMinutes,
                                                             excluding: excluding), !fresh.isEmpty {
            return fresh
        }
        // Without a connection, Apple Intelligence writes them; the caller shows why if it can't.
        if let message = unavailableMessage { throw Unavailable(message: message) }
        let session = warmSession ?? Self.makeSession()
        warmSession = nil
        let response = try await session.respond(
            to: "My ingredients: \(ingredients.joined(separator: ", ")). Suggest 3 different recipes.\(timeRule)\(repeatRule)",
            generating: RecipeList.self
        )
        return response.content.recipes
    }

    struct Unavailable: Error {
        let message: String
    }

    private static func onlineRecipes(from ingredients: [String], maxMinutes: Int?,
                                      excluding: [String]) async throws -> [RecipeSuggestion] {
        struct Request: Encodable { let ingredients: [String]; let maxMinutes: Int?; let excluding: [String] }
        struct Recipe: Decodable {
            let title: String, minutes: Int, difficulty: String, ingredients: [String], amounts: [String], steps: [String]
        }
        struct Response: Decodable { let recipes: [Recipe] }
        var request = URLRequest(url: RecipeArt.server.appending(path: "recipes"), timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Request(ingredients: ingredients, maxMinutes: maxMinutes,
                                                            excluding: Array(excluding.suffix(40))))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }
        return try JSONDecoder().decode(Response.self, from: data).recipes.map {
            RecipeSuggestion(title: $0.title, minutes: $0.minutes, difficulty: $0.difficulty,
                             ingredients: $0.ingredients.map { $0.lowercased() }, amounts: $0.amounts, steps: $0.steps)
        }
    }

    private static func makeSession() -> LanguageModelSession {
        LanguageModelSession(instructions: """
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
    }
}
