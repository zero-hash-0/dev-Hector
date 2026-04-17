import Foundation
import SwiftData

@Model
final class CollectionEntry {
    var id: UUID
    var cardId: String          // e.g. "swsh1-185", the pokemontcg.io ID
    var quantity: Int
    var condition: String       // Condition.rawValue
    var isFoil: Bool
    var purchasePrice: Decimal?
    var purchaseDate: Date?
    var notes: String?
    var addedAt: Date
    var lastPriceCheck: Date?

    init(
        cardId: String,
        quantity: Int = 1,
        condition: Condition = .nearMint,
        isFoil: Bool = false
    ) {
        self.id = UUID()
        self.cardId = cardId
        self.quantity = quantity
        self.condition = condition.rawValue
        self.isFoil = isFoil
        self.addedAt = Date()
    }

    var conditionEnum: Condition {
        get { Condition(rawValue: condition) ?? .nearMint }
        set { condition = newValue.rawValue }
    }
}
