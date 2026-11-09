import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel

    init(viewModel: RecipeDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Text("\(viewModel.recipe.minutes) min · \(viewModel.recipe.difficulty)")
            }
            Section("Ingredients") {
                ForEach(viewModel.recipe.ingredients, id: \.self) { Text($0) }
            }
            Section("Steps") {
                ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                    Text("\(index + 1). \(step)")
                }
            }
        }
        .navigationTitle(viewModel.recipe.title)
        .toolbar {
            Button(viewModel.isSaved ? "Saved" : "Save",
                   systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                   action: viewModel.toggleSave)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(viewModel: RecipeDetailViewModel(
            recipe: RecipeSuggestion(title: "Spinach & Tomato Omelette", minutes: 10, difficulty: "Easy",
                                     ingredients: ["egg", "spinach", "tomato"],
                                     steps: ["Whisk the eggs.", "Sauté spinach and tomato.", "Add eggs and cook."]),
            context: ModelContainer.preview.mainContext
        ))
    }
}
