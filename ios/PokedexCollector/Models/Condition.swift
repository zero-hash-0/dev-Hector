import Foundation

enum Condition: String, CaseIterable, Codable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case lightlyPlayed = "Lightly Played"
    case played = "Played"
    case poor = "Poor"

    var abbreviation: String {
        switch self {
        case .mint: return "M"
        case .nearMint: return "NM"
        case .lightlyPlayed: return "LP"
        case .played: return "PL"
        case .poor: return "PO"
        }
    }
}
