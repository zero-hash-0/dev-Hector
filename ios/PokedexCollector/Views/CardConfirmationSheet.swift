import SwiftUI

struct CardConfirmationSheet: View {
    let card: TCGCard
    let onAdd: (Int, Condition, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var quantity = 1
    @State private var condition: Condition = .nearMint
    @State private var isFoil = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Card art
                        AsyncImage(url: URL(string: card.images.large)) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06))
                                .aspectRatio(0.716, contentMode: .fit)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .frame(maxWidth: 260)
                        .shadow(color: .black.opacity(0.7), radius: 20, y: 10)

                        // Card identity
                        VStack(spacing: 5) {
                            Text(card.name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("\(card.set.name) · #\(card.number)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                            if let price = card.marketPrice {
                                Text(price, format: .currency(code: "USD"))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color.pokemonYellow)
                                    .padding(.top, 2)
                            }
                        }

                        // Options
                        VStack(spacing: 0) {
                            HStack {
                                Text("Quantity")
                                    .foregroundStyle(.white)
                                Spacer()
                                Stepper("\(quantity)", value: $quantity, in: 1...99)
                                    .foregroundStyle(.white)
                                    .tint(Color.pokemonYellow)
                            }
                            .padding()

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                Text("Condition")
                                    .foregroundStyle(.white)
                                Spacer()
                                Picker("Condition", selection: $condition) {
                                    ForEach(Condition.allCases, id: \.self) { c in
                                        Text(c.rawValue).tag(c)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.pokemonYellow)
                            }
                            .padding()

                            Divider().background(Color.white.opacity(0.1))

                            Toggle("Foil / Holo", isOn: $isFoil)
                                .foregroundStyle(.white)
                                .tint(Color.pokemonYellow)
                                .padding()
                        }
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)

                        // Add button
                        Button {
                            onAdd(quantity, condition, isFoil)
                        } label: {
                            Text("Add to Collection")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(Color.pokemonYellow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
