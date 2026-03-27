"use client";

const SSH_OUTPUT = [
  { text: "SSH-2.0-OpenSSH_9.0",                                     color: "#D4D4D4" },
  { text: "The authenticity of host 'hector.dev' can't be confirmed.", color: "#D4D4D4" },
  { text: "ED25519 key fingerprint is SHA256:xK9Lm2PqR7vN3bTqW5uZ...", color: "#D4D4D4" },
  { text: "",                                                          color: "" },
  { text: "▸  Connection established.",                                color: "#DA7756", bright: true },
  { text: "▸  Encryption: AES-256-GCM  ·  HMAC: SHA2-256",           color: "#7A7A7A" },
  { text: "▸  Perfect Forward Secrecy enabled.",                       color: "#7A7A7A" },
  { text: "",                                                          color: "" },
];

export default function Contact() {
  return (
    <section id="contact" className="pt-3 pb-4 px-6 max-w-5xl mx-auto font-mono">

      {/* Section command */}
      <div className="flex items-center gap-2 mb-4 text-xs">
        <span style={{ color: "#7A7A7A" }}>root@hector:~$</span>
        <span style={{ color: "#D4D4D4" }}>ssh contact@hector.dev</span>
      </div>

      <div
        className="border rounded overflow-hidden terminal-window"
        style={{ borderColor: "rgba(218,119,86,0.15)", background: "rgba(20,20,20,0.78)" }}
      >
        {/* Title bar */}
        <div
          className="flex items-center gap-2 px-4 py-2.5 border-b text-xs"
          style={{ borderColor: "rgba(218,119,86,0.09)", background: "rgba(218,119,86,0.03)" }}
        >
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ff3b30", boxShadow: "0 0 4px #ff3b30" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#ffcc02", boxShadow: "0 0 4px #ffcc02" }} />
          <span className="w-2.5 h-2.5 rounded-full" style={{ background: "#DA7756", boxShadow: "0 0 5px rgba(218,119,86,0.7)" }} />
          <span className="mx-auto" style={{ color: "#4A4A4A" }}>root@local — ssh hector.dev</span>
        </div>

        <div className="px-6 py-5">
          {/* SSH handshake output */}
          <div className="text-xs leading-6 mb-6">
            {SSH_OUTPUT.map((line, i) => (
              <div
                key={i}
                style={{
                  color:      line.color || "transparent",
                  textShadow: (line as { bright?: boolean }).bright ? "0 0 10px rgba(218,119,86,0.55)" : "none",
                  fontWeight: (line as { bright?: boolean }).bright ? "700" : "400",
                  minHeight:  "1.5rem",
                }}
              >
                {line.text}
              </div>
            ))}
          </div>

          {/* Divider */}
          <div className="flex items-center gap-3 mb-8" style={{ color: "#282828" }}>
            <span className="flex-1 border-t" style={{ borderColor: "#282828" }} />
            <span className="text-xs" style={{ color: "#4A4A4A" }}>SECURE CHANNEL OPEN</span>
            <span className="flex-1 border-t" style={{ borderColor: "#282828" }} />
          </div>

          {/* Main CTA block */}
          <div className="text-center py-4 space-y-5">
            <div>
              <p className="text-[10px] tracking-[0.2em] uppercase mb-3" style={{ color: "#7A7A7A" }}>
                Contact
              </p>
              <h2
                className="text-3xl sm:text-4xl font-bold tracking-tight glitch phosphor"
                style={{ color: "#DA7756" }}
              >
                Let&apos;s build something.
              </h2>
            </div>

            <p className="text-sm max-w-md mx-auto leading-relaxed" style={{ color: "#D4D4D4" }}>
              Available for freelance, collaboration, and projects that matter.
              My inbox is open — response within 24 hours.
            </p>

            {/* Contact buttons */}
            <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-2">
              <a
                href="mailto:gh0stly@riseup.net"
                className="flex items-center gap-2 px-7 py-3 rounded border text-sm transition-all duration-200"
                style={{ borderColor: "rgba(218,119,86,0.5)", color: "#DA7756" }}
                onMouseEnter={(e) => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.background = "#DA7756";
                  el.style.color      = "#141414";
                }}
                onMouseLeave={(e) => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.background = "transparent";
                  el.style.color      = "#DA7756";
                }}
              >
                $ mail gh0stly@riseup.net
              </a>

              <a
                href="https://x.com/notT0KY0"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-2 px-7 py-3 rounded border text-sm transition-all duration-200"
                style={{ borderColor: "rgba(218,119,86,0.18)", color: "#D4D4D4" }}
                onMouseEnter={(e) => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.color       = "#DA7756";
                  el.style.borderColor = "rgba(218,119,86,0.4)";
                }}
                onMouseLeave={(e) => {
                  const el = e.currentTarget as HTMLElement;
                  el.style.color       = "#D4D4D4";
                  el.style.borderColor = "rgba(218,119,86,0.18)";
                }}
              >
                $ dm @notT0KY0
              </a>
            </div>
          </div>

          {/* Prompt */}
          <div className="mt-8 flex items-center gap-2 text-xs" style={{ color: "#7A7A7A" }}>
            <span>root@hector.dev:~$</span>
            <span className="cursor-blink" style={{ color: "#DA7756" }}>_</span>
          </div>
        </div>
      </div>
    </section>
  );
}
