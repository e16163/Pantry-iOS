import Foundation

extension IngredientCategory {
    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .produce: "carrot"
        case .dairy: "cup.and.saucer"
        case .protein: "fish"
        case .grains: "laurel.leading"
        case .pantry: "shippingbox"
        case .spices: "leaf"
        case .condiments: "drop"
        case .other: "ellipsis.circle"
        }
    }
}
