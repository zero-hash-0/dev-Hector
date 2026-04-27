"use client";

type Project = {
  name:       string;
  dir:        string;
  status:     string;
  statusClr:  string;
  perms:      string;
  type:       string;
  size:       string;
  modified:   string;
  desc:       string;
  tech:       string[];
  link:       string | null;
  linkLabel:  string | null;
};

const PROJECTS: Project[] = [
  {
    name:      "Pokédex Vault",
    dir:       "pokemon-vault/",
    status:    "BETA",
    statusClr: "#DA7756",
    perms:     "drwxr-xr-x",
    type:      "Web + Mobile",
    size:      "6.1M",
    modified:  "Mar 2024",
    desc:      "Pokémon collection manager with Pokédex lookup, favorites, notes, and shareable trainer collections. Built for quick capture logging and clean visual browsing.",
    tech:      ["Next.js", "TypeScript", "Framer Motion", "PokeAPI", "LocalStorage"],
    link:      "/jellycat",
    linkLabel: "open app",
  },
  {
    name:      "Strata",
    dir:       "strata/",
    status:    "SHIPPED",
    statusClr: "#00d4ff",
    perms:     "drwxr-xr-x",
    type:      "Web App",
    size:      "12.8M",
    modified:  "Nov 2023",
    desc:      "Productivity and project tracking web app designed for teams that need clarity without clutter. Built with a focus on clean UX and reliable data architecture.",
    tech:      ["React", "Node.js", "PostgreSQL", "TypeScript"],
    link:      null,
    linkLabel: null,
  },
  {
    name:      "Cipher",
    dir:       "cipher/",
    status:    "PROTOTYPE",
    statusClr: "#ffaa00",
    perms:     "drwxr-xr-x",
    type:      "Dashboard",
    size:      "3.1M",
    modified:  "Aug 2023",
    desc:      "Security monitoring dashboard that surfaces threat signals in a clean, actionable interface. Security tooling should be as well-crafted as consumer software.",
    tech:      ["React", "TypeScript", "Tailwind CSS"],
    link:      null,
    linkLabel: null,
  },
  {
    name:      "Project Brain",
    dir:       "project-brain/",
    status:    "SHIPPED",
    statusClr: "#00d4ff",
    perms:     "drwxr-xr-x",
    type:      "Developer Tool",
    size:      "8.6M",
    modified:  "Mar 2026",
    desc:      "Local-first developer tool that builds persistent repo understanding for AI coding agents. Analyzes your codebase into structured context — architecture, decisions, file intelligence — then generates tailored context packs for Claude Code and Codex so they hit the ground running.",
    tech:      ["React", "TypeScript", "Tailwind CSS", "Vite", "Zustand"],
    link:      "https://github.com/zero-hash-0/project-brain",
    linkLabel: "view on github",
  },
];

export default function Projects() {
  return (
    <section id="projects" className="pt-3 pb-4 px-6 max-w-5xl mx-auto font-mono">

      {/* Section command */}
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: "#7A7A7A" }}>root@hector:~$</span>
        <span style={{ color: "#D4D4D4" }}>ls -la ~/projects/</span>
      </div>

      {/* Dir listing header */}
      <div
        className="hidden sm:grid px-5 py-2 mb-1 text-[10px] gap-4 border-b"
        style={{
          gridTemplateColumns: "120px 1fr 80px 50px 80px",
          borderColor: "rgba(218,119,86,0.08)",
          color: "#4A4A4A",
        }}
      >
        <span>permissions</span>
        <span>name</span>
        <span>type</span>
        <span>size</span>
        <span>modified</span>
      </div>

      {/* Phantom dir entries */}
      {["./", "../"].map((d) => (
        <div key={d} className="px-5 py-1.5 text-[10px] flex gap-4" style={{ color: "#4A4A4A" }}>
          <span className="w-28">drwxr-xr-x</span>
          <span style={{ color: "#7A7A7A" }}>{d}</span>
        </div>
      ))}

      {/* Projects */}
      <div className="space-y-4 mt-4">
        {PROJECTS.map((p) => (
          <div
            key={p.name}
            className="border rounded overflow-hidden card-glow-project"
            style={{ borderColor: "rgba(218,119,86,0.1)", background: "rgba(20,20,20,0.7)" }}
          >
            {/* Directory row */}
            <div
              className="flex flex-wrap items-center gap-x-5 gap-y-1 px-5 py-3 border-b text-[10px]"
              style={{ borderColor: "rgba(218,119,86,0.07)", background: "rgba(218,119,86,0.03)" }}
            >
              <span style={{ color: "#4A4A4A" }}>{p.perms}</span>
              <span className="phosphor-dim" style={{ color: "#DA7756" }}>{p.dir}</span>
              <span style={{ color: "#7A7A7A" }}>{p.type}</span>
              <span style={{ color: "#4A4A4A" }}>{p.size}</span>
              <span style={{ color: "#4A4A4A" }}>{p.modified}</span>
              <span
                className="ml-auto px-2 py-0.5 rounded border text-[9px] font-bold tracking-wider"
                style={{
                  color:       p.statusClr,
                  borderColor: `${p.statusClr}35`,
                  background:  `${p.statusClr}0a`,
                  textShadow:  `0 0 6px ${p.statusClr}60`,
                }}
              >
                {p.status}
              </span>
            </div>

            {/* Content */}
            <div className="px-5 py-4 sm:py-5">
              <h3
                className="text-base font-bold mb-1 phosphor-dim"
                style={{ color: "#DA7756" }}
              >
                {p.name}
              </h3>

              <p className="text-xs leading-relaxed mb-4" style={{ color: "#D4D4D4", lineHeight: 1.85 }}>
                <span style={{ color: "#7A7A7A" }}>$ cat README.md — </span>
                {p.desc}
              </p>

              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex flex-wrap gap-2">
                  {p.tech.map((t) => (
                    <span
                      key={t}
                      className="text-[10px] px-2.5 py-0.5 rounded border"
                      style={{ borderColor: "rgba(218,119,86,0.12)", color: "#7A7A7A" }}
                    >
                      {t}
                    </span>
                  ))}
                </div>
                {p.link && (
                  <a
                    href={p.link}
                    className="text-xs px-4 py-1.5 rounded border transition-all duration-200"
                    style={{ borderColor: "rgba(218,119,86,0.4)", color: "#DA7756" }}
                    onMouseEnter={(e) => {
                      const el = e.currentTarget as HTMLElement;
                      el.style.background = "#DA7756";
                      el.style.color      = "#141414";
                    }}
                    onMouseLeave={(e) => {
                      const el = e.currentTarget as HTMLElement;
                      el.style.background = "transparent";
                      el.style.color      = "#DA7756";
                    }}
                  >
                    ./{p.linkLabel} →
                  </a>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Result line */}
      <div className="mt-5 flex items-center gap-2 text-xs" style={{ color: "#4A4A4A" }}>
        <span>4 directories listed</span>
        <span>·</span>
        <span style={{ color: "#7A7A7A" }}>root@hector:~/projects$</span>
        <span className="cursor-blink" style={{ color: "#DA7756" }}>_</span>
      </div>
    </section>
  );
}
