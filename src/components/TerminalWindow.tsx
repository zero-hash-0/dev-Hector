"use client";

import { useEffect, useRef, useState } from "react";

type Line =
  | { kind: "command"; text: string; partial: boolean }
  | { kind: "output";  text: string; dim?: boolean; accent?: boolean }
  | { kind: "blank" };

type Step =
  | { type: "typeCommand"; text: string }
  | { type: "output";      text: string; dim?: boolean; accent?: boolean }
  | { type: "blank" }
  | { type: "pause";       ms: number };

const PROMPT = "root@hector:~$";

const SCRIPT: Step[] = [
  { type: "typeCommand",  text: "whoami" },
  { type: "pause",        ms: 100 },
  { type: "output",       text: "Hector Ruiz", accent: true },
  { type: "output",       text: "Developer  ·  Product Builder  ·  Cybersecurity", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 140 },

  { type: "typeCommand",  text: "cat background.txt" },
  { type: "pause",        ms: 100 },
  { type: "output",       text: "Degree      BAS · St. Petersburg College" },
  { type: "output",       text: "Field       Cybersecurity & Systems Architecture" },
  { type: "output",       text: "Location    Florida, USA" },
  { type: "output",       text: "Focus       Security-first design · Native iOS" },
  { type: "blank" },
  { type: "pause",        ms: 140 },

  { type: "typeCommand",  text: "ls skills/" },
  { type: "pause",        ms: 100 },
  { type: "output",       text: "Swift/  SwiftUI/  WidgetKit/  React/  Next.js/  TypeScript/" },
  { type: "output",       text: "Node.js/  PostgreSQL/  Figma/  Security/  Product-Design/", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 140 },

  { type: "typeCommand",  text: "ls projects/" },
  { type: "pause",        ms: 100 },
  { type: "output",       text: "Opus/   Strata/   Cipher/" },
  { type: "blank" },
  { type: "pause",        ms: 80 },
  { type: "output",       text: "  Opus    →  iOS task manager · momentum-based · beta", accent: true },
  { type: "output",       text: "  Strata  →  Team productivity & project tracking web app", dim: true },
  { type: "output",       text: "  Cipher  →  Security monitoring dashboard prototype", dim: true },
  { type: "blank" },
  { type: "pause",        ms: 140 },

  { type: "typeCommand",  text: "./availability --check" },
  { type: "pause",        ms: 100 },
  { type: "output",       text: "▸ Status    Available for freelance & collaboration", accent: true },
  { type: "output",       text: "▸ Response  < 24 hours", dim: true },
  { type: "blank" },
];

const CHAR_MS = 20;
const LINE_MS = 25;

export default function TerminalWindow() {
  const [lines,   setLines]   = useState<Line[]>([]);
  const [blink,   setBlink]   = useState(true);
  const [done,    setDone]    = useState(false);
  const bottomRef             = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const id = setInterval(() => setBlink((v) => !v), 530);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [lines]);

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
            setLines((p) => { const n = [...p]; n[n.length - 1] = { kind: "command", text: s, partial: true }; return n; });
            await sleep(CHAR_MS);
          }
          setLines((p) => { const n = [...p]; n[n.length - 1] = { kind: "command", text: step.text, partial: false }; return n; });
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
        display:        "inline-block",
        width:          8,
        height:         14,
        background:     blink ? "#00ff41" : "transparent",
        verticalAlign:  "middle",
        marginLeft:     2,
        boxShadow:      blink ? "0 0 6px #00ff41" : "none",
        transition:     "background 0.07s, box-shadow 0.07s",
      }}
    />
  );

  return (
    <div
      className="w-full rounded border overflow-hidden terminal-window"
      style={{ background: "#020b02", borderColor: "rgba(0,255,65,0.15)" }}
    >
      {/* Title bar */}
      <div
        className="flex items-center gap-2 px-5 py-3 border-b"
        style={{ background: "rgba(0,255,65,0.03)", borderColor: "rgba(0,255,65,0.08)" }}
      >
        <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff3b30", boxShadow: "0 0 4px #ff3b30" }} />
        <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffcc02", boxShadow: "0 0 4px #ffcc02" }} />
        <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#00ff41", boxShadow: "0 0 5px #00ff41" }} />
        <span className="mx-auto font-mono text-[11px]" style={{ color: "#1a4a1d" }}>
          root@hector — bash
        </span>
      </div>

      {/* Body */}
      <div
        className="p-5 sm:p-6 font-mono text-[11px] sm:text-[12px] leading-relaxed overflow-y-auto"
        style={{ minHeight: 300 }}
      >
        {lines.map((line, i) => {
          if (line.kind === "blank") return <div key={i} className="h-1" />;

          if (line.kind === "command") {
            return (
              <div key={i} className="flex items-center gap-2">
                <span className="phosphor-dim" style={{ color: "#00ff41" }}>{PROMPT}</span>
                <span style={{ color: "#c8ffd4" }}>{line.text}</span>
                {line.partial && cursor}
              </div>
            );
          }

          return (
            <div
              key={i}
              style={{
                color:      line.accent ? "#00ff41" : line.dim ? "#1a4a1d" : "#4a8a50",
                textShadow: line.accent ? "0 0 8px rgba(0,255,65,0.45)" : "none",
              }}
            >
              {line.text}
            </div>
          );
        })}

        {done && (
          <div className="flex items-center gap-2 mt-1">
            <span className="phosphor-dim" style={{ color: "#00ff41" }}>{PROMPT}</span>
            {cursor}
          </div>
        )}

        <div ref={bottomRef} />
      </div>
    </div>
  );
}
