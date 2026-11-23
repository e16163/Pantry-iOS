import Foundation
import SwiftData
import Testing
@testable import iOS_App

struct PhotoAndArtTests {
    @Test func cleanNormalizesDedupesSkipsPantryAndKeepsCounts() {
        let items = [("Eggs", 6), ("  ", 0), ("Tomato", 0), ("eggs", 2), ("Garlic", 1)].map { DetectedItem(name: $0, count: $1) }
        let found = IngredientDetector.clean(items, excluding: ["garlic"],
                                             corrections: ScanCorrections(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        #expect(found.map(\.name) == ["egg", "tomato"])
        #expect(found.map(\.quantity) == [6, nil])
        #expect(found[0].unit == .pieces)
    }

    @Test func cleanKeepsLabelAmountsForThingsThatArentCounted() {
        let items = [DetectedItem(name: "skim milk", count: 0, amount: 3.8, unit: "L"),
                     DetectedItem(name: "egg", count: 6, amount: 0, unit: ""),
                     DetectedItem(name: "rice", count: 0, amount: 2, unit: "bags")]
        let found = IngredientDetector.clean(items, excluding: [],
                                             corrections: ScanCorrections(defaults: UserDefaults(suiteName: UUID().uuidString)!))
        #expect(found.map(\.quantity) == [3.8, 6, nil])
        #expect(found.map(\.unit) == [.liters, .pieces, nil])
    }

    @Test func correctionsIgnoreNoOpsAndBecomeHints() {
        var corrections = ScanCorrections(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        corrections.record(from: "egg", to: " Egg ")
        corrections.record(from: "lemon", to: "lime")
        #expect(corrections.fixes == ["lemon": "lime"])
        #expect(corrections.apply("lemon") == "lime")
        #expect(corrections.hints == ["what looks like \"lemon\" is \"lime\""])
    }

    @Test func quantityText() {
        #expect(QuantityUnit.text(3, .pieces) == "3")
        #expect(QuantityUnit.text(500, .grams) == "500 g")
        #expect(QuantityUnit.text(2, .cups) == "2 cups")
        #expect(QuantityUnit.text(0, .cups) == nil)
        #expect(QuantityUnit.text(nil, nil) == nil)
    }

    /// A small library like the real one, so the test doesn't depend on which photos have been made yet.
    let library = PhotoLibrary(dishes: [
        .init(photo: "dish-omelette", words: "omelette omelet frittata", look: "folded omelette with spinach"),
        .init(photo: "dish-tacos", words: "tacos", look: "soft tacos with chicken and salsa"),
        .init(photo: "dish-bean-soup", words: "black bean soup bean soup", look: "black bean soup with avocado"),
        .init(photo: "dish-pb-toast", words: "peanut butter banana toast", look: "toast with banana"),
        .init(photo: "dish-smoothie", words: "smoothie shake", look: "strawberry banana smoothie"),
        .init(photo: "dish-chicken", words: "roast chicken lemon garlic chicken thighs", look: "roasted chicken thighs"),
        .init(photo: "dish-shrimp", words: "garlic butter shrimp scampi", look: "shrimp in a skillet"),
        .init(photo: "dish-steak", words: "steak", look: "sliced steak with herb butter"),
        .init(photo: "dish-fried-rice", words: "fried rice", look: "fried rice with egg"),
        .init(photo: "dish-veggie-burger", words: "veggie burger black bean burger", look: "veggie burger"),
        .init(photo: "dish-bibimbap", words: "bibimbap", look: "rice bowl with egg"),
        .init(photo: "dish-burrito-bowl", words: "burrito bowl", look: "rice, beans and beef in a bowl"),
    ], ingredients: ["black beans", "peanut butter", "banana", "garlic", "butter", "chicken", "steak", "egg", "spinach"])

    @Test(arguments: [
        ("Spinach & Cheddar Omelette", "dish-omelette"),
        ("Black Bean Tacos", "dish-tacos"),            // the kind of dish beats an ingredient
        ("Peanut Butter Smoothie", "dish-smoothie"),
        ("Garlic Butter Steak Bites", "dish-steak"),   // flavor words count less than the dish
        ("Veggie Fried Rice", "dish-fried-rice"),      // "veggie" alone doesn't pick the veggie burger
        ("Bibimbap Rice Bowl", "dish-bibimbap"),       // a specific dish name wins
        ("Lemon Herb Chicken", "dish-chicken"),
    ])
    func photoLibraryPicksTheClosestDish(title: String, photo: String) {
        #expect(library.match(title) == photo)
    }

    @Test func photoLibraryLeavesUnknownDishesWithoutAPhoto() {
        #expect(library.match("Mystery Dish") == nil)
        #expect(library.match("Cheddar Herb Scones") == nil)
    }

    @Test func everyListedDishPhotoIsInTheApp() throws {
        let url = try #require(Bundle.main.url(forResource: "dish_photos", withExtension: "json"))
        let dishes = try JSONDecoder().decode([RecipeArt.Dish].self, from: Data(contentsOf: url))
        #expect(dishes.count >= 15)
        #expect(dishes.filter { !FoodPhoto.exists($0.photo) }.map(\.photo) == [])
    }

    @Test func ingredientPhotoSlugMatchesSlicerScript() {
        #expect(FoodPhoto.slug("Jalapeño") == "jalapeno")
        #expect(FoodPhoto.slug("apple cider vinegar") == "apple-cider-vinegar")
    }

    @MainActor @Test func savedDeleteRemovesRecipe() throws {
        let container = try ModelContainer(for: PantryItem.self, SavedRecipe.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let detail = RecipeDetailViewModel(
            recipe: RecipeSuggestion(title: "Toast", minutes: 5, difficulty: "Easy", ingredients: ["bread"], steps: ["Toast it."]),
            context: container.mainContext)
        detail.toggleSave()
        let saved = SavedViewModel(context: container.mainContext)
        saved.load()
        #expect(saved.recipes.count == 1)
        saved.delete(saved.recipes[0])
        #expect(saved.recipes.isEmpty)
    }
}
