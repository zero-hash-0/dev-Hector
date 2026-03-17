"use client";

import { useEffect } from "react";
import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import TerminalWindow from "./TerminalWindow";

// ── Grain ─────────────────────────────────────────────────────────────────────
function GrainOverlay() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-0 select-none"
      style={{
        opacity: 0.022,
        backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23n)'/%3E%3C/svg%3E")`,
        backgroundRepeat: "repeat",
        backgroundSize: "180px 180px",
      }}
    />
  );
}

// ── Ambient glow ──────────────────────────────────────────────────────────────
function AmbientGlow() {
  const mouseX = useMotionValue(0.4);
  const mouseY = useMotionValue(0.35);
  const sx = useSpring(mouseX, { stiffness: 35, damping: 22 });
  const sy = useSpring(mouseY, { stiffness: 35, damping: 22 });
  const x  = useTransform(sx, [0, 1], ["-15%", "25%"]);
  const y  = useTransform(sy, [0, 1], ["-15%", "25%"]);

  useEffect(() => {
    const mq = window.matchMedia("(pointer: fine)");
    if (!mq.matches) return;
    const fn = (e: MouseEvent) => {
      mouseX.set(e.clientX / window.innerWidth);
      mouseY.set(e.clientY / window.innerHeight);
    };
    window.addEventListener("mousemove", fn);
    return () => window.removeEventListener("mousemove", fn);
  }, [mouseX, mouseY]);

  return (
    <motion.div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden" style={{ x, y }}>
      <motion.div
        initial={{ opacity: 0, scale: 0.8 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 2.5, ease: "easeOut" }}
        className="absolute top-[-20%] left-[-10%] h-[600px] w-[800px]"
        style={{
          background: "radial-gradient(ellipse 55% 50% at 40% 45%, rgba(138,74,243,0.09) 0%, transparent 70%)",
          filter: "blur(50px)",
        }}
      />
    </motion.div>
  );
}

// ── Hero ──────────────────────────────────────────────────────────────────────
export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-background">
      <GrainOverlay />
      <AmbientGlow />

      <div className="relative z-10 mx-auto w-full max-w-4xl px-6 pt-28 pb-20 md:px-8 md:pt-36 md:pb-28">
        <div className="flex flex-col items-center text-center gap-6 mb-12">

          {/* eyebrow */}
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.05 }}
            className="font-mono text-[11px] uppercase tracking-[0.18em]"
            style={{ color: "#8a4af3" }}
          >
            Based in Florida
          </motion.p>

          {/* name */}
          <motion.h1
            initial={{ opacity: 0, y: 28 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.85, delay: 0.1, ease: [0.16, 1, 0.3, 1] }}
            className="text-[clamp(3.8rem,11vw,8rem)] font-semibold leading-[0.92] tracking-[-0.055em] text-foreground"
          >
            Hector
          </motion.h1>

          {/* tagline */}
          <motion.p
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.75, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
            className="text-[clamp(1.1rem,3vw,1.55rem)] font-medium tracking-[-0.02em]"
            style={{ color: "#52525b" }}
          >
            Developer &amp; Product Builder
          </motion.p>

        </div>

        {/* ── Terminal — full width, centered ── */}
        <motion.div
          initial={{ opacity: 0, y: 32 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 0.35, ease: [0.16, 1, 0.3, 1] }}
        >
          <TerminalWindow />
        </motion.div>

        {/* ── CTAs ── */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.65, delay: 0.55, ease: [0.16, 1, 0.3, 1] }}
          className="flex flex-wrap items-center justify-center gap-3 mt-10"
        >
          <motion.a
            href="#projects"
            className="group relative inline-flex items-center gap-2 overflow-hidden rounded-full px-7 py-3 text-sm font-semibold text-white"
            style={{ background: "#8a4af3" }}
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.97 }}
            transition={{ type: "spring", stiffness: 400, damping: 20 }}
          >
            View Work
            <motion.span
              whileHover={{ x: 3 }}
              transition={{ type: "spring", stiffness: 500, damping: 25 }}
            >
              →
            </motion.span>
            <span
              className="absolute inset-0 opacity-0 transition-opacity duration-200 group-hover:opacity-100"
              style={{ background: "#6e6bf5" }}
            />
          </motion.a>

          <motion.a
            href="#contact"
            className="inline-flex items-center rounded-full border border-border px-7 py-3 text-sm text-muted transition-all duration-200 hover:text-foreground"
            style={{ borderColor: "#1e1b26" }}
            whileHover={{ scale: 1.03, borderColor: "#3a3450" }}
            whileTap={{ scale: 0.97 }}
            transition={{ type: "spring", stiffness: 400, damping: 20 }}
          >
            Let&apos;s Build Something
          </motion.a>

          {/* Socials inline */}
          <div className="flex items-center gap-4 pl-2">
            <motion.a
              href="https://github.com/zero-hash-0"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="GitHub"
              className="text-muted hover:text-foreground transition-colors"
              whileHover={{ scale: 1.12, y: -1 }}
              whileTap={{ scale: 0.95 }}
            >
              <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0 1 12 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
              </svg>
            </motion.a>
            <motion.a
              href="https://x.com/notT0KY0"
              target="_blank"
              rel="noopener noreferrer"
              aria-label="X"
              className="text-muted hover:text-foreground transition-colors"
              whileHover={{ scale: 1.12, y: -1 }}
              whileTap={{ scale: 0.95 }}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
              </svg>
            </motion.a>
          </div>
        </motion.div>

      </div>
    </section>
  );
}
