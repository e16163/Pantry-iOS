import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    @State private var isCooking = false

    init(viewModel: RecipeDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                RecipeArtTile(title: viewModel.recipe.title, ingredients: viewModel.recipe.ingredients, emojiSize: 110)
                    .frame(height: 260)
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.recipe.title)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)
                    RecipeMeta(minutes: viewModel.recipe.minutes, difficulty: viewModel.recipe.difficulty,
                               ingredientCount: viewModel.recipe.ingredients.count)
                }
                .padding()
                SectionDivider()
                ingredients
                    .padding()
                SectionDivider()
                steps
                    .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            Button("Start cooking", systemImage: "frying.pan") { isCooking = true }
                .buttonStyle(.primary)
                .disabled(viewModel.recipe.steps.isEmpty)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            Button(viewModel.isSaved ? "Saved" : "Save",
                   systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark",
                   action: viewModel.toggleSave)
        }
        .sensoryFeedback(.success, trigger: viewModel.isSaved)
        #if os(macOS)
        .sheet(isPresented: $isCooking) { CookView(viewModel: viewModel.cookViewModel()) }
        #else
        .fullScreenCover(isPresented: $isCooking) { CookView(viewModel: viewModel.cookViewModel()) }
        #endif
    }

    private var ingredients: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Ingredients", subtitle: "Tap to tick off what you've got out")
            ForEach(viewModel.recipe.ingredients, id: \.self) { ingredient in
                let isChecked = viewModel.checked.contains(ingredient)
                Button {
                    viewModel.toggle(ingredient)
                } label: {
                    HStack(spacing: 14) {
                        Text(IngredientEmoji.emoji(for: ingredient, category: viewModel.category(of: ingredient)))
                            .font(.title2)
                            .frame(width: 52, height: 52)
                            .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 8))
                        Text(ingredient)
                            .font(.body.weight(.medium))
                            .strikethrough(isChecked)
                            .foregroundStyle(isChecked ? .secondary : .primary)
                        Spacer()
                        Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isChecked ? Color.brand : .secondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChecked ? .isSelected : [])
            }
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Steps", subtitle: "^[\(viewModel.recipe.steps.count) step](inflect: true)")
            ForEach(Array(viewModel.recipe.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(.background)
                        .frame(width: 28, height: 28)
                        .background(.primary, in: .circle)
                    Text(step)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
