import Foundation

/// Fehlerfälle rund um das Laden und Validieren des Fragenkatalogs.
enum AssessmentError: Error, LocalizedError, Equatable {
    case fileNotFound
    case decodingFailed
    case invalidQuestion(id: Int)
    case emptyCatalog

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Der Fragenkatalog konnte im App-Bundle nicht gefunden werden."
        case .decodingFailed:
            return "Der Fragenkatalog ist fehlerhaft formatiert und konnte nicht gelesen werden."
        case .invalidQuestion(let id):
            return "Frage \(id) ist unvollständig oder ungültig aufgebaut."
        case .emptyCatalog:
            return "Der Fragenkatalog enthält keine Fragen."
        }
    }
}
