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
    @State private var editingItem: PantryItem?

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
                            row(for: item)
                        }
                    } header: {
                        Label(section.category.title, systemImage: section.category.systemImage)
                    }
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.items.count)
            .animation(.snappy, value: viewModel.recentlyDeleted?.name)
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
            .sheet(item: $editingItem) { item in
                IngredientEditor(title: "Edit ingredient", name: item.name, quantity: item.quantity, unit: item.unit,
                                 onSave: { viewModel.update(item, name: $0, quantity: $1, unit: $2) },
                                 onDelete: { viewModel.delete(item) })
            }
            .safeAreaInset(edge: .bottom) { undoToast }
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
                    Button("Take photo", systemImage: "camera") {
                        viewModel.prepareScan()
                        isTakingPhoto = true
                    }
                }
                #endif
                Button("Choose photo", systemImage: "photo.on.rectangle") {
                    viewModel.prepareScan()
                    isPickingPhoto = true
                }
            }
        }
    }

    /// Tap to edit; swipe or long-press for quick edit and remove.
    private func row(for item: PantryItem) -> some View {
        Button {
            editingItem = item
        } label: {
            HStack(spacing: 14) {
                Text(IngredientEmoji.emoji(for: item.name, category: item.category))
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1), in: .rect(cornerRadius: 10))
                    .accessibilityHidden(true)
                Text(item.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Group {
                    if let quantity = item.quantityText {
                        Text(quantity).foregroundStyle(.primary)
                    } else {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                            Text("Amount")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .font(.footnote.weight(.semibold).monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.secondary.opacity(0.12), in: .capsule)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edit name or amount")
        .swipeActions {
            Button("Remove", systemImage: "trash", role: .destructive) { viewModel.delete(item) }
            Button("Edit", systemImage: "pencil") { editingItem = item }
        }
        .contextMenu {
            Button("Edit", systemImage: "pencil") { editingItem = item }
            Button("Remove", systemImage: "trash", role: .destructive) { viewModel.delete(item) }
        }
    }

    /// "Removed garlic · Undo" for a few seconds after a delete.
    @ViewBuilder
    private var undoToast: some View {
        if let removed = viewModel.recentlyDeleted {
            HStack {
                Text("Removed \(removed.name)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Undo", action: viewModel.undoDelete)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.brand)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .foregroundStyle(.background)
            .background(Color.primary, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: removed.name) {
                try? await Task.sleep(for: .seconds(4))
                withAnimation { viewModel.clearUndo() }
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
