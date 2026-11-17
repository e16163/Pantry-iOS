import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Picks a dish photo for a recipe only when the photo really shows that dish; otherwise none.
enum RecipeArt {
    /// Title phrases each photo truly depicts. Narrow on purpose: no photo beats the wrong one
    /// (the omelette photo must not stand in for scrambled eggs).
    private static let matches: [(phrases: [String], photo: String)] = [
        (["pancake"], "dish-pancakes"),
        (["omelette", "omelet", "frittata"], "dish-eggs"),
        (["spaghetti", "marinara", "tomato pasta", "pasta pomodoro"], "dish-pasta"),
        (["greek salad", "garden salad", "green salad"], "dish-salad"),
        (["vegetable soup", "veggie soup", "minestrone"], "dish-soup"),
        (["chicken curry"], "dish-curry"),
        (["taco"], "dish-tacos"),
        (["fried rice"], "dish-rice-bowl"),
        (["grilled cheese"], "dish-sandwich"),
        (["salmon"], "dish-salmon"),
        (["garlic shrimp", "shrimp scampi", "butter shrimp"], "dish-shrimp"),
        (["roast chicken", "roasted chicken", "lemon garlic chicken", "chicken thigh"], "dish-chicken"),
        (["steak"], "dish-steak"),
        (["roasted potato", "roast potato"], "dish-potatoes"),
        (["oatmeal", "porridge", "overnight oats"], "dish-oatmeal"),
    ]

    /// The matching photo's asset name, or nil when no photo shows this dish (or it hasn't been added).
    static func photo(title: String) -> String? {
        let title = title.lowercased()
        guard let match = matches.first(where: { $0.phrases.contains(where: title.contains) }) else { return nil }
        return FoodPhoto.exists(match.photo) ? match.photo : nil
    }
}

/// A photo from the asset catalog filling its frame, falling back to the first of `fallbacks` that exists and
/// then a gray tile, so the app still looks finished before every photo has been added.
struct FoodPhoto: View {
    let name: String
    var fallbacks: [String] = []

    var body: some View {
        Color.secondary.opacity(0.12)
            .overlay {
                if let found = ([name] + fallbacks).first(where: Self.exists) {
                    Image(found).resizable().scaledToFill()
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }

    static func exists(_ name: String) -> Bool {
        #if canImport(UIKit)
        UIImage(named: name) != nil
        #else
        NSImage(named: name) != nil
        #endif
    }
}

extension FoodPhoto {
    /// The ingredient's own photo, else its category photo, else the category's flat illustration.
    static func ingredient(_ name: String, category: IngredientCategory) -> FoodPhoto {
        FoodPhoto(name: "ingredient-\(slug(name))",
                  fallbacks: ["photo-category-\(category.rawValue)", "category-\(category.rawValue)"])
    }

    /// "jalapeño pepper" → "jalapeno-pepper"; must match tools/slice-ingredient-sheets.py.
    static func slug(_ name: String) -> String {
        name.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: "-")
    }
}
