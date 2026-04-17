import Foundation
import SwiftData

// Denormalized snapshot from pokemontcg.io, refreshed on each fetch.
@Model
final class CardCache {
    var id: String              // matches CollectionEntry.cardId
    var name: String
    var setName: String
    var setId: String
    var number: String
    var rarity: String?
    var imageSmallURL: String
    var imageLargeURL: String
    var currentMarketPriceUSD: Decimal?
    var tcgplayerURL: String?
    var lastFetchedAt: Date

    init(id: String, name: String, setName: String, setId: String, number: String) {
        self.id = id
        self.name = name
        self.setName = setName
        self.setId = setId
        self.number = number
        self.imageSmallURL = ""
        self.imageLargeURL = ""
        self.lastFetchedAt = Date()
    }
}
