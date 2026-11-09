import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Pantry", systemImage: "refrigerator") {
                PantryView()
            }
            Tab("Suggest", systemImage: "sparkles") {
                SuggestView()
            }
            Tab("Saved", systemImage: "bookmark") {
                SavedView()
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(.preview)
}
