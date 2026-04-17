import Foundation
import SwiftData

// Optional local cache; source of truth will be Supabase in M3.
@Model
final class PriceHistoryPoint {
    var cardId: String
    var date: Date
    var marketPriceUSD: Decimal

    init(cardId: String, date: Date, marketPriceUSD: Decimal) {
        self.cardId = cardId
        self.date = date
        self.marketPriceUSD = marketPriceUSD
    }
}
