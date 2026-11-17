import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SuggestViewModel {
    static let timeLimits = [15, 30, 60]

    private(set) var recipes: [RecipeSuggestion] = []
    private(set) var isGenerating = false
    private(set) var errorMessage: String?
    /// Why the shown recipes came from the bundled recipe book instead of the model; nil for model recipes.
    private(set) var fallbackNotice: String?
    private(set) var pantryCount = 0
    /// Longest total time a recipe may take, in minutes; nil means any.
    var maxMinutes: Int?

    var canGenerate: Bool {
        pantryCount > 0 && !isGenerating
    }

    private let context: ModelContext
    private let generator = RecipeGenerator()

    init(context: ModelContext) {
        self.context = context
    }

    /// Call when the screen appears, since the pantry is edited on another tab.
    func refreshPantry() {
        pantryNames = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        pantryCount = pantryNames.count
    }

    private var pantryNames: [String] = []

    /// How many of the recipe's ingredients are already in the pantry (staples count as on hand).
    func onHandCount(for recipe: RecipeSuggestion) -> Int {
        Int((PantryCheck.coverage(of: recipe, pantry: pantryNames) * Double(recipe.ingredients.count)).rounded())
    }

    func generate() async {
        errorMessage = nil
        fallbackNotice = nil
        let names = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        guard !names.isEmpty else { return }
        let limit = maxMinutes
        if let message = generator.unavailableMessage {
            useFallback(pantry: names, maxMinutes: limit, reason: message)
            return
        }
        isGenerating = true
        defer { isGenerating = false }
        do {
            recipes = try await generator.recipes(from: names, maxMinutes: limit)
                .filter { Self.isUsable($0, pantry: names, maxMinutes: limit) }
            if recipes.isEmpty {
                useFallback(pantry: names, maxMinutes: limit,
                            reason: "Couldn't find recipes that fit. Try again or allow more time.")
            }
        } catch {
            useFallback(pantry: names, maxMinutes: limit, reason: RecipeGenerator.message(for: error))
        }
    }

    /// Shows bundled recipes instead, keeping `reason` visible; shows only the error if none fit.
    private func useFallback(pantry: [String], maxMinutes: Int?, reason: String) {
        recipes = FallbackRecipes.best(for: pantry, maxMinutes: maxMinutes)
        if recipes.isEmpty {
            errorMessage = reason
        } else {
            fallbackNotice = reason
        }
    }

    /// A generated recipe is shown only if it uses just the pantry (plus staples) and fits the time limit.
    nonisolated static func isUsable(_ recipe: RecipeSuggestion, pantry: [String], maxMinutes: Int?) -> Bool {
        PantryCheck.usesOnlyPantry(recipe, pantry: pantry) && recipe.minutes <= (maxMinutes ?? .max)
    }

    func detailViewModel(for recipe: RecipeSuggestion) -> RecipeDetailViewModel {
        RecipeDetailViewModel(recipe: recipe, context: context)
    }
}
