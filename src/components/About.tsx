const highlights = [
  { label: "Degree", value: "BAS, St. Petersburg College" },
  { label: "Background", value: "Cybersecurity & Systems Architecture" },
  { label: "Focus", value: "Security-first Design" },
  { label: "Location", value: "Florida, USA" },
];

export default function About() {
  return (
    <section id="about" className="py-20 px-6 max-w-5xl mx-auto">
      <div className="grid md:grid-cols-2 gap-12 items-start">
        <div className="space-y-6">
          <p className="font-mono text-xs text-accent tracking-[0.2em] uppercase">
            About
          </p>
          <h2 className="text-4xl font-semibold tracking-tight">
            Precision meets
            <br />
            design-led thinking.
          </h2>
          <div className="space-y-4 text-muted leading-relaxed">
            <p>
              I&apos;m Hector, a developer and product builder with a background
              in cybersecurity and systems architecture. I care deeply about the
              intersection of security, performance, and design.
            </p>
            <p>
              My approach starts with a security-first foundation and layers
              clean architecture on top. Whether it&apos;s a native iOS experience
              or a full-stack web product, I prioritize systems that are both
              robust and beautiful.
            </p>
            <p>
              I studied at St. Petersburg College where I earned a BAS, and
              I&apos;ve been building products at the intersection of design and
              engineering ever since.
            </p>
          </div>
        </div>

        <div className="space-y-3">
          {highlights.map((item) => (
            <div
              key={item.label}
              className="card-glow flex items-start gap-4 p-4 rounded-xl border border-border bg-surface"
            >
              <span className="font-mono text-xs text-muted w-24 shrink-0 pt-0.5 uppercase tracking-wider">
                {item.label}
              </span>
              <span className="text-sm text-foreground">{item.value}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
