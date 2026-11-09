import SwiftData
import SwiftUI

struct PantryView: View {
    @Bindable var viewModel: PantryViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add an ingredient", text: $viewModel.newItemName)
                            .onSubmit(viewModel.add)
                        Button("Add", action: viewModel.add)
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
