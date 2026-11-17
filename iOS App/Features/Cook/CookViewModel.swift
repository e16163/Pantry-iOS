import Observation

@Observable
@MainActor
final class CookViewModel {
    let title: String
    let steps: [String]
    /// Index of the page on screen; `steps.count` is the done page.
    var page = 0

    init(title: String, steps: [String]) {
        self.title = title
        self.steps = steps
    }

    var isDone: Bool { page >= steps.count }
    var canGoBack: Bool { page > 0 }

    /// "Step 2 of 5", or "Done" on the last page.
    var progressLabel: String {
        isDone ? "Done" : "Step \(page + 1) of \(steps.count)"
    }

    /// From 0 to 1; reaches 1 on the done page.
    var progress: Double {
        steps.isEmpty ? 1 : Double(min(page, steps.count)) / Double(steps.count)
    }

    func next() {
        if !isDone { page += 1 }
    }

    func previous() {
        if canGoBack { page -= 1 }
    }
}
