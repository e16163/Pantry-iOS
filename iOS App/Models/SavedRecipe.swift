import Foundation
import SwiftData

@Model
final class SavedRecipe {
    var title: String
    var minutes: Int
    var difficulty: String
    var ingredients: [String]
    var amounts: [String] = []  // default keeps recipes saved before amounts existed loading
    var steps: [String]
    var savedAt: Date

    init(title: String, minutes: Int, difficulty: String, ingredients: [String], amounts: [String] = [],
         steps: [String], savedAt: Date = .now) {
        self.title = title
        self.minutes = minutes
        self.difficulty = difficulty
        self.ingredients = ingredients
        self.amounts = amounts
        self.steps = steps
        self.savedAt = savedAt
    }
}
