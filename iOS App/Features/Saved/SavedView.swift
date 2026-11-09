import SwiftUI

struct SavedView: View {
    var body: some View {
        NavigationStack {
            Text("Saved recipes will show up here.")
                .foregroundStyle(.secondary)
                .navigationTitle("Saved")
        }
    }
}

#Preview {
    SavedView()
}
