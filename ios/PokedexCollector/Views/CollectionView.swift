import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CollectionEntry.addedAt, order: .reverse) private var entries: [CollectionEntry]
    @Query private var cardCaches: [CardCache]

    @State private var showSearch = false
    @State private var showSettings = false

    private var cacheMap: [String: CardCache] {
        Dictionary(uniqueKeysWithValues: cardCaches.map { ($0.id, $0) })
    }

    private var totalPortfolioValue: Decimal {
        entries.reduce(.zero) { sum, entry in
            guard let price = cacheMap[entry.cardId]?.currentMarketPriceUSD else { return sum }
            return sum + price * Decimal(entry.quantity)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        PortfolioHeaderView(totalValue: totalPortfolioValue, cardCount: entries.count)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 20)

                        if entries.isEmpty {
                            EmptyCollectionView(onAdd: { showSearch = true })
                                .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(entries) { entry in
                                    if let cache = cacheMap[entry.cardId] {
                                        NavigationLink {
                                            CardDetailView(entry: entry, cache: cache)
                                        } label: {
                                            CardGridItem(cache: cache, entry: entry)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 100)
                        }
                    }
                }

                // Pokémon yellow FAB
                Button { showSearch = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.pokemonYellow)
                        .clipShape(Circle())
                        .shadow(color: Color.pokemonYellow.opacity(0.45), radius: 10, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Pokédex")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showSearch) {
            SearchView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

// MARK: - Portfolio header

struct PortfolioHeaderView: View {
    let totalValue: Decimal
    let cardCount: Int

    var body: some View {
        VStack(spacing: 6) {
            Text("Portfolio Value")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
            Text(totalValue, format: .currency(code: "USD"))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.pokemonYellow)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("\(cardCount) card\(cardCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Empty state

struct EmptyCollectionView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.15))
            Text("No cards yet")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.55))
            Text("Tap + to search for a card and add it to your collection.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            Button("Search Cards", action: onAdd)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(Color.pokemonYellow)
                .clipShape(Capsule())
        }
    }
}
