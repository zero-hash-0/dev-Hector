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
    name:      "Opus",
    dir:       "opus/",
    status:    "BETA",
    statusClr: "#00ff41",
    perms:     "drwxr-xr-x",
    type:      "iOS App",
    size:      "4.2M",
    modified:  "Mar 2024",
    desc:      "Task manager for iOS built around momentum, not just lists. Home screen widgets, lock screen glanceable data, recurring tasks, and a streak system that keeps you in flow. 25 founding member spots available.",
    tech:      ["Swift", "SwiftUI", "WidgetKit", "Next.js", "TypeScript"],
    link:      "/beta",
    linkLabel: "join beta",
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
];

export default function Projects() {
  return (
    <section id="projects" className="pt-6 pb-8 px-6 max-w-5xl mx-auto font-mono">

      {/* Section command */}
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: "#2d5a30" }}>root@hector:~$</span>
        <span style={{ color: "#4a8a50" }}>ls -la ~/projects/</span>
      </div>

      {/* Dir listing header */}
      <div
        className="hidden sm:grid px-5 py-2 mb-1 text-[10px] gap-4 border-b"
        style={{
          gridTemplateColumns: "120px 1fr 80px 50px 80px",
          borderColor: "rgba(0,255,65,0.08)",
          color: "#1a4a1d",
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
        <div key={d} className="px-5 py-1.5 text-[10px] flex gap-4" style={{ color: "#1a4a1d" }}>
          <span className="w-28">drwxr-xr-x</span>
          <span style={{ color: "#2d5a30" }}>{d}</span>
        </div>
      ))}

      {/* Projects */}
      <div className="space-y-4 mt-4">
        {PROJECTS.map((p) => (
          <div
            key={p.name}
            className="border rounded overflow-hidden card-glow-project"
            style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(2,11,2,0.7)" }}
          >
            {/* Directory row */}
            <div
              className="flex flex-wrap items-center gap-x-5 gap-y-1 px-5 py-3 border-b text-[10px]"
              style={{ borderColor: "rgba(0,255,65,0.07)", background: "rgba(0,255,65,0.03)" }}
            >
              <span style={{ color: "#1a4a1d" }}>{p.perms}</span>
              <span className="phosphor-dim" style={{ color: "#00ff41" }}>{p.dir}</span>
              <span style={{ color: "#2d5a30" }}>{p.type}</span>
              <span style={{ color: "#1a4a1d" }}>{p.size}</span>
              <span style={{ color: "#1a4a1d" }}>{p.modified}</span>
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
                style={{ color: "#00ff41" }}
              >
                {p.name}
              </h3>

              <p className="text-xs leading-relaxed mb-4" style={{ color: "#4a8a50", lineHeight: 1.85 }}>
                <span style={{ color: "#1a4a1d" }}>$ cat README.md — </span>
                {p.desc}
              </p>

              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex flex-wrap gap-2">
                  {p.tech.map((t) => (
                    <span
                      key={t}
                      className="text-[10px] px-2.5 py-0.5 rounded border"
                      style={{ borderColor: "rgba(0,255,65,0.1)", color: "#2d5a30" }}
                    >
                      {t}
                    </span>
                  ))}
                </div>
                {p.link && (
                  <a
                    href={p.link}
                    className="text-xs px-4 py-1.5 rounded border transition-all duration-200"
                    style={{ borderColor: "rgba(0,255,65,0.4)", color: "#00ff41" }}
                    onMouseEnter={(e) => {
                      const el = e.currentTarget as HTMLElement;
                      el.style.background = "#00ff41";
                      el.style.color      = "#020b02";
                    }}
                    onMouseLeave={(e) => {
                      const el = e.currentTarget as HTMLElement;
                      el.style.background = "transparent";
                      el.style.color      = "#00ff41";
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
      <div className="mt-5 flex items-center gap-2 text-xs" style={{ color: "#1a4a1d" }}>
        <span>3 directories listed</span>
        <span>·</span>
        <span style={{ color: "#2d5a30" }}>root@hector:~/projects$</span>
        <span className="cursor-blink" style={{ color: "#00ff41" }}>_</span>
      </div>
    </section>
  );
}
