import SwiftData
import SwiftUI

struct PantryView: View {
    @Bindable var viewModel: PantryViewModel
    @FocusState private var isFieldFocused: Bool

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
                    ContentUnavailableView(
                        "Your pantry is empty",
                        systemImage: "refrigerator",
                        description: Text("Add what you have, and we'll suggest recipes you can make.")
                    )
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
            .toolbar {
                if isFieldFocused {
                    Button("Done") { isFieldFocused = false }
                }
            }
        }
    }
}

#Preview {
    PantryView(viewModel: PantryViewModel(context: ModelContainer.preview.mainContext))
}
