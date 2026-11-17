import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    @State private var isCooking = false

    init(viewModel: RecipeDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(viewModel.recipe.title)
                        .font(.largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        StatTile(systemImage: "clock", value: "\(viewModel.recipe.minutes)", caption: "min")
                        StatTile(systemImage: "chart.bar", value: viewModel.recipe.difficulty, caption: "level")
                        StatTile(systemImage: "basket", value: "\(viewModel.recipe.ingredients.count)",
                                 caption: "ingredients")
                        StatTile(systemImage: "list.number", value: "\(viewModel.recipe.steps.count)", caption: "steps")
                    }
                    Button("Start cooking", systemImage: "frying.pan") { isCooking = true }
                        .buttonStyle(.primary)
                        .disabled(viewModel.recipe.steps.isEmpty)
                }
                .padding(.vertical, 6)
            }
            Section {
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
            } header: {
                Text("Ingredients")
            } footer: {
                Text("Tap to tick off what you've got out.")
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
        .toolbarTitleDisplayMode(.inline)  // the title is in the header, so the bar stays empty
        .contentMargins(.top, 4, for: .scrollContent)
        .toolbar {
            Button(viewModel.isSaved ? "Saved" : "Save",
                   systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                   action: viewModel.toggleSave)
        }
        #if os(macOS)
        .sheet(isPresented: $isCooking) { CookView(viewModel: viewModel.cookViewModel()) }
        #else
        .fullScreenCover(isPresented: $isCooking) { CookView(viewModel: viewModel.cookViewModel()) }
        #endif
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
