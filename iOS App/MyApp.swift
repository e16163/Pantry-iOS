import SwiftData
import SwiftUI

/// The one store the app and its Siri actions share, so an ingredient added by voice shows up in the app.
enum AppData {
    @MainActor static let container = try! ModelContainer(for: PantryItem.self, SavedRecipe.self)
}

@main struct MyApp: App {
    init() {
        // Dish pictures are about 0.5 MB; the default cache is too small to keep them, so each would download again.
        URLCache.shared = URLCache(memoryCapacity: 50_000_000, diskCapacity: 300_000_000)
    }

    var body: some Scene {
        WindowGroup {
            RootView(context: AppData.container.mainContext)
        }
    }
}
