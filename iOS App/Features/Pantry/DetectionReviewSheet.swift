import SwiftData
import SwiftUI

/// Shows what the model spotted in a photo; everything starts ticked. The user unticks mistakes,
/// taps an item to fix its name or amount, and adds the rest. Name fixes are remembered for later scans.
struct DetectionReviewSheet: View {
    @Bindable var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Detection?

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
                        Button("Add \(viewModel.selectedDetectedCount) to pantry") {
                            viewModel.addDetected()
                            dismiss()
                        }
                        .buttonStyle(.primary)
                        .disabled(viewModel.selectedDetectedCount == 0)
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
            List {
                Section {
                    ForEach($viewModel.detected) { $detection in
                        row(for: $detection)
                    }
                } footer: {
                    Text("Tap an item to fix its name or amount. Pantry remembers your fixes for next time.")
                }
            }
            .sheet(item: $editing) { editing in
                if let index = viewModel.detected.firstIndex(where: { $0.id == editing.id }) {
                    let detection = viewModel.detected[index]
                    IngredientEditor(title: "Fix ingredient", name: detection.name,
                                     quantity: detection.quantity, unit: detection.unit) { name, quantity, unit in
                        let name = IngredientName.normalize(name)
                        guard !name.isEmpty else { return false }
                        viewModel.detected[index].name = name
                        viewModel.detected[index].quantity = quantity
                        viewModel.detected[index].unit = unit
                        viewModel.detected[index].isSelected = true
                        return true
                    }
                }
            }
        }
    }

    private func row(for detection: Binding<Detection>) -> some View {
        let item = detection.wrappedValue
        return HStack(spacing: 14) {
            Button {
                editing = item
            } label: {
                HStack(spacing: 14) {
                    Text(IngredientEmoji.emoji(for: item.name,
                                               category: IngredientCatalog.all.first { $0.name == item.name }?.category ?? .other))
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 10))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.body.weight(.semibold))
                        Text(QuantityUnit.text(item.quantity, item.unit) ?? "Add amount")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Fix name or amount")
            Button(item.isSelected ? "Don't add \(item.name)" : "Add \(item.name)",
                   systemImage: item.isSelected ? "checkmark.circle.fill" : "circle") {
                detection.wrappedValue.isSelected.toggle()
            }
            .labelStyle(.iconOnly)
            .font(.title2)
            .foregroundStyle(item.isSelected ? Color.brand : .secondary)
            .buttonStyle(.plain)
            .accessibilityAddTraits(item.isSelected ? .isSelected : [])
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
