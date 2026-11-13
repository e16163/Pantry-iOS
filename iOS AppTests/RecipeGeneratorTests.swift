import FoundationModels
import Testing
@testable import iOS_App

struct RecipeGeneratorTests {
    @Test func noMessageWhenModelIsAvailable() {
        #expect(RecipeGenerator.message(for: .available) == nil)
    }

    @Test(arguments: [
        (SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible, "doesn't support"),
        (.appleIntelligenceNotEnabled, "Turn on Apple Intelligence"),
        (.modelNotReady, "still getting ready"),
    ])
    func eachUnavailableReasonGetsItsOwnMessage(reason: SystemLanguageModel.Availability.UnavailableReason, phrase: String) {
        #expect(RecipeGenerator.message(for: .unavailable(reason))?.contains(phrase) == true)
    }
}
