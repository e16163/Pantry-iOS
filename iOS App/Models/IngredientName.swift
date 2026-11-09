import Foundation

/// Turns free-form ingredient text ("  Green Onions ", "scallion") into one canonical name ("green onion").
enum IngredientName {
    static func normalize(_ raw: String) -> String {
        let name = raw.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if let canonical = canonical(name) { return canonical }
        for singular in singularForms(of: name) {
            if let canonical = canonical(singular) { return canonical }
        }
        return name
    }

    /// The catalog name for `name`, following aliases, or nil if it's unknown.
    private static func canonical(_ name: String) -> String? {
        if let alias = aliases[name] { return alias }
        return known.contains(name) ? name : nil
    }

    /// Candidate singulars, changing only the last word ("cherry tomatoes" → "cherry tomato").
    private static func singularForms(of name: String) -> [String] {
        var words = name.split(separator: " ").map(String.init)
        guard let last = words.popLast() else { return [] }
        var candidates: [String] = []
        if last.hasSuffix("ies") { candidates.append(String(last.dropLast(3)) + "y") }
        if last.hasSuffix("ves") { candidates.append(String(last.dropLast(3)) + "f") }
        if last.hasSuffix("es") { candidates.append(String(last.dropLast(2))) }
        if last.hasSuffix("s") { candidates.append(String(last.dropLast())) }
        return candidates.map { (words + [$0]).joined(separator: " ") }
    }

    private static let known = Set(IngredientCatalog.all.map(\.name))

    private static let aliases = [
        "scallion": "green onion",
        "spring onion": "green onion",
        "coriander": "cilantro",
        "garbanzo bean": "chickpea",
        "capsicum": "bell pepper",
        "courgette": "zucchini",
        "aubergine": "eggplant",
        "garlic clove": "garlic",
        "minced garlic": "garlic",
        "ground black pepper": "black pepper",
        "extra virgin olive oil": "olive oil",
        "mayo": "mayonnaise",
        "bbq sauce": "barbecue sauce",
        "cheddar": "cheddar cheese",
        "parmesan cheese": "parmesan",
        "mozzarella cheese": "mozzarella",
        "feta cheese": "feta",
        "yoghurt": "yogurt",
    ]
}
