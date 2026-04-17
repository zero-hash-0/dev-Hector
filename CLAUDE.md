# dev-Hector — Claude Code context

## Active projects

### 1. Opus (iOS)
Task/project management app. SwiftUI + SwiftData. Existing, shipping.
- Source: `ios/Opus/`
- Bundle ID: `com.opus.betaapp`
- Has a WidgetKit extension (`ios/OpusWidget/`)

### 2. Pokédex Collector (iOS) — **active build**
Pokémon TCG scanner & portfolio tracker. A Hector.dev personal project.
- Source: `ios/PokedexCollector/`
- Bundle ID: `com.hector.pokedexcollector`
- Branch: `claude/start-building-dNXvC`

#### Spec summary
- **Stack**: SwiftUI + SwiftData (iOS 17+), pokemontcg.io API v2, Supabase (M3+)
- **Accent**: Pokémon yellow `#FFCB05` used sparingly (portfolio value number, FAB only)
- **Theme**: OLED black, dark-first
- **Card ID format**: `{set_id}-{collector_number}` e.g. `swsh1-185`
- **No deck-building, wishlists, marketplace, or social features** (explicit non-goals)

#### Milestone status
| # | Name | Status | What's in it |
|---|------|--------|-------------|
| M1 | Walking skeleton | ✅ Done | SwiftData schema, pokemontcg.io search, collection grid, card detail, settings |
| M2 | Scanning | ⬜ Next | VisionKit `DataScannerViewController`, OCR → collector-number regex → API query → confirmation sheet, disambiguation picker |
| M3 | Charts | ⬜ | Supabase project, nightly price-history cron Edge Function, Swift Charts on card detail, portfolio-over-time chart |
| M4 | Polish | ⬜ | iCloud sync end-to-end, CSV export, haptics, app icon, TestFlight |

#### Key files (M1)
```
ios/PokedexCollector/
  PokedexApp.swift                  — @main, ModelContainer setup
  Models/
    Condition.swift                 — enum: mint/nearMint/lightlyPlayed/played/poor
    CollectionEntry.swift           — @Model: cardId, quantity, condition, isFoil, purchasePrice…
    CardCache.swift                 — @Model: denormalized TCG card snapshot
    PriceHistoryPoint.swift         — @Model: (cardId, date, marketPriceUSD)
  Services/
    PokemonTCGService.swift         — actor, searchCards(name:number:setId:), fetchCard(id:)
  Views/
    CollectionView.swift            — root grid + PortfolioHeaderView + EmptyCollectionView
    CardGridItem.swift              — grid cell with quantity badge
    SearchView.swift                — text search → CardSearchRow list → sheet
    CardConfirmationSheet.swift     — qty/condition/foil picker before adding
    CardDetailView.swift            — large art, market price, editable fields, TCGplayer link
    SettingsView.swift              — API key, iCloud toggle, CSV export (ShareSheet)
  Extensions/
    Color+Hex.swift                 — Color(hex:) + Color.pokemonYellow
ios/project.yml                     — xcodegen config (Opus + OpusWidget + PokedexCollector)
```

#### Scanning strategy (M2 plan)
1. `DataScannerViewController` with `recognizedDataTypes: [.text()]`
2. Filter OCR output for `\d{1,3}/\d{1,3}` (collector number) and card name (largest text near top)
3. Query pokemontcg.io: `q=name:"Charizard" number:185` — or just `number:185` if name OCR is unreliable
4. 1 match → confirmation sheet; 2–5 matches → disambiguation picker with thumbnails; 0 → manual search fallback

#### External services
- **pokemontcg.io API v2** — free tier, `X-Api-Key` header optional (higher rate limit with key)
  - Base URL: `https://api.pokemontcg.io/v2`
- **Supabase** (M3+) — Postgres + Auth + Edge Functions; nightly price-history cron

## iOS project setup
- Uses **xcodegen** (`ios/project.yml`) — run `xcodegen generate` inside `ios/` to regenerate `.xcodeproj`
- Swift 5.9, iOS 17+, Xcode 16
- Dev team: `5HVXGMLSZ6`
