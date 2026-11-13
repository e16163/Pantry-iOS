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
                ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in
                    let isChecked = viewModel.checked.contains(ingredient)
                    Button {
                        viewModel.toggle(ingredient)
                    } label: {
                        Label {
                            Text(ingredient)
                                .strikethrough(isChecked)
                                .foregroundStyle(isChecked ? .secondary : .primary)
                        } icon: {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.tint)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isChecked ? .isSelected : [])
                }
            }
            Section("Steps") {
                ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(index + 1)")
                            .monospacedDigit()
                            .fontWeight(.bold)
                            .foregroundStyle(.tint)
                        Text(step)
                    }
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
