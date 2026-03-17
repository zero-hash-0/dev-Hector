"use client";

import { useEffect, useRef, useState } from "react";

// ── Types ────────────────────────────────────────────────────────────────────
type Line =
  | { kind: "command"; prompt: string; text: string; partial?: boolean }
  | { kind: "output"; text: string; dim?: boolean }
  | { kind: "blank" };

// ── Script: what the terminal "types" ────────────────────────────────────────
const PROMPT = "hector@dev:~$";

type ScriptStep =
  | { type: "typeCommand"; text: string }
  | { type: "outputLine"; text: string; dim?: boolean }
  | { type: "blank" }
  | { type: "pause"; ms: number };

const SCRIPT: ScriptStep[] = [
  { type: "typeCommand", text: "whoami" },
  { type: "pause", ms: 240 },
  { type: "outputLine", text: "Hector Ruiz" },
  { type: "outputLine", text: "Developer · Product Builder · Cybersecurity", dim: true },
  { type: "blank" },
  { type: "pause", ms: 380 },

  { type: "typeCommand", text: "cat about.txt" },
  { type: "pause", ms: 240 },
  { type: "outputLine", text: "Degree      BAS, St. Petersburg College" },
  { type: "outputLine", text: "Field       Cybersecurity & Systems Architecture" },
  { type: "outputLine", text: "Location    Florida, USA" },
  { type: "outputLine", text: "Focus       Security-first design & native iOS" },
  { type: "blank" },
  { type: "pause", ms: 380 },

  { type: "typeCommand", text: "ls projects/" },
  { type: "pause", ms: 240 },
  { type: "outputLine", text: "Opus/     Strata/     Cipher/" },
  { type: "blank" },
  { type: "pause", ms: 380 },

  { type: "typeCommand", text: "./status --current" },
  { type: "pause", ms: 240 },
  { type: "outputLine", text: "▸ Building Opus for iOS TestFlight" },
  { type: "outputLine", text: "▸ Available for freelance & collaboration", dim: true },
];

const CHAR_DELAY = 55;   // ms per character while typing
const LINE_DELAY = 90;   // ms between output lines appearing

// ── Component ────────────────────────────────────────────────────────────────
export default function TerminalWindow() {
  const [lines, setLines] = useState<Line[]>([]);
  const [cursorVisible, setCursorVisible] = useState(true);
  const [done, setDone] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  // Blink cursor
  useEffect(() => {
    const id = setInterval(() => setCursorVisible((v) => !v), 530);
    return () => clearInterval(id);
  }, []);

  // Scroll to bottom as lines are added
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [lines]);

  // Drive the animation
  useEffect(() => {
    let cancelled = false;

    const sleep = (ms: number) =>
      new Promise<void>((res) => setTimeout(res, ms));

    async function run() {
      for (const step of SCRIPT) {
        if (cancelled) return;

        if (step.type === "pause") {
          await sleep(step.ms);
          continue;
        }

        if (step.type === "blank") {
          setLines((prev) => [...prev, { kind: "blank" }]);
          await sleep(LINE_DELAY);
          continue;
        }

        if (step.type === "outputLine") {
          setLines((prev) => [
            ...prev,
            { kind: "output", text: step.text, dim: step.dim },
          ]);
          await sleep(LINE_DELAY);
          continue;
        }

        if (step.type === "typeCommand") {
          // Push empty command line
          setLines((prev) => [
            ...prev,
            { kind: "command", prompt: PROMPT, text: "", partial: true },
          ]);

          // Type each character
          for (let i = 1; i <= step.text.length; i++) {
            if (cancelled) return;
            const typed = step.text.slice(0, i);
            setLines((prev) => {
              const next = [...prev];
              next[next.length - 1] = {
                kind: "command",
                prompt: PROMPT,
                text: typed,
                partial: true,
              };
              return next;
            });
            await sleep(CHAR_DELAY);
          }

          // Mark command complete
          setLines((prev) => {
            const next = [...prev];
            next[next.length - 1] = {
              kind: "command",
              prompt: PROMPT,
              text: step.text,
              partial: false,
            };
            return next;
          });
        }
      }

      if (!cancelled) setDone(true);
    }

    run();
    return () => { cancelled = true; };
  }, []);

  return (
    <div
      className="w-full rounded-xl overflow-hidden border border-[#1e1e1e] shadow-2xl"
      style={{
        background: "#0d0d0d",
        boxShadow: "0 0 0 1px rgba(110,231,183,0.06), 0 32px 64px rgba(0,0,0,0.6), 0 0 80px rgba(110,231,183,0.04)",
      }}
    >
      {/* Title bar */}
      <div
        className="flex items-center gap-2 px-4 py-3 border-b border-[#1e1e1e]"
        style={{ background: "#111111" }}
      >
        <span className="w-3 h-3 rounded-full bg-[#FF5F57]" />
        <span className="w-3 h-3 rounded-full bg-[#FEBC2E]" />
        <span className="w-3 h-3 rounded-full bg-[#28C840]" />
        <span
          className="ml-auto font-mono text-[11px] tracking-widest"
          style={{ color: "#3a3a3a" }}
        >
          hector@dev — terminal
        </span>
      </div>

      {/* Output area */}
      <div
        className="p-5 font-mono text-[13px] leading-relaxed overflow-y-auto"
        style={{ minHeight: "320px", maxHeight: "380px" }}
      >
        {lines.map((line, i) => {
          if (line.kind === "blank") {
            return <div key={i} className="h-3" />;
          }

          if (line.kind === "command") {
            return (
              <div key={i} className="flex items-center gap-2 whitespace-pre">
                <span style={{ color: "#6ee7b7" }}>{line.prompt}</span>
                <span style={{ color: "#e8e8e8" }}>{line.text}</span>
                {/* Show cursor on the currently-typing line */}
                {line.partial && (
                  <span
                    style={{
                      display: "inline-block",
                      width: "8px",
                      height: "14px",
                      background: cursorVisible ? "#6ee7b7" : "transparent",
                      verticalAlign: "middle",
                      marginLeft: "1px",
                      transition: "background 0.1s",
                    }}
                  />
                )}
              </div>
            );
          }

          // output line
          return (
            <div
              key={i}
              className="pl-0 whitespace-pre"
              style={{ color: line.dim ? "#4a4a4a" : "#a3a3a3" }}
            >
              {line.text}
            </div>
          );
        })}

        {/* Idle cursor after script is done */}
        {done && (
          <div className="flex items-center gap-2 mt-1">
            <span style={{ color: "#6ee7b7" }}>{PROMPT}</span>
            <span
              style={{
                display: "inline-block",
                width: "8px",
                height: "14px",
                background: cursorVisible ? "#6ee7b7" : "transparent",
                verticalAlign: "middle",
                transition: "background 0.1s",
              }}
            />
          </div>
        )}

        <div ref={bottomRef} />
      </div>
    </div>
  );
}
