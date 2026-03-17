"use client";

import { useEffect, useRef, useState } from "react";

// ── Types ─────────────────────────────────────────────────────────────────────
type Line =
  | { kind: "command"; text: string; partial: boolean }
  | { kind: "output"; text: string; dim?: boolean; accent?: boolean }
  | { kind: "blank" };

// ── Script ────────────────────────────────────────────────────────────────────
const PROMPT = "hector@dev:~$";

type Step =
  | { type: "typeCommand"; text: string }
  | { type: "output"; text: string; dim?: boolean; accent?: boolean }
  | { type: "blank" }
  | { type: "pause"; ms: number };

const SCRIPT: Step[] = [
  { type: "typeCommand",  text: "whoami" },
  { type: "pause",        ms: 280 },
  { type: "output",       text: "Hector Ruiz" },
  { type: "output",       text: "Developer  ·  Product Builder  ·  Cybersecurity", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 420 },

  { type: "typeCommand",  text: "cat background.txt" },
  { type: "pause",        ms: 280 },
  { type: "output",       text: "Degree      BAS · St. Petersburg College" },
  { type: "output",       text: "Field       Cybersecurity & Systems Architecture" },
  { type: "output",       text: "Location    Florida, USA" },
  { type: "output",       text: "Focus       Security-first design · Native iOS" },
  { type: "blank" },
  { type: "pause",        ms: 420 },

  { type: "typeCommand",  text: "ls skills/" },
  { type: "pause",        ms: 280 },
  { type: "output",       text: "Swift/   SwiftUI/   WidgetKit/   React/   Next.js/   TypeScript/" },
  { type: "output",       text: "Node.js/   PostgreSQL/   Figma/   Security/   Product-Design/", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 420 },

  { type: "typeCommand",  text: "ls projects/" },
  { type: "pause",        ms: 280 },
  { type: "output",       text: "Opus/        Strata/        Cipher/" },
  { type: "blank" },
  { type: "pause",        ms: 260 },
  { type: "output",       text: "  Opus     →  iOS task manager · momentum-based · TestFlight beta" },
  { type: "output",       text: "  Strata   →  Team productivity & project tracking web app", dim: true },
  { type: "output",       text: "  Cipher   →  Security monitoring dashboard prototype", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 420 },

  { type: "typeCommand",  text: "./availability --check" },
  { type: "pause",        ms: 280 },
  { type: "output",       text: "▸ Status     Available for freelance & collaboration", accent: true },
  { type: "output",       text: "▸ Response   < 24 hours", dim: true },
  { type: "blank" },
];

const CHAR_MS  = 52;
const LINE_MS  = 80;

// ── Component ─────────────────────────────────────────────────────────────────
export default function TerminalWindow() {
  const [lines,   setLines]   = useState<Line[]>([]);
  const [blink,   setBlink]   = useState(true);
  const [done,    setDone]    = useState(false);
  const bottomRef             = useRef<HTMLDivElement>(null);

  // cursor blink
  useEffect(() => {
    const id = setInterval(() => setBlink((v) => !v), 520);
    return () => clearInterval(id);
  }, []);

  // auto-scroll
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [lines]);

  // animation driver
  useEffect(() => {
    let dead = false;
    const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

    async function run() {
      for (const step of SCRIPT) {
        if (dead) return;

        if (step.type === "pause")  { await sleep(step.ms); continue; }
        if (step.type === "blank")  { setLines((p) => [...p, { kind: "blank" }]); await sleep(LINE_MS); continue; }
        if (step.type === "output") {
          setLines((p) => [...p, { kind: "output", text: step.text, dim: step.dim, accent: step.accent }]);
          await sleep(LINE_MS);
          continue;
        }

        if (step.type === "typeCommand") {
          setLines((p) => [...p, { kind: "command", text: "", partial: true }]);
          for (let i = 1; i <= step.text.length; i++) {
            if (dead) return;
            const s = step.text.slice(0, i);
            setLines((p) => {
              const n = [...p];
              n[n.length - 1] = { kind: "command", text: s, partial: true };
              return n;
            });
            await sleep(CHAR_MS);
          }
          setLines((p) => {
            const n = [...p];
            n[n.length - 1] = { kind: "command", text: step.text, partial: false };
            return n;
          });
        }
      }
      if (!dead) setDone(true);
    }

    run();
    return () => { dead = true; };
  }, []);

  const cursor = (
    <span
      style={{
        display: "inline-block",
        width: 8,
        height: 15,
        background: blink ? "#6ee7b7" : "transparent",
        verticalAlign: "middle",
        marginLeft: 2,
        transition: "background 0.08s",
      }}
    />
  );

  return (
    <div
      className="w-full rounded-2xl overflow-hidden"
      style={{
        background: "#0c0c0c",
        border: "1px solid #1e1e1e",
        boxShadow:
          "0 0 0 1px rgba(138,74,243,0.08), 0 40px 80px rgba(0,0,0,0.7), 0 0 100px rgba(138,74,243,0.05)",
      }}
    >
      {/* title bar */}
      <div
        className="flex items-center gap-2 px-5 py-3.5 border-b border-[#1a1a1a]"
        style={{ background: "#111111" }}
      >
        <span className="w-3 h-3 rounded-full bg-[#FF5F57]" />
        <span className="w-3 h-3 rounded-full bg-[#FEBC2E]" />
        <span className="w-3 h-3 rounded-full bg-[#28C840]" />
        <span className="mx-auto font-mono text-[11px] tracking-widest" style={{ color: "#333" }}>
          hector@dev — bash
        </span>
      </div>

      {/* body */}
      <div
        className="p-6 font-mono text-[13px] leading-[1.8] overflow-y-auto"
        style={{ minHeight: 420 }}
      >
        {lines.map((line, i) => {
          if (line.kind === "blank") return <div key={i} className="h-2" />;

          if (line.kind === "command") {
            return (
              <div key={i} className="flex items-center gap-2">
                <span style={{ color: "#8a4af3" }}>{PROMPT}</span>
                <span style={{ color: "#e8e8e8" }}>{line.text}</span>
                {line.partial && cursor}
              </div>
            );
          }

          return (
            <div
              key={i}
              style={{
                color: line.accent ? "#6ee7b7" : line.dim ? "#3d3d3d" : "#888",
                paddingLeft: "0",
              }}
            >
              {line.text}
            </div>
          );
        })}

        {done && (
          <div className="flex items-center gap-2 mt-1">
            <span style={{ color: "#8a4af3" }}>{PROMPT}</span>
            {cursor}
          </div>
        )}

        <div ref={bottomRef} />
      </div>
    </div>
  );
}
