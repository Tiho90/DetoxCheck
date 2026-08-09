import Foundation
import Combine

/// Steuert den kompletten Ablauf des Self-Assessments: Laden des Fragenkatalogs,
/// Navigation durch die Fragen, Erfassen der Antworten und Berechnung des Ergebnisses.
///
/// Die Klasse ist bewusst UI-unabhängig gehalten (kein Import von SwiftUI), damit sie sich
/// isoliert per Unit Test prüfen lässt.
@MainActor
final class AssessmentViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var questions: [Question] = []
    @Published var currentIndex: Int = 0
    @Published var isFinished: Bool = false
    @Published var loadError: AssessmentError?

    /// Aktuelle Eingabe für eine Auswahlfrage.
    @Published var selectedOptionID: Int?
    /// Aktuelle Eingabe für eine Slider-Frage.
    @Published var sliderValue: Double = 0
    /// Aktuelle Eingabe für eine Textfrage.
    @Published var textAnswer: String = ""

    @Published private(set) var result: AssessmentResult?

    // MARK: - Private State

    private var scoredAnswers: [Int: Int] = [:]
    private var reflectionAnswers: [Int: String] = [:]

    private let userDefaults: UserDefaults
    private let lastResultKey = "detoxcheck.lastResult"

    // MARK: - Init

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Laden des Fragenkatalogs

    /// Lädt und validiert `questions.json` aus dem angegebenen Bundle.
    func loadQuestions(from bundle: Bundle = .main) {
        loadError = nil

        guard let url = bundle.url(forResource: "questions", withExtension: "json") else {
            loadError = .fileNotFound
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Question].self, from: data)

            guard !decoded.isEmpty else {
                loadError = .emptyCatalog
                return
            }

            for question in decoded {
                try validate(question)
            }

            questions = decoded
            currentIndex = 0
            isFinished = false
            resetCurrentInput()
        } catch let error as AssessmentError {
            loadError = error
        } catch {
            loadError = .decodingFailed
        }
    }

    /// Setzt den Fragenkatalog direkt, ohne über das Bundle zu laden.
    /// Wird ausschließlich von Unit Tests verwendet, um kontrollierte Testdaten einzuspielen.
    func loadQuestionsForTesting(_ questions: [Question]) {
        self.questions = questions
        currentIndex = 0
        isFinished = false
        resetCurrentInput()
    }

    /// Prüft, ob eine Frage in sich konsistent aufgebaut ist.
    func validate(_ question: Question) throws {
        switch question.type {
        case .choice:
            guard let options = question.options, options.count >= 2 else {
                throw AssessmentError.invalidQuestion(id: question.id)
            }
        case .slider:
            guard let min = question.sliderMin,
                  let max = question.sliderMax,
                  let step = question.sliderStep,
                  question.maxScore != nil,
                  max > min, step > 0 else {
                throw AssessmentError.invalidQuestion(id: question.id)
            }
        case .text:
            break
        }
    }

    // MARK: - Navigation

    var currentQuestion: Question? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    /// Übernimmt die aktuelle Eingabe für die laufende Frage und springt zur nächsten
    /// bzw. berechnet am Ende das Ergebnis.
    func submitCurrentAnswer() {
        guard let question = currentQuestion else { return }

        switch question.type {
        case .choice:
            if let selectedID = selectedOptionID,
               let option = question.options?.first(where: { $0.id == selectedID }) {
                scoredAnswers[question.id] = option.score
            }
        case .slider:
            if let min = question.sliderMin, let max = question.sliderMax,
               let maxScore = question.maxScore, max > min {
                let ratio = (sliderValue - min) / (max - min)
                scoredAnswers[question.id] = Int((ratio * Double(maxScore)).rounded())
            }
        case .text:
            reflectionAnswers[question.id] = textAnswer
        }

        advance()
    }

    private func advance() {
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            resetCurrentInput()
        } else {
            finish()
        }
    }

    private func resetCurrentInput() {
        selectedOptionID = nil
        textAnswer = ""
        if let question = currentQuestion, question.type == .slider,
           let min = question.sliderMin {
            sliderValue = min
        } else {
            sliderValue = 0
        }
    }

    // MARK: - Auswertung

    private func finish() {
        let total = scoredAnswers.values.reduce(0, +)
        let maxPossible = questions.compactMap { $0.maxScore }.reduce(0, +)
            + questions.filter { $0.type == .choice }
                .compactMap { $0.options?.map(\.score).max() }
                .reduce(0, +)

        let category = ResultCategory.from(score: total, maxPossibleScore: maxPossible)
        let reflections = questions
            .filter { $0.type == .text }
            .compactMap { reflectionAnswers[$0.id] }
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        let newResult = AssessmentResult(
            totalScore: total,
            maxPossibleScore: maxPossible,
            category: category,
            reflectionAnswers: reflections
        )

        result = newResult
        isFinished = true
        saveAsLastResult(newResult)
    }

    func restart() {
        currentIndex = 0
        isFinished = false
        scoredAnswers = [:]
        reflectionAnswers = [:]
        result = nil
        resetCurrentInput()
    }

    // MARK: - Persistenz des letzten Ergebnisses (Extra-Feature)

    private func saveAsLastResult(_ result: AssessmentResult) {
        guard let data = try? JSONEncoder().encode(result) else { return }
        userDefaults.set(data, forKey: lastResultKey)
    }

    /// Liefert das beim vorherigen Durchlauf gespeicherte Ergebnis, falls vorhanden.
    var lastResult: AssessmentResult? {
        guard let data = userDefaults.data(forKey: lastResultKey),
              let decoded = try? JSONDecoder().decode(AssessmentResult.self, from: data) else {
            return nil
        }
        return decoded
    }
}
