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
                FoodPhoto(name: RecipeArt.photo(title: viewModel.recipe.title, ingredients: viewModel.recipe.ingredients),
                          fallbacks: ["dish-default"])
                    .frame(height: 300)
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.recipe.title)
                        .font(.system(size: 30, weight: .heavy))
                        .tracking(-0.5)
                        .fixedSize(horizontal: false, vertical: true)
                    RecipeMeta(minutes: viewModel.recipe.minutes, difficulty: viewModel.recipe.difficulty,
                               ingredientCount: viewModel.recipe.ingredients.count)
                }
                .padding(Spacing.page)
                .padding(.top, 4)
                SectionDivider()
                ingredients
                    .padding(Spacing.page)
                    .padding(.vertical, 8)
                SectionDivider()
                steps
                    .padding(Spacing.page)
                    .padding(.vertical, 8)
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            Button("Start cooking", systemImage: "frying.pan") { isCooking = true }
                .buttonStyle(.primary)
                .disabled(viewModel.recipe.steps.isEmpty)
                .padding(.horizontal, Spacing.page)
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
                        Thumbnail(photo: .ingredient(ingredient, category: viewModel.category(of: ingredient)))
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
