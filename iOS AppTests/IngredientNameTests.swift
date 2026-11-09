import Testing
@testable import iOS_App

struct IngredientNameTests {
    @Test(arguments: [
        ("egg", "egg"),
        ("  Eggs ", "egg"),
        ("TOMATOES", "tomato"),
        ("cherry   tomatoes", "cherry tomato"),
        ("strawberries", "strawberry"),
        ("bay leaves", "bay leaf"),
        ("radishes", "radish"),
        ("sausages", "sausage"),
        ("red pepper flakes", "red pepper flake"),
        ("scallions", "green onion"),
        ("Garbanzo Beans", "chickpea"),
        ("cheddar", "cheddar cheese"),
    ])
    func normalizesKnownIngredients(input: String, expected: String) {
        #expect(IngredientName.normalize(input) == expected)
    }

    @Test(arguments: ["hummus", "molasses", "couscous", "brussels sprout", "swiss cheese"])
    func leavesNamesAloneWhenSingularIsUnknown(name: String) {
        #expect(IngredientName.normalize(name) == name)
    }

    @Test func lowercasesAndTrimsUnknownNames() {
        #expect(IngredientName.normalize("  Dragon   Fruit ") == "dragon fruit")
    }

    @Test func blankInputBecomesEmpty() {
        #expect(IngredientName.normalize("   ") == "")
    }
}
