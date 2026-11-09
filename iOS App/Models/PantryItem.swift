import Foundation
import SwiftData

enum IngredientCategory: String, Codable, CaseIterable {
    case produce, dairy, protein, grains, pantry, spices, condiments, other
}

@Model
final class PantryItem {
    var name: String
    var category: IngredientCategory
    var addedAt: Date

    init(name: String, category: IngredientCategory = .other, addedAt: Date = .now) {
        self.name = name
        self.category = category
        self.addedAt = addedAt
    }
}
