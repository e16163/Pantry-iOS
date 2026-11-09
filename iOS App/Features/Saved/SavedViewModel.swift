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

    func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recipes[index])
        }
        load()
    }

    func detailViewModel(for saved: SavedRecipe) -> RecipeDetailViewModel {
        let recipe = RecipeSuggestion(
            title: saved.title,
            minutes: saved.minutes,
            difficulty: saved.difficulty,
            ingredients: saved.ingredients,
            steps: saved.steps
        )
        return RecipeDetailViewModel(recipe: recipe, context: context)
    }
}
