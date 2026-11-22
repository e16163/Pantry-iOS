import Foundation

/// Fixes the user made to photo-scan results ("lemon" → "lime"), kept on the phone.
/// Apple's on-device model can't be retrained by an app, so instead later scans apply these fixes
/// directly and pass them to the model as hints.
struct ScanCorrections {
    private(set) var fixes: [String: String]
    private let defaults: UserDefaults
    private static let key = "scanCorrections"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        fixes = defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:]
    }

    mutating func record(from wrong: String, to right: String) {
        let wrong = IngredientName.normalize(wrong)
        let right = IngredientName.normalize(right)
        guard !wrong.isEmpty, !right.isEmpty, wrong != right else { return }
        fixes[wrong] = right
        defaults.set(fixes, forKey: Self.key)
    }

    func apply(_ name: String) -> String { fixes[name] ?? name }

    /// Up to 20 fixes as prompt lines, so the prompt stays short.
    var hints: [String] {
        fixes.sorted { $0.key < $1.key }.prefix(20).map { "what looks like \"\($0.key)\" is \"\($0.value)\"" }
    }
}
