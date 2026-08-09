import Foundation

/// Die vier Ergebniskategorien, in die das Gesamt-Score-Ergebnis eingeordnet wird.
enum ResultCategory: String, Codable, CaseIterable {
    case entspannt = "Entspannt"
    case bewusst = "Bewusst"
    case grenzwertig = "Grenzwertig"
    case suchtgefaehrdet = "Suchtgefährdet"

    /// Ordnet einen erreichten Score der passenden Kategorie zu.
    /// Der Score-Bereich (0...maxPossibleScore) wird dafür in vier gleich große Abschnitte geteilt.
    static func from(score: Int, maxPossibleScore: Int) -> ResultCategory {
        guard maxPossibleScore > 0 else { return .entspannt }
        let ratio = Double(score) / Double(maxPossibleScore)

        switch ratio {
        case ..<0.25:
            return .entspannt
        case 0.25..<0.5:
            return .bewusst
        case 0.5..<0.75:
            return .grenzwertig
        default:
            return .suchtgefaehrdet
        }
    }

    var tip: String {
        switch self {
        case .entspannt:
            return "Dein Umgang mit dem Smartphone ist bereits sehr ausgeglichen. Weiter so!"
        case .bewusst:
            return "Du hast ein gutes Gespür für deinen Konsum, an ein paar Stellen ist noch Luft nach oben."
        case .grenzwertig:
            return "Das Smartphone nimmt in deinem Alltag schon viel Raum ein. Feste Auszeiten könnten helfen."
        case .suchtgefaehrdet:
            return "Dein Konsum ist auffällig hoch. Es könnte sich lohnen, bewusst kleine Pausen einzuplanen."
        }
    }
}
