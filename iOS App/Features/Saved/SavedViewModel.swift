import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SavedViewModel {
    private(set) var recipes: [SavedRecipe] = []

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() {
        recipes = (try? context.fetch(FetchDescriptor<SavedRecipe>(sortBy: [SortDescriptor(\.savedAt, order: .reverse)]))) ?? []
    }

    func delete(_ recipe: SavedRecipe) {
        context.delete(recipe)
        load()
    }

    /// Recipe-book dishes with a matching photo that aren't saved yet, so the tab always has something to browse.
    var picks: [RecipeSuggestion] {
        let saved = Set(recipes.map(\.title))
        return Array(FallbackRecipes.all
            .filter { RecipeArt.photo(title: $0.title) != nil && !saved.contains($0.title) }
            .prefix(6))
    }

    func detailViewModel(for recipe: RecipeSuggestion) -> RecipeDetailViewModel {
        RecipeDetailViewModel(recipe: recipe, context: context)
    }

    func detailViewModel(for saved: SavedRecipe) -> RecipeDetailViewModel {
        let recipe = RecipeSuggestion(
            title: saved.title,
            minutes: saved.minutes,
            difficulty: saved.difficulty,
            ingredients: saved.ingredients,
            amounts: saved.amounts,
            steps: saved.steps
        )
        return RecipeDetailViewModel(recipe: recipe, context: context)
    }
}
