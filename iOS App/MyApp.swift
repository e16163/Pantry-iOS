import SwiftData
import SwiftUI

/// The one store the app and its Siri actions share, so an ingredient added by voice shows up in the app.
enum AppData {
    @MainActor static let container = try! ModelContainer(for: PantryItem.self, SavedRecipe.self)
}

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(context: AppData.container.mainContext)
        }
    }
}
