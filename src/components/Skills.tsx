const SKILLS: Record<string, string[]> = {
  "iOS / Apple":  ["Swift", "SwiftUI", "WidgetKit", "Live Activities", "ActivityKit"],
  "Frontend":     ["React", "Next.js", "TypeScript", "Tailwind CSS", "Framer Motion"],
  "Backend":      ["Node.js", "PostgreSQL", "REST APIs", "Supabase"],
  "Security":     ["Systems Architecture", "Threat Modeling", "Security-first Design", "Pen Testing"],
  "Design":       ["Figma", "Design Systems", "Interaction Design", "Brand Strategy"],
  "Product":      ["Product Strategy", "Creative Direction", "UX Research", "Roadmapping"],
};

const SYSINFO = [
  { key: "OS",       val: "Darwin 23.4.0  macOS Sonoma" },
  { key: "Host",     val: "hector-dev-machine" },
  { key: "Shell",    val: "zsh 5.9" },
  { key: "Editor",   val: "Xcode · Cursor" },
  { key: "Languages",val: "Swift  TypeScript  JS" },
  { key: "Focus",    val: "Security-first Systems" },
  { key: "Uptime",   val: "7+ years coding" },
];

const PALETTE = [
  "#141414","#1C1C1C","#282828","#383838",
  "#4A4A4A","#7A7A7A","#DA7756","#C4614A",
];

const MINI_ASCII = [
  "  ██╗  ██╗",
  "  ██║  ██║",
  "  ███████║",
  "  ██╔══██║",
  "  ██║  ██║",
  "  ╚═╝  ╚═╝",
];

export default function Skills() {
  return (
    <section id="skills" className="pt-3 pb-4 px-6 max-w-5xl mx-auto font-mono">

      {/* Section command */}
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: "#7A7A7A" }}>root@hector:~$</span>
        <span style={{ color: "#D4D4D4" }}>neofetch --skills</span>
      </div>

      <div
        className="border rounded overflow-hidden terminal-window"
        style={{ borderColor: "rgba(218,119,86,0.14)", background: "rgba(20,20,20,0.75)" }}
      >
        {/* Terminal title bar */}
        <div
          className="flex items-center gap-2 px-4 py-2.5 border-b text-xs"
          style={{ borderColor: "rgba(218,119,86,0.09)", background: "rgba(218,119,86,0.03)" }}
        >
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff3b30", boxShadow: "0 0 4px #ff3b30" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffcc02", boxShadow: "0 0 4px #ffcc02" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#DA7756", boxShadow: "0 0 5px rgba(218,119,86,0.7)" }} />
          <span className="mx-auto" style={{ color: "#4A4A4A" }}>hector@dev — neofetch</span>
        </div>

        <div className="p-6 sm:p-8 grid md:grid-cols-[220px,1fr] gap-8 items-start">

          {/* Left: sysinfo */}
          <div className="space-y-4">
            <pre
              className="text-[9px] leading-tight phosphor"
              style={{ color: "#DA7756" }}
            >
              {MINI_ASCII.join("\n")}
            </pre>

            <div className="space-y-1 text-xs">
              <div className="phosphor-dim" style={{ color: "#DA7756" }}>hector@dev</div>
              <div style={{ color: "#4A4A4A" }}>──────────</div>
              {SYSINFO.map(({ key, val }) => (
                <div key={key} className="flex gap-2">
                  <span className="w-[88px] shrink-0 phosphor-dim" style={{ color: "#DA7756" }}>{key}:</span>
                  <span style={{ color: "#D4D4D4" }}>{val}</span>
                </div>
              ))}
            </div>

            {/* Color palette */}
            <div className="flex flex-wrap gap-1.5 pt-2">
              {PALETTE.map((c) => (
                <div
                  key={c}
                  className="w-5 h-5 rounded-sm"
                  style={{
                    background: c,
                    boxShadow: c === "#DA7756" ? "0 0 6px rgba(218,119,86,0.7)" : "none",
                    border: "1px solid rgba(255,255,255,0.06)"
                  }}
                  title={c}
                />
              ))}
            </div>
          </div>

          {/* Right: skills grid */}
          <div className="grid sm:grid-cols-2 gap-3">
            {Object.entries(SKILLS).map(([cat, items]) => (
              <div
                key={cat}
                className="border rounded p-3.5 space-y-2 card-glow"
                style={{ borderColor: "rgba(218,119,86,0.1)", background: "rgba(0,0,0,0.2)" }}
              >
                <div
                  className="text-[10px] tracking-widest uppercase phosphor-dim"
                  style={{ color: "#DA7756" }}
                >
                  {cat}/
                </div>
                <div className="space-y-1">
                  {items.map((item) => (
                    <div key={item} className="flex items-center gap-2 text-xs" style={{ color: "#D4D4D4" }}>
                      <span style={{ color: "#4A4A4A" }}>▸</span>
                      {item}
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
