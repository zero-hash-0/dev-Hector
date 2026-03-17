const projects = [
  {
    name: "Opus",
    status: "Beta",
    description:
      "A task manager for iOS built around momentum, not just lists. Features home screen widgets, lock screen glanceable data, recurring tasks, and a streak system that keeps you in flow. 25 founding member spots available.",
    tech: ["Swift", "SwiftUI", "WidgetKit", "Next.js", "TypeScript"],
    type: "iOS App",
    link: "/beta",
    linkLabel: "Join Beta →",
  },
  {
    name: "Strata",
    status: "Shipped",
    description:
      "A productivity and project tracking web app designed for teams that need clarity without clutter. Built with a focus on clean UX and reliable data architecture.",
    tech: ["React", "Node.js", "PostgreSQL", "TypeScript"],
    type: "Web App",
    link: null,
    linkLabel: null,
  },
  {
    name: "Cipher",
    status: "Prototype",
    description:
      "A security monitoring dashboard that surfaces threat signals in a clean, actionable interface. Security tooling should be as well-crafted as consumer software.",
    tech: ["React", "TypeScript", "Tailwind CSS"],
    type: "Dashboard",
    link: null,
    linkLabel: null,
  },
];

const statusColors: Record<string, string> = {
  Beta:        "text-[#8a4af3] border-[#8a4af3]/30 bg-[#8a4af3]/5",
  Shipped:     "text-[#6ee7b7] border-[#6ee7b7]/30 bg-[#6ee7b7]/5",
  Prototype:   "text-zinc-500 border-zinc-600/30 bg-zinc-600/5",
  "In Progress": "text-yellow-400 border-yellow-400/30 bg-yellow-400/5",
};

export default function Projects() {
  return (
    <section id="projects" className="py-24 px-6 max-w-4xl mx-auto">
      <div className="space-y-10">
        <div className="space-y-3">
          <p className="font-mono text-xs tracking-[0.2em] uppercase" style={{ color: "#8a4af3" }}>
            Projects
          </p>
          <h2 className="text-4xl font-semibold tracking-tight">
            Things I&apos;ve built.
          </h2>
        </div>

        <div className="space-y-4">
          {projects.map((project) => (
            <div
              key={project.name}
              className="card-glow-project p-6 md:p-8 rounded-2xl border border-border bg-surface"
            >
              <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-4">
                <div className="flex items-center gap-3">
                  <h3 className="text-xl font-semibold">{project.name}</h3>
                  <span className={`font-mono text-xs px-2.5 py-0.5 rounded-full border ${statusColors[project.status]}`}>
                    {project.status}
                  </span>
                </div>
                <span className="font-mono text-xs text-muted tracking-wider uppercase">
                  {project.type}
                </span>
              </div>

              <p className="text-muted leading-relaxed mb-5 max-w-2xl">
                {project.description}
              </p>

              <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="flex flex-wrap gap-2">
                  {project.tech.map((t) => (
                    <span
                      key={t}
                      className="font-mono text-xs px-3 py-1 rounded-full border border-border text-muted"
                    >
                      {t}
                    </span>
                  ))}
                </div>
                {project.link && (
                  <a
                    href={project.link}
                    className="font-mono text-xs px-4 py-2 rounded-full border border-[#8a4af3]/40 text-[#8a4af3] bg-[#8a4af3]/5 hover:bg-[#8a4af3]/[0.12] hover:border-[#8a4af3]/60 transition-all duration-200 shrink-0"
                  >
                    {project.linkLabel}
                  </a>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
