"use client";

import { useEffect, useRef, useState } from "react";

// ── Binary Rain Canvas ────────────────────────────────────────────────────────
function BinaryRain() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;

    const FONT_SIZE = 14;
    let cols = 0;
    let drops: number[] = [];
    let speeds: number[] = [];

    const setup = () => {
      canvas.width  = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
      cols   = Math.floor(canvas.width / FONT_SIZE);
      drops  = Array.from({ length: cols }, () => -Math.random() * 60);
      speeds = Array.from({ length: cols }, () => 0.3 + Math.random() * 0.7);
    };

    setup();
    window.addEventListener("resize", setup);

    const draw = () => {
      ctx.fillStyle = "rgba(2,11,2,0.065)";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.font = `${FONT_SIZE}px "Courier New", monospace`;

      for (let i = 0; i < drops.length; i++) {
        drops[i] += speeds[i];
        if (drops[i] * FONT_SIZE > canvas.height && Math.random() > 0.975) {
          drops[i] = -Math.random() * 40;
        }
        if (drops[i] < 0) continue;

        const y   = drops[i] * FONT_SIZE;
        const bit = Math.random() > 0.5 ? "1" : "0";
        const isHead = (drops[i] % 1) < speeds[i] * 1.2;

        if (isHead) {
          ctx.fillStyle = "rgba(200,255,210,0.92)";
        } else {
          const fade = Math.min(1, drops[i] / 18);
          ctx.fillStyle = `rgba(0,255,65,${0.08 + fade * 0.38})`;
        }
        ctx.fillText(bit, i * FONT_SIZE, y);
      }

      animId = requestAnimationFrame(draw);
    };

    animId = requestAnimationFrame(draw);
    return () => {
      cancelAnimationFrame(animId);
      window.removeEventListener("resize", setup);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="absolute inset-0 w-full h-full"
      style={{ opacity: 0.4 }}
    />
  );
}

// ── Boot sequence lines ───────────────────────────────────────────────────────
type BootLine = {
  text:   string;
  delay:  number;
  color?: string;
  bright?: boolean;
};

const BOOT: BootLine[] = [
  { text: "BIOS v2.4.1  ·  Hector Systems Corp.", delay: 0,    color: "#4a8a50" },
  { text: "Copyright (c) 2024  ·  All Rights Reserved", delay: 60,   color: "#2d5a30" },
  { text: "", delay: 100 },
  { text: "Mounting encrypted volumes ............. [  OK  ]", delay: 180,  color: "#4a8a50" },
  { text: "Loading firewall ruleset ............... [  OK  ]", delay: 290,  color: "#4a8a50" },
  { text: "Establishing secure tunnel ............. [  OK  ]", delay: 410,  color: "#4a8a50" },
  { text: "Running integrity checks ............... [  OK  ]", delay: 530,  color: "#4a8a50" },
  { text: "Activating threat detection engine ..... [  OK  ]", delay: 650,  color: "#4a8a50" },
  { text: "Verifying credentials .................. [  OK  ]", delay: 780,  color: "#4a8a50" },
  { text: "", delay: 860 },
  { text: "▸  AUTHENTICATION SUCCESSFUL  ·  SYSTEM READY", delay: 960,  color: "#00ff41", bright: true },
  { text: "", delay: 1040 },
  { text: "Welcome back, root.  Last login: today.", delay: 1120, color: "#4a8a50" },
];

// ── ASCII name ────────────────────────────────────────────────────────────────
const ASCII = [
  "██╗  ██╗███████╗ ██████╗████████╗ ██████╗ ██████╗",
  "██║  ██║██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗",
  "███████║█████╗  ██║        ██║   ██║   ██║██████╔╝",
  "██╔══██║██╔══╝  ██║        ██║   ██║   ██║██╔══██╗",
  "██║  ██║███████╗╚██████╗   ██║   ╚██████╔╝██║  ██║",
  "╚═╝  ╚═╝╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝",
];

// ── Hero ──────────────────────────────────────────────────────────────────────
export default function Hero() {
  const [bootLines, setBootLines] = useState<BootLine[]>([]);
  const [showAscii, setShowAscii] = useState(false);
  const [showCtas,  setShowCtas]  = useState(false);

  useEffect(() => {
    const ids: ReturnType<typeof setTimeout>[] = [];

    BOOT.forEach((line, i) => {
      const id = setTimeout(() => {
        setBootLines((prev) => [...prev, line]);
        if (i === BOOT.length - 1) {
          const a = setTimeout(() => setShowAscii(true), 220);
          const b = setTimeout(() => setShowCtas(true),  620);
          ids.push(a, b);
        }
      }, line.delay + i * 20);
      ids.push(id);
    });

    return () => ids.forEach(clearTimeout);
  }, []);

  return (
    <section
      className="relative overflow-hidden"
      style={{ background: "#020b02" }}
    >
      {/* Binary rain */}
      <BinaryRain />

      {/* Moving scan line */}
      <div className="scan-line" />

      {/* Radial vignette */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          background:
            "radial-gradient(ellipse 80% 80% at 50% 50%, transparent 30%, rgba(2,11,2,0.82) 100%)",
        }}
      />

      {/* Content */}
      <div className="relative z-10 w-full max-w-5xl mx-auto px-5 pt-20 pb-3 font-mono">

        {/* Top border label */}
        <div className="flex items-center gap-3 mb-7 text-xs" style={{ color: "#2d5a30" }}>
          <span>┌─</span>
          <span style={{ color: "#1a4a1d" }}>HECTOR.SYS · BOOT SEQUENCE · v2.4.1</span>
          <span className="flex-1 border-t" style={{ borderColor: "#0a2e0c" }} />
          <span>─┐</span>
        </div>

        {/* Boot terminal */}
        <div
          className="rounded border mb-5 overflow-hidden terminal-window"
          style={{ borderColor: "rgba(0,255,65,0.15)", background: "rgba(2,11,2,0.82)" }}
        >
          {/* Title bar */}
          <div
            className="flex items-center gap-2 px-4 py-2 border-b text-xs"
            style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(0,255,65,0.04)" }}
          >
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff3b30", boxShadow: "0 0 4px #ff3b30" }} />
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffcc02", boxShadow: "0 0 4px #ffcc02" }} />
            <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#00ff41", boxShadow: "0 0 5px #00ff41" }} />
            <span className="mx-auto" style={{ color: "#1a4a1d" }}>
              root@hector — bash — 120×40
            </span>
          </div>

          {/* Lines */}
          <div className="px-5 py-4 text-xs leading-6" style={{ minHeight: 200 }}>
            {bootLines.map((line, i) => (
              <div
                key={i}
                className="h-6"
                style={{
                  color:       line.color ?? "#2d5a30",
                  fontWeight:  line.bright ? "700" : "400",
                  textShadow:  line.bright ? "0 0 10px rgba(0,255,65,0.6)" : "none",
                }}
              >
                {line.text}
              </div>
            ))}
          </div>
        </div>

        {/* ASCII art name */}
        {showAscii && (
          <div className="mb-5 overflow-x-auto">
            <div
              className="text-[7px] sm:text-[9px] md:text-[12px] leading-tight whitespace-pre font-mono phosphor"
              style={{ color: "#00ff41" }}
            >
              {ASCII.map((row, i) => (
                <div
                  key={i}
                  style={{ animation: `slideInRow 0.3s ease ${i * 0.055}s both` }}
                >
                  {row}
                </div>
              ))}
            </div>

            <div
              className="mt-3 flex flex-wrap items-center gap-3 text-xs"
              style={{ color: "#2d5a30" }}
            >
              <span>Developer</span>
              <span style={{ color: "#0a2e0c" }}>·</span>
              <span>Product Builder</span>
              <span style={{ color: "#0a2e0c" }}>·</span>
              <span>Cybersecurity</span>
              <span style={{ color: "#0a2e0c" }}>·</span>
              <span>Florida, USA</span>
              <span className="cursor-blink" style={{ color: "#00ff41" }}>_</span>
            </div>
          </div>
        )}

        {/* CTAs */}
        {showCtas && (
          <div
            className="flex flex-wrap items-center gap-4 fade-up"
          >
            <a
              href="#projects"
              className="flex items-center gap-2 px-6 py-2.5 rounded border text-sm transition-all duration-200"
              style={{ borderColor: "rgba(0,255,65,0.5)", color: "#00ff41" }}
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
              <span style={{ color: "inherit" }}>$</span> ls projects/
            </a>

            <a
              href="#contact"
              className="flex items-center gap-2 px-6 py-2.5 rounded border text-sm transition-all duration-200"
              style={{ borderColor: "rgba(0,255,65,0.18)", color: "#4a8a50" }}
              onMouseEnter={(e) => {
                const el = e.currentTarget as HTMLElement;
                el.style.color       = "#00ff41";
                el.style.borderColor = "rgba(0,255,65,0.4)";
              }}
              onMouseLeave={(e) => {
                const el = e.currentTarget as HTMLElement;
                el.style.color       = "#4a8a50";
                el.style.borderColor = "rgba(0,255,65,0.18)";
              }}
            >
              <span>$</span> ssh contact@hector.dev
            </a>

            <div className="flex items-center gap-5 ml-auto">
              <a
                href="https://github.com/zero-hash-0"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs transition-colors"
                style={{ color: "#1a4a1d" }}
                onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#00ff41")}
                onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#1a4a1d")}
              >
                [github]
              </a>
              <a
                href="https://x.com/notT0KY0"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs transition-colors"
                style={{ color: "#1a4a1d" }}
                onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#00ff41")}
                onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#1a4a1d")}
              >
                [x/twitter]
              </a>
            </div>
          </div>
        )}

        {/* Bottom border label */}
        <div className="flex items-center gap-3 mt-5 text-xs" style={{ color: "#2d5a30" }}>
          <span>└─</span>
          <span className="flex-1 border-t" style={{ borderColor: "#0a2e0c" }} />
          <span style={{ color: "#1a4a1d" }}>END BOOT SEQUENCE</span>
          <span className="flex-1 border-t" style={{ borderColor: "#0a2e0c" }} />
          <span>─┘</span>
        </div>
      </div>
    </section>
  );
}
