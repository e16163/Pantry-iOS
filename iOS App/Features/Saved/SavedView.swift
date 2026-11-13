import SwiftData
import SwiftUI

struct SavedView: View {
    var viewModel: SavedViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recipes) { saved in
                    NavigationLink {
                        RecipeDetailView(viewModel: viewModel.detailViewModel(for: saved))
                    } label: {
                        RecipeRow(title: saved.title, minutes: saved.minutes, difficulty: saved.difficulty)
                    }
                }
                .onDelete(perform: viewModel.delete)
            }
            .overlay {
                if viewModel.recipes.isEmpty {
                    ContentUnavailableView(
                        "No saved recipes",
                        systemImage: "bookmark",
                        description: Text("Tap the bookmark on a recipe to keep it here.")
                    )
                }
            }
            .navigationTitle("Saved")
            .onAppear(perform: viewModel.load)
        }
    }
}

#Preview {
    SavedView(viewModel: SavedViewModel(context: ModelContainer.preview.mainContext))
}
