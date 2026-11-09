import SwiftUI

struct SuggestView: View {
    var body: some View {
        NavigationStack {
            Text("Recipe suggestions will show up here.")
                .foregroundStyle(.secondary)
                .navigationTitle("Suggest")
        }
    }
}

#Preview {
    SuggestView()
}
