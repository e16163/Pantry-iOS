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
                }
                Section("\(viewModel.items.count) ingredients") {
                    ForEach(viewModel.items) { item in
                        Text(item.name)
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
            .navigationTitle("Pantry")
        }
    }
}

#Preview {
    PantryView(viewModel: PantryViewModel(context: ModelContainer.preview.mainContext))
}
