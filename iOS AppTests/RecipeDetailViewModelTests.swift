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

    @Test func pantryIngredientsStartChecked() {
        container.mainContext.insert(PantryItem(name: "egg"))
        let detail = RecipeDetailViewModel(
            recipe: RecipeSuggestion(title: "Omelette", minutes: 10, difficulty: "Easy",
                                     ingredients: ["egg", "spinach"], steps: []),
            context: container.mainContext
        )
        #expect(detail.checked == ["egg"])
    }

    @Test func tappingChecksThenUnchecksOnlyThatIngredient() {
        viewModel.toggle("egg")
        #expect(viewModel.checked == ["egg"])
        viewModel.toggle("egg")
        #expect(viewModel.checked.isEmpty)
    }
}
