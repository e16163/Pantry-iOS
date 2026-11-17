import PhotosUI
import SwiftData
import SwiftUI

struct PantryView: View {
    @Bindable var viewModel: PantryViewModel
    @FocusState private var isFieldFocused: Bool
    @State private var photoItem: PhotosPickerItem?
    @State private var isPickingPhoto = false
    @State private var isTakingPhoto = false
    @State private var isReviewing = false
    @State private var unavailableMessage: String?

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
                            HStack(spacing: 14) {
                                Text(IngredientEmoji.emoji(for: item.name, category: item.category))
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 8))
                                    .accessibilityHidden(true)
                                Text(item.name)
                                    .font(.body.weight(.medium))
                            }
                        }
                        .onDelete { offsets in
                            viewModel.delete(at: offsets, in: section.category)
                        }
                    } header: {
                        Label(section.category.title, systemImage: section.category.systemImage)
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.items.count)
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
                    if isFieldFocused {
                        Button("Done") { isFieldFocused = false }
                    } else {
                        photoButton
                    }
                }
            }
            .photosPicker(isPresented: $isPickingPhoto, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) {
                guard let item = photoItem else { return }
                photoItem = nil
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self) else { return }
                    review(data)
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $isTakingPhoto) {
                CameraPicker(onCapture: review).ignoresSafeArea()
            }
            #endif
            .sheet(isPresented: $isReviewing) {
                DetectionReviewSheet(viewModel: viewModel)
            }
            .alert("Photo scanning unavailable", isPresented: .constant(unavailableMessage != nil)) {
                Button("OK") { unavailableMessage = nil }
            } message: {
                Text(unavailableMessage ?? "")
            }
        }
    }
}

extension PantryView {
    /// Always shown, so a phone that can't scan says why instead of hiding the feature.
    @ViewBuilder
    private var photoButton: some View {
        if let message = IngredientDetector.unavailableMessage {
            Button("Scan a photo", systemImage: "camera") { unavailableMessage = message }
        } else {
            Menu("Scan a photo", systemImage: "camera") {
                #if os(iOS)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take photo", systemImage: "camera") { isTakingPhoto = true }
                }
                #endif
                Button("Choose photo", systemImage: "photo.on.rectangle") { isPickingPhoto = true }
            }
        }
    }

    private func review(_ photo: Data) {
        isReviewing = true
        Task { await viewModel.detect(photo: photo) }
    }
}

#Preview {
    PantryView(viewModel: PantryViewModel(context: ModelContainer.preview.mainContext))
}
