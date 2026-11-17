import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if !viewModel.recipes.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionHeader(title: "Your favorites", subtitle: "Press and hold a recipe to remove it")
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
                    }
                    .padding()
                }
            }
            .overlay {
                if viewModel.recipes.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("No saved recipes")
                        } icon: {
                            Image(.emptySaved).illustration()
                        }
                    } description: {
                        Text("Tap the bookmark on a recipe to keep it here.")
                    }
                }
            }
            .navigationTitle("Saved")
            .toolbarTitleDisplayMode(.inlineLarge)
            .onAppear(perform: viewModel.load)
        }
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
