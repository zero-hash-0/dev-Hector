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
      style={{ borderColor: "rgba(0,255,65,0.1)" }}
    >
      <div className="max-w-5xl mx-auto flex flex-wrap items-center justify-between gap-3">

        {/* Left: status */}
        <div className="flex items-center gap-3" style={{ color: "#1a4a1d" }}>
          <span className="w-1.5 h-1.5 rounded-full status-pulse" style={{ background: "#00ff41" }} />
          <span style={{ color: "#2d5a30" }}>root@hector.dev</span>
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
        <div className="flex items-center gap-5" style={{ color: "#1a4a1d" }}>
          <a
            href="https://github.com/zero-hash-0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-[#00ff41]"
          >
            [github]
          </a>
          <a
            href="https://x.com/notT0KY0"
            target="_blank"
            rel="noopener noreferrer"
            className="transition-colors hover:text-[#00ff41]"
          >
            [x/twitter]
          </a>
          <a
            href="mailto:hello@dev-hector.com"
            className="transition-colors hover:text-[#00ff41]"
          >
            [email]
          </a>
        </div>

        {/* Right: copyright + time */}
        <div className="flex items-center gap-3" style={{ color: "#1a4a1d" }}>
          <span>&copy; {year} hector</span>
          <span>·</span>
          <span className="tabular-nums" style={{ color: "#2d5a30" }}>{time}</span>
        </div>

      </div>
    </footer>
  );
}
