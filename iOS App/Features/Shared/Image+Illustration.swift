import SwiftUI

extension Image {
    /// Brand illustrations are decorative; the text next to them carries the meaning.
    func illustration() -> some View {
        resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
            .accessibilityHidden(true)
    }
}
