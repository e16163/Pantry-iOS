import SwiftUI

/// Shows what the model spotted in a photo so the user can untick mistakes before adding.
struct DetectionReviewSheet: View {
    @Bindable var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isDetecting {
                    ProgressView("Looking at your photo…")
                } else if let error = viewModel.detectionError {
                    ContentUnavailableView("Couldn't read that photo", systemImage: "photo", description: Text(error))
                } else if viewModel.detected.isEmpty {
                    ContentUnavailableView(
                        "No new ingredients spotted",
                        systemImage: "eye.slash",
                        description: Text("Try a closer, brighter photo, or type them in.")
                    )
                } else {
                    List(viewModel.detected, id: \.self) { name in
                        let isSelected = viewModel.selectedDetected.contains(name)
                        Button {
                            if isSelected {
                                viewModel.selectedDetected.remove(name)
                            } else {
                                viewModel.selectedDetected.insert(name)
                            }
                        } label: {
                            Label(name, systemImage: isSelected ? "checkmark.circle.fill" : "circle")
                        }
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                    .safeAreaInset(edge: .bottom) {
                        Button("Add \(viewModel.selectedDetected.count) to pantry") {
                            viewModel.addDetected()
                            dismiss()
                        }
                        .buttonStyle(.primary)
                        .disabled(viewModel.selectedDetected.isEmpty)
                        .padding()
                    }
                }
            }
            .navigationTitle("From your photo")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
