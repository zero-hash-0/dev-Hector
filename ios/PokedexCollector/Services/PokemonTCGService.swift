import Foundation

// MARK: - Response models

struct TCGCard: Identifiable, Codable {
    let id: String
    let name: String
    let number: String
    let rarity: String?
    let images: CardImages
    let set: CardSet
    let tcgplayer: TCGPlayerData?

    struct CardImages: Codable {
        let small: String
        let large: String
    }

    struct CardSet: Codable {
        let id: String
        let name: String
    }

    struct TCGPlayerData: Codable {
        let url: String?
        let prices: TCGPrices?

        struct TCGPrices: Codable {
            let normal: PricePoint?
            let holofoil: PricePoint?
            let reverseHolofoil: PricePoint?

            struct PricePoint: Codable {
                let market: Double?
            }
        }
    }

    // Prefer holofoil > normal > reverseHolofoil market price.
    var marketPrice: Decimal? {
        guard let prices = tcgplayer?.prices else { return nil }
        let raw = prices.holofoil?.market
            ?? prices.normal?.market
            ?? prices.reverseHolofoil?.market
        guard let raw else { return nil }
        return Decimal(raw)
    }
}

private struct TCGSearchResponse: Codable {
    let data: [TCGCard]
}

private struct TCGSingleResponse: Codable {
    let data: TCGCard
}

// MARK: - Service

actor PokemonTCGService {
    static let shared = PokemonTCGService()

    private let baseURL = "https://api.pokemontcg.io/v2"

    private var apiKey: String? {
        UserDefaults.standard.string(forKey: "pokemonTCGApiKey")
    }

    private init() {}

    /// Search by name and/or collector number. Passing both produces an AND query.
    func searchCards(name: String? = nil, number: String? = nil, setId: String? = nil) async throws -> [TCGCard] {
        var queryParts: [String] = []
        if let name, !name.isEmpty {
            queryParts.append("name:\"\(name)\"")
        }
        if let number, !number.isEmpty {
            queryParts.append("number:\(number)")
        }
        if let setId, !setId.isEmpty {
            queryParts.append("set.id:\(setId)")
        }

        var components = URLComponents(string: "\(baseURL)/cards")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pageSize", value: "20"),
            URLQueryItem(name: "orderBy", value: "name"),
        ]
        if !queryParts.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: queryParts.joined(separator: " ")))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(for: authorizedRequest(url))
        return try JSONDecoder().decode(TCGSearchResponse.self, from: data).data
    }

    func fetchCard(id: String) async throws -> TCGCard {
        guard let url = URL(string: "\(baseURL)/cards/\(id)") else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(for: authorizedRequest(url))
        return try JSONDecoder().decode(TCGSingleResponse.self, from: data).data
    }

    private func authorizedRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        if let key = apiKey {
            req.setValue(key, forHTTPHeaderField: "X-Api-Key")
        }
        return req
    }
}
