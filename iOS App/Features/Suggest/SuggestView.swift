import SwiftData
import SwiftUI

struct SuggestView: View {
    @Bindable var viewModel: SuggestViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("How much time do you have?")
                            .font(.headline)
                        HStack(spacing: 8) {
                            ForEach(SuggestViewModel.timeLimits, id: \.self) { minutes in
                                Chip(title: "≤\(minutes) min", isSelected: viewModel.maxMinutes == minutes) {
                                    viewModel.maxMinutes = minutes
                                }
                            }
                            Chip(title: "Any", isSelected: viewModel.maxMinutes == nil) {
                                viewModel.maxMinutes = nil
                            }
                        }
                        Button {
                            Task { await viewModel.generate() }
                        } label: {
                            if viewModel.isGenerating {
                                HStack(spacing: 10) {
                                    ProgressView().tint(.gray)
                                    Text("Thinking up recipes…")
                                }
                            } else {
                                Label("Generate recipes", systemImage: "sparkles")
                            }
                        }
                        .buttonStyle(.primary)
                        .disabled(!viewModel.canGenerate)
                    }
                    .padding(.vertical, 6)
                } footer: {
                    Text("^[\(viewModel.pantryCount) ingredient](inflect: true) in your pantry")
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
                if !viewModel.recipes.isEmpty {
                    Section {
                        ForEach(Array(viewModel.recipes.enumerated()), id: \.offset) { _, recipe in
                            NavigationLink {
                                RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                            } label: {
                                RecipeRow(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty,
                                          ingredientCount: recipe.ingredients.count,
                                          onHandCount: viewModel.onHandCount(for: recipe))
                            }
                        }
                    } header: {
                        Text(viewModel.fallbackNotice == nil ? "Recipes for you" : "From the recipe book")
                    } footer: {
                        if let notice = viewModel.fallbackNotice {
                            Text(notice)
                        }
                    }
                } header: {
                    if viewModel.fallbackNotice != nil {
                        Text("From the recipe book")
                    }
                } footer: {
                    if let notice = viewModel.fallbackNotice {
                        Text(notice)
                    }
                }
            }
            .navigationTitle("Suggest")
            .toolbarTitleDisplayMode(.inlineLarge)
            .contentMargins(.top, 4, for: .scrollContent)
            .onAppear(perform: viewModel.refreshPantry)
        }
    }
}

/// A recipe in a list: bold title, time and difficulty, and how many ingredients are on hand.
struct RecipeRow: View {
    let title: String
    let minutes: Int
    let difficulty: String
    let ingredientCount: Int
    /// nil when there's no pantry to compare against (Saved).
    var onHandCount: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title3.bold())
            HStack(spacing: 12) {
                Text("\(Image(systemName: "clock")) \(minutes) min")
                Text("\(Image(systemName: "chart.bar")) \(difficulty)")
                Text("\(Image(systemName: "basket")) \(ingredientCount)")
                    .accessibilityLabel("\(ingredientCount) ingredients")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            if let onHandCount {
                let missing = ingredientCount - onHandCount
                Label(missing == 0 ? "You have everything" : "You have \(onHandCount) of \(ingredientCount)",
                      systemImage: missing == 0 ? "checkmark.circle.fill" : "circle.lefthalf.filled")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(missing == 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SuggestView(viewModel: SuggestViewModel(context: ModelContainer.preview.mainContext))
}
