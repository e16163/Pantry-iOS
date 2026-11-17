import SwiftData
import SwiftUI

struct SuggestView: View {
    @Bindable var viewModel: SuggestViewModel

    private static let timeChips: [(systemImage: String, title: String, minutes: Int?)] = [
        ("bolt.fill", "15 min", 15), ("timer", "30 min", 30), ("clock", "1 hour", 60), ("infinity", "Any time", nil),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PageTitle(title: "What's cooking?",
                              subtitle: "Cooking with ^[\(viewModel.pantryCount) ingredient](inflect: true) from your pantry")
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, 8)
                    hero
                        .padding(.horizontal, Spacing.page)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.timeChips, id: \.title) { chip in
                                Chip(systemImage: chip.systemImage, title: chip.title, isSelected: viewModel.maxMinutes == chip.minutes) {
                                    viewModel.maxMinutes = chip.minutes
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.page)
                    }
                    SectionDivider()
                        .padding(.top, 8)
                    results
                        .padding(.horizontal, Spacing.page)
                }
                .padding(.bottom, Spacing.section)
            }
            .navigationTitle("Suggest")
            #if os(iOS)
            .toolbarVisibility(.hidden, for: .navigationBar)
            #endif
            .onAppear(perform: viewModel.refreshPantry)
        }
    }

    /// Dark promo-style banner holding the main action.
    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dinner from what\nyou've got.")
                .font(.system(size: 28, weight: .heavy))
                .tracking(-0.5)
            Text(viewModel.pantryCount == 0
                 ? "Add a few ingredients in the Pantry tab to get started."
                 : "Pick a time and we'll find recipes that use your pantry.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.trailing, 90)  // keep clear of the bowl art
            Button {
                Task { await viewModel.generate() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGenerating {
                        ProgressView().tint(.white)
                        Text("Finding recipes…")
                    } else {
                        Text("Find recipes")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .background(Color.brand, in: .capsule)
                .environment(\.colorScheme, .light)  // keep the brand green dark enough for white text
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGenerate)
            .opacity(viewModel.canGenerate || viewModel.isGenerating ? 1 : 0.5)
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(alignment: .bottomTrailing) {
            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.09, green: 0.15, blue: 0.14)  // near-black Pantry green
                Image(.cookingDone)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .clipShape(.rect(cornerRadius: 28))
                    .rotationEffect(.degrees(-12))
                    .offset(x: 26, y: 26)
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
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview {
    SuggestView(viewModel: SuggestViewModel(context: ModelContainer.preview.mainContext))
}
