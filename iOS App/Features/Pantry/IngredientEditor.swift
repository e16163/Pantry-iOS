import SwiftUI

/// Sheet for fixing an ingredient: its name, how much there is, and (for pantry items) removing it.
struct IngredientEditor: View {
    let title: String
    /// Returns false when the name can't be used (blank, or already in the pantry).
    let onSave: (_ name: String, _ quantity: Double?, _ unit: QuantityUnit?) -> Bool
    var onDelete: (() -> Void)? = nil

    @State private var name: String
    @State private var amount: Double?
    @State private var unit: QuantityUnit
    @State private var nameTaken = false
    @Environment(\.dismiss) private var dismiss

    init(title: String, name: String, quantity: Double?, unit: QuantityUnit?,
         onSave: @escaping (String, Double?, QuantityUnit?) -> Bool, onDelete: (() -> Void)? = nil) {
        self.title = title
        self.onSave = onSave
        self.onDelete = onDelete
        _name = State(initialValue: name)
        _amount = State(initialValue: quantity)
        _unit = State(initialValue: unit ?? .pieces)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    nameSection
                    amountSection
                    if let onDelete {
                        Button("Remove from pantry", systemImage: "trash", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Save", action: save)
                    .buttonStyle(.primary)
                    .disabled(IngredientName.normalize(name).isEmpty)
                    .padding()
                    .background(.bar)
            }
        }
        .presentationDragIndicator(.visible)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What is it?")
            HStack(spacing: 14) {
                let normalized = IngredientName.normalize(name)
                Thumbnail(photo: .ingredient(normalized,
                                             category: IngredientCatalog.all.first { $0.name == normalized }?.category ?? .other),
                          size: 56)
                TextField("Ingredient name", text: $name)
                    .font(.title3.weight(.semibold))
                    .autocorrectionDisabled()
                    .padding(.horizontal, 14)
                    .frame(height: 56)
                    .background(Color.fill, in: .rect(cornerRadius: 12))
                    .onChange(of: name) { nameTaken = false }
            }
            if nameTaken {
                Text("That's already in your pantry.")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "How much?", subtitle: "Optional. Leave it empty if you don't want to track it.")
            HStack(spacing: 16) {
                stepButton("minus", label: "Less") {
                    let next = (amount ?? 0) - step
                    amount = next > 0 ? next : nil
                }
                .disabled(amount == nil)
                TextField("–", value: $amount, format: .number)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(maxWidth: .infinity)
                stepButton("plus", label: "More") { amount = (amount ?? 0) + step }
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(QuantityUnit.allCases, id: \.self) { option in
                        unitPill(option)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Grams and millilitres move in bigger jumps than counts.
    private var step: Double { unit == .grams || unit == .milliliters ? 50 : 1 }

    private func stepButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(label, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.title2.weight(.bold))
            .frame(width: 56, height: 56)
            .background(Color.fill, in: .circle)
            .buttonStyle(.plain)
    }

    private func unitPill(_ option: QuantityUnit) -> some View {
        let isSelected = unit == option
        return Button(option.rawValue) { unit = option }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .frame(minHeight: 38)
            .foregroundStyle(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
            .background(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.fill), in: .capsule)
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func save() {
        if onSave(name, amount, amount == nil ? nil : unit) {
            dismiss()
        } else {
            nameTaken = true
        }
    }
}

#Preview {
    IngredientEditor(title: "Edit ingredient", name: "egg", quantity: 6, unit: .pieces,
                     onSave: { _, _, _ in true }, onDelete: {})
}
