import Foundation

/// Die möglichen Fragetypen im Self-Assessment.
enum QuestionType: String, Codable {
    case choice
    case slider
    case text
}

/// Eine Antwortoption für eine Auswahlfrage (`type == .choice`).
struct AnswerOption: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
    let score: Int
}

/// Eine einzelne Frage des Self-Assessments.
///
/// Je nach `type` sind unterschiedliche Felder relevant:
/// - `.choice`: `options` ist gesetzt, jede Option trägt einen festen Score.
/// - `.slider`: `sliderMin`, `sliderMax`, `sliderStep`, `sliderUnit` und `maxScore` sind gesetzt.
///   Der erzielte Score wird linear aus dem gewählten Wert berechnet.
/// - `.text`: keine der obigen Felder gesetzt. Die Antwort fließt nicht in die Wertung ein,
///   sondern wird im Ergebnis-Screen als persönliche Reflexion angezeigt.
struct Question: Codable, Identifiable {
    let id: Int
    let text: String
    let type: QuestionType

    // Nur für .choice
    let options: [AnswerOption]?

    // Nur für .slider
    let sliderMin: Double?
    let sliderMax: Double?
    let sliderStep: Double?
    let sliderUnit: String?
    let maxScore: Int?
}
