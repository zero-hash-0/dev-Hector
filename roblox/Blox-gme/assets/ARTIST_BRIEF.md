# Blox-gme — Art Direction Brief
### For commissioning final icon and thumbnail from a human artist

---

## The Game

Real-time action PvP. Players fight, chase, and steal a glowing gold orb called
**The Core**. First to grab it and escape to their zone wins. Fast, chaotic,
clutch every round.

6 playable characters. Each has a unique look, color, and ability.

---

## Non-Negotiables

- **Hand-drawn or vector illustration only.** No AI generation, no stock assets.
- **Never photorealistic.** This is a stylized game — keep it graphic and clean.
- The art should look like it came from a senior game artist at a mid-tier studio.
- Reference: Valorant agent cards, Fortnite lobby art, Fall Guys promotional art.
  Clean lines, strong silhouettes, bold color blocking, readable at any size.

---

## Color Palette (exact hex)

| Role            | Hex       | Usage                              |
|-----------------|-----------|------------------------------------|
| Background      | `#06060E`  | Near-black navy base               |
| Background mid  | `#1C1C4A`  | Lighter navy for radial gradient   |
| Core / Gold     | `#FFD700`  | The Core orb, title accent         |
| Core highlight  | `#FFF8C0`  | Specular on Core sphere            |
| Cyan accent     | `#00FFFF`  | UI brackets, grid lines, particles |
| White           | `#FFFFFF`  | Title text                         |

### Character colors (each fighter has one signature color)

| Character | Color     |
|-----------|-----------|
| VIPER     | `#00FF88` |
| TANK      | `#FF6B35` |
| GHOST     | `#B8C0FF` |
| SPARK     | `#FFD60A` |
| SURGE     | `#00BFFF` |
| REAPER    | `#A855F7` |

---

## Icon Spec (512 × 512 px, circle crop)

**Deliverables:** PNG with transparent background at 512×512. Must look crisp
when cropped to a circle (Roblox icon format).

### Composition

```
┌─────────────────────────────────┐
│  ╔═╗            corner          │
│  ║ ║  brackets  accents         │
│                                 │
│   [silhouette] ◉ [silhouette]  │
│                CORE             │
│                                 │
│  ────────────────────────       │
│         BLOX                    │
│         -GME                    │
│  ╚═╝                      ╝    │
└─────────────────────────────────┘
```

- **The Core** is the hero element. Glowing gold sphere, center-upper half.
  Should feel like it has weight and energy — internal glow, specular highlight,
  thin engraved rings. Not a flat circle.
- **Two character silhouettes** flank the Core — one on each side, both reaching
  toward it. Silhouettes are dark (#08081A) against the glow. Clean, readable.
  Use any two characters you like. Keep proportions heroic — not chibi.
- **Typography** — "BLOX" large, white, ultra-bold (think condensed heavy weight).
  "-GME" below, same weight, gold (#FFD700). Both text elements tight, no loose
  spacing. Horizontal rule between Core section and text.
- **Corner brackets** — four L-shaped brackets in cyan, one at each corner.
  6px stroke, square end caps. Clean game-UI aesthetic.
- **Background** — very dark radial gradient (navy center to near-black edges).
  Subtle grid of 1px cyan lines at very low opacity (~5%). Adds depth without noise.
- **Particles** — 8–12 small dots in cyan, gold, and purple scattered in empty space.
  Sizes 2–4px. Random but balanced.

### Do NOT
- Gradients that look like sunsets
- Lens flare effects
- Drop shadows that look generic
- Rounded soft glows (use sharp, structured light)
- Any element that feels "stock" or "template"

---

## Thumbnail Spec (1280 × 720 px)

**Deliverables:** PNG 1280×720. No transparency needed.

### Composition (rule of thirds)

```
┌────────────────────────────────────────────────┐
│ ╔╗                              SURGE ──────── │
│ ║║  BLOX        [CORE]          sprinting ──── │
│ ╚╝  -GME                                       │
│      ─────                                     │
│      STEAL THE CORE.  ESCAPE.   REAPER         │
│     [badges]         (carrier)                 │
│                                                │
│     VIPER                        ────────────  │
│     lunging                            ╚╝      │
└────────────────────────────────────────────────┘
```

**Left third:** Game title treatment + tagline + small badges.
**Center:** The Core at the horizon line — dramatic radial light from it.
**Right two-thirds:** Three characters in motion.

### Characters to illustrate

Use these three for the thumbnail (highest contrast, most visual variety):

1. **VIPER** (green `#00FF88`) — left side, low lunge toward Core, arm fully
   extended. Aggressive, hungry. Fast and light build.
2. **REAPER** (purple `#A855F7`) — center, running away from camera slightly,
   Core in hand (or glowing near them). Powerful, dominant stance.
   Small skull ☠ floating above their head (death mark visual).
3. **SURGE** (blue `#00BFFF`) — far right, full sprint toward center, extreme
   forward lean, speed lines trailing off the right edge.

### Lighting

Single primary light source: **The Core itself**.
Gold light from center casts on all characters. Characters are front-lit gold
on their core-facing side, darker on their outer edges.
Background is pure dark — no environment, no arena walls visible.

### Typography

- **"BLOX"** — 148px equivalent, white, ultra-heavy condensed. Hard drop shadow
  (no blur — crisp 4px offset). No gradients on text.
- **"-GME"** — 120px, gold `#FFD700`, same weight. Aligns left under BLOX.
- **Tagline** — "STEAL THE CORE.  ESCAPE." — 22px, `#AAAACC`, wide letter-spacing.
- **Badges** (optional) — "6 FIGHTERS" and "REAL-TIME PvP" — small pill shapes
  in dark fill with colored text. Clean, modern.
- **Thin vertical cyan bar** (4px) left of title block.

### Do NOT
- Multiple light sources that compete
- Busy background with arena details or environments
- Characters that look like default Roblox blocky avatars
- Neon rainbow explosion look — this is dark and focused
- Comic-style outlines unless they are very thin and intentional

---

## Typography Guidelines (applies everywhere)

- **Font family:** Ultra-compressed heavy grotesque. Reference: Barlow Condensed
  Black, Oswald ExtraBold, or custom lettering. NOT regular Arial/Helvetica.
- **Title tracking:** Wide letter-spacing only on the tagline/subtext.
  Title letters should be tight — they're a logo, not body copy.
- **Japanese vertical accent** (optional, per ART_STYLE.md) — a single vertical
  text element on one edge of the thumbnail. Keep it understated, same weight
  as the character brand.

---

## Delivery Format

| Asset          | Size       | Format | Notes                         |
|----------------|------------|--------|-------------------------------|
| Icon           | 512×512    | PNG    | Transparent BG, circle-safe   |
| Icon source    | —          | AI/PSD | Layered, editable             |
| Thumbnail      | 1280×720   | PNG    | White/black BG fine           |
| Thumbnail src  | —          | AI/PSD | Layered, editable             |
| Characters     | any        | PNG    | Individual character art later |

---

## Reference images to share with the artist

Pull from these games for visual reference:
- **Valorant** — character select screen art, agent portrait cards
- **Brawl Stars** — character icons (bold, clean, reads at 64px)
- **Fortnite** — lobby background art (dark, dramatic, single light source)
- **Fall Guys** — thumbnail treatment (bold graphic, not photorealistic)
- **Rocket League** — logo treatment (tight, heavy, neon accent)

---

## SVG Compositions (already in this folder)

`icon.svg` and `thumbnail.svg` are the approved compositional layouts.
They show exact placement, proportions, and color. The artist's job is to
redraw everything at final quality — same layout, professional execution.
Do not change the composition without approval.
