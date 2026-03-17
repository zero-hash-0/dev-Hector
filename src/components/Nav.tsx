"use client";

import { useState, useEffect } from "react";

const links = [
  { label: "About",    href: "#about"    },
  { label: "Projects", href: "#projects" },
  { label: "Skills",   href: "#skills"   },
  { label: "Contact",  href: "#contact"  },
];

export default function Nav() {
  const [scrolled, setScrolled] = useState(false);
  const [open,     setOpen]     = useState(false);
  const [active,   setActive]   = useState("");

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40);
    window.addEventListener("scroll", onScroll);
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  // Highlight active section as user scrolls
  useEffect(() => {
    const ids = links.map((l) => l.href.replace("#", ""));
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) setActive(`#${e.target.id}`);
        });
      },
      { rootMargin: "-40% 0px -55% 0px" }
    );
    ids.forEach((id) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, []);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 flex justify-center pt-5 px-6 pointer-events-none">
      {/* centered pill nav */}
      <div
        className="pointer-events-auto flex items-center gap-1 px-2 py-2 rounded-full transition-all duration-300"
        style={{
          background: scrolled
            ? "rgba(14,12,18,0.85)"
            : "rgba(14,12,18,0.6)",
          border: "1px solid rgba(255,255,255,0.07)",
          backdropFilter: "blur(16px)",
          WebkitBackdropFilter: "blur(16px)",
          boxShadow: "0 4px 24px rgba(0,0,0,0.4)",
        }}
      >
        {links.map((l) => {
          const isActive = active === l.href;
          return (
            <a
              key={l.href}
              href={l.href}
              className="relative px-4 py-1.5 rounded-full text-sm font-medium transition-all duration-200"
              style={{
                color: isActive ? "#8a4af3" : "#71717a",
                background: isActive ? "rgba(138,74,243,0.1)" : "transparent",
              }}
              onMouseEnter={(e) => {
                if (!isActive) (e.currentTarget as HTMLElement).style.color = "#f0f0f0";
              }}
              onMouseLeave={(e) => {
                if (!isActive) (e.currentTarget as HTMLElement).style.color = "#71717a";
              }}
              onClick={() => setActive(l.href)}
            >
              {l.label}
            </a>
          );
        })}

        {/* divider */}
        <span className="w-px h-4 mx-1" style={{ background: "rgba(255,255,255,0.08)" }} />

        <a
          href="https://github.com/zero-hash-0"
          target="_blank"
          rel="noopener noreferrer"
          className="px-4 py-1.5 rounded-full text-sm font-medium transition-all duration-200 hover:text-foreground"
          style={{ color: "#71717a" }}
          onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#f0f0f0")}
          onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#71717a")}
        >
          GitHub
        </a>
      </div>

      {/* mobile hamburger — outside pill */}
      <button
        className="pointer-events-auto md:hidden absolute right-6 top-5 text-muted hover:text-foreground transition-colors p-2"
        onClick={() => setOpen(!open)}
        aria-label="Toggle menu"
      >
        <div className="w-5 flex flex-col gap-1.5">
          <span className={`block h-px bg-current transition-all ${open ? "rotate-45 translate-y-2" : ""}`} />
          <span className={`block h-px bg-current transition-all ${open ? "opacity-0" : ""}`} />
          <span className={`block h-px bg-current transition-all ${open ? "-rotate-45 -translate-y-2" : ""}`} />
        </div>
      </button>

      {open && (
        <div
          className="pointer-events-auto md:hidden absolute top-16 left-4 right-4 rounded-2xl border border-border px-6 py-6 flex flex-col gap-4"
          style={{ background: "rgba(14,12,18,0.95)", backdropFilter: "blur(16px)" }}
        >
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              onClick={() => { setOpen(false); setActive(l.href); }}
              className="text-sm text-muted hover:text-foreground transition-colors"
            >
              {l.label}
            </a>
          ))}
        </div>
      )}
    </header>
  );
}
