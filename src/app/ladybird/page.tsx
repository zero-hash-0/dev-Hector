"use client";

import { useState, useEffect } from "react";
import Link from "next/link";

// ── Commit log ────────────────────────────────────────────────────────────────
const COMMITS = [
  {
    hash:    "a3f9c12",
    date:    "2026-03-24",
    message: "Exploring HTML tokenizer — tracing spec §12.2 state machine",
    status:  "WIP",
  },
  {
    hash:    "b7e2d45",
    date:    "2026-03-22",
    message: "Read through CSSParser::consume_a_list_of_rules",
    status:  "NOTES",
  },
  {
    hash:    "c1a8f67",
    date:    "2026-03-20",
    message: "Set up local build — LibWeb compiles clean on Linux",
    status:  "DONE",
  },
];

const STATUS_COLOR: Record<string, string> = {
  WIP:   "#ffaa00",
  NOTES: "#00d4ff",
  DONE:  "#00ff41",
};

// ── What is Ladybird ──────────────────────────────────────────────────────────
const FACTS = [
  ["Engine",      "Built from scratch — no Chromium, no WebKit, no Gecko"],
  ["Language",    "C++23"],
  ["Standards",   "HTML · CSS · JavaScript · DOM · Web APIs"],
  ["JS Runtime",  "LibJS — custom engine, no V8"],
  ["License",     "BSD-2-Clause"],
  ["Origin",      "Spun out of SerenityOS in 2023"],
];

// ── Dev log entries ──────────────────────────────────────────────────────────
const LOG = [
  {
    label:  "Build Setup",
    status: "complete",
    lines: [
      "$ git clone https://github.com/LadybirdBrowser/ladybird",
      "$ cd ladybird && ./Meta/ladybird.py build",
      "  ✓  LibCore     compiled",
      "  ✓  LibWeb      compiled",
      "  ✓  LibJS       compiled",
      "  ✓  Ladybird    ready",
    ],
  },
  {
    label:  "Current Focus",
    status: "active",
    lines: [
      "// Diving into the HTML tokenizer",
      "// Libs/LibWeb/HTML/Parser/HTMLTokenizer.cpp",
      "",
      "// State machine maps 1:1 to WHATWG HTML spec §12.2",
      "// Each state is a function — clean, readable",
      "// Goal: understand before contributing a fix",
    ],
  },
  {
    label:  "Next Steps",
    status: "pending",
    lines: [
      "[ ] Find a good-first-issue on the tracker",
      "[ ] Write a test case for the area I'm studying",
      "[ ] Open a draft PR with the fix",
      "[ ] Get it reviewed by the core team",
    ],
  },
];

const STATUS_DOT: Record<string, string> = {
  complete: "#00ff41",
  active:   "#ffaa00",
  pending:  "#1a4a1d",
};

// ── Page ──────────────────────────────────────────────────────────────────────
export default function LadybirdPage() {
  const [time, setTime] = useState("");

  useEffect(() => {
    const tick = () => setTime(new Date().toTimeString().slice(0, 8));
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <main
      className="min-h-screen font-mono"
      style={{ background: "#020b02", color: "#4a8a50" }}
    >
      {/* ── Nav bar ── */}
      <header
        className="sticky top-0 z-50 flex items-center justify-between px-6 py-3 border-b text-xs"
        style={{
          borderColor: "rgba(0,255,65,0.12)",
          background:  "rgba(2,11,2,0.96)",
          backdropFilter: "blur(12px)",
        }}
      >
        <div className="flex items-center gap-3">
          <span className="w-1.5 h-1.5 rounded-full" style={{ background: "#00ff41", boxShadow: "0 0 5px #00ff41" }} />
          <span style={{ color: "#2d5a30" }}>root@hector:~$</span>
          <span style={{ color: "#4a8a50" }}>cd ladybird/</span>
        </div>
        <div className="flex items-center gap-5" style={{ color: "#1a4a1d" }}>
          <Link
            href="/"
            className="transition-colors hover:text-[#00ff41]"
          >
            ← back
          </Link>
          <a
            href="https://github.com/LadybirdBrowser/ladybird"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-[#00ff41]"
          >
            [upstream]
          </a>
          <span className="tabular-nums" style={{ color: "#2d5a30" }}>{time}</span>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-10 space-y-10">

        {/* ── Hero ── */}
        <section>
          <div className="text-[10px] tracking-widest uppercase mb-3" style={{ color: "#1a4a1d" }}>
            open source contribution
          </div>
          <h1
            className="text-3xl sm:text-4xl font-bold tracking-tight mb-2"
            style={{ color: "#00ff41", textShadow: "0 0 24px rgba(0,255,65,0.25)" }}
          >
            Ladybird Browser
          </h1>
          <p className="text-sm leading-7 max-w-2xl" style={{ color: "#4a8a50" }}>
            An independent browser engine built completely from scratch — no Chromium, no WebKit.
            I&apos;m learning the internals and working toward meaningful contributions to the C++ codebase.
          </p>

          <div className="flex flex-wrap gap-3 mt-5">
            <a
              href="https://github.com/LadybirdBrowser/ladybird"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs px-4 py-2 rounded border transition-all duration-200"
              style={{ borderColor: "rgba(0,255,65,0.4)", color: "#00ff41" }}
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
              ./view-upstream →
            </a>
            <a
              href="https://github.com/zero-hash-0"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs px-4 py-2 rounded border transition-all duration-200"
              style={{ borderColor: "rgba(0,255,65,0.15)", color: "#2d5a30" }}
              onMouseEnter={(e) => {
                const el = e.currentTarget as HTMLElement;
                el.style.color       = "#00ff41";
                el.style.borderColor = "rgba(0,255,65,0.4)";
              }}
              onMouseLeave={(e) => {
                const el = e.currentTarget as HTMLElement;
                el.style.color       = "#2d5a30";
                el.style.borderColor = "rgba(0,255,65,0.15)";
              }}
            >
              ./my-github →
            </a>
          </div>
        </section>

        {/* ── What is Ladybird ── */}
        <section>
          <div className="flex items-center gap-2 mb-4 text-xs">
            <span style={{ color: "#2d5a30" }}>root@hector:~/ladybird$</span>
            <span style={{ color: "#4a8a50" }}>cat README.md</span>
          </div>

          <div
            className="border rounded overflow-hidden"
            style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(2,11,2,0.7)" }}
          >
            <div
              className="flex items-center justify-between px-5 py-3 border-b text-[10px]"
              style={{ borderColor: "rgba(0,255,65,0.07)", background: "rgba(0,255,65,0.03)" }}
            >
              <span style={{ color: "#00ff41" }}>README.md</span>
              <span style={{ color: "#1a4a1d" }}>LadybirdBrowser/ladybird</span>
            </div>

            <div className="p-5 space-y-2 text-xs">
              {FACTS.map(([key, val]) => (
                <div key={key} className="flex gap-3 flex-wrap">
                  <span className="w-24 shrink-0" style={{ color: "#2d5a30" }}>{key}</span>
                  <span style={{ color: "#00ff41" }}>:</span>
                  <span style={{ color: "#4a8a50" }}>{val}</span>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ── Dev log ── */}
        <section>
          <div className="flex items-center gap-2 mb-4 text-xs">
            <span style={{ color: "#2d5a30" }}>root@hector:~/ladybird$</span>
            <span style={{ color: "#4a8a50" }}>cat dev-log.md</span>
          </div>

          <div className="grid sm:grid-cols-3 gap-4">
            {LOG.map((entry) => (
              <div
                key={entry.label}
                className="border rounded p-4 space-y-3"
                style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(2,11,2,0.7)" }}
              >
                <div className="flex items-center gap-2 text-xs">
                  <span
                    className="w-2 h-2 rounded-full"
                    style={{
                      background: STATUS_DOT[entry.status],
                      boxShadow:  entry.status === "active" ? `0 0 6px ${STATUS_DOT[entry.status]}` : "none",
                    }}
                  />
                  <span style={{ color: "#00ff41" }}>{entry.label}</span>
                </div>
                <div className="space-y-1 text-[11px]" style={{ color: "#2d5a30" }}>
                  {entry.lines.map((line, i) => (
                    <div key={i} style={{ color: line.startsWith("//") ? "#1a4a1d" : line.startsWith("$") ? "#4a8a50" : line.startsWith("  ✓") ? "#00ff41" : "#2d5a30" }}>
                      {line || <span>&nbsp;</span>}
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* ── Commit log ── */}
        <section>
          <div className="flex items-center gap-2 mb-4 text-xs">
            <span style={{ color: "#2d5a30" }}>root@hector:~/ladybird$</span>
            <span style={{ color: "#4a8a50" }}>git log --oneline</span>
          </div>

          <div
            className="border rounded overflow-hidden"
            style={{ borderColor: "rgba(0,255,65,0.1)", background: "rgba(2,11,2,0.7)" }}
          >
            {COMMITS.map((c, i) => (
              <div
                key={c.hash}
                className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-3 text-xs"
                style={{
                  borderBottom: i < COMMITS.length - 1 ? "1px solid rgba(0,255,65,0.06)" : "none",
                }}
              >
                <span style={{ color: "#00ff41" }}>{c.hash}</span>
                <span style={{ color: "#1a4a1d" }}>{c.date}</span>
                <span className="flex-1" style={{ color: "#4a8a50" }}>{c.message}</span>
                <span
                  className="text-[9px] px-2 py-0.5 rounded border font-bold tracking-wider"
                  style={{
                    color:       STATUS_COLOR[c.status],
                    borderColor: `${STATUS_COLOR[c.status]}30`,
                    background:  `${STATUS_COLOR[c.status]}08`,
                  }}
                >
                  {c.status}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* ── Footer prompt ── */}
        <div className="flex items-center gap-2 text-xs pb-4" style={{ color: "#2d5a30" }}>
          <span>root@hector:~/ladybird$</span>
          <span
            className="inline-block w-2 h-3.5 cursor-blink"
            style={{ background: "#00ff41" }}
          />
        </div>

      </div>
    </main>
  );
}
