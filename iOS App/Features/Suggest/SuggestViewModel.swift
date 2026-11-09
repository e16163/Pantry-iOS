import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SuggestViewModel {
    private(set) var recipes: [RecipeSuggestion] = []
    private(set) var isGenerating = false
    private(set) var errorMessage: String?

    private let context: ModelContext
    private let generator = RecipeGenerator()

    init(context: ModelContext) {
        self.context = context
    }

    func generate() async {
        errorMessage = nil
        guard generator.isAvailable else {
            errorMessage = "Apple Intelligence isn't available on this device."
            return
        }
        let pantry = (try? context.fetch(FetchDescriptor<PantryItem>())) ?? []
        guard !pantry.isEmpty else {
            errorMessage = "Add some ingredients to your pantry first."
            return
        }
        isGenerating = true
        defer { isGenerating = false }
        do {
            recipes = try await generator.recipes(from: pantry.map(\.name))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func detailViewModel(for recipe: RecipeSuggestion) -> RecipeDetailViewModel {
        RecipeDetailViewModel(recipe: recipe, context: context)
    }
}
