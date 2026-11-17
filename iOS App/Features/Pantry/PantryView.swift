import PhotosUI
import SwiftData
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct PantryView: View {
    @Bindable var viewModel: PantryViewModel
    @FocusState private var isFieldFocused: Bool
    @State private var isChoosingPhoto = false
    @State private var isTakingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isReviewing = false
    @State private var isShowingPhotoUnavailable = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add an ingredient", text: $viewModel.newItemName)
                            .focused($isFieldFocused)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit {
                                viewModel.add()
                                isFieldFocused = true
                            }
                        Button("Add", action: viewModel.add)
                    }
                    ForEach(viewModel.suggestions, id: \.self) { name in
                        Button {
                            viewModel.add(suggestion: name)
                        } label: {
                            Label(name, systemImage: "plus.circle")
                        }
                    }
                } footer: {
                    if !viewModel.items.isEmpty {
                        Text("^[\(viewModel.items.count) ingredient](inflect: true)")
                    }
                }
                if viewModel.items.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text("Your pantry is empty")
                        } icon: {
                            Image(.emptyPantry).illustration()
                        }
                    } description: {
                        Text("Add what you have, and we'll suggest recipes you can make.")
                    } actions: {
                        Button("Try a sample pantry", action: viewModel.addSample)
                    }
                }
                ForEach(viewModel.sections, id: \.category) { section in
                    Section {
                        ForEach(section.items) { item in
                            Text(item.name)
                        }
                        .onDelete { offsets in
                            viewModel.delete(at: offsets, in: section.category)
                        }
                    } header: {
                        Label(section.category.title, systemImage: section.category.systemImage)
                    }
                }
            }
            .navigationTitle("Pantry")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(.logo)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        Text("pantry")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(.tint)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if IngredientDetector.isAvailable {
                        Menu {
                            #if os(iOS)
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button("Take photo", systemImage: "camera") { isTakingPhoto = true }
                            }
                            #endif
                            Button("Choose photo", systemImage: "photo.on.rectangle") { isChoosingPhoto = true }
                        } label: {
                            Label("Add from photo", systemImage: "camera")
                        }
                    } else {
                        Button("Add from photo", systemImage: "camera") { isShowingPhotoUnavailable = true }
                    }
                }
                if isFieldFocused {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") { isFieldFocused = false }
                    }
                }
            }
            .photosPicker(isPresented: $isChoosingPhoto, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                photoItem = nil
                scan { try? await item.loadTransferable(type: Data.self) }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $isTakingPhoto) {
                CameraPicker { image in
                    scan { image.jpegData(compressionQuality: 0.9) }
                }
                .ignoresSafeArea()
            }
            #endif
            .sheet(isPresented: $isReviewing) {
                DetectionReviewSheet(viewModel: viewModel)
            }
            .alert("Photo scanning isn't available", isPresented: $isShowingPhotoUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Spotting ingredients in a photo needs iOS 27 and Apple Intelligence. You can still type them in.")
            }
        }
    }

    /// Opens the review sheet right away with a spinner, then loads the photo and runs detection.
    private func scan(_ load: @escaping () async -> Data?) {
        viewModel.isDetecting = true
        isReviewing = true
        Task {
            guard let data = await load(), let image = IngredientDetector.image(from: data) else {
                viewModel.detectionError = "That photo couldn't be opened. Try another one."
                viewModel.isDetecting = false
                return
            }
            await viewModel.detect(image)
        }
    }
}

#if os(iOS)
/// The system camera, since SwiftUI has no camera view of its own.
private struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif

#Preview {
    PantryView(viewModel: PantryViewModel(context: ModelContainer.preview.mainContext))
}
