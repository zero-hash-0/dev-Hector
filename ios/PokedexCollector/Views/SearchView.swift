import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allEntries: [CollectionEntry]

    @State private var query = ""
    @State private var results: [TCGCard] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedCard: TCGCard?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                        .padding()

                    Divider().background(Color.white.opacity(0.08))

                    resultArea
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(item: $selectedCard) { card in
            CardConfirmationSheet(card: card) { qty, condition, isFoil in
                addCard(card, quantity: qty, condition: condition, isFoil: isFoil)
                dismiss()
            }
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.4))
            TextField("Card name or collector number…", text: $query)
                .foregroundStyle(.white)
                .tint(Color.pokemonYellow)
                .submitLabel(.search)
                .onSubmit { performSearch() }
            if !query.isEmpty {
                Button {
                    query = ""
                    results = []
                    errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var resultArea: some View {
        if isLoading {
            Spacer()
            ProgressView().tint(Color.pokemonYellow)
            Spacer()
        } else if let error = errorMessage {
            Spacer()
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        } else if results.isEmpty && !query.isEmpty {
            Spacer()
            Text("No results for "\(query)"")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { card in
                        Button { selectedCard = card } label: {
                            CardSearchRow(card: card)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.leading, 74)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Actions

    private func performSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        results = []

        Task {
            do {
                // If it looks like "185" or "185/202" treat it as collector number search.
                let isNumber = trimmed.range(of: #"^\d{1,3}(/\d{1,3})?$"#, options: .regularExpression) != nil
                let cards = try await PokemonTCGService.shared.searchCards(
                    name: isNumber ? nil : trimmed,
                    number: isNumber ? trimmed.components(separatedBy: "/").first : nil
                )
                await MainActor.run {
                    results = cards
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Search failed. Check your connection and try again."
                    isLoading = false
                }
            }
        }
    }

    private func addCard(_ card: TCGCard, quantity: Int, condition: Condition, isFoil: Bool) {
        if let existing = allEntries.first(where: { $0.cardId == card.id }) {
            existing.quantity += quantity
        } else {
            let entry = CollectionEntry(cardId: card.id, quantity: quantity, condition: condition, isFoil: isFoil)
            modelContext.insert(entry)
        }
        upsertCache(from: card)
    }

    private func upsertCache(from card: TCGCard) {
        let cardId = card.id
        let descriptor = FetchDescriptor<CardCache>(predicate: #Predicate<CardCache> { $0.id == cardId })
        let existing = (try? modelContext.fetch(descriptor))?.first

        let cache: CardCache
        if let existing {
            cache = existing
        } else {
            cache = CardCache(id: card.id, name: card.name, setName: card.set.name, setId: card.set.id, number: card.number)
            modelContext.insert(cache)
        }

        cache.name = card.name
        cache.setName = card.set.name
        cache.setId = card.set.id
        cache.number = card.number
        cache.rarity = card.rarity
        cache.imageSmallURL = card.images.small
        cache.imageLargeURL = card.images.large
        cache.currentMarketPriceUSD = card.marketPrice
        cache.tcgplayerURL = card.tcgplayer?.url
        cache.lastFetchedAt = Date()
    }
}

// MARK: - Search result row

struct CardSearchRow: View {
    let card: TCGCard

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: card.images.small)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
            }
            .frame(width: 50, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 5))

            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                Text("\(card.set.name) · #\(card.number)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                if let rarity = card.rarity {
                    Text(rarity)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            Spacer()

            if let price = card.marketPrice {
                Text(price, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.pokemonYellow)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
