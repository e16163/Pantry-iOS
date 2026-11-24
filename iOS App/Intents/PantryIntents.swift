import AppIntents
import SwiftData

/// "Add eggs to my pantry" from Siri, Shortcuts or Spotlight, without opening the app.
struct AddIngredientIntent: AppIntent {
    static let title: LocalizedStringResource = "Add to Pantry"
    static let description = IntentDescription("Adds an ingredient to your pantry.")

    @Parameter(title: "Ingredient", requestValueDialog: "What do you want to add?")
    var ingredient: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let pantry = PantryViewModel(context: AppData.container.mainContext)
        let before = pantry.items.count
        pantry.add(suggestion: ingredient)
        let name = IngredientName.normalize(ingredient)
        if name.isEmpty {
            return .result(dialog: "I didn't catch an ingredient.")
        }
        return .result(dialog: pantry.items.count > before
                       ? "Added \(name) to your pantry."
                       : "\(name) is already in your pantry.")
    }
}

/// "What can I cook?" answered by Siri from the recipe book and what's in the pantry.
struct WhatCanICookIntent: AppIntent {
    static let title: LocalizedStringResource = "What Can I Cook?"
    static let description = IntentDescription("Suggests recipes you can make with what's in your pantry.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let pantry = PantryViewModel(context: AppData.container.mainContext).items.map(\.name)
        guard !pantry.isEmpty else {
            return .result(dialog: "Your pantry is empty. Add a few ingredients first.")
        }
        let titles = FallbackRecipes.best(for: pantry, maxMinutes: nil, limit: 3).map(\.title)
        guard !titles.isEmpty else {
            return .result(dialog: "Nothing in the recipe book fits your pantry yet. Open Pantry to get new recipes written for your pantry.")
        }
        return .result(dialog: "You could make \(titles.formatted(.list(type: .or))).")
    }
}

struct PantryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddIngredientIntent(),
            phrases: ["Add to my pantry in \(.applicationName)", "Add an ingredient in \(.applicationName)"],
            shortTitle: "Add to Pantry",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: WhatCanICookIntent(),
            phrases: ["What can I cook with \(.applicationName)", "What's for dinner in \(.applicationName)"],
            shortTitle: "What Can I Cook?",
            systemImageName: "fork.knife"
        )
    }
}
