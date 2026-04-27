export default function NowShipping() {
  return (
    <section id="now" className="pt-4 pb-3 px-6 max-w-5xl mx-auto font-mono">
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: '#7A7A7A' }}>root@hector:~$</span>
        <span style={{ color: '#D4D4D4' }}>cat ~/pokemon-now.txt</span>
      </div>

      <div
        className="rounded border px-5 py-5 sm:px-6"
        style={{ borderColor: 'rgba(218,119,86,0.14)', background: 'rgba(20,20,20,0.7)' }}
      >
        <p className="text-[10px] tracking-[0.2em] uppercase mb-2" style={{ color: '#4A4A4A' }}>
          Pokémon Build Status
        </p>
        <h2 className="text-lg sm:text-xl font-bold mb-2" style={{ color: '#DA7756' }}>
          Pokédex app + trainer site in active development.
        </h2>
        <p className="text-xs leading-relaxed mb-4" style={{ color: '#D4D4D4', lineHeight: 1.8 }}>
          Current sprint: faster collection entry, Pokédex-based autofill, and cleaner trainer portfolio storytelling.
        </p>

        <div className="flex flex-wrap items-center gap-3 mb-4">
          <span className="text-[10px] px-2.5 py-1 rounded border" style={{ borderColor: 'rgba(218,119,86,0.2)', color: '#7A7A7A' }}>
            focus: collection workflow
          </span>
          <span className="text-[10px] px-2.5 py-1 rounded border" style={{ borderColor: 'rgba(218,119,86,0.2)', color: '#7A7A7A' }}>
            next: shareable trainer pages
          </span>
        </div>

        <div className="flex flex-wrap gap-3">
          <a
            href="/jellycat"
            className="text-xs px-4 py-1.5 rounded border transition-all duration-200"
            style={{ borderColor: 'rgba(218,119,86,0.45)', color: '#DA7756' }}
          >
            ./open-collection-app →
          </a>
        </div>
      </div>
    </section>
  )
}
