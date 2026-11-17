import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    /// Recipe-book dishes that have a matching photo, so the page has something to browse.
    private static let picks = FallbackRecipes.all.filter { RecipeArt.photo(title: $0.title) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    PageTitle(title: "Saved",
                              subtitle: viewModel.recipes.isEmpty ? nil : "Press and hold a recipe to remove it")
                    if viewModel.recipes.isEmpty {
                        emptyState
                    }
                    ForEach(viewModel.recipes) { saved in
                        NavigationLink {
                            RecipeDetailView(viewModel: viewModel.detailViewModel(for: saved))
                        } label: {
                            RecipeCard(title: saved.title, minutes: saved.minutes, difficulty: saved.difficulty,
                                       ingredients: saved.ingredients)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove from Saved", systemImage: "trash", role: .destructive) {
                                viewModel.delete(saved)
                            }
                        }
                    }
                    if !unsavedPicks.isEmpty {
                        SectionHeader(title: "Popular picks", subtitle: "From the Pantry recipe book")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(unsavedPicks, id: \.title) { recipe in
                                    NavigationLink {
                                        RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                                    } label: {
                                        RecipeCard(title: recipe.title, minutes: recipe.minutes,
                                                   difficulty: recipe.difficulty, ingredients: recipe.ingredients)
                                            .frame(width: 280)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Spacing.page)
                        }
                        .padding(.horizontal, -Spacing.page)
                    }
                }
                .padding(.horizontal, Spacing.page)
                .padding(.top, 8)
                .padding(.bottom, Spacing.section)
            }
            .navigationTitle("Saved")
            #if os(iOS)
            .toolbarVisibility(.hidden, for: .navigationBar)
            #endif
            .onAppear(perform: viewModel.load)
        }
    }

    private var unsavedPicks: [RecipeSuggestion] {
        let savedTitles = Set(viewModel.recipes.map(\.title))
        return Self.picks.filter { !savedTitles.contains($0.title) }
    }

    private var emptyState: some View {
        HStack(spacing: 16) {
            Image(.emptySaved)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("No saved recipes yet")
                    .font(.headline)
                Text("Tap the bookmark on any recipe to keep it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.fill, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
