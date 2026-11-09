import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RecipeDetailViewModel {
    let recipe: RecipeSuggestion
    private(set) var isSaved = false

    private let context: ModelContext

    init(recipe: RecipeSuggestion, context: ModelContext) {
        self.recipe = recipe
        self.context = context
        isSaved = savedCopy() != nil
    }

    func toggleSave() {
        if let saved = savedCopy() {
            context.delete(saved)
        } else {
            context.insert(SavedRecipe(
                title: recipe.title,
                minutes: recipe.minutes,
                difficulty: recipe.difficulty,
                ingredients: recipe.ingredients,
                steps: recipe.steps
            ))
        }
        isSaved = savedCopy() != nil
    }

    private func savedCopy() -> SavedRecipe? {
        let title = recipe.title
        let descriptor = FetchDescriptor<SavedRecipe>(predicate: #Predicate { $0.title == title })
        return try? context.fetch(descriptor).first
    }
}
