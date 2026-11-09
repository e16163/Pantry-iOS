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
                    if let message = viewModel.errorMessage {
                        Text(message).foregroundStyle(.red)
                    }
                } footer: {
                    if viewModel.pantryCount == 0 {
                        Text("Add ingredients in the Pantry tab first.")
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
