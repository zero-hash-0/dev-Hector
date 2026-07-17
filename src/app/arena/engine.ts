// Creature Arena battle engine: a self-contained top-down MOBA-lite sim
// rendered to canvas. Lanes, towers, minion waves, abilities, AI hero,
// minimap, particles, floating combat text, streak banners.

import type { AbilityDef, Creature } from "./creatures";
import { svgDataUri } from "./creatures";
import type { Board, Decor } from "./boards";

export type Team = "blue" | "red";
export type MatchResult = "victory" | "defeat" | null;

const TEAM_COLOR: Record<Team, string> = { blue: "#4f8fe8", red: "#e85a4f" };

interface UnitBase {
  id: number;
  team: Team;
  kind: "hero" | "minion" | "tower" | "core";
  x: number;
  y: number;
  radius: number;
  hp: number;
  maxHp: number;
  dead: boolean;
  lastHitAt: number;
  atkCd: number;
}

export interface Hero extends UnitBase {
  kind: "hero";
  creature: Creature;
  level: number;
  xp: number;
  xpNext: number;
  gold: number;
  kills: number;
  deaths: number;
  streak: number;
  atk: number;
  def: number;
  speed: number;
  range: number;
  atkSpd: number;
  facing: number; // -1 | 1
  mx: number;
  my: number;
  cds: [number, number, number];
  shieldHp: number;
  shieldUntil: number;
  buffMult: number;
  buffUntil: number;
  slowAmt: number;
  slowUntil: number;
  snaredUntil: number;
  respawnAt: number;
  bob: number;
  regenDelay: number;
}

interface Minion extends UnitBase {
  kind: "minion";
  wp: number; // next waypoint index (along its direction)
  atk: number;
  speed: number;
}

interface Structure extends UnitBase {
  kind: "tower" | "core";
  atk: number;
  range: number;
}

type Unit = Hero | Minion | Structure;

interface Projectile {
  x: number;
  y: number;
  vx: number;
  vy: number;
  speed: number;
  team: Team;
  dmg: number;
  color: string;
  target: Unit | null; // homing when set
  maxDist: number;
  traveled: number;
  radius: number; // visual size
  aoe: number; // explosion radius (0 = single target)
  pierce: boolean;
  hitIds: Set<number>;
  slow?: { amt: number; dur: number };
  dead: boolean;
}

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  color: string;
  ring?: boolean;
  ringTo?: number;
}

interface FloatText {
  x: number;
  y: number;
  text: string;
  color: string;
  life: number;
  maxLife: number;
  big?: boolean;
}

interface Banner {
  text: string;
  sub?: string;
  color: string;
  life: number;
  maxLife: number;
}

export interface HudState {
  hp: number;
  maxHp: number;
  shield: number;
  level: number;
  xp: number;
  xpNext: number;
  gold: number;
  cds: [number, number, number];
  cdMax: [number, number, number];
  kills: { blue: number; red: number };
  time: number;
  dead: boolean;
  respawnIn: number;
  result: MatchResult;
  towersLeft: { blue: number; red: number };
  coreHp: { blue: number; red: number };
}

const STREAK_BANNERS: Record<number, string> = {
  3: "KILLING SPREE",
  5: "RAMPAGE",
  7: "UNSTOPPABLE",
  9: "LEGENDARY",
};

let nextId = 1;

export class Battle {
  board: Board;
  player: Hero;
  enemy: Hero;
  units: Unit[] = [];
  projectiles: Projectile[] = [];
  particles: Particle[] = [];
  texts: FloatText[] = [];
  banner: Banner | null = null;
  t = 0;
  result: MatchResult = null;
  shake = 0;
  private waveTimer = 3;
  private wave = 0;
  private aiThink = 0;
  private images: Record<string, HTMLImageElement> = {};
  private laneLen: number[] = [];
  private laneTotal = 0;
  onEnd: ((r: Exclude<MatchResult, null>) => void) | null = null;

  constructor(playerCreature: Creature, enemyCreature: Creature, board: Board) {
    this.board = board;
    // lane arc-lengths for placing structures at fractions of the lane
    for (let i = 0; i < board.lane.length - 1; i++) {
      const a = board.lane[i];
      const b = board.lane[i + 1];
      const l = Math.hypot(b.x - a.x, b.y - a.y);
      this.laneLen.push(l);
      this.laneTotal += l;
    }

    const bluePos = this.lanePoint(0.04);
    const redPos = this.lanePoint(0.96);
    this.player = this.makeHero(playerCreature, "blue", bluePos.x, bluePos.y);
    this.enemy = this.makeHero(enemyCreature, "red", redPos.x, redPos.y);
    this.units.push(this.player, this.enemy);

    // cores
    const blueCore = this.lanePoint(0.015);
    const redCore = this.lanePoint(0.985);
    this.units.push(
      this.makeStructure("core", "blue", blueCore.x, blueCore.y, board.coreHp, 0, 0),
      this.makeStructure("core", "red", redCore.x, redCore.y, board.coreHp, 0, 0),
    );
    // towers
    const fracs =
      board.towersPerSide === 1 ? [0.24] : [0.18, 0.34];
    for (const f of fracs) {
      const bp = this.lanePoint(f);
      const rp = this.lanePoint(1 - f);
      this.units.push(
        this.makeStructure("tower", "blue", bp.x, bp.y, board.towerHp, 48, 250),
        this.makeStructure("tower", "red", rp.x, rp.y, board.towerHp, 48, 250),
      );
    }

    for (const c of [playerCreature, enemyCreature]) {
      if (typeof window !== "undefined" && !this.images[c.id]) {
        const img = new Image();
        img.src = svgDataUri(c.svg);
        this.images[c.id] = img;
      }
    }
  }

  /* ── setup helpers ─────────────────────────────────────────────── */

  private makeHero(c: Creature, team: Team, x: number, y: number): Hero {
    return {
      id: nextId++,
      team,
      kind: "hero",
      x,
      y,
      radius: 30,
      hp: c.stats.hp,
      maxHp: c.stats.hp,
      dead: false,
      lastHitAt: -99,
      atkCd: 0,
      creature: c,
      level: 1,
      xp: 0,
      xpNext: 100,
      gold: 0,
      kills: 0,
      deaths: 0,
      streak: 0,
      atk: c.stats.atk,
      def: c.stats.def,
      speed: c.stats.speed,
      range: c.stats.range,
      atkSpd: c.stats.atkSpd,
      facing: team === "blue" ? 1 : -1,
      mx: 0,
      my: 0,
      cds: [0, 0, 0],
      shieldHp: 0,
      shieldUntil: 0,
      buffMult: 1,
      buffUntil: 0,
      slowAmt: 0,
      slowUntil: 0,
      snaredUntil: 0,
      respawnAt: 0,
      bob: 0,
      regenDelay: 0,
    };
  }

  private makeStructure(
    kind: "tower" | "core",
    team: Team,
    x: number,
    y: number,
    hp: number,
    atk: number,
    range: number,
  ): Structure {
    return {
      id: nextId++,
      team,
      kind,
      x,
      y,
      radius: kind === "core" ? 46 : 36,
      hp,
      maxHp: hp,
      dead: false,
      lastHitAt: -99,
      atkCd: 0,
      atk,
      range,
    };
  }

  lanePoint(frac: number): { x: number; y: number } {
    let d = frac * this.laneTotal;
    for (let i = 0; i < this.laneLen.length; i++) {
      if (d <= this.laneLen[i]) {
        const a = this.board.lane[i];
        const b = this.board.lane[i + 1];
        const t = this.laneLen[i] === 0 ? 0 : d / this.laneLen[i];
        return { x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t };
      }
      d -= this.laneLen[i];
    }
    return { ...this.board.lane[this.board.lane.length - 1] };
  }

  /* ── public input ──────────────────────────────────────────────── */

  setMove(mx: number, my: number) {
    this.player.mx = mx;
    this.player.my = my;
  }

  cast(i: 0 | 1 | 2) {
    this.castAbility(this.player, i);
  }

  /* ── core loop ─────────────────────────────────────────────────── */

  update(dt: number) {
    dt = Math.min(dt, 0.05);
    this.t += dt;
    if (this.shake > 0) this.shake = Math.max(0, this.shake - dt * 30);

    if (this.result === null) {
      this.waveTimer -= dt;
      if (this.waveTimer <= 0) {
        this.waveTimer = 18;
        this.spawnWave();
      }
      this.updateAI(dt);
      for (const u of this.units) {
        if (u.dead) {
          if (u.kind === "hero" && this.t >= u.respawnAt) this.respawn(u);
          continue;
        }
        if (u.kind === "hero") this.updateHero(u, dt);
        else if (u.kind === "minion") this.updateMinion(u, dt);
        else this.updateStructure(u, dt);
      }
      this.updateProjectiles(dt);
    }

    // fx always tick so death/victory feels alive
    for (const p of this.particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.94;
      p.vy *= 0.94;
    }
    this.particles = this.particles.filter((p) => p.life > 0);
    for (const ft of this.texts) {
      ft.life -= dt;
      ft.y -= 34 * dt;
    }
    this.texts = this.texts.filter((t) => t.life > 0);
    if (this.banner) {
      this.banner.life -= dt;
      if (this.banner.life <= 0) this.banner = null;
    }
  }

  private spawnWave() {
    this.wave++;
    const hpScale = 1 + this.wave * 0.05;
    for (const team of ["blue", "red"] as Team[]) {
      const start = this.lanePoint(team === "blue" ? 0.06 : 0.94);
      for (let i = 0; i < 3; i++) {
        const m: Minion = {
          id: nextId++,
          team,
          kind: "minion",
          x: start.x + (i - 1) * 34 + (Math.random() * 20 - 10),
          y: start.y + (i - 1) * 26 + (Math.random() * 20 - 10),
          radius: 16,
          hp: Math.round(240 * hpScale),
          maxHp: Math.round(240 * hpScale),
          dead: false,
          lastHitAt: -99,
          atkCd: 0,
          wp: team === "blue" ? 1 : this.board.lane.length - 2,
          atk: 20 + this.wave,
          speed: 130,
        };
        this.units.push(m);
      }
    }
  }

  /* ── unit updates ──────────────────────────────────────────────── */

  private effSpeed(h: Hero): number {
    if (this.t < h.snaredUntil) return 0;
    const slow = this.t < h.slowUntil ? 1 - h.slowAmt : 1;
    return h.speed * slow;
  }

  private updateHero(h: Hero, dt: number) {
    for (let i = 0; i < 3; i++) h.cds[i] = Math.max(0, h.cds[i] - dt);
    if (this.t > h.buffUntil) h.buffMult = 1;
    if (this.t > h.shieldUntil) h.shieldHp = 0;

    const len = Math.hypot(h.mx, h.my);
    if (len > 0.1) {
      const sp = this.effSpeed(h);
      h.x += (h.mx / len) * sp * dt;
      h.y += (h.my / len) * sp * dt;
      if (Math.abs(h.mx) > 0.1) h.facing = h.mx > 0 ? 1 : -1;
      h.bob += dt * 10;
    } else {
      h.bob += dt * 2.5;
    }
    h.x = Math.max(40, Math.min(this.board.world.w - 40, h.x));
    h.y = Math.max(40, Math.min(this.board.world.h - 40, h.y));

    // regen: strong near own core, trickle out of combat
    const core = this.units.find(
      (u) => u.kind === "core" && u.team === h.team && !u.dead,
    );
    const inCombat = this.t - h.lastHitAt < 5;
    if (core && Math.hypot(core.x - h.x, core.y - h.y) < 320) {
      h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.05 * dt);
    } else if (!inCombat) {
      h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.01 * dt);
    }

    // auto attack
    h.atkCd -= dt * h.buffMult;
    if (h.atkCd <= 0) {
      const target = this.nearestEnemy(h, h.range + 20, true);
      if (target) {
        h.atkCd = 1 / h.atkSpd;
        h.facing = target.x >= h.x ? 1 : -1;
        if (h.range > 120) {
          this.fireProjectile(h, target, {
            dmg: h.atk,
            color: h.creature.color,
            speed: 560,
            homing: true,
          });
        } else {
          this.dealDamage(h, target, h.atk);
          this.slashFx(h, target);
        }
      }
    }
  }

  private updateMinion(m: Minion, dt: number) {
    const target = this.nearestEnemy(m, 170, true);
    if (target) {
      const d = Math.hypot(target.x - m.x, target.y - m.y);
      const reach = 12 + m.radius + target.radius;
      if (d > reach) {
        m.x += ((target.x - m.x) / d) * m.speed * dt;
        m.y += ((target.y - m.y) / d) * m.speed * dt;
      }
      m.atkCd -= dt;
      if (d <= reach + 6 && m.atkCd <= 0) {
        m.atkCd = 1;
        this.dealDamage(m, target, m.atk);
      }
      return;
    }
    // march the lane
    const dir = m.team === "blue" ? 1 : -1;
    const wp = this.board.lane[m.wp];
    if (!wp) return;
    const d = Math.hypot(wp.x - m.x, wp.y - m.y);
    if (d < 30) {
      const next = m.wp + dir;
      if (next >= 0 && next < this.board.lane.length) m.wp = next;
      return;
    }
    m.x += ((wp.x - m.x) / d) * m.speed * dt;
    m.y += ((wp.y - m.y) / d) * m.speed * dt;
  }

  private updateStructure(s: Structure, dt: number) {
    if (s.kind !== "tower") return;
    s.atkCd -= dt;
    if (s.atkCd > 0) return;
    // towers prefer minions, then heroes
    const minion = this.nearestEnemy(s, s.range, true, "minion");
    const target = minion ?? this.nearestEnemy(s, s.range, true, "hero");
    if (!target) return;
    s.atkCd = 1.1;
    this.fireProjectile(s, target, {
      dmg: s.atk,
      color: TEAM_COLOR[s.team],
      speed: 480,
      homing: true,
    });
  }

  /* ── AI hero ───────────────────────────────────────────────────── */

  private updateAI(dt: number) {
    const e = this.enemy;
    if (e.dead) return;
    this.aiThink -= dt;

    const p = this.player;
    const distToPlayer = p.dead ? Infinity : Math.hypot(p.x - e.x, p.y - e.y);
    const lowHp = e.hp / e.maxHp < 0.3;

    let tx: number;
    let ty: number;
    if (lowHp) {
      const core = this.units.find(
        (u) => u.kind === "core" && u.team === "red" && !u.dead,
      );
      tx = core ? core.x : this.board.world.w - 100;
      ty = core ? core.y : 100;
    } else if (distToPlayer < 300) {
      // fight: hold ideal range, orbit slightly
      const ideal = Math.max(60, e.range * 0.85);
      const away = distToPlayer < ideal - 20 ? -1 : distToPlayer > ideal + 20 ? 1 : 0;
      const ang = Math.atan2(p.y - e.y, p.x - e.x);
      const orbit = Math.sin(this.t * 1.7) * 0.6;
      tx = e.x + Math.cos(ang + orbit) * away * 100;
      ty = e.y + Math.sin(ang + orbit) * away * 100;
      if (away === 0) {
        tx = e.x + Math.cos(ang + Math.PI / 2) * Math.sin(this.t * 2) * 80;
        ty = e.y + Math.sin(ang + Math.PI / 2) * Math.sin(this.t * 2) * 80;
      }
    } else {
      // push toward nearest standing blue structure, following the lane
      const objective =
        this.units.find((u) => u.kind === "tower" && u.team === "blue" && !u.dead) ??
        this.units.find((u) => u.kind === "core" && u.team === "blue" && !u.dead);
      if (objective) {
        // walk toward the lane point nearest the objective for a natural path
        tx = objective.x;
        ty = objective.y;
      } else {
        tx = e.x;
        ty = e.y;
      }
    }
    const dx = tx - e.x;
    const dy = ty - e.y;
    const dl = Math.hypot(dx, dy);
    if (dl > 14) {
      e.mx = dx / dl;
      e.my = dy / dl;
    } else {
      e.mx = 0;
      e.my = 0;
    }

    // ability usage on a small think cadence
    if (this.aiThink <= 0) {
      this.aiThink = 0.4 + Math.random() * 0.4;
      const abilities = e.creature.abilities;
      for (let i = 0; i < 3; i++) {
        if (e.cds[i] > 0) continue;
        const a = abilities[i];
        const wants = this.aiWants(e, a, distToPlayer, lowHp);
        if (wants) {
          this.castAbility(e, i as 0 | 1 | 2);
          break;
        }
      }
    }
    // movement itself happens in the main unit loop via updateHero
  }

  private aiWants(e: Hero, a: AbilityDef, distToPlayer: number, lowHp: boolean): boolean {
    switch (a.kind) {
      case "projectile":
        return distToPlayer < (a.range ?? 400) * 0.9 || !!this.nearestEnemy(e, 300, true);
      case "nova":
        return !!this.nearestEnemy(e, (a.radius ?? 150) * 0.9, true);
      case "dash":
        return !lowHp && distToPlayer > 120 && distToPlayer < (a.range ?? 240) + 80;
      case "blink":
        return lowHp && distToPlayer < 220;
      case "shield":
        return e.hp / e.maxHp < 0.55;
      case "heal":
        return e.hp / e.maxHp < 0.5;
      case "buff":
        return distToPlayer < 240 && !lowHp;
      case "snare":
        return distToPlayer < (a.range ?? 300) * 0.9;
    }
  }

  /* ── abilities ─────────────────────────────────────────────────── */

  private castAbility(h: Hero, i: 0 | 1 | 2) {
    if (h.dead || this.result) return;
    if (h.cds[i] > 0) return;
    const a = h.creature.abilities[i];
    if (this.t < h.snaredUntil && (a.kind === "dash" || a.kind === "blink")) return;
    h.cds[i] = a.cd;
    const scale = 1 + (h.level - 1) * 0.12;
    const dmg = (a.dmg ?? 0) * scale;

    switch (a.kind) {
      case "projectile": {
        const target = this.nearestEnemy(h, a.range ?? 400, true, "hero") ??
          this.nearestEnemy(h, a.range ?? 400, true);
        this.fireProjectile(h, target, {
          dmg,
          color: a.color,
          speed: a.speed ?? 520,
          homing: !a.pierce,
          maxDist: a.range ?? 420,
          aoe: a.radius ?? 0,
          pierce: !!a.pierce,
          slow: a.slow ? { amt: a.slow, dur: a.duration ?? 2 } : undefined,
          big: true,
        });
        break;
      }
      case "nova": {
        this.ringFx(h.x, h.y, a.radius ?? 150, a.color);
        this.shake = Math.max(this.shake, 5);
        for (const u of this.units) {
          if (u.dead || u.team === h.team) continue;
          if (Math.hypot(u.x - h.x, u.y - h.y) <= (a.radius ?? 150) + u.radius) {
            this.dealDamage(h, u, dmg);
            if (a.slow && u.kind === "hero") {
              u.slowAmt = a.slow;
              u.slowUntil = this.t + (a.duration ?? 2);
            }
          }
        }
        break;
      }
      case "dash": {
        let dx = h.mx;
        let dy = h.my;
        if (Math.hypot(dx, dy) < 0.1) {
          dx = h.facing;
          dy = 0;
        }
        const l = Math.hypot(dx, dy);
        const range = a.range ?? 240;
        const nx = h.x + (dx / l) * range;
        const ny = h.y + (dy / l) * range;
        // damage along the path
        for (const u of this.units) {
          if (u.dead || u.team === h.team) continue;
          if (pointSegDist(u.x, u.y, h.x, h.y, nx, ny) < 70 + u.radius) {
            this.dealDamage(h, u, dmg);
          }
        }
        for (let k = 0; k < 14; k++) {
          const f = k / 14;
          this.puff(h.x + (nx - h.x) * f, h.y + (ny - h.y) * f, a.color, 2);
        }
        h.x = Math.max(40, Math.min(this.board.world.w - 40, nx));
        h.y = Math.max(40, Math.min(this.board.world.h - 40, ny));
        break;
      }
      case "blink": {
        let dx = h.mx;
        let dy = h.my;
        if (Math.hypot(dx, dy) < 0.1) {
          dx = h.facing;
          dy = 0;
        }
        const l = Math.hypot(dx, dy);
        this.puff(h.x, h.y, a.color, 10);
        h.x = Math.max(40, Math.min(this.board.world.w - 40, h.x + (dx / l) * (a.range ?? 260)));
        h.y = Math.max(40, Math.min(this.board.world.h - 40, h.y + (dy / l) * (a.range ?? 260)));
        this.puff(h.x, h.y, a.color, 10);
        break;
      }
      case "shield": {
        h.shieldHp = (a.amount ?? 200) * scale;
        h.shieldUntil = this.t + (a.duration ?? 6);
        this.ringFx(h.x, h.y, 60, a.color);
        break;
      }
      case "heal": {
        const amt = (a.amount ?? 180) * scale;
        h.hp = Math.min(h.maxHp, h.hp + amt);
        this.texts.push({
          x: h.x,
          y: h.y - 50,
          text: `+${Math.round(amt)}`,
          color: "#7dff9a",
          life: 1,
          maxLife: 1,
        });
        this.puff(h.x, h.y, a.color, 12);
        break;
      }
      case "buff": {
        h.buffMult = a.amount ?? 1.5;
        h.buffUntil = this.t + (a.duration ?? 5);
        this.puff(h.x, h.y, a.color, 8);
        break;
      }
      case "snare": {
        const target =
          this.nearestEnemy(h, a.range ?? 300, true, "hero") ??
          this.nearestEnemy(h, a.range ?? 300, true, "minion");
        if (target) {
          this.dealDamage(h, target, dmg);
          if (target.kind === "hero") {
            target.snaredUntil = this.t + (a.duration ?? 1.8);
          }
          this.ringFx(target.x, target.y, 44, a.color);
        }
        break;
      }
    }
  }

  /* ── combat plumbing ───────────────────────────────────────────── */

  private nearestEnemy(
    from: { x: number; y: number; team: Team },
    range: number,
    alive: boolean,
    kind?: Unit["kind"],
  ): Unit | null {
    let best: Unit | null = null;
    let bestD = Infinity;
    for (const u of this.units) {
      if (u.team === from.team) continue;
      if (alive && u.dead) continue;
      if (kind && u.kind !== kind) continue;
      const d = Math.hypot(u.x - from.x, u.y - from.y) - u.radius;
      if (d < bestD && d <= range) {
        bestD = d;
        best = u;
      }
    }
    return best;
  }

  private fireProjectile(
    from: Unit,
    target: Unit | null,
    opts: {
      dmg: number;
      color: string;
      speed: number;
      homing: boolean;
      maxDist?: number;
      aoe?: number;
      pierce?: boolean;
      slow?: { amt: number; dur: number };
      big?: boolean;
    },
  ) {
    let dx = 1;
    let dy = 0;
    if (target) {
      const d = Math.hypot(target.x - from.x, target.y - from.y) || 1;
      dx = (target.x - from.x) / d;
      dy = (target.y - from.y) / d;
    } else if (from.kind === "hero") {
      const h = from as Hero;
      if (Math.hypot(h.mx, h.my) > 0.1) {
        const l = Math.hypot(h.mx, h.my);
        dx = h.mx / l;
        dy = h.my / l;
      } else {
        dx = h.facing;
        dy = 0;
      }
    }
    this.projectiles.push({
      x: from.x,
      y: from.y - 20,
      vx: dx,
      vy: dy,
      speed: opts.speed,
      team: from.team,
      dmg: opts.dmg,
      color: opts.color,
      target: opts.homing ? target : null,
      maxDist: opts.maxDist ?? 600,
      traveled: 0,
      radius: opts.big ? 10 : 6,
      aoe: opts.aoe ?? 0,
      pierce: opts.pierce ?? false,
      hitIds: new Set(),
      slow: opts.slow,
      dead: false,
    });
  }

  private updateProjectiles(dt: number) {
    for (const p of this.projectiles) {
      if (p.dead) continue;
      if (p.target && !p.target.dead) {
        const d = Math.hypot(p.target.x - p.x, p.target.y - p.y) || 1;
        p.vx = (p.target.x - p.x) / d;
        p.vy = (p.target.y - p.y) / d;
      }
      const step = p.speed * dt;
      p.x += p.vx * step;
      p.y += p.vy * step;
      p.traveled += step;
      if (Math.random() < 0.5) this.puff(p.x, p.y, p.color, 1, 0.35);

      for (const u of this.units) {
        if (u.dead || u.team === p.team || p.hitIds.has(u.id)) continue;
        if (Math.hypot(u.x - p.x, u.y - (p.y + 20)) <= u.radius + p.radius + 4) {
          p.hitIds.add(u.id);
          const src = p.team === "blue" ? this.player : this.enemy;
          if (p.aoe > 0) {
            this.ringFx(p.x, p.y + 20, p.aoe, p.color);
            for (const v of this.units) {
              if (v.dead || v.team === p.team) continue;
              if (Math.hypot(v.x - p.x, v.y - 20 - p.y) <= p.aoe + v.radius) {
                this.applyProjHit(src, v, p);
              }
            }
            p.dead = true;
          } else {
            this.applyProjHit(src, u, p);
            if (!p.pierce) p.dead = true;
          }
          if (p.dead) break;
        }
      }
      if (p.traveled >= p.maxDist) {
        if (p.aoe > 0 && !p.dead) {
          this.ringFx(p.x, p.y + 20, p.aoe, p.color);
          const src = p.team === "blue" ? this.player : this.enemy;
          for (const v of this.units) {
            if (v.dead || v.team === p.team) continue;
            if (Math.hypot(v.x - p.x, v.y - 20 - p.y) <= p.aoe + v.radius) {
              this.applyProjHit(src, v, p);
            }
          }
        }
        p.dead = true;
      }
    }
    this.projectiles = this.projectiles.filter((p) => !p.dead);
  }

  private applyProjHit(src: Hero, u: Unit, p: Projectile) {
    this.dealDamage(src, u, p.dmg);
    if (p.slow && u.kind === "hero") {
      u.slowAmt = p.slow.amt;
      u.slowUntil = this.t + p.slow.dur;
    }
  }

  private dealDamage(src: Unit, target: Unit, raw: number) {
    if (target.dead || this.result) return;
    let dmg = raw;
    if (target.kind === "hero") {
      dmg *= 1 - target.def;
      if (target.shieldHp > 0) {
        const absorbed = Math.min(target.shieldHp, dmg);
        target.shieldHp -= absorbed;
        dmg -= absorbed;
      }
    }
    dmg = Math.max(1, Math.round(dmg + (Math.random() * 6 - 3)));
    target.hp -= dmg;
    target.lastHitAt = this.t;
    this.texts.push({
      x: target.x + (Math.random() * 24 - 12),
      y: target.y - target.radius - 18,
      text: `-${dmg}`,
      color: src.team === "blue" ? "#ffe9a8" : "#ff8f86",
      life: 0.8,
      maxLife: 0.8,
    });
    this.puff(target.x, target.y - 14, src.team === "blue" ? "#ffd76e" : "#ff7a6e", 3, 0.5);

    if (target.hp <= 0) this.kill(src, target);
  }

  private kill(src: Unit, target: Unit) {
    target.hp = 0;
    target.dead = true;
    const killerHero = src.team === "blue" ? this.player : this.enemy;
    this.puff(target.x, target.y - 10, "#ffffff", 14, 1);

    if (target.kind === "minion") {
      this.reward(killerHero, 40, 45, target);
      this.units = this.units.filter((u) => u !== target);
    } else if (target.kind === "hero") {
      target.deaths++;
      target.streak = 0;
      target.respawnAt = this.t + 4 + target.level * 0.8;
      killerHero.kills++;
      killerHero.streak++;
      this.reward(killerHero, 300 + killerHero.streak * 25, 220, target);
      this.shake = Math.max(this.shake, 9);
      const streakText = STREAK_BANNERS[killerHero.streak];
      const isPlayer = killerHero === this.player;
      this.banner = {
        text: streakText ?? (isPlayer ? "ENEMY DOWN" : "YOU WERE SLAIN"),
        sub: `${killerHero.creature.name} defeated ${
          (target as Hero).creature.name
        }`,
        color: isPlayer ? "#ffd76e" : "#ff8f86",
        life: 2.2,
        maxLife: 2.2,
      };
    } else if (target.kind === "tower") {
      this.reward(killerHero, 250, 180, target);
      this.shake = Math.max(this.shake, 12);
      this.banner = {
        text: target.team === "red" ? "TOWER DESTROYED" : "TOWER LOST",
        color: target.team === "red" ? "#ffd76e" : "#ff8f86",
        life: 2,
        maxLife: 2,
      };
    } else if (target.kind === "core") {
      this.result = target.team === "red" ? "victory" : "defeat";
      this.shake = 16;
      if (this.onEnd) this.onEnd(this.result);
    }
  }

  private reward(h: Hero, gold: number, xp: number, at: { x: number; y: number }) {
    h.gold += gold;
    if (h === this.player) {
      this.texts.push({
        x: at.x,
        y: at.y - 34,
        text: `+${gold}`,
        color: "#ffd76e",
        life: 1.1,
        maxLife: 1.1,
        big: true,
      });
    }
    h.xp += xp;
    while (h.xp >= h.xpNext) {
      h.xp -= h.xpNext;
      h.level++;
      h.xpNext = Math.round(100 + (h.level - 1) * 85);
      h.maxHp = Math.round(h.maxHp * 1.12);
      h.hp = Math.min(h.maxHp, h.hp + h.maxHp * 0.25);
      h.atk = Math.round(h.atk * 1.1 * 10) / 10;
      this.ringFx(h.x, h.y, 70, "#ffe9a8");
      if (h === this.player) {
        this.texts.push({
          x: h.x,
          y: h.y - 70,
          text: `LEVEL ${h.level}!`,
          color: "#ffe9a8",
          life: 1.4,
          maxLife: 1.4,
          big: true,
        });
      }
    }
  }

  private respawn(h: Hero) {
    const core = this.units.find((u) => u.kind === "core" && u.team === h.team);
    if (!core) return;
    h.dead = false;
    h.hp = h.maxHp;
    h.x = core.x + (h.team === "blue" ? 60 : -60);
    h.y = core.y + 40;
    h.shieldHp = 0;
    h.slowUntil = 0;
    h.snaredUntil = 0;
    this.puff(h.x, h.y, TEAM_COLOR[h.team], 12, 1);
  }

  /* ── fx helpers ────────────────────────────────────────────────── */

  private puff(x: number, y: number, color: string, n: number, life = 0.7) {
    for (let i = 0; i < n; i++) {
      const a = Math.random() * Math.PI * 2;
      const sp = 20 + Math.random() * 90;
      this.particles.push({
        x,
        y,
        vx: Math.cos(a) * sp,
        vy: Math.sin(a) * sp,
        life: life * (0.6 + Math.random() * 0.6),
        maxLife: life,
        size: 3 + Math.random() * 5,
        color,
      });
    }
  }

  private ringFx(x: number, y: number, to: number, color: string) {
    this.particles.push({
      x,
      y,
      vx: 0,
      vy: 0,
      life: 0.45,
      maxLife: 0.45,
      size: 8,
      color,
      ring: true,
      ringTo: to,
    });
  }

  private slashFx(h: Hero, target: Unit) {
    const ang = Math.atan2(target.y - h.y, target.x - h.x);
    for (let i = 0; i < 5; i++) {
      const a = ang + (Math.random() - 0.5) * 0.9;
      this.particles.push({
        x: target.x - Math.cos(ang) * target.radius,
        y: target.y - 10 - Math.sin(ang) * target.radius,
        vx: Math.cos(a) * 130,
        vy: Math.sin(a) * 130,
        life: 0.3,
        maxLife: 0.3,
        size: 3,
        color: "#ffffff",
      });
    }
  }

  /* ── HUD snapshot ──────────────────────────────────────────────── */

  hud(): HudState {
    const towers = (team: Team) =>
      this.units.filter((u) => u.kind === "tower" && u.team === team && !u.dead).length;
    const coreHp = (team: Team) => {
      const c = this.units.find((u) => u.kind === "core" && u.team === team);
      return c ? Math.max(0, c.hp) : 0;
    };
    const p = this.player;
    return {
      hp: Math.max(0, Math.round(p.hp)),
      maxHp: p.maxHp,
      shield: Math.round(p.shieldHp),
      level: p.level,
      xp: p.xp,
      xpNext: p.xpNext,
      gold: p.gold,
      cds: [...p.cds] as [number, number, number],
      cdMax: [
        p.creature.abilities[0].cd,
        p.creature.abilities[1].cd,
        p.creature.abilities[2].cd,
      ],
      kills: { blue: this.player.kills, red: this.enemy.kills },
      time: this.t,
      dead: p.dead,
      respawnIn: p.dead ? Math.max(0, p.respawnAt - this.t) : 0,
      result: this.result,
      towersLeft: { blue: towers("blue"), red: towers("red") },
      coreHp: { blue: coreHp("blue"), red: coreHp("red") },
    };
  }

  /* ── rendering ─────────────────────────────────────────────────── */

  draw(ctx: CanvasRenderingContext2D, vw: number, vh: number) {
    const th = this.board.theme;
    const p = this.player;
    const camX = clamp(p.x - vw / 2, 0, Math.max(0, this.board.world.w - vw));
    const camY = clamp(p.y - vh / 2, 0, Math.max(0, this.board.world.h - vh));
    const sx = this.shake > 0 ? (Math.random() - 0.5) * this.shake : 0;
    const sy = this.shake > 0 ? (Math.random() - 0.5) * this.shake : 0;

    ctx.save();
    ctx.translate(-camX + sx, -camY + sy);

    // ground
    ctx.fillStyle = th.grass;
    ctx.fillRect(camX - 20, camY - 20, vw + 40, vh + 40);
    const tile = 120;
    ctx.fillStyle = th.grassDark;
    const x0 = Math.floor(camX / tile) * tile;
    const y0 = Math.floor(camY / tile) * tile;
    for (let x = x0; x < camX + vw + tile; x += tile) {
      for (let y = y0; y < camY + vh + tile; y += tile) {
        if (((x / tile) | 0) % 2 === ((y / tile) | 0) % 2) continue;
        ctx.globalAlpha = 0.35;
        ctx.fillRect(x, y, tile, tile);
        ctx.globalAlpha = 1;
      }
    }

    // lane
    ctx.lineCap = "round";
    ctx.lineJoin = "round";
    ctx.strokeStyle = th.pathEdge;
    ctx.lineWidth = 150;
    this.strokeLane(ctx);
    ctx.strokeStyle = th.path;
    ctx.lineWidth = 130;
    this.strokeLane(ctx);

    // depth-sorted drawables
    type D = { y: number; fn: () => void };
    const items: D[] = [];
    for (const d of this.board.decor) {
      if (d.x < camX - 120 || d.x > camX + vw + 120 || d.y < camY - 160 || d.y > camY + vh + 120)
        continue;
      if (d.kind === "pond" || d.kind === "lava") {
        // flat: draw immediately under everything
        this.drawDecor(ctx, d);
        continue;
      }
      items.push({ y: d.y, fn: () => this.drawDecor(ctx, d) });
    }
    for (const u of this.units) {
      if (u.dead && u.kind !== "tower" && u.kind !== "core") continue;
      items.push({ y: u.y, fn: () => this.drawUnit(ctx, u) });
    }
    items.sort((a, b) => a.y - b.y);
    for (const it of items) it.fn();

    // projectiles
    for (const pr of this.projectiles) {
      ctx.save();
      ctx.shadowColor = pr.color;
      ctx.shadowBlur = 14;
      ctx.fillStyle = pr.color;
      ctx.beginPath();
      ctx.arc(pr.x, pr.y, pr.radius, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "rgba(255,255,255,0.85)";
      ctx.beginPath();
      ctx.arc(pr.x - pr.vx * 3, pr.y - pr.vy * 3, pr.radius * 0.45, 0, Math.PI * 2);
      ctx.fill();
      ctx.restore();
    }

    // particles
    for (const pa of this.particles) {
      const f = pa.life / pa.maxLife;
      ctx.globalAlpha = Math.max(0, f);
      if (pa.ring) {
        const r = pa.size + (pa.ringTo ?? 60) * (1 - f);
        ctx.strokeStyle = pa.color;
        ctx.lineWidth = 5 * f + 1;
        ctx.beginPath();
        ctx.arc(pa.x, pa.y, r, 0, Math.PI * 2);
        ctx.stroke();
      } else {
        ctx.fillStyle = pa.color;
        ctx.beginPath();
        ctx.arc(pa.x, pa.y, pa.size * f, 0, Math.PI * 2);
        ctx.fill();
      }
      ctx.globalAlpha = 1;
    }

    // floating text
    for (const ft of this.texts) {
      const f = ft.life / ft.maxLife;
      ctx.globalAlpha = Math.min(1, f * 2);
      ctx.font = `bold ${ft.big ? 22 : 16}px system-ui, sans-serif`;
      ctx.textAlign = "center";
      ctx.lineWidth = 4;
      ctx.strokeStyle = "rgba(20,10,30,0.8)";
      ctx.strokeText(ft.text, ft.x, ft.y);
      ctx.fillStyle = ft.color;
      ctx.fillText(ft.text, ft.x, ft.y);
      ctx.globalAlpha = 1;
    }
    ctx.restore();

    // banner (screen space)
    if (this.banner) {
      const b = this.banner;
      const f = b.life / b.maxLife;
      const pop = f > 0.85 ? 1 + (f - 0.85) * 2.2 : 1;
      ctx.save();
      ctx.globalAlpha = Math.min(1, f * 3);
      ctx.translate(vw / 2, vh * 0.24);
      ctx.scale(pop, pop);
      ctx.font = "bold 40px system-ui, sans-serif";
      ctx.textAlign = "center";
      ctx.lineWidth = 8;
      ctx.strokeStyle = "rgba(30,15,40,0.85)";
      ctx.strokeText(b.text, 0, 0);
      ctx.fillStyle = b.color;
      ctx.fillText(b.text, 0, 0);
      if (b.sub) {
        ctx.font = "600 16px system-ui, sans-serif";
        ctx.lineWidth = 5;
        ctx.strokeText(b.sub, 0, 28);
        ctx.fillStyle = "#fff6e0";
        ctx.fillText(b.sub, 0, 28);
      }
      ctx.restore();
    }

    // vignette
    const vg = ctx.createRadialGradient(
      vw / 2,
      vh / 2,
      Math.min(vw, vh) * 0.45,
      vw / 2,
      vh / 2,
      Math.max(vw, vh) * 0.75,
    );
    vg.addColorStop(0, "rgba(0,0,0,0)");
    vg.addColorStop(1, "rgba(10,6,18,0.42)");
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, vw, vh);
  }

  private strokeLane(ctx: CanvasRenderingContext2D) {
    ctx.beginPath();
    const lane = this.board.lane;
    ctx.moveTo(lane[0].x, lane[0].y);
    for (let i = 1; i < lane.length; i++) ctx.lineTo(lane[i].x, lane[i].y);
    ctx.stroke();
  }

  private drawDecor(ctx: CanvasRenderingContext2D, d: Decor) {
    const s = d.s;
    ctx.save();
    ctx.translate(d.x, d.y);
    switch (d.kind) {
      case "pine":
      case "icePine": {
        const dark = d.kind === "icePine" ? "#7fa8bc" : "#2c5e2e";
        const lite = d.kind === "icePine" ? "#dceef5" : "#3f7d3f";
        ctx.fillStyle = "rgba(0,0,0,0.18)";
        ctx.beginPath();
        ctx.ellipse(0, 4 * s, 26 * s, 8 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#6b4a2b";
        ctx.fillRect(-4 * s, -8 * s, 8 * s, 14 * s);
        for (let i = 0; i < 3; i++) {
          const w = (34 - i * 8) * s;
          const yy = -8 * s - i * 20 * s;
          ctx.fillStyle = i % 2 ? lite : dark;
          ctx.beginPath();
          ctx.moveTo(-w, yy);
          ctx.lineTo(w, yy);
          ctx.lineTo(0, yy - 26 * s);
          ctx.closePath();
          ctx.fill();
        }
        break;
      }
      case "roundTree": {
        ctx.fillStyle = "rgba(0,0,0,0.18)";
        ctx.beginPath();
        ctx.ellipse(0, 4 * s, 24 * s, 8 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#6b4a2b";
        ctx.fillRect(-4 * s, -14 * s, 8 * s, 18 * s);
        ctx.fillStyle = "#3f7d3f";
        ctx.beginPath();
        ctx.arc(0, -30 * s, 24 * s, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#57a04f";
        ctx.beginPath();
        ctx.arc(-7 * s, -36 * s, 13 * s, 0, Math.PI * 2);
        ctx.fill();
        break;
      }
      case "rock": {
        ctx.fillStyle = "rgba(0,0,0,0.18)";
        ctx.beginPath();
        ctx.ellipse(0, 4 * s, 22 * s, 7 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = "#4b4a52";
        ctx.beginPath();
        ctx.moveTo(-20 * s, 2 * s);
        ctx.lineTo(-12 * s, -18 * s);
        ctx.lineTo(6 * s, -22 * s);
        ctx.lineTo(20 * s, -6 * s);
        ctx.lineTo(14 * s, 4 * s);
        ctx.closePath();
        ctx.fill();
        ctx.fillStyle = "#61606a";
        ctx.beginPath();
        ctx.moveTo(-12 * s, -18 * s);
        ctx.lineTo(6 * s, -22 * s);
        ctx.lineTo(8 * s, -8 * s);
        ctx.lineTo(-8 * s, -6 * s);
        ctx.closePath();
        ctx.fill();
        break;
      }
      case "crystal": {
        ctx.fillStyle = "rgba(120,200,255,0.25)";
        ctx.beginPath();
        ctx.ellipse(0, 4 * s, 18 * s, 6 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        const pulse = 0.75 + Math.sin(this.t * 2 + d.x) * 0.25;
        ctx.fillStyle = `rgba(140,220,255,${0.8 * pulse})`;
        ctx.beginPath();
        ctx.moveTo(0, -40 * s);
        ctx.lineTo(12 * s, -10 * s);
        ctx.lineTo(0, 4 * s);
        ctx.lineTo(-12 * s, -10 * s);
        ctx.closePath();
        ctx.fill();
        break;
      }
      case "lava": {
        const pulse = 0.7 + Math.sin(this.t * 3 + d.y) * 0.3;
        ctx.fillStyle = "#2e211d";
        ctx.beginPath();
        ctx.ellipse(0, 0, 56 * s, 34 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = `rgba(255,94,46,${0.85 * pulse})`;
        ctx.beginPath();
        ctx.ellipse(0, 0, 46 * s, 26 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = `rgba(255,200,80,${0.7 * pulse})`;
        ctx.beginPath();
        ctx.ellipse(-10 * s, -4 * s, 14 * s, 7 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        break;
      }
      case "pond": {
        ctx.fillStyle = this.board.theme.water;
        ctx.beginPath();
        ctx.ellipse(0, 0, 64 * s, 38 * s, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.strokeStyle = "rgba(255,255,255,0.35)";
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.ellipse(-8 * s, -6 * s, 30 * s, 14 * s, 0, 0, Math.PI * 2);
        ctx.stroke();
        break;
      }
    }
    ctx.restore();
  }

  private drawUnit(ctx: CanvasRenderingContext2D, u: Unit) {
    if (u.kind === "hero") this.drawHero(ctx, u);
    else if (u.kind === "minion") this.drawMinion(ctx, u);
    else this.drawStructure(ctx, u);
  }

  private drawHero(ctx: CanvasRenderingContext2D, h: Hero) {
    if (h.dead) return;
    const img = this.images[h.creature.id];
    const size = 76;
    const bobY = Math.sin(h.bob) * 3;

    ctx.save();
    // team ring + shadow
    ctx.fillStyle = "rgba(0,0,0,0.25)";
    ctx.beginPath();
    ctx.ellipse(h.x, h.y + 26, 26, 9, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = TEAM_COLOR[h.team];
    ctx.globalAlpha = 0.85;
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.ellipse(h.x, h.y + 26, 30, 11, 0, 0, Math.PI * 2);
    ctx.stroke();
    ctx.globalAlpha = 1;

    if (this.t < h.snaredUntil) {
      ctx.strokeStyle = "#5aa348";
      ctx.lineWidth = 4;
      for (let i = 0; i < 3; i++) {
        const a = (i / 3) * Math.PI * 2 + this.t * 2;
        ctx.beginPath();
        ctx.arc(h.x + Math.cos(a) * 18, h.y + 22, 8, 0, Math.PI * 1.4);
        ctx.stroke();
      }
    }

    if (img && img.complete && img.naturalWidth > 0) {
      ctx.translate(h.x, h.y + bobY - 12);
      ctx.scale(h.facing, 1);
      ctx.drawImage(img, -size / 2, -size / 2, size, size);
    } else {
      ctx.fillStyle = h.creature.color;
      ctx.beginPath();
      ctx.arc(h.x, h.y - 10, 26, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.restore();

    // shield bubble
    if (h.shieldHp > 0) {
      ctx.save();
      ctx.globalAlpha = 0.5;
      ctx.strokeStyle = "#bfe8ff";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(h.x, h.y - 12, 44 + Math.sin(this.t * 6) * 2, 0, Math.PI * 2);
      ctx.stroke();
      ctx.restore();
    }

    // hp bar + level
    const bw = 64;
    const bx = h.x - bw / 2;
    const by = h.y - 58 + bobY;
    ctx.fillStyle = "rgba(15,10,25,0.75)";
    roundRect(ctx, bx - 2, by - 2, bw + 4, 12, 4);
    ctx.fill();
    const frac = Math.max(0, h.hp / h.maxHp);
    ctx.fillStyle = h.team === "blue" ? "#5fdc78" : "#ff6e5f";
    roundRect(ctx, bx, by, bw * frac, 8, 3);
    ctx.fill();
    if (h.shieldHp > 0) {
      const sfrac = Math.min(1, h.shieldHp / h.maxHp);
      ctx.fillStyle = "rgba(191,232,255,0.9)";
      roundRect(ctx, bx, by - 4, bw * sfrac, 3, 1.5);
      ctx.fill();
    }
    ctx.fillStyle = TEAM_COLOR[h.team];
    ctx.beginPath();
    ctx.arc(bx - 9, by + 4, 8, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#fff";
    ctx.font = "bold 10px system-ui, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(String(h.level), bx - 9, by + 7.5);
  }

  private drawMinion(ctx: CanvasRenderingContext2D, m: Minion) {
    const c = TEAM_COLOR[m.team];
    const wob = Math.sin(this.t * 8 + m.id) * 2;
    ctx.save();
    ctx.fillStyle = "rgba(0,0,0,0.22)";
    ctx.beginPath();
    ctx.ellipse(m.x, m.y + 12, 14, 5, 0, 0, Math.PI * 2);
    ctx.fill();
    // slime body
    const grad = ctx.createRadialGradient(m.x - 5, m.y - 8 + wob, 3, m.x, m.y + wob, 18);
    grad.addColorStop(0, lighten(c, 0.45));
    grad.addColorStop(1, c);
    ctx.fillStyle = grad;
    ctx.beginPath();
    ctx.ellipse(m.x, m.y + wob * 0.4, 15, 13 - wob * 0.3, 0, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "rgba(20,12,35,0.7)";
    ctx.lineWidth = 2;
    ctx.stroke();
    // eyes
    ctx.fillStyle = "#fff";
    ctx.beginPath();
    ctx.arc(m.x - 5, m.y - 3 + wob * 0.4, 3.4, 0, Math.PI * 2);
    ctx.arc(m.x + 5, m.y - 3 + wob * 0.4, 3.4, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#1a1030";
    ctx.beginPath();
    ctx.arc(m.x - 4.4, m.y - 3 + wob * 0.4, 1.6, 0, Math.PI * 2);
    ctx.arc(m.x + 5.6, m.y - 3 + wob * 0.4, 1.6, 0, Math.PI * 2);
    ctx.fill();
    // hp sliver
    const frac = m.hp / m.maxHp;
    if (frac < 1) {
      ctx.fillStyle = "rgba(15,10,25,0.7)";
      ctx.fillRect(m.x - 13, m.y - 22, 26, 4);
      ctx.fillStyle = m.team === "blue" ? "#5fdc78" : "#ff6e5f";
      ctx.fillRect(m.x - 13, m.y - 22, 26 * frac, 4);
    }
    ctx.restore();
  }

  private drawStructure(ctx: CanvasRenderingContext2D, s: Structure) {
    const c = TEAM_COLOR[s.team];
    ctx.save();
    if (s.kind === "tower") {
      ctx.fillStyle = "rgba(0,0,0,0.25)";
      ctx.beginPath();
      ctx.ellipse(s.x, s.y + 26, 34, 11, 0, 0, Math.PI * 2);
      ctx.fill();
      if (s.dead) {
        // rubble
        ctx.fillStyle = "#57555e";
        ctx.beginPath();
        ctx.moveTo(s.x - 26, s.y + 22);
        ctx.lineTo(s.x - 10, s.y - 2);
        ctx.lineTo(s.x + 8, s.y + 6);
        ctx.lineTo(s.x + 26, s.y + 22);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
        return;
      }
      // stone base
      const grad = ctx.createLinearGradient(s.x, s.y - 70, s.x, s.y + 26);
      grad.addColorStop(0, "#b9b4bd");
      grad.addColorStop(1, "#716d78");
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.moveTo(s.x - 24, s.y + 24);
      ctx.lineTo(s.x - 17, s.y - 52);
      ctx.lineTo(s.x + 17, s.y - 52);
      ctx.lineTo(s.x + 24, s.y + 24);
      ctx.closePath();
      ctx.fill();
      ctx.strokeStyle = "rgba(25,18,38,0.7)";
      ctx.lineWidth = 3;
      ctx.stroke();
      // brick lines
      ctx.strokeStyle = "rgba(25,18,38,0.25)";
      ctx.lineWidth = 1.5;
      for (let i = 0; i < 3; i++) {
        ctx.beginPath();
        ctx.moveTo(s.x - 21 + i, s.y - 30 + i * 22);
        ctx.lineTo(s.x + 21 - i, s.y - 30 + i * 22);
        ctx.stroke();
      }
      // crystal cap
      const pulse = 0.8 + Math.sin(this.t * 3 + s.id) * 0.2;
      ctx.fillStyle = c;
      ctx.globalAlpha = pulse;
      ctx.beginPath();
      ctx.moveTo(s.x, s.y - 92);
      ctx.lineTo(s.x + 14, s.y - 58);
      ctx.lineTo(s.x - 14, s.y - 58);
      ctx.closePath();
      ctx.fill();
      ctx.globalAlpha = 1;
      ctx.strokeStyle = "rgba(25,18,38,0.7)";
      ctx.stroke();
    } else {
      // core: big crystal cluster
      ctx.fillStyle = "rgba(0,0,0,0.25)";
      ctx.beginPath();
      ctx.ellipse(s.x, s.y + 30, 46, 14, 0, 0, Math.PI * 2);
      ctx.fill();
      if (s.dead) {
        ctx.fillStyle = "#57555e";
        ctx.beginPath();
        ctx.ellipse(s.x, s.y + 14, 40, 18, 0, 0, Math.PI * 2);
        ctx.fill();
        ctx.restore();
        return;
      }
      const pulse = 0.8 + Math.sin(this.t * 2.2) * 0.2;
      ctx.save();
      ctx.shadowColor = c;
      ctx.shadowBlur = 26 * pulse;
      const shards: [number, number, number][] = [
        [0, -74, 22],
        [-26, -44, 14],
        [26, -46, 15],
      ];
      for (const [ox, oy, w] of shards) {
        ctx.fillStyle = lighten(c, 0.25);
        ctx.beginPath();
        ctx.moveTo(s.x + ox, s.y + oy);
        ctx.lineTo(s.x + ox + w, s.y + 8);
        ctx.lineTo(s.x + ox - w, s.y + 8);
        ctx.closePath();
        ctx.fill();
        ctx.strokeStyle = "rgba(25,18,38,0.7)";
        ctx.lineWidth = 3;
        ctx.stroke();
      }
      ctx.restore();
      // stone pedestal
      ctx.fillStyle = "#8d8896";
      roundRect(ctx, s.x - 40, s.y + 6, 80, 22, 8);
      ctx.fill();
      ctx.strokeStyle = "rgba(25,18,38,0.7)";
      ctx.lineWidth = 3;
      ctx.stroke();
    }
    // hp bar
    const bw = s.kind === "core" ? 88 : 64;
    const by = s.y - (s.kind === "core" ? 100 : 112);
    ctx.fillStyle = "rgba(15,10,25,0.75)";
    roundRect(ctx, s.x - bw / 2 - 2, by - 2, bw + 4, 11, 4);
    ctx.fill();
    ctx.fillStyle = c;
    roundRect(ctx, s.x - bw / 2, by, bw * Math.max(0, s.hp / s.maxHp), 7, 3);
    ctx.fill();
    ctx.restore();
  }

  drawMinimap(ctx: CanvasRenderingContext2D, w: number, h: number) {
    const { w: ww, h: wh } = this.board.world;
    const sc = Math.min(w / ww, h / wh);
    ctx.clearRect(0, 0, w, h);
    ctx.fillStyle = "rgba(12,18,10,0.85)";
    roundRect(ctx, 0, 0, ww * sc, wh * sc, 6);
    ctx.fill();
    // lane
    ctx.strokeStyle = "rgba(200,170,110,0.8)";
    ctx.lineWidth = 4;
    ctx.lineCap = "round";
    ctx.beginPath();
    const lane = this.board.lane;
    ctx.moveTo(lane[0].x * sc, lane[0].y * sc);
    for (let i = 1; i < lane.length; i++) ctx.lineTo(lane[i].x * sc, lane[i].y * sc);
    ctx.stroke();
    for (const u of this.units) {
      if (u.dead) continue;
      const c = TEAM_COLOR[u.team];
      if (u.kind === "tower") {
        ctx.fillStyle = c;
        ctx.fillRect(u.x * sc - 3, u.y * sc - 3, 6, 6);
      } else if (u.kind === "core") {
        ctx.fillStyle = c;
        ctx.save();
        ctx.translate(u.x * sc, u.y * sc);
        ctx.rotate(Math.PI / 4);
        ctx.fillRect(-4, -4, 8, 8);
        ctx.restore();
      } else if (u.kind === "hero") {
        ctx.fillStyle = "#fff";
        ctx.beginPath();
        ctx.arc(u.x * sc, u.y * sc, 4.5, 0, Math.PI * 2);
        ctx.fill();
        ctx.fillStyle = c;
        ctx.beginPath();
        ctx.arc(u.x * sc, u.y * sc, 3, 0, Math.PI * 2);
        ctx.fill();
      } else {
        ctx.fillStyle = c;
        ctx.globalAlpha = 0.8;
        ctx.beginPath();
        ctx.arc(u.x * sc, u.y * sc, 1.6, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
      }
    }
  }
}

/* ── small utils ─────────────────────────────────────────────────── */

function clamp(v: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, v));
}

function roundRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function pointSegDist(
  px: number,
  py: number,
  ax: number,
  ay: number,
  bx: number,
  by: number,
): number {
  const dx = bx - ax;
  const dy = by - ay;
  const len2 = dx * dx + dy * dy || 1;
  const t = clamp(((px - ax) * dx + (py - ay) * dy) / len2, 0, 1);
  return Math.hypot(px - (ax + t * dx), py - (ay + t * dy));
}

function lighten(hex: string, amt: number): string {
  const n = parseInt(hex.slice(1), 16);
  const r = Math.min(255, ((n >> 16) & 255) + 255 * amt) | 0;
  const g = Math.min(255, ((n >> 8) & 255) + 255 * amt) | 0;
  const b = Math.min(255, (n & 255) + 255 * amt) | 0;
  return `rgb(${r},${g},${b})`;
}
