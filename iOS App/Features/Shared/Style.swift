import SwiftUI

// Shared building blocks for the app's look: white pages split by thick gray bars, bold section
// titles, big food cards, mint info banners, and one black main button per screen.

extension Color {
    /// Brand green from the asset catalog, for tags, banners and highlights.
    static let brand = Color("AccentColor")
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

/// Outlined capsule with an optional emoji, for filters: filled black when selected.
struct Chip: View {
    var emoji: String? = nil
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji { Text(emoji) }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
            .background(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.background), in: .capsule)
            .overlay(Capsule().strokeBorder(Color.secondary.opacity(isSelected ? 0 : 0.3)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Bold section title with an optional gray subtitle.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

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
            .fill(Color.secondary.opacity(0.12))
            .frame(height: 8)
            .accessibilityHidden(true)
    }
}

/// Mint banner with an icon, for good news and notices.
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

/// Small dark-green pill laid over food art, like a promo tag.
struct TagPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.brand, in: .capsule)
            .environment(\.colorScheme, .light)
    }
}

/// Big recipe card: wide art tile with an on-hand tag, then a bold title and a gray meta line.
struct RecipeCard: View {
    let title: String
    let minutes: Int
    let difficulty: String
    let ingredients: [String]
    /// nil when there's no pantry to compare against (Saved).
    var onHandCount: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RecipeArtTile(title: title, ingredients: ingredients, emojiSize: 72)
                .frame(height: 170)
                .clipShape(.rect(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if let onHandCount {
                        TagPill(text: onHandCount >= ingredients.count
                                ? "You have everything"
                                : "You have \(onHandCount) of \(ingredients.count)")
                            .padding(12)
                    }
                }
                .padding(.bottom, 4)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            RecipeMeta(minutes: minutes, difficulty: difficulty, ingredientCount: ingredients.count)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
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
