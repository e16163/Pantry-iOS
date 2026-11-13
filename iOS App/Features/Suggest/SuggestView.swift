import SwiftData
import SwiftUI

struct SuggestView: View {
    @Bindable var viewModel: SuggestViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Time", selection: $viewModel.maxMinutes) {
                        ForEach(SuggestViewModel.timeLimits, id: \.self) { minutes in
                            Text("≤\(minutes) min").tag(Int?.some(minutes))
                        }
                        Text("Any").tag(Int?.none)
                    }
                    .pickerStyle(.segmented)
                    if viewModel.isGenerating {
                        ProgressView("Thinking up recipes…")
                    } else {
                        Button("Generate recipes") {
                            Task { await viewModel.generate() }
                        }
                        .disabled(!viewModel.canGenerate)
                    }
                }
                if let message = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label {
                            Text("No recipes this time")
                        } icon: {
                            Image(.error).illustration()
                        }
                    } description: {
                        Text(message)
                    }
                } else if viewModel.recipes.isEmpty && !viewModel.isGenerating {
                    ContentUnavailableView {
                        Label {
                            Text("Ready when you are")
                        } icon: {
                            Image(.suggestReady).illustration()
                        }
                    } description: {
                        Text(viewModel.pantryCount == 0
                             ? "Add ingredients in the Pantry tab first."
                             : "Pick a time, then tap Generate recipes.")
                    }
                }
                Section {
                    ForEach(Array(viewModel.recipes.enumerated()), id: \.offset) { _, recipe in
                        NavigationLink {
                            RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                        } label: {
                            RecipeRow(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty)
                        }
                    }
                }
            }
            .navigationTitle("Suggest")
            .onAppear(perform: viewModel.refreshPantry)
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
