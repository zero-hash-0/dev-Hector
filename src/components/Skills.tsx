const categories = [
  {
    title: "iOS / Apple",
    items: ["Swift", "SwiftUI", "WidgetKit", "Live Activities", "ActivityKit"],
  },
  {
    title: "Frontend",
    items: ["React", "Next.js", "TypeScript", "Tailwind CSS", "Framer Motion"],
  },
  {
    title: "Backend",
    items: ["Node.js", "PostgreSQL", "REST APIs"],
  },
  {
    title: "Security",
    items: ["Systems Architecture", "Threat Modeling", "Security-first Design"],
  },
  {
    title: "Design",
    items: ["Figma", "Design Systems", "Interaction Design", "Brand Strategy"],
  },
  {
    title: "Product",
    items: ["Product Strategy", "Creative Direction", "UX Research"],
  },
];

export default function Skills() {
  return (
    <section id="skills" className="py-24 px-6 max-w-4xl mx-auto">
      <div className="space-y-10">
        <div className="space-y-3">
          <p className="font-mono text-xs tracking-[0.2em] uppercase" style={{ color: "#8a4af3" }}>
            Skills
          </p>
          <h2 className="text-4xl font-semibold tracking-tight">
            Tools of the trade.
          </h2>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {categories.map((cat) => (
            <div
              key={cat.title}
              className="card-glow p-5 rounded-2xl border border-border bg-surface space-y-4"
            >
              <h3 className="font-mono text-xs tracking-widest uppercase" style={{ color: "#8a4af3" }}>
                {cat.title}
              </h3>
              <ul className="space-y-2">
                {cat.items.map((item) => (
                  <li key={item} className="flex items-center gap-2 text-sm text-muted">
                    <span className="w-1 h-1 rounded-full bg-border shrink-0" />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
