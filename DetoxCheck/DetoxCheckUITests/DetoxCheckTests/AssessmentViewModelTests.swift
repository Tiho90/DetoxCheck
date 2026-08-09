import XCTest
@testable import DetoxCheck

@MainActor
final class AssessmentViewModelTests: XCTestCase {

    private func makeViewModel(defaultsSuite: String = #function) -> AssessmentViewModel {
        let defaults = UserDefaults(suiteName: defaultsSuite)!
        defaults.removePersistentDomain(forName: defaultsSuite)
        return AssessmentViewModel(userDefaults: defaults)
    }

    private func sampleQuestions() -> [Question] {
        [
            Question(
                id: 1, text: "Choice-Frage", type: .choice,
                options: [
                    AnswerOption(id: 1, text: "Nie", score: 0),
                    AnswerOption(id: 2, text: "Immer", score: 3)
                ],
                sliderMin: nil, sliderMax: nil, sliderStep: nil, sliderUnit: nil, maxScore: nil
            ),
            Question(
                id: 2, text: "Slider-Frage", type: .slider,
                options: nil,
                sliderMin: 0, sliderMax: 10, sliderStep: 1, sliderUnit: "h", maxScore: 3
            ),
            Question(
                id: 3, text: "Text-Frage", type: .text,
                options: nil,
                sliderMin: nil, sliderMax: nil, sliderStep: nil, sliderUnit: nil, maxScore: nil
            )
        ]
    }

    // MARK: - Validierung

    func testValidateRejectsChoiceQuestionWithTooFewOptions() {
        let viewModel = makeViewModel()
        let invalid = Question(
            id: 99, text: "Kaputt", type: .choice,
            options: [AnswerOption(id: 1, text: "Nur eine", score: 0)],
            sliderMin: nil, sliderMax: nil, sliderStep: nil, sliderUnit: nil, maxScore: nil
        )
        XCTAssertThrowsError(try viewModel.validate(invalid)) { error in
            XCTAssertEqual(error as? AssessmentError, .invalidQuestion(id: 99))
        }
    }

    func testValidateRejectsSliderQuestionWithMissingRange() {
        let viewModel = makeViewModel()
        let invalid = Question(
            id: 42, text: "Kaputter Slider", type: .slider,
            options: nil,
            sliderMin: nil, sliderMax: 10, sliderStep: 1, sliderUnit: "h", maxScore: 3
        )
        XCTAssertThrowsError(try viewModel.validate(invalid)) { error in
            XCTAssertEqual(error as? AssessmentError, .invalidQuestion(id: 42))
        }
    }

    func testValidateAcceptsWellFormedQuestions() {
        let viewModel = makeViewModel()
        for question in sampleQuestions() {
            XCTAssertNoThrow(try viewModel.validate(question))
        }
    }

    // MARK: - Scoring

    func testChoiceAnswerContributesSelectedScore() {
        let viewModel = makeViewModel()
        viewModel.loadQuestionsForTesting(sampleQuestions())

        viewModel.selectedOptionID = 2 // "Immer", Score 3
        viewModel.submitCurrentAnswer()

        viewModel.sliderValue = 5 // Hälfte von 0...10 -> Score 2 (gerundet von 1.5)
        viewModel.submitCurrentAnswer()

        viewModel.textAnswer = "Ich würde spazieren gehen."
        viewModel.submitCurrentAnswer()

        XCTAssertTrue(viewModel.isFinished)
        XCTAssertEqual(viewModel.result?.totalScore, 5) // 3 (choice) + 2 (slider)
        XCTAssertEqual(viewModel.result?.maxPossibleScore, 6) // 3 (choice) + 3 (slider)
        XCTAssertEqual(viewModel.result?.reflectionAnswers, ["Ich würde spazieren gehen."])
    }

    func testEmptyTextAnswerIsNotIncludedInReflections() {
        let viewModel = makeViewModel()
        viewModel.loadQuestionsForTesting(sampleQuestions())

        viewModel.selectedOptionID = 1
        viewModel.submitCurrentAnswer()
        viewModel.sliderValue = 0
        viewModel.submitCurrentAnswer()
        viewModel.textAnswer = "   "
        viewModel.submitCurrentAnswer()

        XCTAssertEqual(viewModel.result?.reflectionAnswers, [])
    }

    // MARK: - Kategorisierung

    func testCategoryThresholds() {
        XCTAssertEqual(ResultCategory.from(score: 0, maxPossibleScore: 24), .entspannt)
        XCTAssertEqual(ResultCategory.from(score: 12, maxPossibleScore: 24), .grenzwertig)
        XCTAssertEqual(ResultCategory.from(score: 24, maxPossibleScore: 24), .suchtgefaehrdet)
    }

    // MARK: - Persistenz des letzten Ergebnisses

    func testLastResultIsPersistedAcrossRuns() {
        let suiteName = "testLastResultIsPersistedAcrossRuns"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let first = AssessmentViewModel(userDefaults: defaults)
        first.loadQuestionsForTesting(sampleQuestions())
        first.selectedOptionID = 2
        first.submitCurrentAnswer()
        first.sliderValue = 10
        first.submitCurrentAnswer()
        first.textAnswer = ""
        first.submitCurrentAnswer()

        let second = AssessmentViewModel(userDefaults: defaults)
        XCTAssertEqual(second.lastResult?.category, first.result?.category)
    }

    // MARK: - Fehlerfall: fehlende Datei

    func testLoadQuestionsSetsErrorWhenFileMissing() {
        let viewModel = makeViewModel()
        // Bundle ohne questions.json (Test-Bundle enthält die Datei nicht unter diesem Namen).
        let emptyBundle = Bundle(for: BundleMarker.self)
        viewModel.loadQuestions(from: emptyBundle)
        XCTAssertNotNil(viewModel.loadError)
    }
}

/// Hilfsklasse, um an das Test-Bundle heranzukommen.
private final class BundleMarker {}
