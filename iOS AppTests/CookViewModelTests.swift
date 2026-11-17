import Testing
@testable import iOS_App

@MainActor
struct CookViewModelTests {
    let cook = CookViewModel(title: "Test", steps: ["One", "Two"])

    @Test func startsOnFirstStep() {
        #expect(cook.progressLabel == "Step 1 of 2")
        #expect(cook.progress == 0)
        #expect(!cook.canGoBack)
        #expect(!cook.isDone)
    }

    @Test func nextReachesDonePageAndStops() {
        cook.next()
        #expect(cook.progressLabel == "Step 2 of 2")
        cook.next()
        #expect(cook.isDone)
        #expect(cook.progressLabel == "Done")
        #expect(cook.progress == 1)
        cook.next()
        #expect(cook.page == 2)
    }

    @Test func previousStopsAtFirstStep() {
        cook.next()
        cook.previous()
        cook.previous()
        #expect(cook.page == 0)
    }
}
