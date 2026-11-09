import Foundation

/// A known ingredient from the bundled `ingredients.json`, used for autocomplete and default categories.
struct CatalogIngredient: Decodable {
    let name: String
    let category: IngredientCategory
}

enum IngredientCatalog {
    /// Decoded once, on first use.
    static let all: [CatalogIngredient] = {
        let url = Bundle.main.url(forResource: "ingredients", withExtension: "json")!
        return try! JSONDecoder().decode([CatalogIngredient].self, from: Data(contentsOf: url))
    }()
}
