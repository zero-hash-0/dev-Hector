// ── Section command header ─────────────────────────────────────────────────────
function CmdHeader({ cmd }: { cmd: string }) {
  return (
    <div className="flex items-center gap-2 mb-4 font-mono text-xs">
      <span style={{ color: "#2d5a30" }}>root@hector</span>
      <span style={{ color: "#1a4a1d" }}>:~$</span>
      <span style={{ color: "#4a8a50" }}>{cmd}</span>
    </div>
  );
}

const IDENTITY = [
  ["name",     '"Hector Ruiz"',  false],
  ["role",     '"Developer"',    false],
  ["focus",    '"Cybersecurity"',false],
  ["location", '"Florida, USA"', false],
  ["degree",   '"BAS · SPC"',    false],
  ["status",   '"Available"',    true ],
] as const;

const TAGS = [
  "security-first", "native-ios", "privacy-focused",
  "full-stack", "product-builder", "open-to-collab",
];

export default function About() {
  return (
    <section id="about" className="pt-3 pb-4 px-6 max-w-5xl mx-auto">
      <CmdHeader cmd="cat about.md" />

      <div
        className="rounded border overflow-hidden card-glow-project font-mono"
        style={{ borderColor: "rgba(0,255,65,0.12)", background: "rgba(2,11,2,0.7)" }}
      >
        {/* File metadata bar */}
        <div
          className="flex flex-wrap items-center justify-between gap-3 px-5 py-3 border-b text-[10px]"
          style={{ borderColor: "rgba(0,255,65,0.08)", background: "rgba(0,255,65,0.03)" }}
        >
          <div className="flex items-center gap-3" style={{ color: "#2d5a30" }}>
            <span>-rw-r--r--</span>
            <span style={{ color: "#1a4a1d" }}>1  hector  staff  2.3K</span>
            <span style={{ color: "#00ff41" }}>about.md</span>
          </div>
          <div className="flex items-center gap-2" style={{ color: "#1a4a1d" }}>
            <span>UTF-8</span>
            <span>·</span>
            <span>markdown</span>
          </div>
        </div>

        {/* Body */}
        <div className="p-6 sm:p-8 grid md:grid-cols-[260px,1fr] gap-8">

          {/* Left: identity.json */}
          <div className="space-y-4">
            <div
              className="border rounded p-4 text-xs space-y-1.5"
              style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(0,0,0,0.35)" }}
            >
              <div className="mb-3" style={{ color: "#00ff41" }}>{"// identity.json"}</div>
              <div style={{ color: "#2d5a30" }}>{"{"}</div>
              {IDENTITY.map(([key, val, accent]) => (
                <div key={key} className="flex gap-2 pl-3">
                  <span style={{ color: "#2d5a30" }}>&quot;{key}&quot;:</span>
                  <span style={{ color: accent ? "#00ff41" : "#4a8a50", textShadow: accent ? "0 0 8px rgba(0,255,65,0.4)" : "none" }}>
                    {val},
                  </span>
                </div>
              ))}
              <div style={{ color: "#2d5a30" }}>{"}"}</div>
            </div>

            {/* Online status */}
            <div
              className="flex items-center gap-2 text-xs px-3 py-2 rounded border"
              style={{
                borderColor: "rgba(0,255,65,0.2)",
                color: "#00ff41",
                background: "rgba(0,255,65,0.05)",
              }}
            >
              <span className="w-1.5 h-1.5 rounded-full status-pulse" style={{ background: "#00ff41" }} />
              ONLINE · ACCEPTING WORK
            </div>

            {/* Tags */}
            <div className="flex flex-wrap gap-1.5">
              {TAGS.map((tag) => (
                <span
                  key={tag}
                  className="text-[10px] px-2 py-1 rounded border"
                  style={{ borderColor: "rgba(0,255,65,0.1)", color: "#2d5a30" }}
                >
                  #{tag}
                </span>
              ))}
            </div>
          </div>

          {/* Right: bio */}
          <div className="space-y-5 text-sm leading-7" style={{ color: "#4a8a50" }}>
            <p>
              <span style={{ color: "#2d5a30" }}>{"// "}</span>
              Hey, I&apos;m{" "}
              <span className="phosphor-dim" style={{ color: "#00ff41" }}>Hector Ruiz</span>.
              {" "}I studied at St. Petersburg College, where I earned a BAS with a focus
              on Cybersecurity and Systems Architecture.
            </p>
            <p>
              <span style={{ color: "#2d5a30" }}>{"// "}</span>
              Cybersecurity isn&apos;t just a career path for me — it&apos;s a conviction.
              I got into this field because I genuinely care about privacy and believe people
              deserve to move through the digital world without being exposed, exploited,
              or watched.
            </p>
            <p>
              <span style={{ color: "#2d5a30" }}>{"// "}</span>
              That principle drives every system I design and every product I build.
              Good design and strong security can coexist, and I build things that
              prove they can.
            </p>

            {/* divider */}
            <div
              className="flex items-center gap-3 text-xs pt-2"
              style={{ color: "#1a4a1d" }}
            >
              <span>──────────────────────────────</span>
              <span style={{ color: "#2d5a30" }}>EOF</span>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
