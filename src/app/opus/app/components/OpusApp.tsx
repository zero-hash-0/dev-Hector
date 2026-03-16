"use client";
import { useState, useEffect, useRef } from "react";

// ─── Types ────────────────────────────────────────────────────────────────────
type Tag = "Work" | "Side" | "Learn";
type Schedule = "today" | "later";
interface Task {
  id: number;
  title: string;
  tag: Tag;
  time?: string;
  schedule: Schedule;
  done: boolean;
  priority: "high" | "mid" | "low";
}

const TAG_COLORS: Record<Tag, { bg: string; text: string }> = {
  Work:  { bg: "rgba(245,166,35,0.15)",  text: "#f5a623" },
  Side:  { bg: "rgba(144,32,238,0.18)",  text: "#b060f0" },
  Learn: { bg: "rgba(52,211,153,0.15)",  text: "#34d399" },
};
const PRIORITY_COLORS = { high: "#ff5555", mid: "#f5a623", low: "#6c6c7e" };

const SEED_TASKS: Task[] = [
  { id: 1, title: "Write proposal draft",  tag: "Work",  time: "today", schedule: "today", done: false, priority: "high" },
  { id: 2, title: "Review Q2 metrics",     tag: "Work",  schedule: "today", done: false, priority: "mid"  },
  { id: 3, title: "Update portfolio",      tag: "Side",  schedule: "today", done: false, priority: "mid"  },
  { id: 4, title: "Read chapter 4",        tag: "Learn", schedule: "today", done: false, priority: "low"  },
  { id: 5, title: "Expense report",        tag: "Work",  schedule: "today", done: false, priority: "low"  },
  { id: 6, title: "Call with Sarah",       tag: "Work",  time: "2pm",   schedule: "today", done: true,  priority: "high" },
  { id: 7, title: "Workout",               tag: "Side",  time: "7am",   schedule: "later", done: false, priority: "mid"  },
  { id: 8, title: "Plan sprint backlog",   tag: "Work",  schedule: "later", done: false, priority: "mid"  },
  { id: 9, title: "Finish SwiftUI book",   tag: "Learn", schedule: "later", done: false, priority: "low"  },
];

// ─── SVG Llama Icon ───────────────────────────────────────────────────────────
function LlamaIcon({ size = 48 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 200 200" fill="none" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <filter id="glowL" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="7" result="b"/>
          <feColorMatrix type="matrix" values="1 0.53 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0" in="b"/>
        </filter>
        <filter id="glowR" x="-40%" y="-40%" width="180%" height="180%">
          <feGaussianBlur stdDeviation="7" result="b"/>
          <feColorMatrix type="matrix" values="0.56 0 0 0 0 0.12 0 0 0 0 0.93 0 0 0 0 0 0 0 1 0" in="b"/>
        </filter>
        <radialGradient id="muzzle" cx="50%" cy="38%" r="55%">
          <stop offset="0%" stopColor="#d8d4cc"/>
          <stop offset="100%" stopColor="#a8a49c"/>
        </radialGradient>
        <radialGradient id="eyeAmber" cx="35%" cy="30%" r="60%">
          <stop offset="0%" stopColor="#f5d060"/>
          <stop offset="100%" stopColor="#f2bc00"/>
        </radialGradient>
      </defs>
      <rect width="200" height="200" fill="#10101a"/>
      {/* Neon rim glows */}
      <ellipse cx="66" cy="112" rx="50" ry="74" fill="#ff8800" filter="url(#glowL)" opacity="0.75"/>
      <ellipse cx="134" cy="112" rx="50" ry="74" fill="#9020ee" filter="url(#glowR)" opacity="0.75"/>
      {/* Left ear white */}
      <path d="M70 44 L60 10 L80 8 L84 42 Z" fill="#e8e4e0"/>
      <path d="M71 42 L63 16 L78 14 L81 40 Z" fill="#c4bfba"/>
      {/* Right ear black */}
      <path d="M130 44 L120 8 L140 10 L130 42 Z" fill="#18161f"/>
      <path d="M129 42 L122 12 L136 13 L130 40 Z" fill="#0d0d14"/>
      {/* Body */}
      <ellipse cx="100" cy="158" rx="54" ry="56" fill="#cec9c5"/>
      <ellipse cx="100" cy="163" rx="47" ry="48" fill="#c3beba"/>
      {/* Dark fur cap */}
      <path d="M56 80 Q60 48 100 46 Q140 48 144 80 Q138 68 128 65 Q118 60 108 62 Q106 55 100 54 Q94 55 92 62 Q82 60 72 65 Q62 68 56 80 Z" fill="#1d1b28"/>
      <path d="M63 82 L68 72 L74 80 L80 70 L86 78 L92 68 L98 76 L104 68 L110 78 L116 70 L122 80 L128 72 L135 82 Q128 74 100 72 Q72 74 63 82 Z" fill="#242233"/>
      {/* Head */}
      <ellipse cx="100" cy="102" rx="44" ry="48" fill="#d8d4d0"/>
      <ellipse cx="100" cy="110" rx="38" ry="40" fill="#ccc8c4"/>
      {/* Muzzle */}
      <ellipse cx="100" cy="124" rx="23" ry="17" fill="url(#muzzle)"/>
      {/* Eye sockets */}
      <ellipse cx="83" cy="98" rx="12" ry="9" fill="#38364c"/>
      <ellipse cx="117" cy="98" rx="12" ry="9" fill="#38364c"/>
      {/* Amber eyes */}
      <ellipse cx="83" cy="99" rx="10" ry="7" fill="url(#eyeAmber)"/>
      <ellipse cx="117" cy="99" rx="10" ry="7" fill="url(#eyeAmber)"/>
      {/* Heavy droopy eyelids */}
      <path d="M73 95 Q83 89 93 95 L93 99 Q83 93 73 99 Z" fill="#38364c"/>
      <path d="M107 95 Q117 89 127 95 L127 99 Q117 93 107 99 Z" fill="#38364c"/>
      {/* Dark pupils */}
      <ellipse cx="83" cy="101" rx="4.5" ry="3.5" fill="#0d0d14"/>
      <ellipse cx="117" cy="101" rx="4.5" ry="3.5" fill="#0d0d14"/>
      {/* Specular dots */}
      <circle cx="86" cy="97" r="1.8" fill="rgba(255,255,255,0.75)"/>
      <circle cx="120" cy="97" r="1.8" fill="rgba(255,255,255,0.75)"/>
      {/* Grumpy brows */}
      <path d="M74 88 Q83 83 92 88" stroke="#4c4a62" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
      <path d="M108 88 Q117 83 126 88" stroke="#4c4a62" strokeWidth="2.2" fill="none" strokeLinecap="round"/>
      <path d="M91 86 L100 82 L109 86" stroke="#4c4a62" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
      {/* Nose */}
      <ellipse cx="100" cy="118" rx="4" ry="2.8" fill="#8a8480"/>
      {/* Grumpy mouth */}
      <path d="M89 128 Q94 124 100 125 Q106 124 111 128" stroke="#7a7470" strokeWidth="1.6" fill="none" strokeLinecap="round"/>
      <path d="M89 128 Q87 131 88 133" stroke="#7a7470" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
      <path d="M111 128 Q113 131 112 133" stroke="#7a7470" strokeWidth="1.5" fill="none" strokeLinecap="round"/>
    </svg>
  );
}

// ─── Momentum Ring ────────────────────────────────────────────────────────────
function MomentumRing({ value }: { value: number }) {
  const r = 36, cx = 46, cy = 46;
  const circ = 2 * Math.PI * r;
  const offset = circ - (value / 100) * circ;
  return (
    <svg width="92" height="92" viewBox="0 0 92 92">
      <defs>
        <linearGradient id="ringGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#ff8800"/>
          <stop offset="100%" stopColor="#f5c623"/>
        </linearGradient>
      </defs>
      <circle cx={cx} cy={cy} r={r} fill="none" stroke="rgba(255,255,255,0.07)" strokeWidth="7"/>
      <circle
        cx={cx} cy={cy} r={r} fill="none"
        stroke="url(#ringGrad)" strokeWidth="7" strokeLinecap="round"
        strokeDasharray={circ} strokeDashoffset={offset}
        transform={`rotate(-90 ${cx} ${cy})`}
        style={{ transition: "stroke-dashoffset 0.9s cubic-bezier(0.34,1.56,0.64,1)" }}
      />
      <text x={cx} y={cy + 7} textAnchor="middle" fill="white" fontSize="20" fontWeight="700" fontFamily="system-ui,-apple-system">{value}</text>
    </svg>
  );
}

// ─── Streak Dots ──────────────────────────────────────────────────────────────
function StreakDots({ streak }: { streak: number }) {
  return (
    <div style={{ display: "flex", gap: 4, marginTop: 5 }}>
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} style={{
          width: 7, height: 7, borderRadius: "50%",
          background: i < Math.min(streak, 8) ? "#f5a623" : "rgba(255,255,255,0.1)",
          transition: "background 0.3s ease",
        }}/>
      ))}
    </div>
  );
}

// ─── Task Row ─────────────────────────────────────────────────────────────────
function TaskRow({ task, onToggle }: { task: Task; onToggle: () => void }) {
  const [pressed, setPressed] = useState(false);
  const tc = TAG_COLORS[task.tag];
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 11, padding: "11px 0",
      opacity: task.done ? 0.55 : 1,
      transform: pressed ? "scale(0.97)" : "scale(1)",
      transition: "transform 0.15s ease, opacity 0.3s ease",
    }}
      onMouseDown={() => setPressed(true)} onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)} onTouchStart={() => setPressed(true)}
      onTouchEnd={() => setPressed(false)}
    >
      <button onClick={onToggle} style={{
        width: 25, height: 25, borderRadius: "50%", flexShrink: 0, padding: 0,
        border: task.done ? "none" : "1.5px solid rgba(255,255,255,0.2)",
        background: task.done ? "#34d399" : "transparent",
        display: "flex", alignItems: "center", justifyContent: "center",
        cursor: "pointer", transition: "all 0.25s ease",
      }}>
        {task.done && (
          <svg width="12" height="12" viewBox="0 0 12 12" fill="none">
            <path d="M2 6.5L5 9.5L10 3" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </button>
      <div style={{ width: 7, height: 7, borderRadius: "50%", flexShrink: 0, background: PRIORITY_COLORS[task.priority] }}/>
      <span style={{
        flex: 1, fontSize: 15, fontWeight: 500,
        color: task.done ? "rgba(255,255,255,0.35)" : "rgba(255,255,255,0.88)",
        textDecoration: task.done ? "line-through" : "none", transition: "all 0.3s ease",
      }}>{task.title}</span>
      {task.time && !task.done && (
        <span style={{ fontSize: 11, color: "rgba(255,255,255,0.3)", flexShrink: 0 }}>{task.time}</span>
      )}
      <span style={{
        fontSize: 11, fontWeight: 600, color: tc.text, background: tc.bg,
        padding: "3px 9px", borderRadius: 20, flexShrink: 0,
        border: `0.5px solid ${tc.text}44`,
      }}>{task.tag}</span>
    </div>
  );
}

// ─── Add Task Sheet ───────────────────────────────────────────────────────────
function AddTaskSheet({ open, onClose, onAdd }: {
  open: boolean; onClose: () => void; onAdd: (t: string, tag: Tag) => void;
}) {
  const [title, setTitle] = useState("");
  const [tag, setTag] = useState<Tag>("Work");
  const inputRef = useRef<HTMLInputElement>(null);
  useEffect(() => { if (open) { setTitle(""); setTimeout(() => inputRef.current?.focus(), 320); } }, [open]);
  const submit = () => { if (!title.trim()) return; onAdd(title.trim(), tag); onClose(); };
  return (
    <>
      <div onClick={onClose} style={{
        position: "fixed", inset: 0, background: "rgba(0,0,0,0.55)",
        backdropFilter: "blur(10px)", WebkitBackdropFilter: "blur(10px)",
        opacity: open ? 1 : 0, pointerEvents: open ? "all" : "none",
        transition: "opacity 0.3s ease", zIndex: 40,
      }}/>
      <div style={{
        position: "fixed", bottom: 0, left: 0, right: 0, zIndex: 50,
        background: "#1c1a2a", borderRadius: "22px 22px 0 0",
        padding: "0 20px 44px", border: "1px solid rgba(255,255,255,0.09)",
        boxShadow: "0 -12px 48px rgba(0,0,0,0.65)",
        transform: open ? "translateY(0)" : "translateY(108%)",
        transition: "transform 0.4s cubic-bezier(0.34,1.2,0.64,1)",
      }} onClick={e => e.stopPropagation()}>
        <div style={{ display: "flex", justifyContent: "center", padding: "13px 0 22px" }}>
          <div style={{ width: 38, height: 4, borderRadius: 2, background: "rgba(255,255,255,0.18)" }}/>
        </div>
        <p style={{ color: "rgba(255,255,255,0.92)", fontSize: 18, fontWeight: 700, margin: "0 0 18px" }}>New Task</p>
        <input
          ref={inputRef} value={title}
          onChange={e => setTitle(e.target.value.slice(0, 200))}
          onKeyDown={e => e.key === "Enter" && submit()}
          placeholder="Task title..."
          style={{
            width: "100%", padding: "14px 16px", fontSize: 16, color: "white",
            background: "rgba(255,255,255,0.07)", border: "1px solid rgba(255,255,255,0.1)",
            borderRadius: 14, outline: "none", boxSizing: "border-box", fontFamily: "inherit",
          }}
        />
        <div style={{ display: "flex", gap: 8, margin: "14px 0 18px" }}>
          {(["Work","Side","Learn"] as Tag[]).map(t => {
            const tc = TAG_COLORS[t]; const active = tag === t;
            return (
              <button key={t} onClick={() => setTag(t)} style={{
                padding: "8px 18px", borderRadius: 20, fontSize: 13, fontWeight: 600, cursor: "pointer",
                border: active ? `1px solid ${tc.text}` : "1px solid rgba(255,255,255,0.1)",
                background: active ? tc.bg : "transparent",
                color: active ? tc.text : "rgba(255,255,255,0.45)",
                transition: "all 0.2s ease",
              }}>{t}</button>
            );
          })}
        </div>
        <button onClick={submit} disabled={!title.trim()} style={{
          width: "100%", padding: "16px", borderRadius: 14, fontSize: 16, fontWeight: 700,
          color: "white", border: "none", cursor: title.trim() ? "pointer" : "not-allowed",
          background: title.trim() ? "linear-gradient(135deg,#ff7b2b,#ff3b30)" : "rgba(255,255,255,0.1)",
          transition: "all 0.25s ease", opacity: title.trim() ? 1 : 0.45,
        }}>Add Task</button>
      </div>
    </>
  );
}

// ─── Tab Icon ─────────────────────────────────────────────────────────────────
function TabIcon({ name, active }: { name: string; active: boolean }) {
  const c = active ? "#ff8800" : "rgba(255,255,255,0.5)";
  if (name === "sun") return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M2 12h2M20 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"/></svg>;
  if (name === "grid") return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round"><rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/></svg>;
  if (name === "target") return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>;
  return <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>;
}

// ─── Main App ─────────────────────────────────────────────────────────────────
export default function OpusApp() {
  const [tasks, setTasks]         = useState<Task[]>(SEED_TASKS);
  const [activeTab, setActiveTab] = useState<"today"|"projects"|"focus"|"profile">("today");
  const [showAdd, setShowAdd]     = useState(false);
  const [laterOpen, setLaterOpen] = useState(false);
  const [gearRot, setGearRot]     = useState(0);
  const [fabRot, setFabRot]       = useState(false);
  const [time, setTime]           = useState(new Date());
  const nextId = useRef(100);

  useEffect(() => { const t = setInterval(() => setTime(new Date()), 30000); return () => clearInterval(t); }, []);

  const todayTasks = tasks.filter(t => t.schedule === "today");
  const pending    = todayTasks.filter(t => !t.done);
  const done       = todayTasks.filter(t => t.done);
  const laterTasks = tasks.filter(t => t.schedule === "later");
  const streak     = 14;
  const momentum   = Math.min(100, Math.round(streak * 4 + (done.length / Math.max(todayTasks.length, 1)) * 28));
  const taskPct    = todayTasks.length > 0 ? done.length / todayTasks.length : 0;

  const toggle  = (id: number) => setTasks(ts => ts.map(t => t.id === id ? { ...t, done: !t.done } : t));
  const addTask = (title: string, tag: Tag) => {
    setTasks(ts => [...ts, { id: nextId.current++, title, tag, schedule: "today", done: false, priority: "mid" }]);
    setFabRot(false);
  };

  const h = time.getHours();
  const greeting  = h < 12 ? "Good morning." : h < 17 ? "Good afternoon." : "Good evening.";
  const dateLabel = time.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric" });
  const timeStr   = time.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });

  return (
    <div style={{
      position: "relative", width: "100%", height: "100%", background: "#0d0d14",
      fontFamily: "-apple-system,BlinkMacSystemFont,'SF Pro Display','Segoe UI',sans-serif",
      color: "white", display: "flex", flexDirection: "column", overflowX: "hidden",
    }}>
      {/* Scrollable content */}
      <div style={{ flex: 1, overflowY: "auto", paddingBottom: 130, WebkitOverflowScrolling: "touch" as never }}>

        {/* Status bar */}
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"12px 20px 4px" }}>
          <span style={{ background:"#1e3a2f", color:"#34d399", fontSize:13, fontWeight:700, padding:"3px 10px", borderRadius:20 }}>● {timeStr}</span>
          <div style={{ display:"flex", alignItems:"center", gap:5, fontSize:12, color:"rgba(255,255,255,0.45)" }}>
            <span>78%</span>
            <svg width="22" height="12" viewBox="0 0 22 12">
              <rect x=".5" y=".5" width="18" height="11" rx="2.5" stroke="rgba(255,255,255,0.35)" fill="none"/>
              <rect x="19" y="3.5" width="2.5" height="5" rx="1" fill="rgba(255,255,255,0.25)"/>
              <rect x="1.5" y="1.5" width="13" height="9" rx="1.5" fill="#34d399"/>
            </svg>
          </div>
        </div>

        {/* Header */}
        <div style={{ padding:"8px 20px 4px" }}>
          <p style={{ fontSize:13, color:"rgba(255,255,255,0.38)", fontWeight:500, margin:0 }}>{dateLabel}</p>
          <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginTop:4 }}>
            <h1 style={{ fontSize:28, fontWeight:700, letterSpacing:-0.5, lineHeight:1.1, margin:0 }}>{greeting}</h1>
            <button
              onClick={() => setGearRot(r => r + 30)}
              style={{
                width:38, height:38, borderRadius:"50%", background:"rgba(255,255,255,0.07)",
                border:"none", cursor:"pointer", display:"flex", alignItems:"center", justifyContent:"center",
                transform:`rotate(${gearRot}deg)`, transition:"transform 0.4s cubic-bezier(0.34,1.56,0.64,1)",
              }}
            >
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.45)" strokeWidth="1.8" strokeLinecap="round">
                <circle cx="12" cy="12" r="3"/>
                <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06A1.65 1.65 0 009 4.68a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z"/>
              </svg>
            </button>
          </div>
        </div>

        {/* Momentum card */}
        <div style={{
          margin:"16px 16px 0", borderRadius:20, padding:"18px 14px",
          background:"rgba(255,255,255,0.05)", backdropFilter:"blur(24px)", WebkitBackdropFilter:"blur(24px)",
          border:"1px solid rgba(255,255,255,0.09)",
          boxShadow:"0 4px 24px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.06)",
        }}>
          <div style={{ display:"flex", alignItems:"center" }}>
            {/* Momentum */}
            <div style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
              <MomentumRing value={momentum}/>
              <span style={{ fontSize:11, color:"rgba(255,255,255,0.38)", fontWeight:500 }}>Momentum</span>
            </div>
            <div style={{ width:1, height:60, background:"rgba(255,255,255,0.08)" }}/>
            {/* Streak */}
            <div style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
              <div style={{ display:"flex", alignItems:"baseline", gap:4 }}>
                <span style={{ fontSize:26, fontWeight:700 }}>{streak}</span>
                <span style={{ fontSize:22 }}>🔥</span>
              </div>
              <span style={{ fontSize:11, color:"rgba(255,255,255,0.38)", fontWeight:500 }}>day streak</span>
              <StreakDots streak={streak}/>
            </div>
            <div style={{ width:1, height:60, background:"rgba(255,255,255,0.08)" }}/>
            {/* Tasks */}
            <div style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
              <div style={{ display:"flex", alignItems:"baseline", gap:3 }}>
                <span style={{ fontSize:26, fontWeight:700 }}>{done.length}</span>
                <span style={{ fontSize:13, color:"rgba(255,255,255,0.38)" }}>of {todayTasks.length}</span>
              </div>
              <span style={{ fontSize:11, color:"rgba(255,255,255,0.38)", fontWeight:500 }}>today</span>
              <div style={{ width:"80%", height:4, borderRadius:2, background:"rgba(255,255,255,0.08)", overflow:"hidden" }}>
                <div style={{
                  height:"100%", borderRadius:2,
                  background:"linear-gradient(90deg,#ff5555,#ff3b30)",
                  width:`${taskPct*100}%`,
                  transition:"width 0.7s cubic-bezier(0.34,1.56,0.64,1)",
                }}/>
              </div>
            </div>
          </div>
        </div>

        {/* TODAY */}
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"20px 20px 8px" }}>
          <span style={{ fontSize:11, fontWeight:700, letterSpacing:1.4, color:"rgba(255,255,255,0.38)", textTransform:"uppercase" }}>Today</span>
          <span style={{ fontSize:12, color:"rgba(255,255,255,0.28)" }}>{pending.length} remaining</span>
        </div>
        <div style={{ margin:"0 16px", borderRadius:16, background:"rgba(255,255,255,0.03)", border:"1px solid rgba(255,255,255,0.06)", padding:"0 14px" }}>
          {pending.map((t, i) => (
            <div key={t.id}>
              <TaskRow task={t} onToggle={() => toggle(t.id)}/>
              {i < pending.length-1 && <div style={{ height:1, background:"rgba(255,255,255,0.06)" }}/>}
            </div>
          ))}
          {pending.length === 0 && <p style={{ textAlign:"center", padding:"20px 0", color:"rgba(255,255,255,0.22)", fontSize:14 }}>All done! 🎉</p>}
        </div>

        {/* DONE */}
        {done.length > 0 && (
          <>
            <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"18px 20px 8px" }}>
              <span style={{ fontSize:11, fontWeight:700, letterSpacing:1.4, color:"rgba(52,211,153,0.55)", textTransform:"uppercase" }}>Done</span>
              <span style={{ fontSize:11, fontWeight:600, color:"#34d399", background:"rgba(52,211,153,0.1)", padding:"2px 8px", borderRadius:20 }}>{done.length}</span>
            </div>
            <div style={{ margin:"0 16px", borderRadius:16, background:"rgba(52,211,153,0.03)", border:"1px solid rgba(52,211,153,0.1)", padding:"0 14px" }}>
              {done.map((t, i) => (
                <div key={t.id}>
                  <TaskRow task={t} onToggle={() => toggle(t.id)}/>
                  {i < done.length-1 && <div style={{ height:1, background:"rgba(255,255,255,0.06)" }}/>}
                </div>
              ))}
            </div>
          </>
        )}

        {/* LATER */}
        <div style={{ padding:"18px 20px 8px" }}>
          <button onClick={() => setLaterOpen(o => !o)} style={{
            display:"flex", alignItems:"center", gap:8, background:"none", border:"none", cursor:"pointer", padding:0,
          }}>
            <span style={{ fontSize:11, fontWeight:700, letterSpacing:1.4, color:"rgba(255,255,255,0.38)", textTransform:"uppercase" }}>Later</span>
            <span style={{ fontSize:11, color:"rgba(255,255,255,0.28)", background:"rgba(255,255,255,0.07)", padding:"2px 7px", borderRadius:10 }}>{laterTasks.length}</span>
            <svg width="12" height="12" viewBox="0 0 12 12" style={{ transition:"transform 0.3s ease", transform:laterOpen?"rotate(180deg)":"rotate(0deg)" }}>
              <path d="M2 4L6 8L10 4" stroke="rgba(255,255,255,0.3)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>
        </div>
        <div style={{ overflow:"hidden", maxHeight:laterOpen?500:0, transition:"max-height 0.4s cubic-bezier(0.4,0,0.2,1)", margin:"0 16px" }}>
          <div style={{ borderRadius:16, background:"rgba(255,255,255,0.03)", border:"1px solid rgba(255,255,255,0.06)", padding:"0 14px" }}>
            {laterTasks.map((t,i) => (
              <div key={t.id}>
                <TaskRow task={t} onToggle={() => toggle(t.id)}/>
                {i < laterTasks.length-1 && <div style={{ height:1, background:"rgba(255,255,255,0.06)" }}/>}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* FAB */}
      <button
        onClick={() => { setFabRot(r => !r); setShowAdd(true); }}
        style={{
          position:"fixed", bottom:82, left:"50%",
          transform:`translateX(-50%) rotate(${fabRot?45:0}deg)`,
          width:54, height:54, borderRadius:"50%", border:"none", cursor:"pointer",
          background:"linear-gradient(135deg,#ff7b2b,#ff3b30)",
          boxShadow:"0 4px 24px rgba(255,90,40,0.55)",
          display:"flex", alignItems:"center", justifyContent:"center", zIndex:31,
          transition:"transform 0.35s cubic-bezier(0.34,1.56,0.64,1)",
        }}
      >
        <svg width="22" height="22" viewBox="0 0 22 22" fill="none">
          <path d="M11 4V18M4 11H18" stroke="white" strokeWidth="2.5" strokeLinecap="round"/>
        </svg>
      </button>

      {/* Liquid glass dock */}
      <div style={{
        position:"fixed", bottom:16, left:14, right:14, zIndex:30,
        backdropFilter:"blur(40px) saturate(200%)", WebkitBackdropFilter:"blur(40px) saturate(200%)",
        background:"rgba(255,255,255,0.09)", border:"1px solid rgba(255,255,255,0.2)",
        boxShadow:"0 8px 32px rgba(0,0,0,0.55), inset 0 1.5px 0 rgba(255,255,255,0.28)",
        borderRadius:26, padding:"10px 6px 13px",
      }}>
        <div style={{ display:"flex", alignItems:"flex-end", justifyContent:"space-around" }}>
          {([
            { key:"today",    label:"Today",      icon:"sun" },
            { key:"projects", label:"Projects",   icon:"grid" },
            { key:"focus",    label:"Focus Mode", icon:"target" },
            { key:"profile",  label:"Profile",    icon:"person" },
          ] as const).map(tab => {
            const active = activeTab === tab.key;
            return (
              <button key={tab.key} onClick={() => setActiveTab(tab.key)} style={{
                flex:1, background:"none", border:"none", cursor:"pointer",
                display:"flex", flexDirection:"column", alignItems:"center", gap:3, padding:"3px 0",
                opacity:active?1:0.45, transition:"opacity 0.2s ease",
              }}>
                <TabIcon name={tab.icon} active={active}/>
                <span style={{ fontSize:10, fontWeight:active?600:400, color:active?"#ff8800":"rgba(255,255,255,0.55)" }}>{tab.label}</span>
                {active && <div style={{ width:5, height:5, borderRadius:"50%", background:"white", marginTop:-1 }}/>}
              </button>
            );
          })}
        </div>
      </div>

      <AddTaskSheet open={showAdd} onClose={() => { setShowAdd(false); setFabRot(false); }} onAdd={addTask}/>
    </div>
  );
}
