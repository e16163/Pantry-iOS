import Testing
@testable import iOS_App

struct PantryCheckTests {
    let pantry = ["egg", "spinach", "cheddar cheese", "chicken breast", "rice"]

    func recipe(_ ingredients: [String]) -> RecipeSuggestion {
        RecipeSuggestion(title: "Test", minutes: 10, difficulty: "Easy", ingredients: ingredients, steps: [])
    }

    @Test func allowsPantryItemsAndStaples() {
        #expect(PantryCheck.usesOnlyPantry(recipe(["egg", "spinach", "salt", "olive oil", "water"]), pantry: pantry))
    }

    @Test func rejectsInventedIngredient() {
        #expect(!PantryCheck.usesOnlyPantry(recipe(["egg", "bacon"]), pantry: pantry))
    }

    @Test func matchesAfterNormalizing() {
        #expect(PantryCheck.usesOnlyPantry(recipe(["Eggs", " SPINACH "]), pantry: pantry))
    }

    @Test func generalNameIsCoveredBySpecificPantryItem() {
        #expect(PantryCheck.usesOnlyPantry(recipe(["cheese", "chicken"]), pantry: pantry))
    }

    @Test func specificNameIsNotCoveredByGeneralPantryItem() {
        #expect(!PantryCheck.usesOnlyPantry(recipe(["brown rice"]), pantry: ["rice"]))
        #expect(!PantryCheck.usesOnlyPantry(recipe(["chicken thigh"]), pantry: pantry))
    }

    @Test func partialWordsDontMatch() {
        #expect(!PantryCheck.usesOnlyPantry(recipe(["egg"]), pantry: ["eggplant"]))
    }
}
