import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.section) {
                    PageTitle(title: "Saved",
                              subtitle: viewModel.recipes.isEmpty
                                ? "Recipes you bookmark show up here"
                                : "Press and hold a recipe to remove it")
                    if viewModel.recipes.isEmpty {
                        emptyCard
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
                    if !viewModel.picks.isEmpty {
                        SectionHeader(title: viewModel.recipes.isEmpty ? "Popular picks" : "More to try",
                                      subtitle: "From the Pantry recipe book")
                            .padding(.top, viewModel.recipes.isEmpty ? 0 : 8)
                        ForEach(viewModel.picks, id: \.title) { recipe in
                            NavigationLink {
                                RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                            } label: {
                                RecipeCard(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty,
                                           ingredients: recipe.ingredients)
                            }
                            .buttonStyle(.plain)
                        }
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
}

extension SavedView {
    private var emptyCard: some View {
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
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.fill, in: .rect(cornerRadius: 12))
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
