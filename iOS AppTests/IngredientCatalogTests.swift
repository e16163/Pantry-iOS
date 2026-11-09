import Foundation
import Testing
@testable import iOS_App

struct IngredientCatalogTests {
    @Test func loadsAllIngredients() {
        #expect(IngredientCatalog.all.count == 200)
    }

    @Test func namesAreUniqueLowercaseAndTrimmed() {
        let names = IngredientCatalog.all.map(\.name)
        #expect(Set(names).count == names.count)
        #expect(names.allSatisfy { $0 == $0.lowercased().trimmingCharacters(in: .whitespaces) })
    }
}
