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
    @State private var unavailableMessage: String?

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
                            HStack(spacing: 14) {
                                Thumbnail(photo: .ingredient(item.name, category: item.category))
                                Text(item.name)
                                    .font(.body.weight(.medium))
                                Spacer()
                            }
                            .plainRow(top: 8, bottom: 8)
                        }
                        .onDelete { offsets in
                            viewModel.delete(at: offsets, in: section.category)
                        }
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(section.category.title)
                                .font(.system(size: 22, weight: .bold))
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
            .alert("Photo scanning unavailable", isPresented: .constant(unavailableMessage != nil)) {
                Button("OK") { unavailableMessage = nil }
            } message: {
                Text(unavailableMessage ?? "")
            }
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
