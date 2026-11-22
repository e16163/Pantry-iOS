import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class RecipeDetailViewModel {
    let recipe: RecipeSuggestion
    private(set) var isSaved = false
    private(set) var checked: Set<String> = []

    private let context: ModelContext

    init(recipe: RecipeSuggestion, context: ModelContext) {
        self.recipe = recipe
        self.context = context
        isSaved = savedCopy() != nil
        // Start with what's already in the pantry ticked, so only the missing ones need attention.
        let pantry = ((try? context.fetch(FetchDescriptor<PantryItem>())) ?? []).map(\.name)
        checked = PantryCheck.onHand(in: recipe, pantry: pantry)
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
                amounts: recipe.amounts,
                steps: recipe.steps
            ))
        }
        isSaved = savedCopy() != nil
    }

    func toggle(_ ingredient: String) {
        if checked.remove(ingredient) == nil {
            checked.insert(ingredient)
        }
    }

    /// Catalog category for an ingredient name, `.other` if it's not in the catalog.
    func category(of ingredient: String) -> IngredientCategory {
        let name = IngredientName.normalize(ingredient)
        return IngredientCatalog.all.first { $0.name == name }?.category ?? .other
    }

    func cookViewModel() -> CookViewModel {
        CookViewModel(title: recipe.title, steps: recipe.steps)
    }

    private func savedCopy() -> SavedRecipe? {
        let title = recipe.title
        let descriptor = FetchDescriptor<SavedRecipe>(predicate: #Predicate { $0.title == title })
        return try? context.fetch(descriptor).first
    }
}
