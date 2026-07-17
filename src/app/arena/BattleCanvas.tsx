"use client";

// Battle screen: hosts the engine's canvas, wires input (WASD/arrows +
// 1/2/3 or J/K/L on desktop, virtual joystick + tap buttons on touch),
// and renders the DOM HUD on top.

import { useEffect, useRef, useState } from "react";
import { Battle, type HudState, type MatchResult } from "./engine";
import type { Creature } from "./creatures";
import type { Board } from "./boards";

export interface BattleStats {
  kills: number;
  deaths: number;
  gold: number;
  level: number;
  time: number;
}

export default function BattleCanvas({
  playerCreature,
  enemyCreature,
  board,
  onEnd,
}: {
  playerCreature: Creature;
  enemyCreature: Creature;
  board: Board;
  onEnd: (result: Exclude<MatchResult, null>, stats: BattleStats) => void;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const miniRef = useRef<HTMLCanvasElement>(null);
  const battleRef = useRef<Battle | null>(null);
  const [hud, setHud] = useState<HudState | null>(null);
  const joyRef = useRef<{ id: number; sx: number; sy: number; dx: number; dy: number } | null>(
    null,
  );
  const [joyUi, setJoyUi] = useState<{ x: number; y: number; dx: number; dy: number } | null>(
    null,
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    const mini = miniRef.current;
    if (!canvas || !mini) return;
    const ctx = canvas.getContext("2d");
    const mctx = mini.getContext("2d");
    if (!ctx || !mctx) return;

    const battle = new Battle(playerCreature, enemyCreature, board);
    battleRef.current = battle;
    let ended = false;
    battle.onEnd = (r) => {
      if (ended) return;
      ended = true;
      const p = battle.player;
      const stats: BattleStats = {
        kills: p.kills,
        deaths: p.deaths,
        gold: p.gold,
        level: p.level,
        time: battle.t,
      };
      // linger so the final blow + banner land, then hand off
      window.setTimeout(() => onEnd(r, stats), 2200);
    };

    const keys = new Set<string>();
    const applyMove = () => {
      let mx = 0;
      let my = 0;
      if (keys.has("a") || keys.has("arrowleft")) mx -= 1;
      if (keys.has("d") || keys.has("arrowright")) mx += 1;
      if (keys.has("w") || keys.has("arrowup")) my -= 1;
      if (keys.has("s") || keys.has("arrowdown")) my += 1;
      const joy = joyRef.current;
      if (joy && (Math.abs(joy.dx) > 6 || Math.abs(joy.dy) > 6)) {
        mx = joy.dx / 52;
        my = joy.dy / 52;
        const l = Math.hypot(mx, my);
        if (l > 1) {
          mx /= l;
          my /= l;
        }
      }
      battle.setMove(mx, my);
    };

    const onKeyDown = (e: KeyboardEvent) => {
      const k = e.key.toLowerCase();
      if (["arrowup", "arrowdown", "arrowleft", "arrowright", " "].includes(k)) {
        e.preventDefault();
      }
      if (k === "1" || k === "j") battle.cast(0);
      if (k === "2" || k === "k") battle.cast(1);
      if (k === "3" || k === "l") battle.cast(2);
      keys.add(k);
      applyMove();
    };
    const onKeyUp = (e: KeyboardEvent) => {
      keys.delete(e.key.toLowerCase());
      applyMove();
    };
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);

    // touch joystick on the left 55% of the screen
    const onTouchStart = (e: TouchEvent) => {
      for (const t of Array.from(e.changedTouches)) {
        if (joyRef.current === null && t.clientX < window.innerWidth * 0.55) {
          joyRef.current = { id: t.identifier, sx: t.clientX, sy: t.clientY, dx: 0, dy: 0 };
          setJoyUi({ x: t.clientX, y: t.clientY, dx: 0, dy: 0 });
          e.preventDefault();
        }
      }
    };
    const onTouchMove = (e: TouchEvent) => {
      const joy = joyRef.current;
      if (!joy) return;
      for (const t of Array.from(e.changedTouches)) {
        if (t.identifier === joy.id) {
          const dx = t.clientX - joy.sx;
          const dy = t.clientY - joy.sy;
          const l = Math.hypot(dx, dy);
          const max = 52;
          joy.dx = l > max ? (dx / l) * max : dx;
          joy.dy = l > max ? (dy / l) * max : dy;
          setJoyUi({ x: joy.sx, y: joy.sy, dx: joy.dx, dy: joy.dy });
          applyMove();
          e.preventDefault();
        }
      }
    };
    const onTouchEnd = (e: TouchEvent) => {
      const joy = joyRef.current;
      if (!joy) return;
      for (const t of Array.from(e.changedTouches)) {
        if (t.identifier === joy.id) {
          joyRef.current = null;
          setJoyUi(null);
          applyMove();
        }
      }
    };
    canvas.addEventListener("touchstart", onTouchStart, { passive: false });
    canvas.addEventListener("touchmove", onTouchMove, { passive: false });
    canvas.addEventListener("touchend", onTouchEnd);
    canvas.addEventListener("touchcancel", onTouchEnd);

    const dpr = Math.min(2, window.devicePixelRatio || 1);
    let vw = 0;
    let vh = 0;
    const resize = () => {
      vw = canvas.clientWidth;
      vh = canvas.clientHeight;
      canvas.width = Math.round(vw * dpr);
      canvas.height = Math.round(vh * dpr);
      mini.width = 150 * dpr;
      mini.height = 120 * dpr;
    };
    resize();
    window.addEventListener("resize", resize);

    let raf = 0;
    let last = performance.now();
    let hudAcc = 0;
    const loop = (now: number) => {
      const dt = Math.min(0.05, (now - last) / 1000);
      last = now;
      battle.update(dt);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      battle.draw(ctx, vw, vh);
      mctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      battle.drawMinimap(mctx, 150, 120);
      hudAcc += dt;
      if (hudAcc > 0.1) {
        hudAcc = 0;
        setHud(battle.hud());
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("keydown", onKeyDown);
      window.removeEventListener("keyup", onKeyUp);
      window.removeEventListener("resize", resize);
      canvas.removeEventListener("touchstart", onTouchStart);
      canvas.removeEventListener("touchmove", onTouchMove);
      canvas.removeEventListener("touchend", onTouchEnd);
      canvas.removeEventListener("touchcancel", onTouchEnd);
    };
  }, [playerCreature, enemyCreature, board, onEnd]);

  const abilities = playerCreature.abilities;

  return (
    <div className="fixed inset-0 bg-[#101010] select-none touch-none overflow-hidden">
      <canvas ref={canvasRef} className="w-full h-full block" />

      {/* top bar: score + timer */}
      {hud && (
        <div className="absolute top-2 left-1/2 -translate-x-1/2 flex items-center gap-3 rounded-xl bg-black/55 backdrop-blur px-4 py-1.5 border border-white/10">
          <span className="text-[#7db2ff] font-bold text-lg tabular-nums">{hud.kills.blue}</span>
          <span className="text-white/40 text-xs">⚔</span>
          <span className="text-white font-semibold tabular-nums text-sm">
            {fmtTime(hud.time)}
          </span>
          <span className="text-white/40 text-xs">⚔</span>
          <span className="text-[#ff9a8f] font-bold text-lg tabular-nums">{hud.kills.red}</span>
        </div>
      )}

      {/* objectives strip */}
      {hud && (
        <div className="absolute top-14 left-1/2 -translate-x-1/2 flex items-center gap-4 text-[11px] text-white/70">
          <span>
            🏰 <span className="text-[#7db2ff]">{hud.towersLeft.blue}</span> ·{" "}
            <span className="text-[#7db2ff]">{Math.round(hud.coreHp.blue)}</span>
          </span>
          <span>
            <span className="text-[#ff9a8f]">{Math.round(hud.coreHp.red)}</span> ·{" "}
            <span className="text-[#ff9a8f]">{hud.towersLeft.red}</span> 🏰
          </span>
        </div>
      )}

      {/* minimap */}
      <div className="absolute top-2 left-2 rounded-lg overflow-hidden border border-white/15 bg-black/40">
        <canvas ref={miniRef} style={{ width: 150, height: 120 }} />
      </div>

      {/* death overlay */}
      {hud?.dead && !hud.result && (
        <div className="absolute inset-0 bg-red-950/40 flex items-center justify-center pointer-events-none">
          <div className="text-center">
            <div className="text-4xl font-black text-white/90 drop-shadow">DEFEATED</div>
            <div className="mt-2 text-white/80">
              Respawning in{" "}
              <span className="font-bold text-amber-300">{Math.ceil(hud.respawnIn)}</span>…
            </div>
          </div>
        </div>
      )}

      {/* bottom HUD */}
      {hud && (
        <div className="absolute bottom-0 inset-x-0 flex items-end justify-between p-3 sm:p-4 gap-3 pointer-events-none">
          {/* portrait + bars */}
          <div className="flex items-center gap-3 rounded-2xl bg-black/55 backdrop-blur border border-white/10 p-2.5 pr-4 min-w-0">
            <div
              className="w-14 h-14 sm:w-16 sm:h-16 shrink-0 rounded-xl border-2 p-0.5 bg-[#1c1c24]"
              style={{ borderColor: playerCreature.color }}
              dangerouslySetInnerHTML={{ __html: playerCreature.svg }}
            />
            <div className="w-36 sm:w-48">
              <div className="flex justify-between text-[11px] text-white/80 mb-0.5">
                <span className="font-bold">{playerCreature.name}</span>
                <span>
                  Lv <b className="text-amber-300">{hud.level}</b>
                </span>
              </div>
              <div className="h-3 rounded-full bg-black/60 overflow-hidden border border-white/10">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-emerald-500 to-lime-400 transition-[width] duration-150"
                  style={{ width: `${(hud.hp / hud.maxHp) * 100}%` }}
                />
              </div>
              <div className="flex justify-between text-[10px] text-white/60 mt-0.5">
                <span className="tabular-nums">
                  {hud.hp}/{hud.maxHp}
                  {hud.shield > 0 && <span className="text-sky-300"> +{hud.shield}</span>}
                </span>
                <span className="text-amber-300 tabular-nums">◉ {hud.gold}</span>
              </div>
              <div className="h-1.5 rounded-full bg-black/60 overflow-hidden mt-1">
                <div
                  className="h-full bg-violet-400"
                  style={{ width: `${(hud.xp / hud.xpNext) * 100}%` }}
                />
              </div>
            </div>
          </div>

          {/* abilities */}
          <div className="flex gap-2.5 pointer-events-auto">
            {abilities.map((a, i) => {
              const cd = hud.cds[i];
              const frac = hud.cdMax[i] > 0 ? cd / hud.cdMax[i] : 0;
              return (
                <button
                  key={a.name}
                  aria-label={a.name}
                  onPointerDown={(e) => {
                    e.preventDefault();
                    battleRef.current?.cast(i as 0 | 1 | 2);
                  }}
                  className="relative w-14 h-14 sm:w-16 sm:h-16 rounded-2xl border-2 bg-black/60 backdrop-blur overflow-hidden active:scale-95 transition-transform"
                  style={{ borderColor: cd > 0 ? "#ffffff22" : a.color }}
                >
                  <div
                    className="absolute inset-0"
                    style={{ background: `radial-gradient(circle at 35% 30%, ${a.color}66, ${a.color}22)` }}
                  />
                  <span className="absolute inset-0 flex items-center justify-center text-xl font-black text-white drop-shadow">
                    {cd > 0 ? Math.ceil(cd) : i + 1}
                  </span>
                  {cd > 0 && (
                    <div
                      className="absolute inset-x-0 bottom-0 bg-black/70"
                      style={{ height: `${frac * 100}%` }}
                    />
                  )}
                  <span className="absolute bottom-0.5 inset-x-0 text-center text-[8px] font-semibold text-white/85 leading-none truncate px-1">
                    {a.name}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      )}

      {/* virtual joystick */}
      {joyUi && (
        <div
          className="absolute pointer-events-none"
          style={{ left: joyUi.x - 52, top: joyUi.y - 52 }}
        >
          <div className="w-[104px] h-[104px] rounded-full border-2 border-white/25 bg-white/5" />
          <div
            className="absolute w-12 h-12 rounded-full bg-white/30 border border-white/40"
            style={{ left: 28 + joyUi.dx, top: 28 + joyUi.dy }}
          />
        </div>
      )}

      {/* controls hint */}
      <div className="absolute bottom-24 sm:bottom-2 left-1/2 -translate-x-1/2 text-[10px] text-white/35 pointer-events-none hidden md:block">
        WASD / arrows to move · 1 2 3 (or J K L) for abilities · attacks are automatic
      </div>
    </div>
  );
}

function fmtTime(t: number): string {
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}
