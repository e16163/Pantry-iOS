import SwiftData

extension ModelContainer {
    /// In-memory container with sample data, for SwiftUI previews only.
    @MainActor
    static let preview: ModelContainer = {
        let container = try! ModelContainer(
            for: PantryItem.self, SavedRecipe.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        for (name, category) in [
            ("egg", IngredientCategory.protein), ("milk", .dairy), ("spinach", .produce),
            ("tomato", .produce), ("rice", .grains), ("garlic", .produce), ("soy sauce", .condiments),
        ] {
            context.insert(PantryItem(name: name, category: category))
        }
        context.insert(SavedRecipe(
            title: "Spinach & Tomato Omelette",
            minutes: 10,
            difficulty: "Easy",
            ingredients: ["egg", "spinach", "tomato"],
            steps: ["Whisk the eggs.", "Sauté spinach and tomato.", "Pour in eggs and cook until set."]
        ))
        return container
    }()
}
