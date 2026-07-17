"use client";

// Creature Arena: screen flow — title → pick creature → pick board → battle → result.

import { useCallback, useMemo, useState } from "react";
import Link from "next/link";
import {
  CREATURES,
  CreatureArt,
  TYPE_COLORS,
  type Creature,
} from "./creatures";
import { BOARDS, type Board } from "./boards";
import BattleCanvas, { type BattleStats } from "./BattleCanvas";

type Screen = "title" | "select" | "board" | "battle" | "result";

const STAT_MAX = { hp: 1000, atk: 80, def: 0.25, speed: 250, range: 250 };

export default function ArenaGame() {
  const [screen, setScreen] = useState<Screen>("title");
  const [picked, setPicked] = useState<Creature>(CREATURES[0]);
  const [boardId, setBoardId] = useState<string>(BOARDS[0].id);
  const [rival, setRival] = useState<Creature | null>(null);
  const [lastResult, setLastResult] = useState<"victory" | "defeat">("victory");
  const [stats, setStats] = useState<BattleStats | null>(null);
  const [battleKey, setBattleKey] = useState(0);

  const board: Board = useMemo(
    () => BOARDS.find((b) => b.id === boardId) ?? BOARDS[0],
    [boardId],
  );

  const rollRival = useCallback((exclude: string) => {
    const pool = CREATURES.filter((c) => c.id !== exclude);
    return pool[Math.floor(Math.random() * pool.length)];
  }, []);

  const startBattle = () => {
    setRival((r) => r ?? rollRival(picked.id));
    setBattleKey((k) => k + 1);
    setScreen("battle");
  };

  const handleEnd = useCallback(
    (result: "victory" | "defeat", s: BattleStats) => {
      setLastResult(result);
      setStats(s);
      setScreen("result");
    },
    [],
  );

  if (screen === "battle" && rival) {
    return (
      <BattleCanvas
        key={battleKey}
        playerCreature={picked}
        enemyCreature={rival}
        board={board}
        onEnd={handleEnd}
      />
    );
  }

  return (
    <div className="min-h-screen bg-[#141414] text-[#D4D4D4] flex flex-col">
      <div className="mx-auto w-full max-w-5xl px-4 py-6 flex-1 flex flex-col">
        {/* header */}
        <header className="flex items-center justify-between mb-6">
          <Link href="/" className="text-xs text-[#7A7A7A] hover:text-[#DA7756] transition-colors">
            ← hector.dev
          </Link>
          <div className="text-center">
            <h1 className="text-2xl sm:text-3xl font-black tracking-tight">
              <span className="text-[#DA7756]">CREATURE</span> ARENA
            </h1>
          </div>
          <div className="w-16" />
        </header>

        {screen === "title" && (
          <TitleScreen onPlay={() => setScreen("select")} />
        )}

        {screen === "select" && (
          <SelectScreen
            picked={picked}
            onPick={setPicked}
            onBack={() => setScreen("title")}
            onNext={() => {
              setRival(rollRival(picked.id));
              setScreen("board");
            }}
          />
        )}

        {screen === "board" && rival && (
          <BoardScreen
            boardId={boardId}
            onPickBoard={setBoardId}
            picked={picked}
            rival={rival}
            onRerollRival={() => setRival(rollRival(picked.id))}
            onBack={() => setScreen("select")}
            onFight={startBattle}
          />
        )}

        {screen === "result" && stats && (
          <ResultScreen
            result={lastResult}
            stats={stats}
            picked={picked}
            rival={rival}
            board={board}
            onRematch={() => {
              setBattleKey((k) => k + 1);
              setScreen("battle");
            }}
            onNewFight={() => setScreen("select")}
          />
        )}
      </div>
    </div>
  );
}

/* ── title ──────────────────────────────────────────────────────── */

function TitleScreen({ onPlay }: { onPlay: () => void }) {
  return (
    <div className="flex-1 flex flex-col items-center justify-center text-center gap-8 py-8">
      <div className="flex -space-x-6 sm:-space-x-4">
        {CREATURES.slice(0, 5).map((c, i) => (
          <div
            key={c.id}
            className="w-20 h-20 sm:w-28 sm:h-28 drop-shadow-xl"
            style={{
              transform: `rotate(${(i - 2) * 7}deg) translateY(${Math.abs(i - 2) * 8}px)`,
              zIndex: 5 - Math.abs(i - 2),
            }}
          >
            <CreatureArt creature={c} />
          </div>
        ))}
      </div>
      <div>
        <p className="text-lg sm:text-xl text-white/85 font-semibold">
          Pick your creature. Pick your board. Break their crystal.
        </p>
        <p className="mt-2 text-sm text-[#7A7A7A] max-w-md mx-auto">
          A pocket-sized MOBA: push the lane with your minions, topple towers,
          out-duel a rival creature, and destroy the enemy core.
        </p>
      </div>
      <button
        onClick={onPlay}
        className="px-10 py-4 rounded-2xl bg-[#DA7756] hover:bg-[#C4614A] text-[#141414] text-lg font-black tracking-wide transition-colors shadow-[0_0_40px_rgba(218,119,86,0.35)]"
      >
        PLAY
      </button>
      <div className="text-[11px] text-[#7A7A7A] space-y-1">
        <p>🖥 WASD / arrows to move · 1 2 3 for abilities</p>
        <p>📱 left thumb to move · tap ability buttons</p>
        <p>Attacks fire automatically at the nearest enemy.</p>
      </div>
    </div>
  );
}

/* ── character select ───────────────────────────────────────────── */

function SelectScreen({
  picked,
  onPick,
  onBack,
  onNext,
}: {
  picked: Creature;
  onPick: (c: Creature) => void;
  onBack: () => void;
  onNext: () => void;
}) {
  return (
    <div className="flex-1 flex flex-col gap-5">
      <h2 className="text-center text-sm uppercase tracking-[0.3em] text-[#7A7A7A]">
        Choose your creature
      </h2>
      <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-7 gap-2.5">
        {CREATURES.map((c) => {
          const active = picked.id === c.id;
          return (
            <button
              key={c.id}
              onClick={() => onPick(c)}
              className={`group relative rounded-2xl border-2 p-2 pb-1 transition-all bg-[#1C1C1C] hover:-translate-y-0.5 ${
                active ? "shadow-lg" : "border-[#282828] hover:border-[#3a3a3a]"
              }`}
              style={active ? { borderColor: c.color, boxShadow: `0 0 24px ${c.color}44` } : undefined}
            >
              <CreatureArt creature={c} className="w-full aspect-square" />
              <div className="mt-1 text-[11px] font-bold text-white/90 truncate">{c.name}</div>
              <div
                className="text-[9px] font-semibold uppercase tracking-wide"
                style={{ color: TYPE_COLORS[c.type] }}
              >
                {c.type}
              </div>
            </button>
          );
        })}
      </div>

      {/* detail panel */}
      <div className="rounded-2xl border border-[#282828] bg-[#1C1C1C] p-4 sm:p-5 grid sm:grid-cols-[9rem_1fr_1fr] gap-4 items-center">
        <div
          className="w-28 h-28 sm:w-36 sm:h-36 mx-auto rounded-2xl p-2"
          style={{ background: `radial-gradient(circle at 40% 30%, ${picked.color}33, transparent 70%)` }}
        >
          <CreatureArt creature={picked} />
        </div>
        <div>
          <div className="flex items-baseline gap-2 flex-wrap">
            <h3 className="text-xl font-black text-white">{picked.name}</h3>
            <span className="text-xs text-[#7A7A7A]">{picked.species}</span>
          </div>
          <div className="mt-1 flex gap-2">
            <Badge color={TYPE_COLORS[picked.type]}>{picked.type}</Badge>
            <Badge color="#8d8896">{picked.role}</Badge>
          </div>
          <p className="mt-2 text-xs text-[#9a9a9a] leading-relaxed">{picked.flavor}</p>
          <div className="mt-3 space-y-1.5">
            <StatBar label="HP" value={picked.stats.hp / STAT_MAX.hp} color="#5fdc78" />
            <StatBar label="ATK" value={picked.stats.atk / STAT_MAX.atk} color="#ff8a3d" />
            <StatBar label="DEF" value={picked.stats.def / STAT_MAX.def} color="#7db2ff" />
            <StatBar label="SPD" value={picked.stats.speed / STAT_MAX.speed} color="#ffd94f" />
            <StatBar label="RNG" value={picked.stats.range / STAT_MAX.range} color="#b895ec" />
          </div>
        </div>
        <div className="space-y-2">
          {picked.abilities.map((a, i) => (
            <div
              key={a.name}
              className="rounded-xl bg-[#141414] border border-[#282828] p-2.5 flex gap-2.5 items-start"
            >
              <span
                className="mt-0.5 w-6 h-6 shrink-0 rounded-lg flex items-center justify-center text-[11px] font-black text-[#141414]"
                style={{ background: a.color }}
              >
                {i + 1}
              </span>
              <div className="min-w-0">
                <div className="flex items-baseline gap-2">
                  <span className="text-xs font-bold text-white/90">{a.name}</span>
                  <span className="text-[10px] text-[#7A7A7A]">{a.cd}s</span>
                </div>
                <p className="text-[10px] text-[#9a9a9a] leading-snug">{a.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex justify-between">
        <NavBtn onClick={onBack}>← Back</NavBtn>
        <button
          onClick={onNext}
          className="px-8 py-3 rounded-xl bg-[#DA7756] hover:bg-[#C4614A] text-[#141414] font-black transition-colors"
        >
          Choose board →
        </button>
      </div>
    </div>
  );
}

/* ── board select ───────────────────────────────────────────────── */

function BoardScreen({
  boardId,
  onPickBoard,
  picked,
  rival,
  onRerollRival,
  onBack,
  onFight,
}: {
  boardId: string;
  onPickBoard: (id: string) => void;
  picked: Creature;
  rival: Creature;
  onRerollRival: () => void;
  onBack: () => void;
  onFight: () => void;
}) {
  return (
    <div className="flex-1 flex flex-col gap-5">
      <h2 className="text-center text-sm uppercase tracking-[0.3em] text-[#7A7A7A]">
        Choose the battle board
      </h2>
      <div className="grid sm:grid-cols-3 gap-3">
        {BOARDS.map((b) => {
          const active = b.id === boardId;
          return (
            <button
              key={b.id}
              onClick={() => onPickBoard(b.id)}
              className={`text-left rounded-2xl border-2 overflow-hidden bg-[#1C1C1C] transition-all hover:-translate-y-0.5 ${
                active ? "border-[#DA7756] shadow-[0_0_24px_rgba(218,119,86,0.25)]" : "border-[#282828]"
              }`}
            >
              <BoardPreview board={b} />
              <div className="p-3">
                <div className="font-black text-white">{b.name}</div>
                <div className="text-[10px] uppercase tracking-wide text-[#DA7756] font-bold">
                  {b.subtitle}
                </div>
                <p className="mt-1.5 text-[11px] text-[#9a9a9a] leading-snug">{b.desc}</p>
                <div className="mt-2 flex gap-3 text-[10px] text-[#7A7A7A]">
                  <span>🏰 {b.towersPerSide}× towers</span>
                  <span>💎 {b.coreHp} core HP</span>
                </div>
              </div>
            </button>
          );
        })}
      </div>

      {/* matchup */}
      <div className="rounded-2xl border border-[#282828] bg-[#1C1C1C] p-4 flex items-center justify-center gap-4 sm:gap-8">
        <div className="text-center">
          <CreatureArt creature={picked} className="w-20 h-20 mx-auto" />
          <div className="text-xs font-bold text-[#7db2ff]">{picked.name}</div>
        </div>
        <div className="text-2xl font-black text-[#DA7756]">VS</div>
        <div className="text-center">
          <CreatureArt creature={rival} className="w-20 h-20 mx-auto" />
          <div className="text-xs font-bold text-[#ff9a8f]">{rival.name}</div>
          <button
            onClick={onRerollRival}
            className="mt-1 text-[10px] text-[#7A7A7A] hover:text-[#DA7756] transition-colors"
          >
            ↻ reroll rival
          </button>
        </div>
      </div>

      <div className="flex justify-between">
        <NavBtn onClick={onBack}>← Back</NavBtn>
        <button
          onClick={onFight}
          className="px-10 py-3 rounded-xl bg-[#DA7756] hover:bg-[#C4614A] text-[#141414] font-black text-lg transition-colors shadow-[0_0_32px_rgba(218,119,86,0.35)]"
        >
          FIGHT!
        </button>
      </div>
    </div>
  );
}

function BoardPreview({ board }: { board: Board }) {
  const { w, h } = board.world;
  const pts = board.lane.map((p) => `${(p.x / w) * 100},${(p.y / h) * 60}`).join(" ");
  return (
    <div className="h-24 relative" style={{ background: board.previewColors[0] }}>
      <svg viewBox="0 0 100 60" className="absolute inset-0 w-full h-full" preserveAspectRatio="none">
        <polyline
          points={pts}
          fill="none"
          stroke={board.previewColors[1]}
          strokeWidth="7"
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity="0.9"
        />
        <circle cx={(board.lane[0].x / w) * 100} cy={(board.lane[0].y / h) * 60} r="4" fill="#4f8fe8" />
        <circle
          cx={(board.lane[board.lane.length - 1].x / w) * 100}
          cy={(board.lane[board.lane.length - 1].y / h) * 60}
          r="4"
          fill="#e85a4f"
        />
        {[...Array(14)].map((_, i) => (
          <circle
            key={i}
            cx={(i * 37 + 13) % 100}
            cy={(i * 23 + 7) % 60}
            r="1.6"
            fill={board.previewColors[2]}
            opacity="0.8"
          />
        ))}
      </svg>
    </div>
  );
}

/* ── result ─────────────────────────────────────────────────────── */

function ResultScreen({
  result,
  stats,
  picked,
  rival,
  board,
  onRematch,
  onNewFight,
}: {
  result: "victory" | "defeat";
  stats: BattleStats;
  picked: Creature;
  rival: Creature | null;
  board: Board;
  onRematch: () => void;
  onNewFight: () => void;
}) {
  const won = result === "victory";
  return (
    <div className="flex-1 flex flex-col items-center justify-center gap-6 text-center py-8">
      <div
        className={`text-5xl sm:text-6xl font-black tracking-tight ${
          won ? "text-[#ffd76e]" : "text-[#ff8f86]"
        }`}
        style={{ textShadow: won ? "0 0 40px rgba(255,215,110,0.4)" : "0 0 40px rgba(255,80,70,0.35)" }}
      >
        {won ? "VICTORY!" : "DEFEAT"}
      </div>
      <p className="text-sm text-[#9a9a9a] -mt-3">
        {picked.name} {won ? "shattered" : "fell to"} {rival?.name ?? "the rival"} on {board.name}
      </p>
      <div className={`w-32 h-32 ${won ? "" : "grayscale opacity-70"}`}>
        <CreatureArt creature={picked} />
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-2 w-full max-w-lg">
        <StatCard label="Kills" value={String(stats.kills)} />
        <StatCard label="Deaths" value={String(stats.deaths)} />
        <StatCard label="Level" value={String(stats.level)} />
        <StatCard label="Gold" value={String(stats.gold)} />
        <StatCard label="Time" value={`${Math.floor(stats.time / 60)}:${String(Math.floor(stats.time % 60)).padStart(2, "0")}`} />
      </div>
      <div className="flex gap-3 flex-wrap justify-center">
        <button
          onClick={onRematch}
          className="px-8 py-3 rounded-xl bg-[#DA7756] hover:bg-[#C4614A] text-[#141414] font-black transition-colors"
        >
          Rematch
        </button>
        <NavBtn onClick={onNewFight}>New creature / board</NavBtn>
      </div>
    </div>
  );
}

/* ── bits ───────────────────────────────────────────────────────── */

function Badge({ color, children }: { color: string; children: React.ReactNode }) {
  return (
    <span
      className="px-2 py-0.5 rounded-md text-[10px] font-black uppercase tracking-wide text-[#141414]"
      style={{ background: color }}
    >
      {children}
    </span>
  );
}

function StatBar({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-8 text-[9px] font-bold text-[#7A7A7A]">{label}</span>
      <div className="flex-1 h-1.5 rounded-full bg-[#141414] overflow-hidden">
        <div
          className="h-full rounded-full"
          style={{ width: `${Math.min(100, value * 100)}%`, background: color }}
        />
      </div>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl bg-[#1C1C1C] border border-[#282828] px-3 py-2.5">
      <div className="text-lg font-black text-white tabular-nums">{value}</div>
      <div className="text-[9px] uppercase tracking-wider text-[#7A7A7A]">{label}</div>
    </div>
  );
}

function NavBtn({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      onClick={onClick}
      className="px-5 py-3 rounded-xl border border-[#282828] hover:border-[#DA7756] text-sm text-[#9a9a9a] hover:text-[#DA7756] font-bold transition-colors"
    >
      {children}
    </button>
  );
}
