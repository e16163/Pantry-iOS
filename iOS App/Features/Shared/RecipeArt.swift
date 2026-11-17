import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Picks a dish photo for a recipe from keywords in its title, then its ingredients.
enum RecipeArt {
    /// Checked in order; the first keyword found in the title (then the ingredients) wins.
    private static let keywords: [(words: [String], photo: String)] = [
        (["pancake", "waffle"], "dish-pancakes"),
        (["omelette", "omelet", "scrambled", "frittata", "egg"], "dish-eggs"),
        (["pasta", "spaghetti", "penne", "macaroni", "mac and cheese", "noodle"], "dish-pasta"),
        (["salad"], "dish-salad"),
        (["soup", "stew"], "dish-soup"),
        (["curry"], "dish-curry"),
        (["taco", "quesadilla", "burrito", "tortilla"], "dish-tacos"),
        (["fried rice", "rice", "bowl"], "dish-rice-bowl"),
        (["toast", "sandwich", "melt", "grilled cheese", "bread"], "dish-sandwich"),
        (["salmon", "tilapia", "fish", "tuna"], "dish-salmon"),
        (["shrimp"], "dish-shrimp"),
        (["chicken"], "dish-chicken"),
        (["beef", "steak", "burger"], "dish-steak"),
        (["potato", "fries"], "dish-potatoes"),
        (["yogurt", "parfait", "granola", "oat", "banana"], "dish-oatmeal"),
    ]

    static func photo(title: String, ingredients: [String]) -> String {
        for text in [title.lowercased(), ingredients.joined(separator: " ").lowercased()] {
            if let match = keywords.first(where: { $0.words.contains(where: text.contains) }) {
                return match.photo
            }
        }
        return "dish-default"
    }
}

/// A photo from the asset catalog filling its frame, falling back to `fallback` (another asset) and then a
/// gray tile, so the app still looks finished before every photo has been added.
struct FoodPhoto: View {
    let name: String
    var fallback: String? = nil

    var body: some View {
        Color.secondary.opacity(0.12)
            .overlay {
                if let found = [name, fallback].compactMap({ $0 }).first(where: Self.exists) {
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

extension IngredientCategory {
    /// Photo for ingredient rows in this category; the older flat illustration stands in until it's added.
    var photo: FoodPhoto {
        FoodPhoto(name: "photo-category-\(rawValue)", fallback: "category-\(rawValue)")
    }
}
