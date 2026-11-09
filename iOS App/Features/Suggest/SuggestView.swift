import SwiftData
import SwiftUI

struct SuggestView: View {
    var viewModel: SuggestViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if viewModel.isGenerating {
                        ProgressView("Thinking up recipes…")
                    } else {
                        Button("Generate recipes") {
                            Task { await viewModel.generate() }
                        }
                    }
                    if let message = viewModel.errorMessage {
                        Text(message).foregroundStyle(.red)
                    }
                }
                Section {
                    ForEach(viewModel.recipes, id: \.title) { recipe in
                        NavigationLink {
                            RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                        } label: {
                            RecipeRow(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty)
                        }
                    }
                }
            }
            .navigationTitle("Suggest")
        }
    }
}

struct RecipeRow: View {
    let title: String
    let minutes: Int
    let difficulty: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text("\(minutes) min · \(difficulty)").foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SuggestView(viewModel: SuggestViewModel(context: ModelContainer.preview.mainContext))
}
