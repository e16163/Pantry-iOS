import Testing
@testable import iOS_App

struct IngredientDetectorTests {
    @Test func cleanNormalizesAndDropsBlanksDuplicatesAndPantryItems() {
        let names = ["Eggs", "  ", "egg", "Scallions", "Tomato", "dragon fruit"]
        #expect(IngredientDetector.clean(names, excluding: ["tomato"]) == ["egg", "green onion", "dragon fruit"])
    }
}
