import SwiftData
import SwiftUI

struct SuggestView: View {
    @Bindable var viewModel: SuggestViewModel

    private static let timeChips: [(emoji: String, title: String, minutes: Int?)] = [
        ("⚡️", "15 min", 15), ("⏱️", "30 min", 30), ("🍲", "1 hour", 60), ("✨", "Any time", nil),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Cooking with ^[\(viewModel.pantryCount) ingredient](inflect: true) from your pantry")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    hero
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.timeChips, id: \.title) { chip in
                                Chip(emoji: chip.emoji, title: chip.title, isSelected: viewModel.maxMinutes == chip.minutes) {
                                    viewModel.maxMinutes = chip.minutes
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    SectionDivider()
                    results
                        .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Suggest")
            .toolbarTitleDisplayMode(.inlineLarge)
            .onAppear(perform: viewModel.refreshPantry)
        }
    }

    /// Dark promo-style banner holding the main action.
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dinner from what\nyou've got.")
                .font(.title.bold())
            Text(viewModel.pantryCount == 0
                 ? "Add a few ingredients in the Pantry tab to get started."
                 : "Pick a time and we'll find recipes that use your pantry.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.trailing, 90)  // keep clear of the pan art
            Button {
                Task { await viewModel.generate() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGenerating {
                        ProgressView().tint(.black)
                        Text("Finding recipes…")
                    } else {
                        Text("Find recipes")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Color(red: 0.36, green: 0.84, blue: 0.53), in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGenerate)
            .opacity(viewModel.canGenerate || viewModel.isGenerating ? 1 : 0.5)
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(alignment: .trailing) {
            ZStack(alignment: .trailing) {
                Color(red: 0.09, green: 0.15, blue: 0.14)
                Text("🥘")
                    .font(.system(size: 110))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 28, y: 34)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
    }

    @ViewBuilder
    private var results: some View {
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
        } else if viewModel.isGenerating && viewModel.recipes.isEmpty {
            SectionHeader(title: "Recipes for you", subtitle: "Checking your pantry…")
            ForEach(0..<2, id: \.self) { _ in
                RecipeCard(title: "Placeholder recipe name", minutes: 20, difficulty: "Easy",
                           ingredients: ["one", "two", "three"])
                    .redacted(reason: .placeholder)
            }
        } else if viewModel.recipes.isEmpty {
            ContentUnavailableView {
                Label {
                    Text("Ready when you are")
                } icon: {
                    Image(.suggestReady).illustration()
                }
            } description: {
                Text(viewModel.pantryCount == 0
                     ? "Add ingredients in the Pantry tab first."
                     : "Pick a time, then tap Find recipes.")
            }
        } else {
            SectionHeader(title: "Recipes for you",
                          subtitle: viewModel.fallbackNotice == nil ? "Made from your pantry" : "From the Pantry recipe book")
            if let notice = viewModel.fallbackNotice {
                InfoBanner(systemImage: "book.closed", title: "Showing picks from our recipe book", message: notice)
            }
            ForEach(Array(viewModel.recipes.enumerated()), id: \.offset) { _, recipe in
                NavigationLink {
                    RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
                } label: {
                    RecipeCard(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty,
                               ingredients: recipe.ingredients, onHandCount: viewModel.onHandCount(for: recipe))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    SuggestView(viewModel: SuggestViewModel(context: ModelContainer.preview.mainContext))
}
