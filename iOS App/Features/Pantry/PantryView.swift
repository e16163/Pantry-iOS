import PhotosUI
import SwiftData
import SwiftUI

struct PantryView: View {
    @Bindable var viewModel: PantryViewModel
    @FocusState private var isFieldFocused: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var photoItem: PhotosPickerItem?
    @State private var isPickingPhoto = false
    @State private var isTakingPhoto = false
    @State private var isReviewing = false
    @State private var editingItem: PantryItem?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn

    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading, spacing: 16) {
                    PageTitle(title: "Your pantry",
                              subtitle: viewModel.items.isEmpty ? nil : "^[\(viewModel.items.count) ingredient](inflect: true) on hand")
                    searchField
                }
                .plainRow(top: 8, bottom: viewModel.suggestions.isEmpty ? 12 : 4)
                ForEach(viewModel.suggestions, id: \.self) { name in
                    Button {
                        viewModel.add(suggestion: name)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 36, height: 36)
                                .background(Color.fill, in: .circle)
                            Text(name).font(.body.weight(.medium))
                            Spacer()
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .plainRow(top: 6, bottom: 6)
                }
                if viewModel.items.isEmpty {
                    emptyState
                        .plainRow(top: 32, bottom: 32)
                }
                ForEach(viewModel.sections, id: \.category) { section in
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                                .plainRow(top: 8, bottom: 8)
                        }
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(section.category.title)
                                .font(.title2.bold())
                                .foregroundStyle(Color.primary)
                            Spacer()
                            Text("\(section.items.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .textCase(nil)
                        .padding(.top, 4)
                        .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .listStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.items.count)
            .onChange(of: scenePhase) {
                if scenePhase == .active { viewModel.load() }  // picks up items added with Siri
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
            .animation(.snappy, value: viewModel.recentlyDeleted?.name)
        }
    }
}

extension PantryView {
    /// Gray pill field, like a delivery app's search bar.
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Add an ingredient", text: $viewModel.newItemName)
                .focused($isFieldFocused)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    viewModel.add()
                    isFieldFocused = true
                }
            if !viewModel.newItemName.isEmpty {
                Button("Add", action: viewModel.add)
                    .font(.subheadline.weight(.bold))
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(Color.fill, in: .capsule)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(.emptyPantry).illustration()
            Text("Your pantry is empty")
                .font(.title2.bold())
            Text("Add what you have, or scan your fridge, and we'll suggest recipes you can make.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Try a sample pantry", action: viewModel.addSample)
                .buttonStyle(.primary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private var photoButton: some View {
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

    /// Tap to edit; swipe or long-press for quick edit and remove.
    private func row(for item: PantryItem) -> some View {
        Button {
            editingItem = item
        } label: {
            HStack(spacing: 14) {
                Thumbnail(photo: .ingredient(item.name, category: item.category))
                // At accessibility text sizes the amount goes under the name, so neither wraps mid-word.
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                    : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    Text(item.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    amountPill(item)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.quantityText.map { "\(item.name), \($0)" } ?? item.name)
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

    private func amountPill(_ item: PantryItem) -> some View {
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
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.fill, in: .capsule)
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
            .padding(.horizontal, Spacing.page)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: removed.name) {
                // VoiceOver users hear it and get longer to reach Undo.
                AccessibilityNotification.Announcement("Removed \(removed.name). Undo is available.").post()
                try? await Task.sleep(for: .seconds(voiceOverOn ? 10 : 4))
                withAnimation { viewModel.clearUndo() }
            }
        }
    }

    private func review(_ photo: Data) {
        isReviewing = true
        Task { await viewModel.detect(photo: photo) }
    }
}

private extension View {
    /// List row with the page margins, no separator, and the given vertical padding.
    func plainRow(top: CGFloat, bottom: CGFloat) -> some View {
        listRowInsets(EdgeInsets(top: top, leading: Spacing.page, bottom: bottom, trailing: Spacing.page))
            .listRowSeparator(.hidden)
    }
}

#Preview {
    PantryView(viewModel: PantryViewModel(context: ModelContainer.preview.mainContext))
}
