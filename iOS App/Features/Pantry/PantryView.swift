import SwiftUI

struct PantryView: View {
    var body: some View {
        NavigationStack {
            Text("Your ingredients will show up here.")
                .foregroundStyle(.secondary)
                .navigationTitle("Pantry")
        }
    }
}

#Preview {
    PantryView()
}
