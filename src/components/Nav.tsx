"use client";

import { useState, useEffect } from "react";

const LINKS = [
  { label: "about",    href: "#about"    },
  { label: "now",      href: "#now"      },
  { label: "projects", href: "#projects" },
  { label: "skills",   href: "#skills"   },
  { label: "contact",  href: "#contact"  },
];

export default function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open,     setOpen]     = useState(false);
  const [active,   setActive]   = useState("");
  const [time,     setTime]     = useState("");

  useEffect(() => {
    const tick = () => setTime(new Date().toTimeString().slice(0, 8));
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  useEffect(() => {
    const fn = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", fn);
    return () => window.removeEventListener("scroll", fn);
  }, []);

  useEffect(() => {
    const ids = LINKS.map((l) => l.href.slice(1));
    const obs = new IntersectionObserver(
      (entries) => entries.forEach((e) => { if (e.isIntersecting) setActive(`#${e.target.id}`); }),
      { rootMargin: "-40% 0px -55% 0px" }
    );
    ids.forEach((id) => { const el = document.getElementById(id); if (el) obs.observe(el); });
    return () => obs.disconnect();
  }, []);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 px-4 pt-3 pointer-events-none font-mono text-xs">

      {/* ── Desktop bar ── */}
      <div
        className="pointer-events-auto hidden md:flex items-stretch rounded border overflow-hidden"
        style={{
          background: scrolled ? "rgba(20,20,20,0.97)" : "rgba(20,20,20,0.88)",
          borderColor: "rgba(218,119,86,0.2)",
          backdropFilter: "blur(14px)",
          WebkitBackdropFilter: "blur(14px)",
          boxShadow: "0 0 24px rgba(218,119,86,0.06), 0 4px 20px rgba(0,0,0,0.6)",
        }}
      >
        {/* prompt */}
        <div
          className="flex items-center gap-2 px-4 border-r"
          style={{ borderColor: "rgba(218,119,86,0.12)" }}
        >
          <span className="w-1.5 h-1.5 rounded-full status-pulse" style={{ background: "#DA7756" }} />
          <span style={{ color: "#D4D4D4" }}>root</span>
          <span style={{ color: "#4A4A4A" }}>@</span>
          <span style={{ color: "#DA7756" }}>hector</span>
          <span style={{ color: "#4A4A4A" }}>:~$</span>
        </div>

        {/* links */}
        {LINKS.map((l) => {
          const isActive = active === l.href;
          return (
            <a
              key={l.href}
              href={l.href}
              onClick={() => setActive(l.href)}
              className="flex items-center gap-1.5 px-4 py-2.5 border-r transition-all duration-150"
              style={{
                borderColor: "rgba(218,119,86,0.1)",
                color: isActive ? "#DA7756" : "#7A7A7A",
                background: isActive ? "rgba(218,119,86,0.08)" : "transparent",
              }}
              onMouseEnter={(e) => { if (!isActive) (e.currentTarget as HTMLElement).style.color = "#D4D4D4"; }}
              onMouseLeave={(e) => { if (!isActive) (e.currentTarget as HTMLElement).style.color = "#7A7A7A"; }}
            >
              {isActive && <span style={{ color: "#DA7756" }}>▶</span>}
              {l.label}
            </a>
          );
        })}

        {/* right status */}
        <div
          className="flex items-center gap-3 px-4 ml-auto"
          style={{ color: "#4A4A4A" }}
        >
          <span style={{ color: "#DA7756" }}>◈</span>
          <span style={{ color: "#7A7A7A" }}>SECURE</span>
          <span className="w-px h-3.5 mx-1" style={{ background: "rgba(218,119,86,0.12)" }} />
          <a
            href="https://github.com/zero-hash-0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors"
            style={{ color: "#4A4A4A" }}
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#DA7756")}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#4A4A4A")}
          >
            [github]
          </a>
          <span className="w-px h-3.5 mx-1" style={{ background: "rgba(218,119,86,0.08)" }} />
          <span className="tabular-nums" style={{ color: "#7A7A7A" }}>{time}</span>
        </div>
      </div>

      {/* ── Mobile button ── */}
      <button
        className="pointer-events-auto md:hidden absolute right-4 top-3 px-3 py-1.5 border rounded text-xs font-mono"
        style={{ borderColor: "rgba(218,119,86,0.35)", color: "#DA7756", background: "rgba(20,20,20,0.92)" }}
        onClick={() => setOpen(!open)}
        aria-label="Toggle menu"
      >
        {open ? "[×]" : "[≡]"}
      </button>

      {/* ── Mobile dropdown ── */}
      {open && (
        <div
          className="pointer-events-auto md:hidden absolute top-14 left-4 right-4 border rounded font-mono"
          style={{ background: "rgba(20,20,20,0.97)", borderColor: "rgba(218,119,86,0.2)" }}
        >
          {LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              onClick={() => { setOpen(false); setActive(l.href); }}
              className="flex items-center gap-3 px-5 py-3 border-b text-xs transition-colors"
              style={{ borderColor: "rgba(218,119,86,0.08)", color: "#D4D4D4" }}
            >
              <span style={{ color: "#7A7A7A" }}>$</span>
              cd {l.label}/
            </a>
          ))}
        </div>
      )}
    </header>
  );
}
