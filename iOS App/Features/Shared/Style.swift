import SwiftUI

// Shared building blocks for the Uber Eats-style look: heavy black titles, photo-led cards, gray pill
// fields and chips, thick gray section bars, one black main button per screen, and the same spacing
// everywhere (16pt page margins, 28pt between sections).

extension Color {
    /// Brand green from the asset catalog, for tags, banners and highlights.
    static let brand = Color("AccentColor")
    /// Light gray fill for search fields, chips and thumbnails.
    static let fill = Color.secondary.opacity(0.1)
}

enum Spacing {
    static let page: CGFloat = 16
    static let section: CGFloat = 28
}

/// Full-width black (white in dark mode) button for the one main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(.background)
            .background(Color.primary.opacity(isEnabled ? 1 : 0.3), in: .rect(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

/// The big heavy page title with a gray line under it, in place of the navigation bar title.
struct PageTitle: View {
    let title: String
    /// A key, not a String, so `^[...](inflect: true)` plurals work.
    var subtitle: LocalizedStringKey? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.largeTitle.weight(.heavy))
                .tracking(-0.5)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Gray pill filter with an icon, sharing the row's width equally: filled black when selected.
struct Chip: View {
    let systemImage: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            // Icons are dropped at accessibility text sizes so the words fit.
            Label(title, systemImage: systemImage)
                .labelStyle(typeSize.isAccessibilitySize ? AnyLabelStyle(.titleOnly) : AnyLabelStyle(.titleAndIcon))
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, minHeight: 38)
                .foregroundStyle(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
                .background(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(Color.fill), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Bold section title with an optional gray subtitle.
struct SectionHeader: View {
    let title: String
    /// A key, not a String, so `^[...](inflect: true)` plurals work.
    var subtitle: LocalizedStringKey? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title2.bold())
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The thick light-gray bar that separates sections.
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.fill)
            .frame(height: 8)
            .accessibilityHidden(true)
    }
}

/// Green-tinted banner with an icon, for good news and notices.
struct InfoBanner: View {
    let systemImage: String
    let title: String
    var message: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                if let message {
                    Text(message).font(.footnote)
                }
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.brand)
        .padding(14)
        .background(Color.brand.opacity(0.1), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

/// Small green pill laid over a photo, like a promo tag.
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.brand, in: .capsule)
            .environment(\.colorScheme, .light)
    }
}

/// Square photo thumbnail for list rows.
struct Thumbnail: View {
    let photo: FoodPhoto
    var size: CGFloat = 52

    var body: some View {
        photo
            .frame(width: size, height: size)
            .clipShape(.rect(cornerRadius: 10))
    }
}

/// Big recipe card: wide dish photo with an on-hand tag, then a bold title with a time pill and a gray meta line.
struct RecipeCard: View {
    let title: String
    let minutes: Int
    let difficulty: String
    let ingredients: [String]
    /// nil when there's no pantry to compare against (Saved).
    var onHandCount: Int? = nil

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Every card gets a picture of the same size, like a delivery app's menu.
            Group {
                if let photo = RecipeArt.photo(title: title) {
                    FoodPhoto(name: photo)
                } else {
                    IngredientMosaic(ingredients: ingredients)
                }
            }
            .frame(height: 190)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(alignment: .topLeading) { onHandTag.padding(12) }
            // The time pill goes under the title at accessibility text sizes, so the title keeps the full width.
            (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                                          : AnyLayout(HStackLayout(alignment: .top, spacing: 12))) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text("\(difficulty) • ^[\(ingredients.count) ingredient](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                Text("\(minutes) min")
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.fill, in: .capsule)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var onHandTag: some View {
        if let onHandCount {
            TagPill(text: onHandCount >= ingredients.count
                    ? "You have everything"
                    : "You have \(onHandCount) of \(ingredients.count)")
        }
    }
}

/// Stand-in for a dish photo: the recipe's first few ingredient drawings side by side, edge to edge.
struct IngredientMosaic: View {
    let ingredients: [String]

    var body: some View {
        let names = ingredients.map { "ingredient-\(FoodPhoto.slug($0))" }.filter(FoodPhoto.exists).prefix(3)
        if names.isEmpty {
            FoodPhoto(name: "")  // gray tile with a fork and knife
        } else {
            // Whole drawings as rounded squares on the hero's near-black green, so nothing gets cropped.
            HStack(spacing: 10) {
                ForEach(Array(names), id: \.self) { name in
                    Image(name).resizable().scaledToFit()
                        .clipShape(.rect(cornerRadius: 14))
                        .frame(maxWidth: 110)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.09, green: 0.15, blue: 0.14))
            .accessibilityHidden(true)
        }
    }
}

/// "10 min • Easy • 5 ingredients" in gray.
struct RecipeMeta: View {
    let minutes: Int
    let difficulty: String
    let ingredientCount: Int

    var body: some View {
        Text("\(minutes) min • \(difficulty) • ^[\(ingredientCount) ingredient](inflect: true)")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

/// Lets a view switch label styles at runtime.
struct AnyLabelStyle: LabelStyle {
    private let make: (Configuration) -> AnyView

    init(_ style: some LabelStyle) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}
