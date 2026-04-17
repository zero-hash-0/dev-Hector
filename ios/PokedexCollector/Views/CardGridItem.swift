import SwiftUI

struct CardGridItem: View {
    let cache: CardCache
    let entry: CollectionEntry

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                AsyncImage(url: URL(string: cache.imageSmallURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                        .aspectRatio(0.716, contentMode: .fit)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(spacing: 2) {
                    Text(cache.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let price = cache.currentMarketPriceUSD {
                        Text(price, format: .currency(code: "USD"))
                            .font(.caption2)
                            .foregroundStyle(.pokemonYellow)
                    }
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if entry.quantity > 1 {
                Text("×\(entry.quantity)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.pokemonYellow)
                    .clipShape(Capsule())
                    .offset(x: -6, y: 6)
            }
        }
    }
}
