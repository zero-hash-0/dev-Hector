"use client";

const SSH_OUTPUT = [
  { text: "SSH-2.0-OpenSSH_9.0",                                     color: "#4a8a50" },
  { text: "The authenticity of host 'hector.dev' can't be confirmed.", color: "#4a8a50" },
  { text: "ED25519 key fingerprint is SHA256:xK9Lm2PqR7vN3bTqW5uZ...", color: "#4a8a50" },
  { text: "",                                                          color: "" },
  { text: "▸  Connection established.",                                color: "#00ff41", bright: true },
  { text: "▸  Encryption: AES-256-GCM  ·  HMAC: SHA2-256",           color: "#2d5a30" },
  { text: "▸  Perfect Forward Secrecy enabled.",                       color: "#2d5a30" },
  { text: "",                                                          color: "" },
];

export default function Contact() {
  return (
    <section id="contact" className="pt-6 pb-8 px-6 max-w-5xl mx-auto font-mono">

      {/* Section command */}
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: "#2d5a30" }}>root@hector:~$</span>
        <span style={{ color: "#4a8a50" }}>ssh contact@hector.dev</span>
      </div>

      <div
        className="border rounded overflow-hidden terminal-window"
        style={{ borderColor: "rgba(0,255,65,0.15)", background: "rgba(2,11,2,0.75)" }}
      >
        {/* Title bar */}
        <div
          className="flex items-center gap-2 px-4 py-2.5 border-b text-xs"
          style={{ borderColor: "rgba(0,255,65,0.09)", background: "rgba(0,255,65,0.03)" }}
        >
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff3b30", boxShadow: "0 0 4px #ff3b30" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffcc02", boxShadow: "0 0 4px #ffcc02" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#00ff41", boxShadow: "0 0 5px #00ff41" }} />
          <span className="mx-auto" style={{ color: "#1a4a1d" }}>root@local — ssh hector.dev</span>
        </div>

        <div className="px-6 py-5">
          {/* SSH handshake output */}
          <div className="text-xs leading-6 mb-6">
            {SSH_OUTPUT.map((line, i) => (
              <div
                key={i}
                style={{
                  color:      line.color || "transparent",
                  textShadow: line.bright ? "0 0 10px rgba(0,255,65,0.55)" : "none",
                  fontWeight: line.bright ? "700" : "400",
                  minHeight:  "1.5rem",
                }}
              >
                {line.text}
              </div>
            ))}
          </div>

          {/* Divider */}
          <div className="flex items-center gap-3 mb-8" style={{ color: "#0a2e0c" }}>
            <span className="flex-1 border-t" style={{ borderColor: "#0a2e0c" }} />
            <span className="text-xs" style={{ color: "#1a4a1d" }}>SECURE CHANNEL OPEN</span>
            <span className="flex-1 border-t" style={{ borderColor: "#0a2e0c" }} />
          </div>

          {/* Main CTA block */}
          <div className="text-center py-4 space-y-5">
            <div>
              <p className="text-[10px] tracking-[0.2em] uppercase mb-3" style={{ color: "#2d5a30" }}>
                Contact
              </p>
              <h2
                className="text-3xl sm:text-4xl font-bold tracking-tight glitch phosphor"
                style={{ color: "#00ff41" }}
              >
                Let&apos;s build something.
              </h2>
            </div>

            <p className="text-sm max-w-md mx-auto leading-relaxed" style={{ color: "#4a8a50" }}>
              Available for freelance, collaboration, and projects that matter.
              My inbox is open — response within 24 hours.
            </p>

            {/* Contact buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-2">
              <a
                href="mailto:hello@dev-hector.com"
                className="flex items-center gap-2 px-7 py-3 rounded border text-sm transition-all duration-200"
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
                $ mail hello@dev-hector.com
              </a>

              <a
                href="https://x.com/notT0KY0"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 px-7 py-3 rounded border text-sm transition-all duration-200"
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
                $ dm @notT0KY0
              </a>
            </div>
          </div>

          {/* Prompt */}
          <div className="mt-8 flex items-center gap-2 text-xs" style={{ color: "#2d5a30" }}>
            <span>root@hector.dev:~$</span>
            <span className="cursor-blink" style={{ color: "#00ff41" }}>_</span>
          </div>
        </div>
      </div>
    </section>
  );
}
