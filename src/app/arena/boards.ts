// Battle boards. Each board defines a world, a lane the minions march down,
// tower/core placements, and a visual theme the renderer interprets.

export type DecorKind = "pine" | "roundTree" | "rock" | "lava" | "icePine" | "crystal" | "pond";

export interface Decor {
  kind: DecorKind;
  x: number;
  y: number;
  s: number; // scale
}

export interface BoardTheme {
  grass: string;
  grassDark: string;
  path: string;
  pathEdge: string;
  water: string;
  glow: string; // ambient accent
}

export interface Board {
  id: string;
  name: string;
  subtitle: string;
  desc: string;
  world: { w: number; h: number };
  lane: { x: number; y: number }[]; // blue core -> red core
  towersPerSide: number; // towers are placed along the lane
  coreHp: number;
  towerHp: number;
  theme: BoardTheme;
  decor: Decor[];
  previewColors: [string, string, string];
}

function scatter(
  kind: DecorKind,
  count: number,
  w: number,
  h: number,
  seed: number,
  avoid: (x: number, y: number) => boolean,
): Decor[] {
  // deterministic pseudo-random so boards look identical every match
  let s = seed;
  const rnd = () => {
    s = (s * 16807) % 2147483647;
    return s / 2147483647;
  };
  const out: Decor[] = [];
  let guard = 0;
  while (out.length < count && guard++ < count * 30) {
    const x = 60 + rnd() * (w - 120);
    const y = 60 + rnd() * (h - 120);
    if (avoid(x, y)) continue;
    out.push({ kind, x, y, s: 0.7 + rnd() * 0.8 });
  }
  return out;
}

function distToLane(lane: { x: number; y: number }[], x: number, y: number): number {
  let best = Infinity;
  for (let i = 0; i < lane.length - 1; i++) {
    const a = lane[i];
    const b = lane[i + 1];
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len2 = dx * dx + dy * dy || 1;
    const t = Math.max(0, Math.min(1, ((x - a.x) * dx + (y - a.y) * dy) / len2));
    const px = a.x + t * dx;
    const py = a.y + t * dy;
    best = Math.min(best, Math.hypot(x - px, y - py));
  }
  return best;
}

function makeBoard(
  base: Omit<Board, "decor"> & { decorSpec: { kind: DecorKind; count: number; seed: number }[] },
): Board {
  const { decorSpec, ...rest } = base;
  const avoid = (x: number, y: number) => distToLane(rest.lane, x, y) < 130;
  const decor = decorSpec.flatMap((d) =>
    scatter(d.kind, d.count, rest.world.w, rest.world.h, d.seed, avoid),
  );
  return { ...rest, decor };
}

export const BOARDS: Board[] = [
  makeBoard({
    id: "willowmere",
    name: "Willowmere Woods",
    subtitle: "The classic lane",
    desc: "A winding forest path between two shrine-crystals. One tower guards each side. Balanced and honest.",
    world: { w: 2400, h: 1700 },
    lane: [
      { x: 220, y: 1480 },
      { x: 640, y: 1240 },
      { x: 1050, y: 900 },
      { x: 1500, y: 620 },
      { x: 1950, y: 380 },
      { x: 2180, y: 240 },
    ],
    towersPerSide: 1,
    coreHp: 1400,
    towerHp: 950,
    theme: {
      grass: "#69a75c",
      grassDark: "#578f4c",
      path: "#a9814f",
      pathEdge: "#8d6a3e",
      water: "#4f8fc9",
      glow: "#d9ffb0",
    },
    decorSpec: [
      { kind: "pine", count: 90, seed: 1337 },
      { kind: "roundTree", count: 18, seed: 777 },
      { kind: "rock", count: 12, seed: 4242 },
      { kind: "pond", count: 3, seed: 99 },
    ],
    previewColors: ["#69a75c", "#a9814f", "#2c5e2e"],
  }),
  makeBoard({
    id: "cinder",
    name: "Cinder Rift",
    subtitle: "Double tower gauntlet",
    desc: "A scorched trench through a volcano's shadow. Two towers per side make sieges brutal — bring burst.",
    world: { w: 2600, h: 1500 },
    lane: [
      { x: 220, y: 750 },
      { x: 760, y: 620 },
      { x: 1300, y: 820 },
      { x: 1840, y: 640 },
      { x: 2380, y: 750 },
    ],
    towersPerSide: 2,
    coreHp: 1200,
    towerHp: 800,
    theme: {
      grass: "#6e5548",
      grassDark: "#5d463c",
      path: "#3f2f2a",
      pathEdge: "#2e211d",
      water: "#ff5e2e",
      glow: "#ffb27a",
    },
    decorSpec: [
      { kind: "rock", count: 60, seed: 2020 },
      { kind: "lava", count: 14, seed: 313 },
      { kind: "pine", count: 20, seed: 555 },
    ],
    previewColors: ["#6e5548", "#ff5e2e", "#2e211d"],
  }),
  makeBoard({
    id: "frostveil",
    name: "Frostveil Basin",
    subtitle: "Long march, fortified core",
    desc: "A frozen S-curve where the cores are hardened by ancient ice. Endurance wins here — pace your trades.",
    world: { w: 2200, h: 2000 },
    lane: [
      { x: 260, y: 1780 },
      { x: 900, y: 1620 },
      { x: 1500, y: 1300 },
      { x: 1100, y: 950 },
      { x: 700, y: 640 },
      { x: 1300, y: 420 },
      { x: 1940, y: 260 },
    ],
    towersPerSide: 1,
    coreHp: 1800,
    towerHp: 1100,
    theme: {
      grass: "#a8c8d8",
      grassDark: "#93b6c9",
      path: "#e8f1f6",
      pathEdge: "#c2d8e4",
      water: "#5aa2d0",
      glow: "#e0f7ff",
    },
    decorSpec: [
      { kind: "icePine", count: 80, seed: 909 },
      { kind: "crystal", count: 16, seed: 606 },
      { kind: "rock", count: 14, seed: 123 },
      { kind: "pond", count: 4, seed: 42 },
    ],
    previewColors: ["#a8c8d8", "#e8f1f6", "#5aa2d0"],
  }),
];

export function boardById(id: string): Board {
  const b = BOARDS.find((b) => b.id === id);
  if (!b) throw new Error(`unknown board: ${id}`);
  return b;
}
