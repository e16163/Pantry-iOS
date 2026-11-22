import SwiftData
import SwiftUI

struct SuggestView: View {
    @Bindable var viewModel: SuggestViewModel
    @Environment(\.dynamicTypeSize) private var typeSize

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
                    // One row normally; two columns at accessibility text sizes so the labels fit.
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                                             count: typeSize.isAccessibilitySize ? 2 : 4), spacing: 8) {
                        ForEach(Self.timeChips, id: \.title) { chip in
                            Chip(systemImage: chip.systemImage, title: chip.title, isSelected: viewModel.maxMinutes == chip.minutes) {
                                viewModel.maxMinutes = chip.minutes
                                // Already showing results: search again for the new time instead of just hiding cards.
                                if !viewModel.recipes.isEmpty { Task { await viewModel.generate() } }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.page)
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
                .font(.title.weight(.heavy))
                .tracking(-0.5)
            Text(viewModel.pantryCount == 0
                 ? "Add a few ingredients in the Pantry tab to get started."
                 : "Pick a time and we'll find recipes that use your pantry.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.trailing, 90)  // keep clear of the pan art
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
        .background(alignment: .trailing) {
            ZStack(alignment: .trailing) {
                Color(red: 0.09, green: 0.15, blue: 0.14)  // near-black Pantry green
                Text("🥘")  // the pan art from the first TestFlight build, kept on request
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
        } else if viewModel.isGenerating && viewModel.visibleRecipes.isEmpty {
            SectionHeader(title: "Recipes for you", subtitle: "Checking your pantry…")
            ForEach(0..<2, id: \.self) { _ in
                RecipeCard(title: "Placeholder recipe name", minutes: 20, difficulty: "Easy",
                           ingredients: ["one", "two", "three"])
                    .redacted(reason: .placeholder)
            }
        } else if viewModel.visibleRecipes.isEmpty {
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
                InfoBanner(systemImage: "book.closed", title: "Using the built-in recipe book", message: notice)
            }
            if viewModel.isGenerating {
                InfoBanner(systemImage: "sparkles", title: "Apple Intelligence is writing new recipes for you",
                           message: "They'll appear at the top in a moment. Start with these meanwhile.")
            }
            // At accessibility text sizes, side-scrolling cards get too cramped, so only the list shows.
            let shelves = typeSize.isAccessibilitySize ? [] : viewModel.shelves
            ForEach(shelves, id: \.title) { shelf in
                shelfRow(shelf.title, shelf.recipes)
            }
            if !shelves.isEmpty {
                SectionHeader(title: "All recipes").padding(.top, 4)
            }
            ForEach(Array(viewModel.visibleRecipes.enumerated()), id: \.offset) { _, recipe in
                card(recipe)
                    .padding(.bottom, 12)
            }
            if viewModel.hasMore {
                Button {
                    Task { await viewModel.loadMore() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoadingMore {
                            ProgressView()
                            Text("Cooking up more…")
                        } else {
                            Image(systemName: "sparkles")
                            Text("More recipes")
                        }
                    }
                }
                .buttonStyle(.primary)
                .disabled(viewModel.isLoadingMore)
                // Reaching the bottom loads more on its own, again whenever a search finishes or new recipes
                // land while it's still in view. A load that adds nothing stops it; the button is the retry.
                .task(id: "\(viewModel.recipes.count) \(viewModel.isGenerating)") {
                    guard !viewModel.isLoadingMore, !viewModel.isGenerating else { return }
                    Task { await viewModel.loadMore() }  // unstructured, so scrolling away doesn't cancel the model call
                }
            } else {
                Text("That's every recipe that fits your pantry right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func card(_ recipe: RecipeSuggestion) -> some View {
        NavigationLink {
            RecipeDetailView(viewModel: viewModel.detailViewModel(for: recipe))
        } label: {
            RecipeCard(title: recipe.title, minutes: recipe.minutes, difficulty: recipe.difficulty,
                       ingredients: recipe.ingredients, onHandCount: viewModel.onHandCount(for: recipe))
        }
        .buttonStyle(.plain)
    }

    /// A titled row of cards that swipes sideways and runs edge to edge, like a delivery app's shelves.
    private func shelfRow(_ title: String, _ recipes: [RecipeSuggestion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(recipes.enumerated()), id: \.offset) { _, recipe in
                        card(recipe)
                            .containerRelativeFrame(.horizontal) { width, _ in width * 0.78 }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Spacing.page, for: .scrollContent)
            .padding(.horizontal, -Spacing.page)
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    SuggestView(viewModel: SuggestViewModel(context: ModelContainer.preview.mainContext))
}
