import SwiftData
import SwiftUI

@main struct MyApp: App {
    let container = try! ModelContainer(for: PantryItem.self, SavedRecipe.self)

    var body: some Scene {
        WindowGroup {
            RootView(context: container.mainContext)
        }
    }
}
