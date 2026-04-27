import Link from 'next/link'

const searchItems = [
  { set: 'ASCENDED HEROES', name: 'Mega Charizard Y ex', rarity: 'Mega Hyper Rare', number: '#294' },
  { set: 'ASCENDED HEROES', name: 'Mega Charizard Y ex', rarity: 'Double Rare', number: '#22' },
  { set: 'PHANTASMAL FLAMES', name: 'Mega Charizard X ex', rarity: 'Special Illustration Rare', number: '#125' },
]

const sets = [
  { code: 'POR', name: 'Perfect Order', date: 'Mar 2026', cards: 124 },
  { code: 'ASC', name: 'Ascended Heroes', date: 'Jan 2026', cards: 295 },
  { code: 'PFL', name: 'Phantasmal Flames', date: 'Nov 2025', cards: 130 },
  { code: 'MEG', name: 'Mega Evolution', date: 'Sep 2025', cards: 188 },
]

export default function DexLedgerPage() {
  return (
    <main className="min-h-screen bg-[#02060F] text-[#EAF2FF]">
      <section className="max-w-6xl mx-auto px-6 pt-16 pb-10">
        <p className="text-xs tracking-[0.25em] uppercase text-[#7EA7DA] mb-3">DexLedger</p>
        <h1 className="text-4xl sm:text-5xl font-semibold mb-4">The portfolio tracker for Pokémon TCG collectors.</h1>
        <p className="text-[#9AB4D4] max-w-2xl mb-7">
          Search cards, browse sets, and track collection value in one clean mobile-first experience.
          Built for fast check-ins during trades, store runs, and live openings.
        </p>
        <div className="flex flex-wrap gap-3">
          <Link href="/jellycat" className="px-5 py-2.5 rounded-xl bg-[#F7D80A] text-[#061327] font-semibold">Open app demo</Link>
          <a href="#screens" className="px-5 py-2.5 rounded-xl border border-[#2A4770] text-[#B8CBE3]">View screens</a>
        </div>
      </section>

      <section id="screens" className="max-w-6xl mx-auto px-6 pb-16 grid lg:grid-cols-3 gap-6">
        <article className="rounded-3xl border border-[#173458] bg-gradient-to-b from-[#071831] to-[#040B18] p-5 lg:col-span-2">
          <h2 className="text-2xl font-semibold mb-4">Search</h2>
          <div className="rounded-2xl bg-white/10 text-[#8EA8C8] px-4 py-3 mb-4">Cards, booster boxes, ETBs...</div>
          <div className="space-y-3">
            {searchItems.map((item) => (
              <div key={`${item.name}-${item.number}`} className="rounded-2xl border border-[#1F3C64] bg-[#081A34] p-4 flex items-center justify-between gap-4">
                <div>
                  <p className="text-[#4C8DFF] text-xs font-semibold tracking-wide">{item.set}</p>
                  <p className="text-lg font-semibold">{item.name}</p>
                  <p className="text-[#84A3C7]">{item.rarity} · {item.number}</p>
                </div>
                <button className="w-11 h-11 rounded-full bg-[#F7D80A] text-[#082041] text-3xl leading-none">+</button>
              </div>
            ))}
          </div>
        </article>

        <article className="rounded-3xl border border-[#173458] bg-gradient-to-b from-[#071831] to-[#040B18] p-5">
          <h2 className="text-2xl font-semibold mb-4">Collection</h2>
          <div className="rounded-2xl border border-[#1F3C64] bg-[#081A34] p-4 mb-4">
            <p className="text-xs uppercase tracking-[0.2em] text-[#7DA3CE]">Portfolio</p>
            <p className="text-5xl font-bold my-2">$638.33</p>
            <p className="text-[#11E68E] font-semibold">↗ +621.29 (+3646.07%)</p>
          </div>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div className="rounded-xl bg-[#0C2342] p-3"><p className="text-2xl font-bold text-[#4C8DFF]">8</p><p className="text-xs text-[#8CA8C8]">Unique</p></div>
            <div className="rounded-xl bg-[#2B1027] p-3"><p className="text-2xl font-bold text-[#FF315D]">1</p><p className="text-xs text-[#8CA8C8]">Cards</p></div>
            <div className="rounded-xl bg-[#2A2C10] p-3"><p className="text-2xl font-bold text-[#F7D80A]">7</p><p className="text-xs text-[#8CA8C8]">Sealed</p></div>
          </div>
        </article>

        <article className="rounded-3xl border border-[#173458] bg-gradient-to-b from-[#071831] to-[#040B18] p-5 lg:col-span-3">
          <h2 className="text-2xl font-semibold mb-4">Sets</h2>
          <div className="grid md:grid-cols-2 gap-3">
            {sets.map((set) => (
              <div key={set.code} className="rounded-2xl border border-[#1F3C64] bg-[#081A34] p-4 flex items-center justify-between">
                <div>
                  <p className="text-sm text-[#8CA8C8]">{set.code}</p>
                  <p className="text-xl font-semibold">{set.name}</p>
                  <p className="text-[#8CA8C8]">{set.date} · {set.cards} cards</p>
                </div>
                <span className="text-2xl text-[#7DA3CE]">›</span>
              </div>
            ))}
          </div>
        </article>
      </section>
    </main>
  )
}
