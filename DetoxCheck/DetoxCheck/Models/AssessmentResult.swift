import Foundation

/// Das Endergebnis eines durchlaufenen Self-Assessments.
struct AssessmentResult: Codable, Equatable {
    let totalScore: Int
    let maxPossibleScore: Int
    let category: ResultCategory
    /// Die frei formulierten Antworten auf die Reflexionsfragen (type == .text),
    /// werden im Ergebnis-Screen persönlich zurückgespiegelt statt bewertet.
    let reflectionAnswers: [String]
}
