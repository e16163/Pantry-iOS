import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if !viewModel.recipes.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Your go-to recipes", subtitle: "Press and hold a recipe to remove it")
                        ForEach(viewModel.recipes) { saved in
                            NavigationLink {
                                RecipeDetailView(viewModel: viewModel.detailViewModel(for: saved))
                            } label: {
                                RecipeCard(title: saved.title, minutes: saved.minutes, difficulty: saved.difficulty,
                                           ingredients: saved.ingredients)
                                    .overlay(alignment: .topTrailing) {
                                        Image(systemName: "heart.fill")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color.brand, in: .circle)
                                            .padding(12)
                                            .accessibilityHidden(true)
                                    }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Remove from Favorites", systemImage: "heart.slash", role: .destructive) {
                                    viewModel.delete(saved)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .overlay {
                if viewModel.recipes.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("No favorites yet")
                        } icon: {
                            Image(.emptySaved).illustration()
                        }
                    } description: {
                        Text("Tap the heart on a recipe to keep it here.")
                    }
                }
            }
            .navigationTitle("Favorites")
            .toolbarTitleDisplayMode(.inlineLarge)
            .onAppear(perform: viewModel.load)
        }
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
