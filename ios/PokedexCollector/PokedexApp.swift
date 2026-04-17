import SwiftUI
import SwiftData

@main
struct PokedexApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: CollectionEntry.self, CardCache.self, PriceHistoryPoint.self
            )
        } catch {
            fatalError("Failed to initialise SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            CollectionView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
