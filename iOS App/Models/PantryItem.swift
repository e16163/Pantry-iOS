import Foundation
import SwiftData

enum IngredientCategory: String, Codable, CaseIterable {
    case produce, dairy, protein, grains, pantry, spices, condiments, other
}

/// What a quantity is counted in. `pieces` shows as a bare number ("3 eggs" → "3").
enum QuantityUnit: String, Codable, CaseIterable {
    case pieces = "pcs", grams = "g", kilograms = "kg", milliliters = "ml", liters = "L", cups, pounds = "lb", ounces = "oz"

    /// "3", "500 g", "1.5 cups", or nil when there's no amount.
    static func text(_ amount: Double?, _ unit: QuantityUnit?) -> String? {
        guard let amount, amount > 0 else { return nil }
        let number = amount.formatted(.number.precision(.fractionLength(0...2)))
        guard let unit, unit != .pieces else { return number }
        return "\(number) \(unit.rawValue)"
    }
}

@Model
final class PantryItem {
    var name: String
    var category: IngredientCategory
    var addedAt: Date
    /// nil when the user hasn't said how much they have.
    var quantity: Double?
    var unit: QuantityUnit?

    init(name: String, category: IngredientCategory = .other, addedAt: Date = .now,
         quantity: Double? = nil, unit: QuantityUnit? = nil) {
        self.name = name
        self.category = category
        self.addedAt = addedAt
        self.quantity = quantity
        self.unit = unit
    }

    var quantityText: String? { QuantityUnit.text(quantity, unit) }
}
