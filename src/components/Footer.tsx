"use client";

import { useState, useEffect } from "react";

export default function Footer() {
  const year = new Date().getFullYear();
  const [time, setTime] = useState("");
  const [uptime, setUptime] = useState(0);

  useEffect(() => {
    const start = Date.now();
    const tick = () => {
      setTime(new Date().toTimeString().slice(0, 8));
      setUptime(Math.floor((Date.now() - start) / 1000));
    };
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <footer
      className="border-t font-mono text-[10px] px-6 py-4"
      style={{ borderColor: "rgba(218,119,86,0.1)" }}
    >
      <div className="max-w-5xl mx-auto flex flex-wrap items-center justify-between gap-3">

        {/* Left: status */}
        <div className="flex items-center gap-3" style={{ color: "#4A4A4A" }}>
          <span className="w-1.5 h-1.5 rounded-full status-pulse" style={{ background: "#DA7756" }} />
          <span style={{ color: "#7A7A7A" }}>root@hector.dev</span>
          <span>·</span>
          <span>ONLINE</span>
          {uptime > 0 && (
            <>
              <span>·</span>
              <span>session {uptime}s</span>
            </>
          )}
        </div>

        {/* Center: links */}
        <div className="flex items-center gap-5" style={{ color: "#4A4A4A" }}>
          <a
            href="https://github.com/zero-hash-0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#DA7756")}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#4A4A4A")}
          >
            [github]
          </a>
          <a
            href="https://x.com/notT0KY0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#DA7756")}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#4A4A4A")}
          >
            [x/twitter]
          </a>
          <a
            href="mailto:gh0stly@riseup.net"
            className="transition-colors"
            onMouseEnter={(e) => ((e.currentTarget as HTMLElement).style.color = "#DA7756")}
            onMouseLeave={(e) => ((e.currentTarget as HTMLElement).style.color = "#4A4A4A")}
          >
            [email]
          </a>
        </div>

        {/* Right: copyright + time */}
        <div className="flex items-center gap-3" style={{ color: "#4A4A4A" }}>
          <span>&copy; {year} hector</span>
          <span>·</span>
          <span className="tabular-nums" style={{ color: "#7A7A7A" }}>{time}</span>
        </div>

      </div>
    </footer>
  );
}
