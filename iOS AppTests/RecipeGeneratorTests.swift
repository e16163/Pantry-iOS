import Foundation
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

    @Test(arguments: [
        (LanguageModelSession.GenerationError.guardrailViolation(.init(debugDescription: "")), RecipeGenerator.safetyMessage),
        (.rateLimited(.init(debugDescription: "")), RecipeGenerator.busyMessage),
        (.exceededContextWindowSize(.init(debugDescription: "")), RecipeGenerator.tooLongMessage),
        (.assetsUnavailable(.init(debugDescription: "")), RecipeGenerator.genericMessage),
    ])
    func generationErrorsGetFriendlyMessages(error: LanguageModelSession.GenerationError, expected: String) {
        #expect(RecipeGenerator.message(for: error) == expected)
    }

    @Test func unrelatedErrorsGetTheGenericMessage() {
        #expect(RecipeGenerator.message(for: URLError(.badURL)) == RecipeGenerator.genericMessage)
    }
}
