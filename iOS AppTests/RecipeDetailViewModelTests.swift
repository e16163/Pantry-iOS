import SwiftData
import Testing
@testable import iOS_App

struct RecipeDetailViewModelTests {
    let container: ModelContainer  // must outlive the view model's context
    let viewModel: RecipeDetailViewModel

    init() throws {
        container = try ModelContainer(
            for: PantryItem.self, SavedRecipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        viewModel = RecipeDetailViewModel(
            recipe: RecipeSuggestion(title: "Omelette", minutes: 10, difficulty: "Easy",
                                     ingredients: ["egg", "spinach"], steps: []),
            context: container.mainContext
        )
    }

    @Test func nothingIsCheckedAtFirst() {
        #expect(viewModel.checked.isEmpty)
    }

    @Test func tappingChecksThenUnchecksOnlyThatIngredient() {
        viewModel.toggle("egg")
        #expect(viewModel.checked == ["egg"])
        viewModel.toggle("egg")
        #expect(viewModel.checked.isEmpty)
    }
}
