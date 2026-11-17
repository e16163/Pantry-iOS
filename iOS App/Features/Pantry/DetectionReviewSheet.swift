import SwiftData
import SwiftUI

/// Shows what the model spotted in a photo; everything starts ticked, the user unticks mistakes and adds the rest.
struct DetectionReviewSheet: View {
    @Bindable var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Found in your photo")
                .toolbarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if !viewModel.isDetecting && !viewModel.detected.isEmpty {
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
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isDetecting {
            ProgressView("Looking at your photo…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let message = viewModel.detectionError {
            ContentUnavailableView("Couldn't read that photo", systemImage: "photo.badge.exclamationmark",
                                   description: Text(message))
        } else if viewModel.detected.isEmpty {
            ContentUnavailableView("No new ingredients spotted", systemImage: "eye.slash",
                                   description: Text("Everything in the photo is already in your pantry, or try a closer, brighter shot."))
        } else {
            List(viewModel.detected, id: \.self) { name in
                let isOn = viewModel.selectedDetected.contains(name)
                Button {
                    if isOn { viewModel.selectedDetected.remove(name) } else { viewModel.selectedDetected.insert(name) }
                } label: {
                    HStack(spacing: 14) {
                        Thumbnail(photo: .ingredient(name, category: IngredientCatalog.all.first { $0.name == name }?.category ?? .other), size: 44)
                        Text(name)
                            .font(.body.weight(.medium))
                        Spacer()
                        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(isOn ? Color.brand : .secondary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
    }
}

#if os(iOS)
/// The system camera, returning the shot as JPEG data.
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let data = (info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.8) {
                parent.onCapture(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
