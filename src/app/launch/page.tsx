"use client";

import { useEffect, useRef, useState } from "react";
import { motion, useInView, useScroll, useTransform } from "framer-motion";
import Link from "next/link";

// ── Grain ────────────────────────────────────────────────────────────────────
function Grain() {
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

// ── iPhone frame wrapper ──────────────────────────────────────────────────────
function IPhoneFrame({
  children,
  scale = 1,
  className = "",
}: {
  children: React.ReactNode;
  scale?: number;
  className?: string;
}) {
  const W = 260 * scale;
  const H = 540 * scale;
  const R = 44 * scale;
  const notch = 80 * scale;

  return (
    <div
      className={className}
      style={{
        width: W,
        height: H,
        borderRadius: R,
        background: "linear-gradient(160deg, #1c1c28 0%, #0f0f18 100%)",
        boxShadow: `
          0 0 0 ${1.5 * scale}px rgba(255,255,255,0.13),
          0 0 0 ${3 * scale}px rgba(0,0,0,0.6),
          0 ${40 * scale}px ${100 * scale}px rgba(0,0,0,0.65),
          inset 0 ${1 * scale}px ${2 * scale}px rgba(255,255,255,0.07)
        `,
        position: "relative",
        overflow: "hidden",
        flexShrink: 0,
      }}
    >
      {/* Notch */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: "50%",
          transform: "translateX(-50%)",
          width: notch,
          height: 24 * scale,
          background: "#000",
          borderBottomLeftRadius: 14 * scale,
          borderBottomRightRadius: 14 * scale,
          zIndex: 10,
        }}
      />
      {/* Screen content */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: R,
          overflow: "hidden",
        }}
      >
        {children}
      </div>
      {/* Reflection shimmer */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          borderRadius: R,
          background:
            "linear-gradient(120deg, rgba(255,255,255,0.04) 0%, transparent 40%)",
          pointerEvents: "none",
        }}
      />
    </div>
  );
}

// ── Screen: Dashboard ────────────────────────────────────────────────────────
function DashboardScreen({ s = 1 }: { s?: number }) {
  const tasks = [
    { title: "Write proposal draft", cat: "Work", color: "#F5A623", done: false },
    { title: "Update portfolio",      cat: "Side", color: "#A78BFA", done: false },
    { title: "Read chapter 4",         cat: "Learn", color: "#34D399", done: false },
    { title: "Morning run",            cat: "Health", color: "#F87171", done: true },
  ];
  return (
    <div
      style={{
        background: "#0D0D10",
        width: "100%",
        height: "100%",
        padding: `${36 * s}px ${14 * s}px ${14 * s}px`,
        display: "flex",
        flexDirection: "column",
        gap: 10 * s,
        overflow: "hidden",
      }}
    >
      {/* Header */}
      <div style={{ paddingBottom: 4 * s }}>
        <div style={{ fontSize: 10 * s, color: "rgba(255,255,255,0.35)", marginBottom: 2 * s }}>
          Tuesday, March 17
        </div>
        <div style={{ fontSize: 18 * s, fontWeight: 700, color: "#fff", lineHeight: 1.1 }}>
          Good morning,<br />Hector.
        </div>
      </div>

      {/* Streak pill */}
      <div style={{ display: "flex", gap: 6 * s }}>
        <div style={{
          background: "rgba(138,74,243,0.18)",
          border: "1px solid rgba(138,74,243,0.35)",
          borderRadius: 100,
          padding: `${4 * s}px ${10 * s}px`,
          fontSize: 9 * s, fontWeight: 600, color: "#A78BFA",
          display: "flex", alignItems: "center", gap: 4 * s,
        }}>
          🔥 Day 7 streak
        </div>
        <div style={{
          background: "rgba(255,255,255,0.06)",
          border: "1px solid rgba(255,255,255,0.1)",
          borderRadius: 100,
          padding: `${4 * s}px ${10 * s}px`,
          fontSize: 9 * s, color: "rgba(255,255,255,0.5)",
        }}>
          3 tasks left
        </div>
      </div>

      {/* Stats card */}
      <div style={{
        background: "#1A1A1E",
        border: "1px solid rgba(255,255,255,0.06)",
        borderRadius: 14 * s,
        padding: `${10 * s}px ${12 * s}px`,
        display: "flex",
        alignItems: "center",
        gap: 10 * s,
      }}>
        {/* Ring */}
        <svg width={46 * s} height={46 * s} viewBox="0 0 46 46">
          <circle cx="23" cy="23" r="18" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="5" />
          <circle cx="23" cy="23" r="18" fill="none"
            stroke="url(#g)" strokeWidth="5" strokeLinecap="round"
            strokeDasharray={`${2 * Math.PI * 18 * 0.74} ${2 * Math.PI * 18}`}
            transform="rotate(-90 23 23)" />
          <defs>
            <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#6E6BF5" />
              <stop offset="100%" stopColor="#8A4AF3" />
            </linearGradient>
          </defs>
          <text x="23" y="27" textAnchor="middle" fill="#fff"
            fontSize="11" fontWeight="800" fontFamily="system-ui">74</text>
        </svg>
        <div>
          <div style={{ fontSize: 9 * s, color: "rgba(255,255,255,0.3)" }}>Momentum</div>
          <div style={{ fontSize: 11 * s, fontWeight: 700, color: "#fff" }}>4/6 done today</div>
        </div>
      </div>

      {/* Today label */}
      <div style={{ fontSize: 11 * s, fontWeight: 700, color: "#fff", paddingLeft: 2 * s }}>
        Today
        <span style={{
          background: "rgba(138,74,243,0.18)",
          color: "#8A4AF3",
          borderRadius: 100,
          padding: `${2 * s}px ${7 * s}px`,
          fontSize: 8 * s,
          marginLeft: 6 * s,
        }}>3</span>
      </div>

      {/* Task cards */}
      {tasks.map((t) => (
        <div key={t.title} style={{
          background: t.done ? "#141416" : "#1A1A1E",
          border: `${0.5 * s}px solid rgba(255,255,255,${t.done ? 0.04 : 0.07})`,
          borderRadius: 10 * s,
          padding: `${8 * s}px ${10 * s}px`,
          display: "flex",
          alignItems: "center",
          gap: 8 * s,
        }}>
          <div style={{
            width: 16 * s, height: 16 * s, borderRadius: "50%",
            border: `1.5px solid ${t.done ? "#34D399" : "rgba(255,255,255,0.18)"}`,
            background: t.done ? "rgba(52,211,153,0.12)" : "transparent",
            display: "flex", alignItems: "center", justifyContent: "center",
            flexShrink: 0,
          }}>
            {t.done && <div style={{ width: 6 * s, height: 6 * s, borderRadius: "50%", background: "#34D399" }} />}
          </div>
          <div style={{ width: 5 * s, height: 5 * s, borderRadius: "50%", background: t.color, flexShrink: 0 }} />
          <div style={{
            flex: 1,
            fontSize: 9.5 * s,
            fontWeight: 500,
            color: t.done ? "rgba(255,255,255,0.3)" : "rgba(255,255,255,0.85)",
            textDecoration: t.done ? "line-through" : "none",
            overflow: "hidden",
            textOverflow: "ellipsis",
            whiteSpace: "nowrap",
          }}>{t.title}</div>
          <div style={{
            background: `${t.color}22`,
            color: t.color,
            borderRadius: 100,
            padding: `${2 * s}px ${6 * s}px`,
            fontSize: 7.5 * s,
            fontWeight: 600,
            flexShrink: 0,
          }}>{t.cat}</div>
        </div>
      ))}
    </div>
  );
}

// ── Screen: Focus Mode ───────────────────────────────────────────────────────
function FocusScreen({ s = 1 }: { s?: number }) {
  const progress = 0.38;
  const r = 68 * s;
  const circ = 2 * Math.PI * r;
  return (
    <div style={{
      background: "#0D0D10",
      width: "100%", height: "100%",
      display: "flex", flexDirection: "column",
      alignItems: "center",
      padding: `${36 * s}px ${14 * s}px ${14 * s}px`,
      gap: 12 * s,
      overflow: "hidden",
    }}>
      {/* Header */}
      <div style={{ width: "100%", display: "flex", justifyContent: "space-between", alignItems: "flex-end" }}>
        <div>
          <div style={{ fontSize: 16 * s, fontWeight: 700, color: "#fff" }}>Focus Mode</div>
          <div style={{ fontSize: 9 * s, color: "#8A4AF3" }}>Focus Session</div>
        </div>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontSize: 13 * s, fontWeight: 800, color: "#A78BFA" }}>42m</div>
          <div style={{ fontSize: 8 * s, color: "rgba(255,255,255,0.3)" }}>today</div>
        </div>
      </div>

      {/* Segment picker */}
      <div style={{
        background: "rgba(255,255,255,0.06)",
        borderRadius: 100,
        display: "flex",
        padding: 3 * s,
        gap: 2 * s,
      }}>
        {["Focus", "Short Break", "Long Break"].map((l, i) => (
          <div key={l} style={{
            background: i === 0 ? "rgba(138,74,243,0.28)" : "transparent",
            color: i === 0 ? "#fff" : "rgba(255,255,255,0.38)",
            borderRadius: 100,
            padding: `${4 * s}px ${8 * s}px`,
            fontSize: 7.5 * s, fontWeight: 600,
          }}>{l}</div>
        ))}
      </div>

      {/* Timer ring */}
      <div style={{ position: "relative", width: 165 * s, height: 165 * s }}>
        {/* Glow */}
        <div style={{
          position: "absolute", inset: 0, borderRadius: "50%",
          background: "rgba(138,74,243,0.12)",
          filter: `blur(${16 * s}px)`,
        }} />
        <svg width={165 * s} height={165 * s} viewBox={`0 0 ${165} ${165}`}
          style={{ position: "absolute", inset: 0 }}>
          <circle cx="82.5" cy="82.5" r={r / s} fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth={10} />
          <circle cx="82.5" cy="82.5" r={r / s} fill="none"
            stroke="url(#fg)" strokeWidth={10} strokeLinecap="round"
            strokeDasharray={`${circ / s * progress} ${circ / s}`}
            transform="rotate(-90 82.5 82.5)"
            style={{ filter: "drop-shadow(0 0 8px rgba(138,74,243,0.8))" }}
          />
          <defs>
            <linearGradient id="fg" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="rgba(138,74,243,0.6)" />
              <stop offset="50%" stopColor="#8A4AF3" />
              <stop offset="100%" stopColor="rgba(138,74,243,0.9)" />
            </linearGradient>
          </defs>
        </svg>
        <div style={{
          position: "absolute", inset: 0,
          display: "flex", flexDirection: "column",
          alignItems: "center", justifyContent: "center",
          gap: 2 * s,
        }}>
          <div style={{ fontSize: 30 * s, fontWeight: 100, color: "#fff", letterSpacing: -1, fontVariantNumeric: "tabular-nums" }}>
            15:22
          </div>
          <div style={{ fontSize: 8 * s, color: "rgba(255,255,255,0.3)" }}>Keep going</div>
        </div>
      </div>

      {/* Session dots */}
      <div style={{ display: "flex", gap: 6 * s, alignItems: "center" }}>
        {[1, 1, 0, 0].map((filled, i) => (
          <div key={i} style={{
            width: filled ? 18 * s : 7 * s,
            height: 7 * s,
            borderRadius: 3 * s,
            background: filled ? "#8A4AF3" : "rgba(255,255,255,0.12)",
          }} />
        ))}
      </div>

      {/* Controls */}
      <div style={{ display: "flex", gap: 14 * s, alignItems: "center" }}>
        {["↺", null, "⏭"].map((icon, i) => i === 1 ? (
          <div key="play" style={{
            width: 54 * s, height: 54 * s, borderRadius: "50%",
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 22 * s, color: "#fff",
            boxShadow: `0 ${8 * s}px ${20 * s}px rgba(138,74,243,0.55)`,
          }}>⏸</div>
        ) : (
          <div key={icon} style={{
            width: 38 * s, height: 38 * s, borderRadius: "50%",
            background: "rgba(255,255,255,0.07)",
            border: "1px solid rgba(255,255,255,0.08)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 14 * s, color: "rgba(255,255,255,0.55)",
          }}>{icon}</div>
        ))}
      </div>

      {/* Current task */}
      <div style={{
        width: "100%",
        background: "#1A1A1E",
        border: "1px solid rgba(138,74,243,0.2)",
        borderRadius: 10 * s,
        padding: `${8 * s}px ${10 * s}px`,
        display: "flex", alignItems: "center", gap: 8 * s,
      }}>
        <div style={{ width: 6 * s, height: 6 * s, borderRadius: "50%", background: "#8A4AF3" }} />
        <div style={{ flex: 1, fontSize: 9.5 * s, fontWeight: 500, color: "rgba(255,255,255,0.8)" }}>
          Write proposal draft
        </div>
        <div style={{ fontSize: 10 * s, color: "rgba(255,255,255,0.25)" }}>⌄⌃</div>
      </div>
    </div>
  );
}

// ── Screen: Projects ─────────────────────────────────────────────────────────
function ProjectsScreen({ s = 1 }: { s?: number }) {
  const projects = [
    { name: "Dev Portfolio", emoji: "💻", color: "#8A4AF3", done: 2, total: 5 },
    { name: "Learning Path",  emoji: "📚", color: "#60A5FA", done: 2, total: 4 },
    { name: "Health & Fitness", emoji: "💪", color: "#34D399", done: 1, total: 3 },
  ];
  return (
    <div style={{
      background: "#0D0D10",
      width: "100%", height: "100%",
      padding: `${36 * s}px ${14 * s}px`,
      display: "flex", flexDirection: "column",
      gap: 12 * s, overflow: "hidden",
    }}>
      <div>
        <div style={{ fontSize: 18 * s, fontWeight: 700, color: "#fff" }}>Projects</div>
        <div style={{ fontSize: 9 * s, color: "rgba(255,255,255,0.35)", marginTop: 2 * s }}>3 active</div>
      </div>

      {projects.map((p) => {
        const pct = p.done / p.total;
        return (
          <div key={p.name} style={{
            background: "#1A1A1E",
            border: "1px solid rgba(255,255,255,0.07)",
            borderRadius: 14 * s,
            padding: `${12 * s}px ${12 * s}px`,
            display: "flex", flexDirection: "column",
            gap: 8 * s,
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8 * s }}>
              <div style={{
                width: 32 * s, height: 32 * s, borderRadius: 9 * s,
                background: `${p.color}22`,
                border: `1px solid ${p.color}44`,
                display: "flex", alignItems: "center", justifyContent: "center",
                fontSize: 16 * s,
              }}>{p.emoji}</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 11 * s, fontWeight: 600, color: "#fff" }}>{p.name}</div>
                <div style={{ fontSize: 8.5 * s, color: "rgba(255,255,255,0.3)", marginTop: 1 * s }}>
                  {p.done}/{p.total} tasks
                </div>
              </div>
              <div style={{
                width: 28 * s, height: 28 * s, position: "relative",
              }}>
                <svg width={28 * s} height={28 * s} viewBox="0 0 28 28">
                  <circle cx="14" cy="14" r="11" fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="3.5" />
                  <circle cx="14" cy="14" r="11" fill="none"
                    stroke={p.color} strokeWidth="3.5" strokeLinecap="round"
                    strokeDasharray={`${2 * Math.PI * 11 * pct} ${2 * Math.PI * 11}`}
                    transform="rotate(-90 14 14)"
                    style={{ filter: `drop-shadow(0 0 4px ${p.color}80)` }}
                  />
                  <text x="14" y="18" textAnchor="middle" fill="#fff"
                    fontSize="8" fontWeight="800" fontFamily="system-ui">
                    {Math.round(pct * 100)}
                  </text>
                </svg>
              </div>
            </div>
            {/* Progress bar */}
            <div style={{
              height: 3 * s, borderRadius: 2 * s,
              background: "rgba(255,255,255,0.06)", overflow: "hidden",
            }}>
              <div style={{
                height: "100%", width: `${pct * 100}%`, borderRadius: 2 * s,
                background: `linear-gradient(90deg, ${p.color}99, ${p.color})`,
                boxShadow: `0 0 6px ${p.color}60`,
              }} />
            </div>
          </div>
        );
      })}

      {/* Add project button */}
      <div style={{
        border: "1px dashed rgba(138,74,243,0.25)",
        borderRadius: 14 * s,
        padding: `${10 * s}px`,
        display: "flex", alignItems: "center", justifyContent: "center", gap: 6 * s,
        color: "rgba(138,74,243,0.55)",
        fontSize: 9.5 * s, fontWeight: 600,
      }}>
        <span style={{ fontSize: 14 * s }}>+</span> New Project
      </div>
    </div>
  );
}

// ── Feature card ─────────────────────────────────────────────────────────────
function FeatureCard({
  icon, title, desc, color, delay,
}: {
  icon: string; title: string; desc: string; color: string; delay: number;
}) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true, margin: "-60px" });
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 28 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.6, delay, ease: [0.16, 1, 0.3, 1] }}
      style={{
        background: "rgba(255,255,255,0.03)",
        border: "1px solid rgba(255,255,255,0.08)",
        borderRadius: 20,
        padding: "24px",
        display: "flex",
        flexDirection: "column",
        gap: 12,
      }}
    >
      <div style={{
        width: 44, height: 44, borderRadius: 13,
        background: `${color}18`,
        border: `1px solid ${color}30`,
        display: "flex", alignItems: "center", justifyContent: "center",
        fontSize: 22,
      }}>{icon}</div>
      <div>
        <div style={{ fontSize: 16, fontWeight: 700, color: "#F2F0FF", marginBottom: 6 }}>{title}</div>
        <div style={{ fontSize: 14, color: "rgba(242,240,255,0.45)", lineHeight: 1.6 }}>{desc}</div>
      </div>
    </motion.div>
  );
}

// ── Main ─────────────────────────────────────────────────────────────────────
export default function LaunchPage() {
  const heroRef = useRef(null);
  const { scrollY } = useScroll();
  const phone1Y = useTransform(scrollY, [0, 500], [0, -40]);
  const phone2Y = useTransform(scrollY, [0, 500], [0, -20]);
  const phone3Y = useTransform(scrollY, [0, 500], [0, -60]);

  const [spotsLeft, setSpotsLeft] = useState<number | null>(null);
  useEffect(() => {
    fetch("/api/beta").then(r => r.json()).then(d => setSpotsLeft(d.remaining)).catch(() => {});
  }, []);

  return (
    <div style={{ background: "#070709", minHeight: "100vh", color: "#F2F0FF", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      <Grain />

      {/* Ambient glows */}
      <div aria-hidden className="pointer-events-none fixed inset-0 overflow-hidden" style={{ zIndex: 0 }}>
        <div style={{
          position: "absolute", top: "-20%", left: "-15%",
          width: 900, height: 700,
          background: "radial-gradient(ellipse 55% 50% at 40% 45%, rgba(110,107,245,0.12) 0%, transparent 70%)",
          filter: "blur(60px)",
        }} />
        <div style={{
          position: "absolute", top: "40%", right: "-10%",
          width: 600, height: 500,
          background: "radial-gradient(ellipse 50% 50% at 60% 50%, rgba(138,74,243,0.09) 0%, transparent 70%)",
          filter: "blur(50px)",
        }} />
      </div>

      {/* ── NAV ── */}
      <nav style={{
        position: "fixed", top: 0, left: 0, right: 0, zIndex: 100,
        padding: "0 24px",
        height: 60,
        display: "flex", alignItems: "center", justifyContent: "space-between",
        background: "rgba(7,7,9,0.7)",
        backdropFilter: "blur(16px)",
        borderBottom: "1px solid rgba(255,255,255,0.06)",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 14, fontWeight: 700, color: "#fff",
          }}>✓</div>
          <span style={{ fontSize: 16, fontWeight: 700, letterSpacing: "-0.02em" }}>Opus</span>
        </div>
        <Link href="/beta" style={{
          background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
          color: "#fff",
          borderRadius: 100,
          padding: "8px 20px",
          fontSize: 13,
          fontWeight: 600,
          textDecoration: "none",
          boxShadow: "0 4px 16px rgba(138,74,243,0.4)",
        }}>
          Join Beta →
        </Link>
      </nav>

      {/* ── HERO ── */}
      <section
        ref={heroRef}
        style={{
          position: "relative", zIndex: 1,
          paddingTop: 130,
          paddingBottom: 80,
          paddingLeft: 24, paddingRight: 24,
          textAlign: "center",
          display: "flex", flexDirection: "column",
          alignItems: "center", gap: 24,
          maxWidth: 900, margin: "0 auto",
        }}
      >
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          style={{
            display: "inline-flex", alignItems: "center", gap: 8,
            background: "rgba(234,179,8,0.1)",
            border: "1px solid rgba(234,179,8,0.28)",
            borderRadius: 100,
            padding: "6px 16px",
            fontSize: 12, fontWeight: 700, color: "#EAB308",
            letterSpacing: "0.04em",
          }}
        >
          🥇 {spotsLeft !== null ? `${spotsLeft} of 25 spots left` : "25 founding member spots"}
        </motion.div>

        {/* Headline */}
        <motion.h1
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.75, delay: 0.08, ease: [0.16, 1, 0.3, 1] }}
          style={{
            fontSize: "clamp(2.8rem, 9vw, 5.5rem)",
            fontWeight: 800,
            letterSpacing: "-0.04em",
            lineHeight: 1.04,
            margin: 0,
            background: "linear-gradient(160deg, #F2F0FF 30%, rgba(167,139,250,0.85) 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}
        >
          Your day,<br />redesigned.
        </motion.h1>

        {/* Sub */}
        <motion.p
          initial={{ opacity: 0, y: 18 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.65, delay: 0.18, ease: [0.16, 1, 0.3, 1] }}
          style={{
            fontSize: "clamp(1rem, 2.5vw, 1.2rem)",
            color: "rgba(242,240,255,0.45)",
            maxWidth: 520,
            lineHeight: 1.65,
            margin: 0,
          }}
        >
          Opus is a task and focus app built around human energy — not task volume.
          Track streaks, run deep work sessions, and ship what matters.
        </motion.p>

        {/* CTAs */}
        <motion.div
          initial={{ opacity: 0, y: 14 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.28, ease: [0.16, 1, 0.3, 1] }}
          style={{ display: "flex", gap: 12, flexWrap: "wrap", justifyContent: "center" }}
        >
          <Link href="/beta" style={{
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            color: "#fff",
            borderRadius: 100,
            padding: "14px 32px",
            fontSize: 16,
            fontWeight: 700,
            textDecoration: "none",
            boxShadow: "0 8px 32px rgba(138,74,243,0.45)",
            display: "inline-block",
          }}>
            Claim your spot →
          </Link>
          <a href="#features" style={{
            border: "1px solid rgba(255,255,255,0.12)",
            color: "rgba(242,240,255,0.65)",
            borderRadius: 100,
            padding: "14px 28px",
            fontSize: 15,
            fontWeight: 500,
            textDecoration: "none",
            display: "inline-block",
          }}>
            See the app
          </a>
        </motion.div>
      </section>

      {/* ── PHONE MOCKUPS ── */}
      <section style={{
        position: "relative", zIndex: 1,
        display: "flex",
        justifyContent: "center",
        alignItems: "flex-end",
        gap: 20,
        padding: "0 20px 80px",
        overflowX: "hidden",
      }}>
        {/* Left: Projects */}
        <motion.div
          style={{ y: phone1Y }}
          initial={{ opacity: 0, y: 60, rotate: -4 }}
          animate={{ opacity: 1, y: 0, rotate: -4 }}
          transition={{ duration: 0.9, delay: 0.35, ease: [0.16, 1, 0.3, 1] }}
        >
          <IPhoneFrame scale={0.82} className="hidden md:block">
            <ProjectsScreen s={0.82} />
          </IPhoneFrame>
        </motion.div>

        {/* Center: Dashboard (hero) */}
        <motion.div
          style={{ y: phone2Y, zIndex: 10 }}
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.9, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
        >
          <IPhoneFrame scale={1}>
            <DashboardScreen s={1} />
          </IPhoneFrame>
        </motion.div>

        {/* Right: Focus */}
        <motion.div
          style={{ y: phone3Y }}
          initial={{ opacity: 0, y: 80, rotate: 4 }}
          animate={{ opacity: 1, y: 0, rotate: 4 }}
          transition={{ duration: 0.9, delay: 0.45, ease: [0.16, 1, 0.3, 1] }}
        >
          <IPhoneFrame scale={0.82} className="hidden md:block">
            <FocusScreen s={0.82} />
          </IPhoneFrame>
        </motion.div>
      </section>

      {/* ── FEATURES ── */}
      <section id="features" style={{
        position: "relative", zIndex: 1,
        maxWidth: 960, margin: "0 auto",
        padding: "60px 24px 80px",
      }}>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-60px" }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          style={{ textAlign: "center", marginBottom: 48 }}
        >
          <p style={{ fontSize: 11, fontWeight: 700, letterSpacing: "0.14em", color: "rgba(242,240,255,0.28)", textTransform: "uppercase", marginBottom: 12 }}>
            Everything you need
          </p>
          <h2 style={{
            fontSize: "clamp(1.8rem, 5vw, 2.8rem)",
            fontWeight: 800, letterSpacing: "-0.03em",
            color: "#F2F0FF", margin: 0,
          }}>
            Built for people who build.
          </h2>
        </motion.div>

        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: 16,
        }}>
          <FeatureCard icon="⚡" title="Deep Work Timer"     color="#6E6BF5" delay={0}    desc="Pomodoro focus sessions with automatic break scheduling. Your streak grows every session you finish." />
          <FeatureCard icon="🔥" title="Daily Streaks"       color="#F59E0B" delay={0.07} desc="Consecutive days of completing tasks build momentum. Miss a day and start again — simple." />
          <FeatureCard icon="📂" title="Project Tracking"    color="#60A5FA" delay={0.14} desc="Group tasks under projects with progress rings and completion rates at a glance." />
          <FeatureCard icon="🔁" title="Recurring Tasks"     color="#34D399" delay={0.21} desc="Daily and weekly habits that automatically reset each morning without any manual work." />
          <FeatureCard icon="📊" title="Momentum Score"      color="#A78BFA" delay={0.28} desc="A live score that combines your streak, completion rate, and consistency into one number." />
          <FeatureCard icon="🎯" title="Category Filters"    color="#F87171" delay={0.35} desc="Organize tasks as Work, Side, Learn, Health, or Personal. Filter your list in one tap." />
        </div>
      </section>

      {/* ── SOCIAL PROOF / BADGE ── */}
      <section style={{
        position: "relative", zIndex: 1,
        maxWidth: 680, margin: "0 auto",
        padding: "0 24px 80px",
        textAlign: "center",
      }}>
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-60px" }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          style={{
            background: "linear-gradient(135deg, rgba(234,179,8,0.1), rgba(161,122,0,0.06))",
            border: "1px solid rgba(234,179,8,0.25)",
            borderRadius: 24,
            padding: "40px 36px",
          }}
        >
          <div style={{ fontSize: 48, marginBottom: 16 }}>🥇</div>
          <h3 style={{ fontSize: 22, fontWeight: 800, color: "#EAB308", marginBottom: 12 }}>
            Founding Member Badge
          </h3>
          <p style={{ fontSize: 15, color: "rgba(234,179,8,0.65)", lineHeight: 1.65, maxWidth: 400, margin: "0 auto 24px" }}>
            The first 25 testers receive a permanent gold badge on their profile.
            A small thank-you that never goes away — for the people who were here first.
          </p>
          <Link href="/beta" style={{
            background: "linear-gradient(135deg, #CA8A04, #EAB308)",
            color: "#000",
            borderRadius: 100,
            padding: "13px 28px",
            fontSize: 14,
            fontWeight: 700,
            textDecoration: "none",
            display: "inline-block",
            boxShadow: "0 6px 24px rgba(234,179,8,0.35)",
          }}>
            Claim your gold badge →
          </Link>
        </motion.div>
      </section>

      {/* ── FINAL CTA ── */}
      <section style={{
        position: "relative", zIndex: 1,
        textAlign: "center",
        padding: "40px 24px 100px",
      }}>
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 20 }}
        >
          <p style={{ fontSize: 13, color: "rgba(242,240,255,0.28)", letterSpacing: "0.1em", textTransform: "uppercase", fontWeight: 600 }}>
            iOS · TestFlight · Free during beta
          </p>
          <h2 style={{
            fontSize: "clamp(2rem, 6vw, 3.5rem)",
            fontWeight: 800,
            letterSpacing: "-0.04em",
            margin: 0,
            background: "linear-gradient(160deg, #F2F0FF 20%, rgba(167,139,250,0.75) 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
          }}>
            Ready to build your best day?
          </h2>
          <Link href="/beta" style={{
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            color: "#fff",
            borderRadius: 100,
            padding: "16px 40px",
            fontSize: 17,
            fontWeight: 700,
            textDecoration: "none",
            boxShadow: "0 10px 40px rgba(138,74,243,0.5)",
            display: "inline-block",
          }}>
            Join the Beta →
          </Link>
          <p style={{ fontSize: 12, color: "rgba(242,240,255,0.2)" }}>
            No App Store. TestFlight invite sent within 24 hours.
          </p>
        </motion.div>
      </section>

      {/* ── FOOTER ── */}
      <footer style={{
        position: "relative", zIndex: 1,
        borderTop: "1px solid rgba(255,255,255,0.06)",
        padding: "24px",
        display: "flex", justifyContent: "space-between", alignItems: "center",
        flexWrap: "wrap", gap: 12,
        maxWidth: 960, margin: "0 auto",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{
            width: 22, height: 22, borderRadius: 6,
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 11, color: "#fff", fontWeight: 700,
          }}>✓</div>
          <span style={{ fontSize: 13, color: "rgba(242,240,255,0.35)" }}>© 2026 Opus</span>
        </div>
        <div style={{ display: "flex", gap: 24 }}>
          <Link href="/beta" style={{ fontSize: 13, color: "rgba(242,240,255,0.35)", textDecoration: "none" }}>Join Beta</Link>
        </div>
      </footer>
    </div>
  );
}
