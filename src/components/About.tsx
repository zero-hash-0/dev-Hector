import Image from "next/image";

export default function About() {
  return (
    <section id="about" className="py-24 px-6 max-w-4xl mx-auto">
      <div className="grid md:grid-cols-2 gap-14 items-center">

        {/* ── Left: photo ── */}
        <div className="flex flex-col items-center gap-5">
          {/* glow + ring */}
          <div className="relative">
            {/* ambient glow behind */}
            <div
              className="absolute inset-0 rounded-full"
              style={{
                background: "radial-gradient(circle, rgba(138,74,243,0.4) 0%, transparent 68%)",
                filter: "blur(24px)",
                transform: "scale(1.3)",
              }}
            />
            {/* gradient ring */}
            <div
              className="relative rounded-full p-[3px]"
              style={{
                background: "linear-gradient(135deg, #8a4af3 0%, #6e6bf5 50%, rgba(138,74,243,0.4) 100%)",
              }}
            >
              <div className="rounded-full overflow-hidden w-56 h-56 md:w-64 md:h-64 bg-surface">
                <Image
                  src="/hector.jpg"
                  alt="Hector Ruiz"
                  width={256}
                  height={256}
                  className="w-full h-full object-cover"
                  priority
                />
              </div>
            </div>
          </div>

          {/* name badge */}
          <div
            className="flex items-center gap-2 px-4 py-2 rounded-full border font-mono text-xs font-bold tracking-[0.14em] uppercase"
            style={{
              borderColor: "rgba(138,74,243,0.35)",
              background: "rgba(138,74,243,0.08)",
              color: "#b48af7",
            }}
          >
            <span
              className="w-1.5 h-1.5 rounded-full"
              style={{ background: "#8a4af3", boxShadow: "0 0 6px #8a4af3" }}
            />
            Hector Ruiz
          </div>
        </div>

        {/* ── Right: bio ── */}
        <div className="space-y-6">
          {/* label */}
          <span
            className="inline-block font-mono text-[11px] font-bold tracking-[0.18em] uppercase px-3 py-1.5 rounded-full border"
            style={{
              color: "#8a4af3",
              borderColor: "rgba(138,74,243,0.3)",
              background: "rgba(138,74,243,0.07)",
            }}
          >
            About the Developer
          </span>

          <h2 className="text-4xl md:text-5xl font-semibold tracking-tight leading-[1.06]">
            Meet the<br />developer.
          </h2>

          <div className="space-y-4 text-muted leading-[1.8] text-[1rem]">
            <p>
              Hey, I&apos;m <span className="text-foreground font-medium">Hector Ruiz</span>.
              I studied at St. Petersburg College, where I earned a BAS with a focus
              on Cybersecurity and Systems Architecture.
            </p>
            <p>
              Cybersecurity isn&apos;t just a career path for me, it&apos;s a conviction.
              I got into this field because I genuinely care about privacy and
              believe people deserve to move through the digital world without
              being exposed, exploited, or watched. That principle drives every
              system I design and every product I build.
            </p>
            <p>
              When I&apos;m not writing code, I&apos;m thinking about how good design
              and strong security can coexist, and building things that prove
              they can.
            </p>
          </div>
        </div>

      </div>
    </section>
  );
}
