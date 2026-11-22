import SwiftUI

/// Stand-in food art for recipes (we have no photos): an emoji picked from keywords on a pastel tile.
enum RecipeArt {
    /// Checked in order; the first keyword found in the title (then the ingredients) wins.
    private static let keywords: [(words: [String], emoji: String)] = [
        (["pancake", "waffle"], "🥞"),
        (["omelette", "omelet", "scrambled", "egg"], "🍳"),
        (["pasta", "spaghetti", "penne", "macaroni", "mac and cheese", "noodle"], "🍝"),
        (["salad"], "🥗"),
        (["soup", "stew"], "🍲"),
        (["curry"], "🍛"),
        (["taco", "quesadilla", "burrito", "tortilla"], "🌮"),
        (["fried rice", "rice", "bowl"], "🍚"),
        (["toast", "sandwich", "melt", "grilled cheese", "bread"], "🥪"),
        (["salmon", "tilapia", "fish", "tuna"], "🐟"),
        (["shrimp"], "🍤"),
        (["chicken"], "🍗"),
        (["beef", "steak", "burger"], "🥩"),
        (["potato", "fries"], "🥔"),
        (["yogurt", "parfait", "granola", "oat"], "🥣"),
        (["banana"], "🍌"),
    ]

    static func emoji(title: String, ingredients: [String]) -> String {
        for text in [title.lowercased(), ingredients.joined(separator: " ").lowercased()] {
            if let match = keywords.first(where: { $0.words.contains(where: text.contains) }) {
                return match.emoji
            }
        }
        return "🍽️"
    }

    static let palette: [Color] = [
        Color(red: 1.00, green: 0.93, blue: 0.85),  // peach
        Color(red: 0.88, green: 0.96, blue: 0.89),  // mint
        Color(red: 1.00, green: 0.96, blue: 0.80),  // butter
        Color(red: 0.90, green: 0.92, blue: 1.00),  // periwinkle
        Color(red: 1.00, green: 0.89, blue: 0.91),  // rose
        Color(red: 0.92, green: 0.90, blue: 0.98),  // lavender
    ]

    /// Same title, same color on every launch (`hashValue` is reseeded per launch, so it's not used).
    static func colorIndex(title: String) -> Int {
        title.unicodeScalars.reduce(0) { $0 + Int($1.value) } % palette.count
    }
}

/// The emoji on its pastel background, sized by the caller; replaced by a generated illustration once one is ready.
struct RecipeArtTile: View {
    let title: String
    let ingredients: [String]
    var emojiSize: CGFloat = 64

    @State private var thumbnail: CGImage?
    @Environment(\.redactionReasons) private var redactionReasons

    var body: some View {
        RecipeArt.palette[RecipeArt.colorIndex(title: title)]
            .overlay {
                if let thumbnail {
                    Image(decorative: thumbnail, scale: 1)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    Text(RecipeArt.emoji(title: title, ingredients: ingredients))
                        .font(.system(size: emojiSize))
                }
            }
            .clipped()
            .environment(\.colorScheme, .light)  // pastels stay pastel in dark mode
            .accessibilityHidden(true)
            .task(id: title) {
                // Loading placeholders don't get art.
                guard !redactionReasons.contains(.placeholder) else { return }
                let image = await RecipeThumbnails.shared.image(title: title, ingredients: ingredients)
                withAnimation(.easeOut(duration: 0.3)) { thumbnail = image }
            }
    }
}

/// Thumbnail emoji for an ingredient row: a specific one when the name has a match, else the category's.
enum IngredientEmoji {
    private static let byWord: [(word: String, emoji: String)] = [
        ("garlic", "🧄"), ("onion", "🧅"), ("shallot", "🧅"), ("tomato", "🍅"), ("carrot", "🥕"),
        ("potato", "🥔"), ("broccoli", "🥦"), ("corn", "🌽"), ("pepper", "🫑"), ("jalapeño", "🌶️"),
        ("mushroom", "🍄"), ("cucumber", "🥒"), ("avocado", "🥑"), ("lemon", "🍋"), ("lime", "🍋"),
        ("apple", "🍎"), ("banana", "🍌"), ("strawberry", "🍓"), ("blueberry", "🫐"), ("grape", "🍇"),
        ("peach", "🍑"), ("pear", "🍐"), ("pineapple", "🍍"), ("mango", "🥭"), ("watermelon", "🍉"),
        ("orange", "🍊"), ("eggplant", "🍆"), ("egg", "🥚"), ("butter", "🧈"), ("cheese", "🧀"),
        ("parmesan", "🧀"), ("mozzarella", "🧀"), ("feta", "🧀"), ("milk", "🥛"), ("cream", "🥛"),
        ("bread", "🍞"), ("bagel", "🥯"), ("tortilla", "🫓"), ("pita", "🫓"), ("pasta", "🍝"),
        ("spaghetti", "🍝"), ("macaroni", "🍝"), ("penne", "🍝"), ("noodle", "🍜"), ("rice", "🍚"),
        ("chicken", "🍗"), ("turkey", "🍗"), ("bacon", "🥓"), ("beef", "🥩"), ("steak", "🥩"),
        ("pork", "🥩"), ("sausage", "🌭"), ("hot dog", "🌭"), ("salmon", "🐟"), ("tuna", "🐟"),
        ("tilapia", "🐟"), ("shrimp", "🍤"), ("tofu", "🧈"), ("honey", "🍯"), ("salt", "🧂"),
        ("peanut butter", "🥜"), ("peanut", "🥜"), ("almond", "🥜"), ("walnut", "🥜"), ("cashew", "🥜"), ("bean", "🫘"),
        ("chickpea", "🫘"), ("lentil", "🫘"), ("coconut", "🥥"), ("oil", "🫒"), ("basil", "🌿"),
        ("cilantro", "🌿"), ("parsley", "🌿"), ("mint", "🌿"), ("spinach", "🥬"), ("lettuce", "🥬"),
        ("kale", "🥬"), ("cabbage", "🥬"),
    ]

    /// Longest matching word wins, so "eggplant" isn't an egg and "peanut butter" isn't butter.
    static func emoji(for name: String, category: IngredientCategory) -> String {
        let lowered = name.lowercased()
        let match = byWord.filter { lowered.contains($0.word) }.max { $0.word.count < $1.word.count }
        return match?.emoji ?? category.emoji
    }
}
