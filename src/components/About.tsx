export default function About() {
  return (
    <section id="about" className="py-24 px-6 max-w-4xl mx-auto">
      <div className="space-y-8 max-w-2xl">
        <p className="font-mono text-xs tracking-[0.2em] uppercase" style={{ color: "#8a4af3" }}>
          About
        </p>
        <h2 className="text-4xl md:text-5xl font-semibold tracking-tight leading-[1.08]">
          Precision meets<br />design-led thinking.
        </h2>
        <div className="space-y-5 leading-[1.75] text-muted text-[1.05rem]">
          <p>
            I care about the intersection of security, performance, and design — the
            belief that robust systems and beautiful products aren&apos;t at odds.
            They reinforce each other.
          </p>
          <p>
            My work starts from a security-first foundation, then layers clean
            architecture and purposeful UX on top. Whether that&apos;s a native iOS
            experience, a real-time web platform, or a system-level tool — the
            standard is the same.
          </p>
          <p>
            I build things that are fast, honest, and built to last.
          </p>
        </div>
      </div>
    </section>
  );
}
