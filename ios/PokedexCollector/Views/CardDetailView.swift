import SwiftUI
import SwiftData

struct CardDetailView: View {
    let entry: CollectionEntry
    let cache: CardCache

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Large card art
                    AsyncImage(url: URL(string: cache.imageLargeURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .aspectRatio(0.716, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .frame(maxWidth: 300)
                    .shadow(color: .black.opacity(0.7), radius: 20, y: 10)
                    .padding(.top, 8)

                    // Identity
                    VStack(spacing: 5) {
                        Text(cache.name)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("\(cache.setName) · #\(cache.number)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                        if let rarity = cache.rarity {
                            Text(rarity)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }

                    // Market price
                    if let price = cache.currentMarketPriceUSD {
                        VStack(spacing: 4) {
                            Text("Market Price")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                            Text(price, format: .currency(code: "USD"))
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.pokemonYellow)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                    }

                    // Editable collection fields
                    VStack(spacing: 0) {
                        DetailRow(label: "Quantity") {
                            Stepper(
                                "\(entry.quantity)",
                                value: Binding(get: { entry.quantity }, set: { entry.quantity = $0 }),
                                in: 1...99
                            )
                            .tint(Color.pokemonYellow)
                        }

                        Divider().background(Color.white.opacity(0.1))

                        DetailRow(label: "Condition") {
                            Picker(
                                "Condition",
                                selection: Binding(get: { entry.conditionEnum }, set: { entry.conditionEnum = $0 })
                            ) {
                                ForEach(Condition.allCases, id: \.self) { c in
                                    Text(c.rawValue).tag(c)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color.pokemonYellow)
                        }

                        Divider().background(Color.white.opacity(0.1))

                        DetailRow(label: "Foil") {
                            Toggle("", isOn: Binding(get: { entry.isFoil }, set: { entry.isFoil = $0 }))
                                .tint(Color.pokemonYellow)
                                .labelsHidden()
                        }

                        if let paid = entry.purchasePrice {
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(label: "Paid") {
                                Text(paid, format: .currency(code: "USD"))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }

                        if let added = formatDate(entry.addedAt) {
                            Divider().background(Color.white.opacity(0.1))
                            DetailRow(label: "Added") {
                                Text(added)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .font(.subheadline)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    // TCGplayer link
                    if let urlString = cache.tcgplayerURL, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Text("View on TCGplayer")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .foregroundStyle(Color.pokemonYellow)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                    }

                    // Remove from collection
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Remove from Collection")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Remove \(cache.name) from collection?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Reusable row layout

struct DetailRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            content()
        }
        .padding()
    }
}
