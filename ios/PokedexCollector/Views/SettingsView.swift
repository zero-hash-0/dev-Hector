import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [CollectionEntry]
    @Query private var caches: [CardCache]

    @AppStorage("pokemonTCGApiKey") private var apiKey = ""
    @AppStorage("iCloudSyncEnabled") private var iCloudSync = true

    @State private var showExportShare = false
    @State private var csvURL: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                Form {
                    Section {
                        SecureField("Paste your API key here", text: $apiKey)
                            .foregroundStyle(.white)
                    } header: {
                        Text("pokemontcg.io API Key")
                    } footer: {
                        Text("Optional. Increases rate limits beyond the free tier. Get a free key at pokemontcg.io.")
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Section {
                        Toggle("iCloud Sync", isOn: $iCloudSync)
                            .tint(Color.pokemonYellow)
                    } header: {
                        Text("Sync")
                    } footer: {
                        Text("Full iCloud sync will be verified in M4.")
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    Section {
                        Button("Export as CSV") { exportCSV() }
                            .foregroundStyle(Color.pokemonYellow)
                    } header: {
                        Text("Data")
                    }

                    Section {
                        InfoRow(label: "Version", value: "1.0 (M1)")
                        InfoRow(label: "Cards tracked", value: "\(entries.count)")
                        InfoRow(label: "Non-English cards", value: "Not supported (v2)")
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.pokemonYellow)
                }
            }
            .sheet(isPresented: $showExportShare) {
                if let url = csvURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportCSV() {
        let cacheMap = Dictionary(uniqueKeysWithValues: caches.map { ($0.id, $0) })
        var rows = ["Card,Set,Number,Rarity,Quantity,Condition,Foil,Market Price,Purchase Price,Added At"]
        for entry in entries {
            let cache = cacheMap[entry.cardId]
            let price = cache?.currentMarketPriceUSD.map { "\($0)" } ?? ""
            let paid = entry.purchasePrice.map { "\($0)" } ?? ""
            let row = [
                cache?.name ?? entry.cardId,
                cache?.setName ?? "",
                cache?.number ?? "",
                cache?.rarity ?? "",
                "\(entry.quantity)",
                entry.conditionEnum.rawValue,
                entry.isFoil ? "Yes" : "No",
                price,
                paid,
                ISO8601DateFormatter().string(from: entry.addedAt),
            ].map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
                .joined(separator: ",")
            rows.append(row)
        }
        let csv = rows.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pokedex_collection.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        csvURL = url
        showExportShare = true
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.white)
            Spacer()
            Text(value).foregroundStyle(.white.opacity(0.4))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
