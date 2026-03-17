"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";

const BETA_LIMIT = 25;

// ── Types ──────────────────────────────────────────────────────────────────────
type Status = "idle" | "loading" | "success" | "error" | "full" | "duplicate";

interface BetaStatus {
  count: number;
  remaining: number;
  full: boolean;
}

// ── Grain overlay ──────────────────────────────────────────────────────────────
function Grain() {
  return (
    <div
      aria-hidden
      className="pointer-events-none fixed inset-0 z-0"
      style={{
        opacity: 0.022,
        backgroundImage: `url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='300' height='300'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.75' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='300' height='300' filter='url(%23n)'/%3E%3C/svg%3E")`,
        backgroundRepeat: "repeat",
        backgroundSize: "180px 180px",
      }}
    />
  );
}

// ── Slot counter ──────────────────────────────────────────────────────────────
function SlotBar({ remaining }: { remaining: number }) {
  const filled = BETA_LIMIT - remaining;
  const pct = (filled / BETA_LIMIT) * 100;

  return (
    <div className="w-full max-w-xs">
      <div
        className="flex justify-between mb-2"
        style={{ fontSize: 12, color: "rgba(242,240,255,0.38)" }}
      >
        <span>{filled} claimed</span>
        <span style={{ color: remaining <= 5 ? "#EAB308" : "rgba(242,240,255,0.38)" }}>
          {remaining} left
        </span>
      </div>
      <div
        className="w-full rounded-full overflow-hidden"
        style={{ height: 5, background: "rgba(242,240,255,0.07)" }}
      >
        <motion.div
          className="h-full rounded-full"
          style={{
            background:
              remaining <= 5
                ? "linear-gradient(90deg, #EAB308, #F59E0B)"
                : "linear-gradient(90deg, #6E6BF5, #8A4AF3)",
          }}
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 1, ease: [0.16, 1, 0.3, 1] }}
        />
      </div>
    </div>
  );
}

// ── Feature pill ──────────────────────────────────────────────────────────────
function FeaturePill({ icon, text }: { icon: string; text: string }) {
  return (
    <div
      className="inline-flex items-center gap-2 rounded-full px-3 py-1.5"
      style={{
        background: "rgba(242,240,255,0.05)",
        border: "1px solid rgba(242,240,255,0.09)",
        fontSize: 13,
        color: "rgba(242,240,255,0.6)",
      }}
    >
      <span>{icon}</span>
      <span>{text}</span>
    </div>
  );
}

// ── Success screen ─────────────────────────────────────────────────────────────
function SuccessScreen({
  name,
  slot,
  isEarlyTester,
}: {
  name: string;
  slot: number;
  isEarlyTester: boolean;
}) {
  const firstName = name.trim().split(" ")[0];

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.96 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
      className="flex flex-col items-center text-center gap-6"
    >
      {/* Icon */}
      <motion.div
        initial={{ scale: 0.4, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: 0.1, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        style={{
          width: 80,
          height: 80,
          borderRadius: 24,
          background: isEarlyTester
            ? "linear-gradient(135deg, rgba(234,179,8,0.25), rgba(161,122,0,0.15))"
            : "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
          border: isEarlyTester ? "1px solid rgba(234,179,8,0.4)" : "none",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          fontSize: 36,
          boxShadow: isEarlyTester
            ? "0 0 40px rgba(234,179,8,0.2)"
            : "0 0 40px rgba(138,74,243,0.4)",
        }}
      >
        {isEarlyTester ? "🥇" : "✓"}
      </motion.div>

      {/* Headline */}
      <div>
        <h2
          style={{ fontSize: 28, fontWeight: 700, color: "#F2F0FF", marginBottom: 8 }}
        >
          You&apos;re in, {firstName}.
        </h2>
        <p style={{ color: "rgba(242,240,255,0.45)", fontSize: 15, lineHeight: 1.6 }}>
          {isEarlyTester
            ? `You're founding member #${slot} of ${BETA_LIMIT}. Gold badge secured.`
            : `You're tester #${slot}. Check your email for the download link.`}
        </p>
      </div>

      {/* Gold badge callout */}
      {isEarlyTester && (
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3, duration: 0.5 }}
          style={{
            background: "linear-gradient(135deg, rgba(234,179,8,0.12), rgba(161,122,0,0.08))",
            border: "1px solid rgba(234,179,8,0.3)",
            borderRadius: 14,
            padding: "16px 20px",
            maxWidth: 340,
            textAlign: "left",
          }}
        >
          <p
            style={{
              color: "#EAB308",
              fontSize: 11,
              fontWeight: 700,
              letterSpacing: "0.12em",
              textTransform: "uppercase",
              marginBottom: 6,
            }}
          >
            🏆 Founding Member Badge
          </p>
          <p style={{ color: "rgba(234,179,8,0.75)", fontSize: 13, lineHeight: 1.55 }}>
            Your profile carries a permanent gold badge. A small token of
            gratitude that never goes away.
          </p>
        </motion.div>
      )}

      {/* Next steps */}
      <p
        style={{
          color: "rgba(242,240,255,0.3)",
          fontSize: 13,
          lineHeight: 1.6,
          maxWidth: 300,
        }}
      >
        Check your inbox — the TestFlight invite arrives within 24 hours.
        Reply to that email with any feedback, it goes straight to the builder.
      </p>
    </motion.div>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────────
export default function BetaPage() {
  const [betaStatus, setBetaStatus] = useState<BetaStatus>({
    count: 0,
    remaining: BETA_LIMIT,
    full: false,
  });
  const [name, setName]       = useState("");
  const [email, setEmail]     = useState("");
  const [status, setStatus]   = useState<Status>("idle");
  const [result, setResult]   = useState<{ slot: number; isEarlyTester: boolean } | null>(null);
  const [errMsg, setErrMsg]   = useState("");
  const nameRef = useRef<HTMLInputElement>(null);

  // Fetch live count on mount
  useEffect(() => {
    fetch("/api/beta")
      .then((r) => r.json())
      .then((d: BetaStatus) => setBetaStatus(d))
      .catch(() => {});
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim() || !email.trim()) return;
    setStatus("loading");

    try {
      const res = await fetch("/api/beta", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: name.trim(), email: email.trim() }),
      });
      const data = await res.json();

      if (res.status === 409 && data.full) {
        setStatus("full");
      } else if (res.status === 409 && data.duplicate) {
        setStatus("duplicate");
        setErrMsg("This email is already registered.");
      } else if (!res.ok) {
        setStatus("error");
        setErrMsg(data.error || "Something went wrong. Try again.");
      } else {
        setResult({ slot: data.slot, isEarlyTester: data.isEarlyTester });
        setBetaStatus((prev) => ({
          ...prev,
          count: data.slot,
          remaining: data.remaining,
          full: data.remaining === 0,
        }));
        setStatus("success");
      }
    } catch {
      setStatus("error");
      setErrMsg("Network error. Please try again.");
    }
  };

  const showForm = status !== "success" && status !== "full";

  return (
    <div
      className="relative min-h-screen flex flex-col items-center justify-center px-5 py-16"
      style={{ background: "#0A090D" }}
    >
      <Grain />

      {/* Ambient glows */}
      <div
        aria-hidden
        className="pointer-events-none fixed inset-0 overflow-hidden"
      >
        <div
          style={{
            position: "absolute",
            top: "-15%",
            left: "-10%",
            width: 700,
            height: 600,
            background:
              "radial-gradient(ellipse 55% 50% at 40% 45%, rgba(110,107,245,0.14) 0%, transparent 70%)",
            filter: "blur(60px)",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: "10%",
            right: "-5%",
            width: 500,
            height: 400,
            background:
              "radial-gradient(ellipse 50% 50% at 60% 50%, rgba(138,74,243,0.1) 0%, transparent 70%)",
            filter: "blur(50px)",
          }}
        />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 28 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
        className="relative z-10 w-full max-w-md flex flex-col items-center gap-8"
      >
        {/* ── Logo mark ── */}
        <motion.div
          initial={{ scale: 0.7, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.65, ease: [0.16, 1, 0.3, 1] }}
          style={{
            width: 56,
            height: 56,
            borderRadius: 16,
            background: "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 26,
            boxShadow: "0 0 40px rgba(138,74,243,0.45), 0 8px 32px rgba(0,0,0,0.4)",
          }}
        >
          ✓
        </motion.div>

        <AnimatePresence mode="wait">
          {status === "success" && result ? (
            <SuccessScreen
              key="success"
              name={name}
              slot={result.slot}
              isEarlyTester={result.isEarlyTester}
            />
          ) : status === "full" ? (
            <motion.div
              key="full"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center flex flex-col items-center gap-4"
            >
              <div style={{ fontSize: 48 }}>😔</div>
              <h2 style={{ fontSize: 24, fontWeight: 700, color: "#F2F0FF" }}>
                Beta is full
              </h2>
              <p style={{ color: "rgba(242,240,255,0.4)", fontSize: 15, lineHeight: 1.6 }}>
                All {BETA_LIMIT} spots have been claimed. Join the waitlist to
                hear about the public launch.
              </p>
            </motion.div>
          ) : (
            <motion.div
              key="form"
              className="w-full flex flex-col items-center gap-8"
            >
              {/* ── Header ── */}
              <div className="text-center flex flex-col items-center gap-3">
                {/* Badge */}
                <div
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: 8,
                    background: "rgba(234,179,8,0.1)",
                    border: "1px solid rgba(234,179,8,0.28)",
                    borderRadius: 100,
                    padding: "5px 14px",
                    fontSize: 12,
                    fontWeight: 600,
                    color: "#EAB308",
                    letterSpacing: "0.04em",
                  }}
                >
                  <span>🥇</span>
                  <span>First {BETA_LIMIT} get a gold badge</span>
                </div>

                <h1
                  style={{
                    fontSize: "clamp(2rem, 8vw, 2.8rem)",
                    fontWeight: 700,
                    letterSpacing: "-0.035em",
                    color: "#F2F0FF",
                    lineHeight: 1.08,
                    margin: 0,
                  }}
                >
                  Opus Beta
                </h1>
                <p
                  style={{
                    color: "rgba(242,240,255,0.42)",
                    fontSize: 15,
                    lineHeight: 1.65,
                    maxWidth: 320,
                    margin: 0,
                  }}
                >
                  A new way to manage your day. Private access for the first{" "}
                  {BETA_LIMIT} testers. No App Store — straight to your phone
                  via TestFlight.
                </p>
              </div>

              {/* ── Slot bar ── */}
              {!betaStatus.full && (
                <SlotBar remaining={betaStatus.remaining} />
              )}

              {/* ── Feature pills ── */}
              <div className="flex flex-wrap justify-center gap-2">
                <FeaturePill icon="⚡" text="Pomodoro focus timer" />
                <FeaturePill icon="🔥" text="Daily streaks" />
                <FeaturePill icon="📂" text="Projects" />
                <FeaturePill icon="🔁" text="Recurring tasks" />
              </div>

              {/* ── Form ── */}
              {showForm && (
                <form
                  onSubmit={handleSubmit}
                  className="w-full flex flex-col gap-3"
                >
                  <input
                    ref={nameRef}
                    type="text"
                    placeholder="First name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    autoComplete="given-name"
                    style={{
                      width: "100%",
                      background: "rgba(242,240,255,0.05)",
                      border: "1px solid rgba(242,240,255,0.1)",
                      borderRadius: 12,
                      padding: "14px 16px",
                      fontSize: 15,
                      color: "#F2F0FF",
                      outline: "none",
                      boxSizing: "border-box",
                      transition: "border-color 0.2s",
                    }}
                    onFocus={(e) =>
                      (e.currentTarget.style.borderColor = "rgba(138,74,243,0.55)")
                    }
                    onBlur={(e) =>
                      (e.currentTarget.style.borderColor = "rgba(242,240,255,0.1)")
                    }
                  />
                  <input
                    type="email"
                    placeholder="Email address"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoComplete="email"
                    style={{
                      width: "100%",
                      background: "rgba(242,240,255,0.05)",
                      border: "1px solid rgba(242,240,255,0.1)",
                      borderRadius: 12,
                      padding: "14px 16px",
                      fontSize: 15,
                      color: "#F2F0FF",
                      outline: "none",
                      boxSizing: "border-box",
                      transition: "border-color 0.2s",
                    }}
                    onFocus={(e) =>
                      (e.currentTarget.style.borderColor = "rgba(138,74,243,0.55)")
                    }
                    onBlur={(e) =>
                      (e.currentTarget.style.borderColor = "rgba(242,240,255,0.1)")
                    }
                  />

                  {/* Error message */}
                  <AnimatePresence>
                    {(status === "error" || status === "duplicate") && (
                      <motion.p
                        initial={{ opacity: 0, y: -4 }}
                        animate={{ opacity: 1, y: 0 }}
                        exit={{ opacity: 0 }}
                        style={{
                          color: "#F87171",
                          fontSize: 13,
                          margin: 0,
                        }}
                      >
                        {errMsg}
                      </motion.p>
                    )}
                  </AnimatePresence>

                  <motion.button
                    type="submit"
                    disabled={
                      status === "loading" ||
                      !name.trim() ||
                      !email.trim()
                    }
                    whileTap={{ scale: 0.97 }}
                    style={{
                      width: "100%",
                      background:
                        status === "loading" ||
                        !name.trim() ||
                        !email.trim()
                          ? "rgba(138,74,243,0.35)"
                          : "linear-gradient(135deg, #6E6BF5, #8A4AF3)",
                      border: "none",
                      borderRadius: 12,
                      padding: "15px 0",
                      fontSize: 15,
                      fontWeight: 600,
                      color: "#fff",
                      cursor:
                        status === "loading" ||
                        !name.trim() ||
                        !email.trim()
                          ? "not-allowed"
                          : "pointer",
                      boxShadow:
                        status === "loading" ||
                        !name.trim() ||
                        !email.trim()
                          ? "none"
                          : "0 8px 24px rgba(138,74,243,0.4)",
                      transition: "background 0.2s, box-shadow 0.2s",
                    }}
                  >
                    {status === "loading"
                      ? "Securing your spot…"
                      : "Claim My Spot →"}
                  </motion.button>

                  <p
                    style={{
                      color: "rgba(242,240,255,0.2)",
                      fontSize: 12,
                      textAlign: "center",
                      margin: 0,
                    }}
                  >
                    No spam. One email with your TestFlight invite.
                  </p>
                </form>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
