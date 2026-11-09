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
        pantryCount = (try? context.fetchCount(FetchDescriptor<PantryItem>())) ?? 0
    }

    func generate() async {
        errorMessage = nil
        guard generator.isAvailable else {
            errorMessage = "Apple Intelligence isn't available on this device."
            return
        }
        let names = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        guard !names.isEmpty else { return }
        isGenerating = true
        defer { isGenerating = false }
        do {
            let limit = maxMinutes
            recipes = try await generator.recipes(from: names, maxMinutes: limit)
                .filter { Self.isUsable($0, pantry: names, maxMinutes: limit) }
            if recipes.isEmpty {
                errorMessage = "Couldn't find recipes that fit. Try again or allow more time."
            }
        } catch {
            errorMessage = error.localizedDescription
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
