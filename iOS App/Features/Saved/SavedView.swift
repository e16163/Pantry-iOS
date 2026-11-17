import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if !viewModel.recipes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.section) {
                        PageTitle(title: "Saved", subtitle: "Press and hold a recipe to remove it")
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
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, 8)
                    .padding(.bottom, Spacing.section)
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
            #if os(iOS)
            .toolbarVisibility(.hidden, for: .navigationBar)
            #endif
            .onAppear(perform: viewModel.load)
        }
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
