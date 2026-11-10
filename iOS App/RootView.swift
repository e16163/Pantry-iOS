import SwiftData
import SwiftUI

struct RootView: View {
    @State private var pantry: PantryViewModel
    @State private var suggest: SuggestViewModel
    @State private var saved: SavedViewModel

    init(context: ModelContext) {
        _pantry = State(initialValue: PantryViewModel(context: context))
        _suggest = State(initialValue: SuggestViewModel(context: context))
        _saved = State(initialValue: SavedViewModel(context: context))
    }

    var body: some View {
        TabView {
            Tab("Pantry", systemImage: "refrigerator") {
                PantryView(viewModel: pantry)
            }
            Tab("Suggest", systemImage: "sparkles") {
                SuggestView(viewModel: suggest)
            }
            Tab("Saved", systemImage: "bookmark") {
                SavedView(viewModel: saved)
            }
        }
        .fontDesign(.rounded)
    }
}

#Preview {
    RootView(context: ModelContainer.preview.mainContext)
}
