import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SuggestViewModel {
    static let timeLimits = [15, 30, 60]

    private(set) var recipes: [RecipeSuggestion] = []
    private(set) var isGenerating = false
    private(set) var isLoadingMore = false
    /// False once neither Apple Intelligence nor the recipe book has anything new to add.
    private(set) var hasMore = true
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
    private let generator: RecipeGenerator

    init(context: ModelContext, generator: RecipeGenerator = RecipeGenerator()) {
        self.context = context
        self.generator = generator
    }

    /// Call when the screen appears, since the pantry is edited on another tab.
    func refreshPantry() {
        pantryNames = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        pantryCount = pantryNames.count
        generator.prewarm()
    }

    private var pantryNames: [String] = []

    /// How many of the recipe's ingredients are already in the pantry (staples count as on hand).
    func onHandCount(for recipe: RecipeSuggestion) -> Int {
        Int((PantryCheck.coverage(of: recipe, pantry: pantryNames) * Double(recipe.ingredients.count)).rounded())
    }

    /// Shows recipe-book matches right away, then puts newly written recipes on top when they're ready.
    func generate() async {
        errorMessage = nil
        hasMore = true
        fallbackNotice = nil
        let names = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        guard !names.isEmpty else { return }
        let limit = maxMinutes
        run += 1
        let thisRun = run
        recipes = FallbackRecipes.best(for: names, maxMinutes: limit)
        isGenerating = true
        defer { if run == thisRun { isGenerating = false } }
        do {
            let shown = Set(recipes.map(\.title))
            let fresh = try await generator.recipes(from: names, maxMinutes: limit, excluding: recipes.map(\.title))
                .filter { Self.isUsable($0, pantry: names, maxMinutes: limit) && !shown.contains($0.title) }
            guard run == thisRun else { return }  // a newer search replaced this one
            recipes = fresh + recipes
            if recipes.isEmpty { errorMessage = "Couldn't find recipes that fit. Try again or allow more time." }
        } catch let error as RecipeGenerator.Unavailable {
            guard run == thisRun else { return }
            // The reason reads as a note above book recipes, so it isn't shown on its own.
            if recipes.isEmpty { errorMessage = Self.noBookMatchMessage } else { fallbackNotice = error.message }
        } catch {
            guard run == thisRun else { return }
            report(RecipeGenerator.message(for: error))
        }
    }

    nonisolated static let noBookMatchMessage =
        "None of the built-in recipes fit your pantry yet. Add a few more ingredients or allow more time."

    /// Bumped by every search, so an older one that finishes late doesn't overwrite newer results.
    private var run = 0

    /// Keeps the recipe-book results with `reason` as a notice, or shows only the error if there are none.
    private func report(_ reason: String) {
        if recipes.isEmpty { errorMessage = reason } else { fallbackNotice = reason }
    }

    /// Recipes that fit the selected time, so switching chips takes effect right away.
    var visibleRecipes: [RecipeSuggestion] {
        recipes.filter { $0.minutes <= (maxMinutes ?? .max) }
    }

    /// Swipe-across rows above the full list. Rows don't repeat each other, need at least two recipes,
    /// and only show once there are enough recipes that they aren't just the list again.
    var shelves: [(title: String, recipes: [RecipeSuggestion])] {
        guard visibleRecipes.count >= 6 else { return [] }
        let ready = visibleRecipes.filter { onHandCount(for: $0) >= $0.ingredients.count }
        let readyTitles = Set(ready.map(\.title))
        // Pointless when the time chip already limits everything to 15 minutes.
        let quick = (maxMinutes ?? .max) > 15
            ? visibleRecipes.filter { $0.minutes <= 15 && !readyTitles.contains($0.title) } : []
        return [("You have everything", ready), ("Ready in 15 min", quick)].filter { $0.recipes.count >= 2 }
    }

    /// Adds more recipes below the current ones: newly written ones, else the next recipe-book matches.
    func loadMore() async {
        let names = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        let shown = Set(recipes.map(\.title))
        let limit = maxMinutes
        isLoadingMore = true
        defer { isLoadingMore = false }
        var fresh: [RecipeSuggestion] = []
        // No cap: every load is a new model call. A call whose recipes all fail the pantry check gets retried,
        // so one off batch doesn't stop the feed.
        for _ in 0..<3 where fresh.isEmpty {
            guard let more = try? await generator.recipes(from: names, maxMinutes: limit,
                                                          excluding: recipes.map(\.title)) else { break }
            fresh = more.filter { Self.isUsable($0, pantry: names, maxMinutes: limit) && !shown.contains($0.title) }
        }
        if fresh.isEmpty {
            fresh = Array(FallbackRecipes.best(for: names, maxMinutes: limit, limit: .max)
                .filter { !shown.contains($0.title) }
                .prefix(6))
        }
        recipes += fresh
        // The models can always write more, so only the recipe book ever runs out.
        hasMore = !fresh.isEmpty
    }

    /// A generated recipe is shown only if it uses just the pantry (plus staples) and fits the time limit.
    nonisolated static func isUsable(_ recipe: RecipeSuggestion, pantry: [String], maxMinutes: Int?) -> Bool {
        PantryCheck.usesOnlyPantry(recipe, pantry: pantry) && recipe.minutes <= (maxMinutes ?? .max)
    }

    func detailViewModel(for recipe: RecipeSuggestion) -> RecipeDetailViewModel {
        RecipeDetailViewModel(recipe: recipe, context: context)
    }
}
