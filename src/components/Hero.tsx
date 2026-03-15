"use client";
import { useEffect } from "react";
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
// ─── Animation variants ──────────────────────────────────────────────────────
const container = {
  hidden: {},
  show: {
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.06,
    },
  },
};
const slideUp = {
  hidden: { opacity: 0, y: 32 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.8, ease: [0.16, 1, 0.3, 1] },
  },
};
const fadeIn = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { duration: 0.65, ease: "easeOut" },
  },
};
const subtleFade = {
  hidden: { opacity: 0, y: 10 },
  show: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.55, ease: [0.16, 1, 0.3, 1] },
  },
};
// ─── Grain overlay ───────────────────────────────────────────────────────────
function GrainOverlay() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-0 select-none"
      style={{
        opacity: 0.025,
        backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23n)'/%3E%3C/svg%3E")`,
        backgroundRepeat: "repeat",
        backgroundSize: "180px 180px",
      }}
    />
  );
}
// ─── Ambient glow ────────────────────────────────────────────────────────────
function AmbientGlow() {
  const mouseX = useMotionValue(0.4);
  const mouseY = useMotionValue(0.35);
  const springX = useSpring(mouseX, { stiffness: 40, damping: 20 });
  const springY = useSpring(mouseY, { stiffness: 40, damping: 20 });
  const x = useTransform(springX, [0, 1], ["-10%", "30%"]);
  const y = useTransform(springY, [0, 1], ["-20%", "20%"]);
  useEffect(() => {
    const mq = window.matchMedia("(pointer: fine)");
    if (!mq.matches) return;
    const onMove = (e: MouseEvent) => {
      mouseX.set(e.clientX / window.innerWidth);
      mouseY.set(e.clientY / window.innerHeight);
    };
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [mouseX, mouseY]);
  return (
    <motion.div
      aria-hidden
      className="pointer-events-none absolute inset-0 overflow-hidden"
      style={{ x, y }}
    >
      <motion.div
        initial={{ opacity: 0, scale: 0.85 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 2.2, ease: "easeOut" }}
        className="absolute top-[-10%] left-[-5%] h-[500px] w-[700px]"
        style={{
          background:
            "radial-gradient(ellipse 60% 55% at 40% 45%, rgba(110,231,183,0.07) 0%, transparent 70%)",
          filter: "blur(40px)",
        }}
      />
    </motion.div>
  );
}
// ─── Social links ────────────────────────────────────────────────────────────
const socials = [
  {
    label: "GitHub",
    href: "https://github.com/zero-hash-0",
    icon: (
      <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
      </svg>
    ),
  },
  {
    label: "X",
    href: "https://x.com/notT0KY0",
    icon: (
      <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
        <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
      </svg>
    ),
  },
];
// ─── Hero ────────────────────────────────────────────────────────────────────
export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-background">
      <GrainOverlay />
      <AmbientGlow />
      <div className="relative z-10 mx-auto w-full max-w-4xl px-6 pt-24 pb-14 md:px-8 md:pt-32 md:pb-20">
        <motion.div
          variants={container}
          initial="hidden"
          animate="show"
          className="flex flex-col gap-8 md:gap-10"
        >
          <motion.p
            variants={fadeIn}
            className="font-mono text-[11px] uppercase tracking-[0.16em] text-muted"
          >
            Based in Florida
          </motion.p>
          <motion.div
            variants={slideUp}
            className="flex flex-col gap-1.5 md:gap-2"
          >
            <h1 className="text-[clamp(3.5rem,10vw,7.2rem)] font-semibold leading-[0.94] tracking-[-0.05em] text-foreground">
              Hector
            </h1>
            <p className="text-[clamp(1.55rem,4.3vw,3.15rem)] font-semibold leading-[1.02] tracking-[-0.03em] text-muted">
              Developer &amp; Product Builder
            </p>
          </motion.div>
          <motion.div variants={fadeIn} className="max-w-[680px]">
            <p className="text-[1rem] leading-[1.5] text-muted md:text-[1.2rem] md:leading-[1.55]">
              I design and build high-performance digital products with a
              security-first mindset. My work spans iOS apps, real-time
              platforms, and full-stack systems.
            </p>
          </motion.div>
          <motion.div
            variants={subtleFade}
            className="flex flex-wrap items-center gap-3"
          >
            <motion.a
              href="#projects"
              className="group relative inline-flex items-center gap-2 overflow-hidden rounded-full bg-accent px-6 py-3 text-sm font-semibold text-background"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              transition={{ type: "spring", stiffness: 400, damping: 20 }}
            >
              <span className="relative z-10">View Work</span>
              <motion.span
                className="relative z-10 inline-block"
                whileHover={{ x: 3 }}
                transition={{ type: "spring", stiffness: 500, damping: 25 }}
              >
                →
              </motion.span>
              <span className="absolute inset-0 bg-accent-dim opacity-0 transition-opacity duration-200 group-hover:opacity-100" />
            </motion.a>
            <motion.a
              href="#contact"
              className="inline-flex items-center rounded-full border border-border px-6 py-3 text-sm text-muted transition-all duration-200 hover:border-zinc-600 hover:text-foreground"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              transition={{ type: "spring", stiffness: 400, damping: 20 }}
            >
              Let&apos;s Build Something
            </motion.a>
          </motion.div>
          <motion.div
            variants={container}
            className="flex items-center gap-5 pt-1"
          >
            {socials.map((s) => (
              <motion.a
                key={s.label}
                variants={subtleFade}
                href={s.href}
                target="_blank"
                rel="noopener noreferrer"
                aria-label={s.label}
                className="text-muted transition-colors duration-200 hover:text-foreground"
                whileHover={{ scale: 1.12, y: -1 }}
                whileTap={{ scale: 0.95 }}
                transition={{ type: "spring", stiffness: 500, damping: 22 }}
              >
                {s.icon}
              </motion.a>
            ))}
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
