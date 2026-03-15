const projects = [
  {
    name: "PulseArt",
    status: "In Progress",
    description:
      "A native iOS sports experience built with SwiftUI and Live Activities. Delivers real-time game updates directly to the lock screen and Dynamic Island using ActivityKit.",
    tech: ["Swift", "SwiftUI", "ActivityKit", "WidgetKit", "Live Activities"],
    type: "iOS App",
  },
  {
    name: "Strata",
    status: "Shipped",
    description:
      "A productivity and project tracking web app designed for teams that need clarity without clutter. Built with a focus on clean UX and reliable data architecture.",
    tech: ["React", "Node.js", "PostgreSQL", "TypeScript"],
    type: "Web App",
  },
  {
    name: "Cipher",
    status: "Prototype",
    description:
      "A security monitoring dashboard that surfaces threat signals in a clean, actionable interface. Designed around the principle that security tooling should be as well-crafted as consumer software.",
    tech: ["React", "TypeScript", "Tailwind CSS"],
    type: "Dashboard",
  },
];

const statusColors: Record<string, string> = {
  "In Progress": "text-yellow-400 border-yellow-400/30 bg-yellow-400/5",
  Shipped: "text-accent border-accent/30 bg-accent/5",
  Prototype: "text-zinc-400 border-zinc-600/30 bg-zinc-600/5",
};

export default function Projects() {
  return (
    <section id="projects" className="py-20 px-6 max-w-5xl mx-auto">
      <div className="space-y-10">
        <div className="space-y-3">
          <p className="font-mono text-xs text-accent tracking-[0.2em] uppercase">
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
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
