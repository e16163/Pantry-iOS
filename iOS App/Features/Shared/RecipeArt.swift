import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Picks the closest photo for any recipe title, including ones Apple Intelligence just wrote, from the
/// dish photo library listed in `dish_photos.json`, and gives each title its own picture made online.
enum RecipeArt {
    /// Pantry's free Cloudflare Worker (worker/ in this repo).
    static let server = URL(string: "https://pantry.supersaladstinger.workers.dev")!

    /// The photo a card shows for this title: a real Pixabay photo checked to show exactly this dish, else an
    /// AI-made picture of it. Never the closest bundled photo, which similar dishes would share.
    static func photoURL(title: String) -> URL {
        server.appending(path: "photo").appending(queryItems: [URLQueryItem(name: "title", value: title)])
    }

    /// Downloads these dishes' photos into the shared cache, so their cards show them right away.
    static func prefetchPhotos(_ titles: [String]) async {
        let urls = titles.map(photoURL)
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { _ = try? await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 4)) }
            }
        }
    }

    struct Dish: Decodable {
        let photo: String
        /// Words a title is matched against, like "quesadilla quesadillas".
        let words: String
        /// What the photo shows; its words only break ties.
        let look: String
    }

    static func photo(title: String) -> String? {
        library.match(title)
    }

    static let library: PhotoLibrary = {
        let url = Bundle.main.url(forResource: "dish_photos", withExtension: "json")!
        return PhotoLibrary(dishes: try! JSONDecoder().decode([Dish].self, from: Data(contentsOf: url)),
                            ingredients: IngredientCatalog.all.map(\.name))
    }()
}

/// Matches a title the way a person would: a specific dish name ("bibimbap") wins outright, otherwise the
/// kind of dish ("tacos", "soup") narrows it down and ingredients only break ties, so "Black Bean Tacos"
/// gets tacos, not bean soup. Titles with nothing to go on ("Mystery Dish") get nil.
struct PhotoLibrary {
    private struct Entry {
        let photo: String
        let words: Set<String>
        let look: Set<String>
        /// Last word of the photo name, the dish's main word: "dish-beef-stew" → "stew".
        let head: String
    }

    private let entries: [Entry]
    /// How many dishes use each word; rare words say more about a dish.
    private let dishCount: [String: Int]
    private let ingredientWords: Set<String>

    init(dishes: [RecipeArt.Dish], ingredients: [String]) {
        entries = dishes.map {
            Entry(photo: $0.photo, words: Set(Self.words($0.words)), look: Set(Self.words($0.look)),
                  head: Self.words($0.photo.split(separator: "-").last.map(String.init) ?? "").first ?? "")
        }
        dishCount = entries.flatMap(\.words).reduce(into: [:]) { $0[$1, default: 0] += 1 }
        ingredientWords = Set(ingredients.flatMap(Self.words))
    }

    func match(_ title: String) -> String? {
        let words = Self.words(title)
        let titleWords = Set(words)
        let specific = Set(words.filter {
            (dishCount[$0] ?? .max) <= 3 && !ingredientWords.contains($0)
                && !Self.kinds.contains($0) && !Self.generic.contains($0)
        })
        // The last kind word is the dish: "Breakfast Burrito Bowl" is a bowl.
        let kind = words.last { Self.kinds.contains($0) && dishCount[$0] != nil }
        let pool = if !specific.isEmpty {
            entries.filter { !$0.words.isDisjoint(with: specific) }
        } else if let kind {
            entries.filter { $0.words.contains(kind) }
        } else {
            entries.filter { mainWordMatches($0, titleWords) }
        }
        var best: (score: Double, photo: String)?
        for entry in pool {  // strictly greater, so the earlier, more general dish wins a tie
            let score = score(entry, titleWords, kind: kind)
            if score > best?.score ?? -.infinity { best = (score, entry.photo) }
        }
        return best?.photo
    }

    private func mainWordMatches(_ entry: Entry, _ titleWords: Set<String>) -> Bool {
        (titleWords.contains(entry.head) && !Self.generic.contains(entry.head))
            || entry.words.intersection(titleWords).count >= 2
    }

    private func score(_ entry: Entry, _ titleWords: Set<String>, kind: String?) -> Double {
        let shared = entry.words.intersection(titleWords).reduce(0.0) { total, word in
            let rarity = log(Double(entries.count) / Double(dishCount[word] ?? 1))
            // "Garlic butter" describes flavor, so it counts less than the dish itself.
            let weight = Self.generic.contains(word) || (ingredientWords.contains(word) && word != entry.head) ? 0.5 : 1
            return total + rarity * weight
        }
        let bonus: Double = if let kind { entry.head == kind ? 1 : 0 } else { mainWordMatches(entry, titleWords) ? 3 : 0 }
        return shared + 0.3 * Double(entry.look.intersection(titleWords).count) + bonus
    }

    /// Lowercase words with fillers dropped and plurals folded: "Crispy Black Bean Tacos" → black, bean, taco.
    static func words(_ text: String) -> [String] {
        text.lowercased().split { !("a"..."z").contains($0) }.map(String.init)
            .filter { !stopWords.contains($0) }
            .map { $0.count > 3 && $0.hasSuffix("s") && !$0.hasSuffix("ss") ? String($0.dropLast()) : $0 }
    }

    private static let stopWords: Set<String> = ["with", "and", "on", "the", "a", "of", "in", "style", "classic",
        "easy", "quick", "simple", "homemade", "my", "best", "one", "pan", "skillet", "creamy", "spicy", "crispy",
        "fresh", "warm", "hearty", "light", "white", "tuscan", "cheesy", "fluffy", "chunky", "stuffed", "smoky",
        "glazed"]
    private static let kinds = Set(words("""
        soup stew chili salad taco burrito bowl pasta noodle spaghetti curry sandwich toast pizza burger smoothie \
        pancake waffle omelette rice cake pie cookie muffin wrap pita quesadilla fry hash skewer kebab dumpling roll \
        chowder risotto casserole dip fajita enchilada nacho parfait
        """))
    /// Describe a dish without naming one, so they never decide the photo alone.
    private static let generic = Set(words("""
        veggie vegetable fried grilled roasted roast baked loaded bite breakfast sweet sour hot cold thai korean \
        chinese japanese indian mexican italian greek french vietnamese spanish american southern moroccan \
        mediterranean
        """))
}

/// The dish's own photo through the Worker. Until it arrives (or offline) the ingredient drawings show, never the
/// closest bundled photo, which can be a different dish.
struct RecipePicture: View {
    let title: String
    let ingredients: [String]

    var body: some View {
        AsyncImage(url: RecipeArt.photoURL(title: title)) { phase in
            if let image = phase.image {
                Color.clear.overlay { image.resizable().scaledToFill() }.clipped()
            } else {
                IngredientMosaic(ingredients: ingredients)
            }
        }
        // Menu-photo grade: the bright gray studio backgrounds glare on the dark app, so pull them down a
        // little and darken the edges so the dish carries the frame. Colors stay true; boosting them looked fake.
        .contrast(1.04)
        .brightness(-0.08)
        .overlay {
            ZStack {
                Color.black.opacity(0.06)
                RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 40, endRadius: 280)
            }
        }
        .accessibilityHidden(true)
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
    /// The ingredient's own illustration, else its category's illustration in the same style.
    static func ingredient(_ name: String, category: IngredientCategory) -> FoodPhoto {
        FoodPhoto(name: "ingredient-\(slug(name))",
                  fallbacks: ["category-\(category.rawValue)"])
    }

    /// "jalapeño pepper" → "jalapeno-pepper"; must match tools/slice-ingredient-sheets.py.
    static func slug(_ name: String) -> String {
        name.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .joined(separator: "-")
    }
}
