// Creature Arena — original pocket-monster style roster.
// Each creature ships with hand-built vector art (used in menus AND in-battle),
// base stats, and three abilities interpreted by the battle engine.

export type ElementType =
  | "Fire"
  | "Water"
  | "Electric"
  | "Grass"
  | "Rock"
  | "Ghost";

export type AbilityKind =
  | "projectile"
  | "nova"
  | "dash"
  | "shield"
  | "heal"
  | "buff"
  | "blink"
  | "snare";

export interface AbilityDef {
  name: string;
  desc: string;
  kind: AbilityKind;
  cd: number; // seconds
  dmg?: number;
  radius?: number;
  range?: number;
  speed?: number;
  duration?: number;
  amount?: number; // shield hp / heal hp / buff multiplier
  slow?: number; // 0..1 movement slow applied
  pierce?: boolean; // projectile passes through enemies
  color: string;
}

export interface CreatureStats {
  hp: number;
  atk: number;
  def: number; // % damage reduction 0..1
  speed: number; // world units / s
  range: number; // attack range
  atkSpd: number; // attacks per second
}

export interface Creature {
  id: string;
  name: string;
  species: string;
  type: ElementType;
  role: string;
  flavor: string;
  color: string; // signature color for UI
  stats: CreatureStats;
  abilities: [AbilityDef, AbilityDef, AbilityDef];
  svg: string; // 120x120 viewBox full-body art
}

export const TYPE_COLORS: Record<ElementType, string> = {
  Fire: "#ff7a45",
  Water: "#4fc3f7",
  Electric: "#ffd54f",
  Grass: "#81c784",
  Rock: "#bcaaa4",
  Ghost: "#b39ddb",
};

/* ────────────────────────────────────────────────────────────────────────────
   Vector art. Shared style: dark plum outline, radial-lit bodies, big glossy
   eyes with double speculars, soft ground shadow. Gradient ids are prefixed
   per creature so several can be inlined on one page.
──────────────────────────────────────────────────────────────────────────── */

const OUT = "#39274a"; // outline
const SW = 3; // stroke width

const emberyxSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="emb-body" cx="42%" cy="32%" r="80%">
      <stop offset="0%" stop-color="#ffb27a"/><stop offset="55%" stop-color="#ff8a3d"/><stop offset="100%" stop-color="#e85d1f"/>
    </radialGradient>
    <linearGradient id="emb-flame" x1="0" y1="1" x2="0" y2="0">
      <stop offset="0%" stop-color="#ff6a00"/><stop offset="60%" stop-color="#ffc233"/><stop offset="100%" stop-color="#fff3b0"/>
    </linearGradient>
    <radialGradient id="emb-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#ffb547"/><stop offset="100%" stop-color="#c33d00"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="107" rx="30" ry="6" fill="rgba(0,0,0,0.25)"/>
  <!-- twin flame tails -->
  <path d="M88 78 Q104 70 100 52 Q99 62 92 64 Q98 50 90 40 Q92 52 84 58 Q80 68 84 78 Z" fill="url(#emb-flame)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M92 84 Q108 82 110 66 Q106 74 100 74 Q106 64 102 54 Q101 66 93 70 Q88 78 92 84 Z" fill="url(#emb-flame)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- hind leg -->
  <ellipse cx="78" cy="92" rx="13" ry="11" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- body -->
  <path d="M38 74 Q38 58 56 56 Q80 54 86 74 Q90 92 70 100 Q46 106 38 88 Z" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- cream chest -->
  <path d="M44 78 Q46 66 58 66 Q70 68 70 82 Q68 96 56 96 Q44 92 44 78 Z" fill="#ffe8c9" stroke="none"/>
  <!-- front paws -->
  <ellipse cx="49" cy="99" rx="8" ry="6" fill="#ffe8c9" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="66" cy="101" rx="8" ry="6" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- head -->
  <path d="M28 44 Q28 20 52 18 Q78 16 82 40 Q84 62 58 64 Q32 66 28 44 Z" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- ears with inner flame -->
  <path d="M32 30 L26 8 L46 20 Z" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M66 18 L78 2 L84 24 Z" fill="url(#emb-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M34 25 L31 13 L42 20 Z" fill="url(#emb-flame)"/>
  <path d="M70 16 L77 7 L80 20 Z" fill="url(#emb-flame)"/>
  <!-- head flame tuft -->
  <path d="M50 18 Q48 8 56 4 Q54 10 60 12 Q58 4 66 4 Q62 10 64 16 Z" fill="url(#emb-flame)" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <!-- muzzle -->
  <path d="M42 48 Q44 40 54 42 Q62 44 60 52 Q56 60 46 56 Q42 54 42 48 Z" fill="#ffe8c9"/>
  <!-- eyes -->
  <ellipse cx="43" cy="40" rx="7.5" ry="9" fill="#fff"/>
  <ellipse cx="44" cy="41" rx="5.5" ry="7" fill="url(#emb-eye)"/>
  <circle cx="44.5" cy="42" r="2.6" fill="#2a1230"/>
  <circle cx="42" cy="38" r="2" fill="#fff"/>
  <circle cx="46" cy="44" r="1" fill="#fff" opacity="0.8"/>
  <ellipse cx="68" cy="38" rx="7.5" ry="9" fill="#fff"/>
  <ellipse cx="68" cy="39" rx="5.5" ry="7" fill="url(#emb-eye)"/>
  <circle cx="67.5" cy="40" r="2.6" fill="#2a1230"/>
  <circle cx="65.5" cy="36" r="2" fill="#fff"/>
  <circle cx="70" cy="42" r="1" fill="#fff" opacity="0.8"/>
  <!-- nose + mouth -->
  <path d="M50 49 Q52 47 54 49 Q52 52 50 49 Z" fill="${OUT}"/>
  <path d="M49 54 Q52 57 56 54" fill="none" stroke="${OUT}" stroke-width="2" stroke-linecap="round"/>
  <!-- blush -->
  <ellipse cx="36" cy="50" rx="4" ry="2.5" fill="#ff5f4a" opacity="0.55"/>
  <ellipse cx="74" cy="47" rx="4" ry="2.5" fill="#ff5f4a" opacity="0.55"/>
</svg>`;

const marlochSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="mar-body" cx="40%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#a5ecf5"/><stop offset="55%" stop-color="#5fd0e8"/><stop offset="100%" stop-color="#2e9fc9"/>
    </radialGradient>
    <linearGradient id="mar-gill" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#ffb3c7"/><stop offset="100%" stop-color="#ff7a9e"/>
    </linearGradient>
    <radialGradient id="mar-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#5f79ff"/><stop offset="100%" stop-color="#1c2a8f"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="108" rx="32" ry="6" fill="rgba(0,0,0,0.25)"/>
  <!-- tail fin -->
  <path d="M86 82 Q104 78 108 62 Q104 70 96 70 Q104 58 100 48 Q96 60 86 64 Q80 74 86 82 Z" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- gill fronds left -->
  <path d="M26 34 Q10 28 8 16 Q18 22 24 20 Q14 12 16 4 Q26 14 32 16 Q36 26 26 34 Z" fill="url(#mar-gill)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M24 48 Q8 48 2 38 Q12 40 18 36 Q8 34 6 26 Q18 32 26 32 Q32 42 24 48 Z" fill="url(#mar-gill)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- gill fronds right -->
  <path d="M88 30 Q104 22 106 10 Q96 18 90 16 Q100 8 98 0 Q88 10 82 14 Q80 24 88 30 Z" fill="url(#mar-gill)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M92 44 Q108 42 114 32 Q104 34 98 31 Q108 28 110 20 Q98 26 90 28 Q84 38 92 44 Z" fill="url(#mar-gill)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- body -->
  <path d="M34 72 Q32 52 56 50 Q82 50 84 72 Q86 94 60 98 Q36 96 34 72 Z" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- belly -->
  <ellipse cx="59" cy="80" rx="17" ry="14" fill="#e9fbff"/>
  <!-- stubby arms -->
  <ellipse cx="34" cy="80" rx="8" ry="6" transform="rotate(-24 34 80)" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="86" cy="80" rx="8" ry="6" transform="rotate(24 86 80)" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- feet -->
  <ellipse cx="48" cy="100" rx="9" ry="5.5" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="72" cy="100" rx="9" ry="5.5" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- head -->
  <path d="M26 34 Q28 10 58 10 Q88 10 90 34 Q90 56 58 56 Q26 56 26 34 Z" fill="url(#mar-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- head fin -->
  <path d="M52 12 Q50 2 58 0 Q56 6 62 8 Q60 2 68 2 Q64 8 64 12 Z" fill="url(#mar-gill)" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <!-- eyes -->
  <ellipse cx="42" cy="33" rx="8.5" ry="10" fill="#fff"/>
  <ellipse cx="43" cy="34" rx="6.5" ry="8" fill="url(#mar-eye)"/>
  <circle cx="43.5" cy="35" r="3" fill="#101336"/>
  <circle cx="40.5" cy="30.5" r="2.3" fill="#fff"/>
  <circle cx="46" cy="38" r="1.2" fill="#fff" opacity="0.85"/>
  <ellipse cx="76" cy="33" rx="8.5" ry="10" fill="#fff"/>
  <ellipse cx="75" cy="34" rx="6.5" ry="8" fill="url(#mar-eye)"/>
  <circle cx="74.5" cy="35" r="3" fill="#101336"/>
  <circle cx="72" cy="30.5" r="2.3" fill="#fff"/>
  <circle cx="78" cy="38" r="1.2" fill="#fff" opacity="0.85"/>
  <!-- smile -->
  <path d="M50 46 Q59 52 68 46" fill="none" stroke="${OUT}" stroke-width="2.5" stroke-linecap="round"/>
  <!-- blush -->
  <ellipse cx="34" cy="42" rx="4.5" ry="2.6" fill="#ff8fb0" opacity="0.6"/>
  <ellipse cx="84" cy="42" rx="4.5" ry="2.6" fill="#ff8fb0" opacity="0.6"/>
  <!-- bubbles -->
  <circle cx="14" cy="60" r="3.5" fill="none" stroke="#bdeffa" stroke-width="1.8"/>
  <circle cx="106" cy="54" r="2.6" fill="none" stroke="#bdeffa" stroke-width="1.6"/>
</svg>`;

const zaplitSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="zap-body" cx="42%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#fff2a8"/><stop offset="55%" stop-color="#ffd94f"/><stop offset="100%" stop-color="#f5a623"/>
    </radialGradient>
    <linearGradient id="zap-bolt" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#fffbe0"/><stop offset="100%" stop-color="#ffc400"/>
    </linearGradient>
    <radialGradient id="zap-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#7ad4ff"/><stop offset="100%" stop-color="#0c4ea8"/>
    </radialGradient>
  </defs>
  <ellipse cx="58" cy="108" rx="28" ry="6" fill="rgba(0,0,0,0.25)"/>
  <!-- lightning tail -->
  <path d="M82 84 L98 74 L90 72 L106 58 L96 58 L108 42 L92 50 L96 38 L82 54 Q76 70 82 84 Z" fill="url(#zap-bolt)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- ears: jagged bolts -->
  <path d="M34 26 L24 2 L34 10 L36 0 L46 18 Z" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M70 16 L84 0 L82 12 L94 6 L82 26 Z" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M36 20 L30 8 L40 15 Z" fill="#5a4300" opacity="0.5"/>
  <path d="M74 15 L83 5 L80 18 Z" fill="#5a4300" opacity="0.5"/>
  <!-- body -->
  <path d="M36 72 Q34 56 56 54 Q80 54 82 72 Q84 92 58 96 Q38 94 36 72 Z" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- belly -->
  <ellipse cx="58" cy="78" rx="15" ry="12" fill="#fff8dc"/>
  <!-- back stripes -->
  <path d="M42 62 Q48 66 42 70 Z M78 62 Q72 66 78 70 Z" fill="#c77f1b"/>
  <!-- arms -->
  <ellipse cx="38" cy="74" rx="7" ry="5.5" transform="rotate(-20 38 74)" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="80" cy="74" rx="7" ry="5.5" transform="rotate(20 80 74)" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- feet -->
  <ellipse cx="48" cy="97" rx="9" ry="5.5" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="70" cy="97" rx="9" ry="5.5" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- head -->
  <path d="M28 38 Q28 14 56 12 Q86 12 88 36 Q88 58 58 60 Q28 60 28 38 Z" fill="url(#zap-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- eyes -->
  <ellipse cx="44" cy="36" rx="8" ry="9.5" fill="#fff"/>
  <ellipse cx="45" cy="37" rx="6" ry="7.5" fill="url(#zap-eye)"/>
  <circle cx="45.5" cy="38" r="2.8" fill="#0a102e"/>
  <circle cx="43" cy="33.5" r="2.2" fill="#fff"/>
  <circle cx="48" cy="41" r="1.1" fill="#fff" opacity="0.85"/>
  <ellipse cx="72" cy="36" rx="8" ry="9.5" fill="#fff"/>
  <ellipse cx="71" cy="37" rx="6" ry="7.5" fill="url(#zap-eye)"/>
  <circle cx="70.5" cy="38" r="2.8" fill="#0a102e"/>
  <circle cx="68.5" cy="33.5" r="2.2" fill="#fff"/>
  <circle cx="74" cy="41" r="1.1" fill="#fff" opacity="0.85"/>
  <!-- spark cheeks -->
  <path d="M30 46 L36 44 L33 48 L38 48 L31 52 L33 48 Z" fill="#ff9500" stroke="#e06d00" stroke-width="1"/>
  <path d="M88 46 L82 44 L85 48 L80 48 L87 52 L85 48 Z" fill="#ff9500" stroke="#e06d00" stroke-width="1"/>
  <!-- tiny mouth -->
  <path d="M54 50 Q58 54 62 50" fill="none" stroke="${OUT}" stroke-width="2.2" stroke-linecap="round"/>
  <!-- static sparks -->
  <path d="M16 26 l4 -2 -2 4 4 -1 -5 4 1 -3 z" fill="#ffe14d"/>
  <path d="M102 30 l-4 -2 2 4 -4 -1 5 4 -1 -3 z" fill="#ffe14d"/>
</svg>`;

const sylvaneSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="syl-body" cx="42%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#d3f2b7"/><stop offset="55%" stop-color="#96d477"/><stop offset="100%" stop-color="#5aa348"/>
    </radialGradient>
    <linearGradient id="syl-leaf" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#8fdd6b"/><stop offset="100%" stop-color="#3f8f3a"/>
    </linearGradient>
    <radialGradient id="syl-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#ffd166"/><stop offset="100%" stop-color="#8a4b00"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="108" rx="30" ry="6" fill="rgba(0,0,0,0.25)"/>
  <!-- leaf wings -->
  <path d="M22 62 Q2 58 0 40 Q10 48 18 46 Q6 38 8 24 Q18 36 28 38 Q36 52 22 62 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M98 62 Q118 58 120 40 Q110 48 102 46 Q114 38 112 24 Q102 36 92 38 Q84 52 98 62 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M10 44 Q16 44 24 50 M110 44 Q104 44 96 50" fill="none" stroke="#2f6b2c" stroke-width="1.6"/>
  <!-- tail leaf -->
  <path d="M74 92 Q88 96 96 88 Q88 86 86 82 Q96 82 98 74 Q86 76 78 80 Q72 86 74 92 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- body -->
  <path d="M34 74 Q32 56 58 54 Q86 54 86 76 Q86 96 60 100 Q36 98 34 74 Z" fill="url(#syl-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- belly with seed spots -->
  <ellipse cx="60" cy="80" rx="17" ry="14" fill="#f2ffe3"/>
  <circle cx="54" cy="76" r="2" fill="#a9c98a"/><circle cx="66" cy="76" r="2" fill="#a9c98a"/><circle cx="60" cy="86" r="2" fill="#a9c98a"/>
  <!-- talons -->
  <path d="M46 100 l-3 6 M50 101 l0 6 M54 100 l3 6" stroke="${OUT}" stroke-width="2.6" stroke-linecap="round"/>
  <path d="M66 100 l-3 6 M70 101 l0 6 M74 100 l3 6" stroke="${OUT}" stroke-width="2.6" stroke-linecap="round"/>
  <!-- head -->
  <path d="M28 36 Q28 12 58 10 Q90 10 90 36 Q90 58 59 58 Q28 58 28 36 Z" fill="url(#syl-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- leaf brow crown -->
  <path d="M44 12 Q40 2 30 4 Q36 8 36 12 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="M58 10 Q58 0 48 -2 Q52 6 50 10 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <path d="M72 12 Q76 2 86 4 Q80 8 80 12 Z" fill="url(#syl-leaf)" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
  <!-- facial disc -->
  <path d="M36 36 Q36 20 58 19 Q82 20 82 36 Q82 52 59 52 Q36 52 36 36 Z" fill="#f2ffe3" opacity="0.9"/>
  <!-- eyes -->
  <ellipse cx="46" cy="35" rx="8.5" ry="10" fill="#fff"/>
  <ellipse cx="47" cy="36" rx="6.5" ry="8" fill="url(#syl-eye)"/>
  <circle cx="47.5" cy="37" r="3" fill="#241303"/>
  <circle cx="44.5" cy="32.5" r="2.3" fill="#fff"/>
  <circle cx="50" cy="40" r="1.2" fill="#fff" opacity="0.85"/>
  <ellipse cx="72" cy="35" rx="8.5" ry="10" fill="#fff"/>
  <ellipse cx="71" cy="36" rx="6.5" ry="8" fill="url(#syl-eye)"/>
  <circle cx="70.5" cy="37" r="3" fill="#241303"/>
  <circle cx="68" cy="32.5" r="2.3" fill="#fff"/>
  <circle cx="74" cy="40" r="1.2" fill="#fff" opacity="0.85"/>
  <!-- beak -->
  <path d="M55 42 Q59 40 63 42 L59 50 Z" fill="#f5a623" stroke="${OUT}" stroke-width="2" stroke-linejoin="round"/>
</svg>`;

const brammothSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="bra-body" cx="42%" cy="28%" r="85%">
      <stop offset="0%" stop-color="#d9d3cc"/><stop offset="55%" stop-color="#a89f96"/><stop offset="100%" stop-color="#6f655c"/>
    </radialGradient>
    <linearGradient id="bra-moss" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#9ed474"/><stop offset="100%" stop-color="#5d9e46"/>
    </linearGradient>
    <radialGradient id="bra-eye" cx="40%" cy="40%" r="80%">
      <stop offset="0%" stop-color="#ffd97a"/><stop offset="100%" stop-color="#e8801a"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="109" rx="36" ry="6.5" fill="rgba(0,0,0,0.28)"/>
  <!-- back boulder plates -->
  <path d="M30 52 L24 34 L40 24 L44 40 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M76 40 L80 22 L98 32 L90 50 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M54 30 L58 12 L74 20 L68 36 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- moss patch on plates -->
  <path d="M56 30 Q60 22 68 24 Q66 30 60 32 Z" fill="url(#bra-moss)"/>
  <!-- massive arms -->
  <path d="M14 62 Q6 78 16 92 Q28 100 34 90 Q38 78 30 66 Q22 56 14 62 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M106 62 Q114 78 104 92 Q92 100 86 90 Q82 78 90 66 Q98 56 106 62 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- knuckle cracks -->
  <path d="M18 84 l8 2 M94 84 l8 -2" stroke="#4d443c" stroke-width="2" stroke-linecap="round"/>
  <!-- body: craggy torso -->
  <path d="M30 66 L36 44 L60 38 L86 46 L90 70 L82 94 L58 102 L36 94 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- crack lines -->
  <path d="M44 58 l10 6 M70 52 l-6 10 M52 84 l10 -4" stroke="#4d443c" stroke-width="2" stroke-linecap="round"/>
  <!-- moss chest -->
  <path d="M46 70 Q60 62 74 70 Q72 82 60 84 Q48 82 46 70 Z" fill="url(#bra-moss)" opacity="0.9"/>
  <!-- face plate -->
  <path d="M40 48 L60 42 L80 50 L76 66 L58 72 L42 64 Z" fill="#c4bbb1" stroke="${OUT}" stroke-width="2.4" stroke-linejoin="round"/>
  <!-- glowing gem eyes -->
  <path d="M48 54 l7 -3 2 8 -7 3 Z" fill="url(#bra-eye)" stroke="${OUT}" stroke-width="1.6"/>
  <path d="M72 55 l-7 -3 -2 8 7 3 Z" fill="url(#bra-eye)" stroke="${OUT}" stroke-width="1.6"/>
  <circle cx="51" cy="55" r="1.4" fill="#fff8e0"/>
  <circle cx="68" cy="56" r="1.4" fill="#fff8e0"/>
  <!-- sturdy mouth -->
  <path d="M52 66 L60 68 L68 66" fill="none" stroke="${OUT}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- feet -->
  <path d="M40 96 Q38 108 50 108 Q56 106 52 96 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M68 98 Q66 110 78 108 Q84 106 80 96 Z" fill="url(#bra-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- floating pebbles -->
  <circle cx="12" cy="40" r="3" fill="url(#bra-body)" stroke="${OUT}" stroke-width="1.6"/>
  <circle cx="108" cy="44" r="2.4" fill="url(#bra-body)" stroke="${OUT}" stroke-width="1.6"/>
</svg>`;

const nyxisSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="nyx-body" cx="42%" cy="28%" r="85%">
      <stop offset="0%" stop-color="#cdb6f2"/><stop offset="55%" stop-color="#9a72d8"/><stop offset="100%" stop-color="#5f3d9e"/>
    </radialGradient>
    <linearGradient id="nyx-wisp" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#b895ec"/><stop offset="100%" stop-color="#5f3d9e" stop-opacity="0.15"/>
    </linearGradient>
    <radialGradient id="nyx-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#9ff7ee"/><stop offset="100%" stop-color="#0e9a8c"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="108" rx="26" ry="5" fill="rgba(0,0,0,0.2)"/>
  <!-- wisp tail trail -->
  <path d="M78 74 Q98 70 102 52 Q104 66 96 78 Q108 76 112 66 Q112 84 94 90 Q82 92 76 84 Z" fill="url(#nyx-wisp)" stroke="${OUT}" stroke-width="2.4" stroke-linejoin="round"/>
  <!-- lower body dissolving into wisps -->
  <path d="M36 70 Q34 52 60 50 Q86 52 84 72 Q84 88 74 94 Q76 100 68 100 Q66 94 60 96 Q58 102 50 100 Q50 94 44 92 Q36 84 36 70 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- crescent chest mark -->
  <path d="M52 72 Q50 80 58 84 Q52 86 47 81 Q44 74 50 69 Q51 70 52 72 Z" fill="#ffe27a"/>
  <!-- arms: little wisp paws -->
  <path d="M34 72 Q24 74 22 82 Q30 82 34 78 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="2.4" stroke-linejoin="round"/>
  <path d="M86 72 Q96 74 98 82 Q90 82 86 78 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="2.4" stroke-linejoin="round"/>
  <!-- head -->
  <path d="M28 34 Q28 10 58 8 Q90 8 90 34 Q90 54 59 54 Q28 54 28 34 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- pointed ghost-cat ears -->
  <path d="M34 22 L28 0 L50 12 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M84 22 L92 0 L68 12 Z" fill="url(#nyx-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M37 17 L33 6 L45 13 Z" fill="#3c2566"/>
  <path d="M81 17 L86 6 L73 13 Z" fill="#3c2566"/>
  <!-- big glow eyes -->
  <ellipse cx="45" cy="33" rx="8.5" ry="10.5" fill="#fff"/>
  <ellipse cx="46" cy="34" rx="6.5" ry="8.5" fill="url(#nyx-eye)"/>
  <ellipse cx="46.5" cy="35" rx="2.6" ry="3.4" fill="#04211e"/>
  <circle cx="43.5" cy="30" r="2.3" fill="#fff"/>
  <circle cx="49" cy="38.5" r="1.2" fill="#fff" opacity="0.85"/>
  <ellipse cx="73" cy="33" rx="8.5" ry="10.5" fill="#fff"/>
  <ellipse cx="72" cy="34" rx="6.5" ry="8.5" fill="url(#nyx-eye)"/>
  <ellipse cx="71.5" cy="35" rx="2.6" ry="3.4" fill="#04211e"/>
  <circle cx="69" cy="30" r="2.3" fill="#fff"/>
  <circle cx="75" cy="38.5" r="1.2" fill="#fff" opacity="0.85"/>
  <!-- cat smile with fang -->
  <path d="M52 45 Q56 49 60 45 Q64 49 68 45" fill="none" stroke="${OUT}" stroke-width="2.2" stroke-linecap="round"/>
  <path d="M56 46 l2 4 2 -4 Z" fill="#fff"/>
  <!-- forehead moon -->
  <path d="M58 14 Q54 18 58 24 Q52 22 52 17 Q54 13 58 14 Z" fill="#ffe27a"/>
  <!-- ambient wisps -->
  <path d="M16 52 Q12 46 18 42 Q16 48 22 50 Z" fill="#b895ec" opacity="0.7"/>
  <path d="M104 40 Q108 34 102 30 Q104 36 98 38 Z" fill="#b895ec" opacity="0.7"/>
</svg>`;

const torvokSvg = `
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="tor-body" cx="42%" cy="30%" r="85%">
      <stop offset="0%" stop-color="#9ff0d8"/><stop offset="55%" stop-color="#4ecfa4"/><stop offset="100%" stop-color="#1f8f6e"/>
    </radialGradient>
    <linearGradient id="tor-shell" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#3a6ea8"/><stop offset="100%" stop-color="#1d3f6e"/>
    </linearGradient>
    <radialGradient id="tor-eye" cx="35%" cy="35%" r="80%">
      <stop offset="0%" stop-color="#ffb547"/><stop offset="100%" stop-color="#9e3d00"/>
    </radialGradient>
  </defs>
  <ellipse cx="60" cy="108" rx="33" ry="6" fill="rgba(0,0,0,0.25)"/>
  <!-- spiked shell behind -->
  <path d="M24 70 Q18 34 60 30 Q102 34 96 70 Q92 92 60 94 Q28 92 24 70 Z" fill="url(#tor-shell)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <path d="M38 38 L34 24 L48 32 Z M56 32 L60 18 L66 32 Z M76 34 L86 24 L82 38 Z" fill="#e8f4ff" stroke="${OUT}" stroke-width="2.4" stroke-linejoin="round"/>
  <!-- shell rim -->
  <path d="M28 70 Q30 84 46 88 M92 70 Q90 84 74 88" fill="none" stroke="#142c4e" stroke-width="3" stroke-linecap="round"/>
  <!-- body/head emerging -->
  <path d="M34 66 Q34 44 60 42 Q86 44 86 66 Q86 88 60 92 Q34 88 34 66 Z" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- belly plate -->
  <path d="M46 70 Q46 60 60 60 Q74 60 74 70 Q74 84 60 86 Q46 84 46 70 Z" fill="#f4ffe8"/>
  <path d="M50 66 h20 M48 74 h24 M52 82 h16" stroke="#c9dbb4" stroke-width="2"/>
  <!-- arms -->
  <ellipse cx="34" cy="76" rx="9" ry="6.5" transform="rotate(-26 34 76)" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="86" cy="76" rx="9" ry="6.5" transform="rotate(26 86 76)" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- feet -->
  <ellipse cx="47" cy="98" rx="10" ry="6" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <ellipse cx="73" cy="98" rx="10" ry="6" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}"/>
  <!-- head -->
  <path d="M32 30 Q34 8 60 8 Q86 8 88 30 Q88 50 60 50 Q32 50 32 30 Z" fill="url(#tor-body)" stroke="${OUT}" stroke-width="${SW}" stroke-linejoin="round"/>
  <!-- snout -->
  <path d="M48 36 Q48 28 60 28 Q72 28 72 36 Q72 44 60 44 Q48 44 48 36 Z" fill="#d8fbea"/>
  <circle cx="56" cy="34" r="1.6" fill="${OUT}"/>
  <circle cx="64" cy="34" r="1.6" fill="${OUT}"/>
  <path d="M54 40 Q60 44 66 40" fill="none" stroke="${OUT}" stroke-width="2.2" stroke-linecap="round"/>
  <!-- eyes -->
  <ellipse cx="42" cy="26" rx="7" ry="8.5" fill="#fff"/>
  <ellipse cx="43" cy="27" rx="5.2" ry="6.8" fill="url(#tor-eye)"/>
  <circle cx="43.5" cy="28" r="2.4" fill="#230a00"/>
  <circle cx="41" cy="24" r="1.9" fill="#fff"/>
  <ellipse cx="78" cy="26" rx="7" ry="8.5" fill="#fff"/>
  <ellipse cx="77" cy="27" rx="5.2" ry="6.8" fill="url(#tor-eye)"/>
  <circle cx="76.5" cy="28" r="2.4" fill="#230a00"/>
  <circle cx="74.5" cy="24" r="1.9" fill="#fff"/>
  <!-- water squirt -->
  <path d="M20 30 Q14 24 18 16 Q22 22 28 22 Q24 28 20 30 Z" fill="#7ad4ff" opacity="0.8"/>
</svg>`;

export const CREATURES: Creature[] = [
  {
    id: "emberyx",
    name: "Emberyx",
    species: "Kindle Fox",
    type: "Fire",
    role: "Assassin",
    flavor:
      "A restless fox kit whose twin tails burn hotter the faster it runs. It naps in campfires for fun.",
    color: "#ff8a3d",
    stats: { hp: 620, atk: 62, def: 0.08, speed: 235, range: 70, atkSpd: 1.25 },
    abilities: [
      {
        name: "Flame Dash",
        desc: "Dash forward, scorching everything along the path.",
        kind: "dash",
        cd: 5,
        dmg: 70,
        range: 240,
        color: "#ff9d3d",
      },
      {
        name: "Fire Spin",
        desc: "Erupt in a ring of flame, burning nearby enemies.",
        kind: "nova",
        cd: 8,
        dmg: 110,
        radius: 150,
        color: "#ff6a00",
      },
      {
        name: "Kindle",
        desc: "Fan the flames: attack speed +60% for 5s.",
        kind: "buff",
        cd: 14,
        amount: 1.6,
        duration: 5,
        color: "#ffc233",
      },
    ],
    svg: emberyxSvg,
  },
  {
    id: "marloch",
    name: "Marloch",
    species: "Tide Axolotl",
    type: "Water",
    role: "Battle Mage",
    flavor:
      "Its feathered gills read water currents like sheet music. Hums when it charges a spell.",
    color: "#5fd0e8",
    stats: { hp: 700, atk: 58, def: 0.1, speed: 205, range: 200, atkSpd: 0.95 },
    abilities: [
      {
        name: "Bubble Jet",
        desc: "Fire a piercing jet of pressurized bubbles.",
        kind: "projectile",
        cd: 4,
        dmg: 95,
        range: 420,
        speed: 520,
        pierce: true,
        color: "#7ad4ff",
      },
      {
        name: "Tide Ward",
        desc: "Wrap in a water veil that absorbs 220 damage.",
        kind: "shield",
        cd: 12,
        amount: 220,
        duration: 6,
        color: "#9be8ff",
      },
      {
        name: "Riptide",
        desc: "A crashing wave slows and batters nearby foes.",
        kind: "nova",
        cd: 10,
        dmg: 85,
        radius: 170,
        slow: 0.45,
        duration: 2.5,
        color: "#4fc3f7",
      },
    ],
    svg: marlochSvg,
  },
  {
    id: "zaplit",
    name: "Zaplit",
    species: "Storm Pup",
    type: "Electric",
    role: "Burst Caster",
    flavor:
      "Static builds in its bolt-shaped ears until they crackle. Petting it is a calculated risk.",
    color: "#ffd94f",
    stats: { hp: 560, atk: 68, def: 0.05, speed: 225, range: 210, atkSpd: 1.1 },
    abilities: [
      {
        name: "Volt Bolt",
        desc: "Hurl a crackling bolt that zaps the first foe hit.",
        kind: "projectile",
        cd: 3.5,
        dmg: 105,
        range: 440,
        speed: 600,
        color: "#ffe14d",
      },
      {
        name: "Static Field",
        desc: "Discharge a field that shocks and slows enemies.",
        kind: "nova",
        cd: 9,
        dmg: 90,
        radius: 160,
        slow: 0.5,
        duration: 2,
        color: "#fff2a8",
      },
      {
        name: "Overcharge",
        desc: "Supercharge: attack speed +80% for 4s.",
        kind: "buff",
        cd: 15,
        amount: 1.8,
        duration: 4,
        color: "#ffc400",
      },
    ],
    svg: zaplitSvg,
  },
  {
    id: "sylvane",
    name: "Sylvane",
    species: "Grove Owl",
    type: "Grass",
    role: "Ranger",
    flavor:
      "Grows a new brow-leaf each season and remembers every forest it has ever flown over.",
    color: "#96d477",
    stats: { hp: 640, atk: 60, def: 0.08, speed: 215, range: 240, atkSpd: 1.0 },
    abilities: [
      {
        name: "Leaf Blade",
        desc: "Launch a razor leaf that pierces through enemies.",
        kind: "projectile",
        cd: 4,
        dmg: 90,
        range: 460,
        speed: 560,
        pierce: true,
        color: "#8fdd6b",
      },
      {
        name: "Verdant Bloom",
        desc: "Blossom and restore 200 HP over the bloom.",
        kind: "heal",
        cd: 13,
        amount: 200,
        color: "#c8f7a8",
      },
      {
        name: "Vine Snare",
        desc: "Roots the nearest enemy in place for 1.8s.",
        kind: "snare",
        cd: 11,
        dmg: 55,
        range: 300,
        duration: 1.8,
        color: "#5aa348",
      },
    ],
    svg: sylvaneSvg,
  },
  {
    id: "brammoth",
    name: "Brammoth",
    species: "Moss Golem",
    type: "Rock",
    role: "Juggernaut",
    flavor:
      "Woke up after a three-century nap with a garden on its back. Refuses to weed it.",
    color: "#a89f96",
    stats: { hp: 920, atk: 55, def: 0.22, speed: 175, range: 80, atkSpd: 0.8 },
    abilities: [
      {
        name: "Boulder Toss",
        desc: "Lob a boulder that cracks down in an area.",
        kind: "projectile",
        cd: 6,
        dmg: 100,
        range: 380,
        speed: 420,
        radius: 90,
        color: "#c4bbb1",
      },
      {
        name: "Stone Aegis",
        desc: "Harden: absorb 300 damage for 6s.",
        kind: "shield",
        cd: 14,
        amount: 300,
        duration: 6,
        color: "#d9d3cc",
      },
      {
        name: "Quake",
        desc: "Slam the ground, damaging and slowing all around.",
        kind: "nova",
        cd: 10,
        dmg: 120,
        radius: 190,
        slow: 0.4,
        duration: 2.2,
        color: "#8d7f6f",
      },
    ],
    svg: brammothSvg,
  },
  {
    id: "nyxis",
    name: "Nyxis",
    species: "Wisp Cat",
    type: "Ghost",
    role: "Trickster",
    flavor:
      "Half here, half elsewhere. Its purr is only audible to people it is about to ambush.",
    color: "#9a72d8",
    stats: { hp: 580, atk: 66, def: 0.06, speed: 230, range: 190, atkSpd: 1.15 },
    abilities: [
      {
        name: "Shadow Bolt",
        desc: "A homing orb of dusk that seeks the nearest foe.",
        kind: "projectile",
        cd: 3.5,
        dmg: 100,
        range: 420,
        speed: 480,
        color: "#b895ec",
      },
      {
        name: "Phase Step",
        desc: "Blink a short distance in your move direction.",
        kind: "blink",
        cd: 8,
        range: 260,
        color: "#cdb6f2",
      },
      {
        name: "Dread Howl",
        desc: "A chilling howl damages and slows all nearby foes.",
        kind: "nova",
        cd: 11,
        dmg: 95,
        radius: 180,
        slow: 0.5,
        duration: 2.4,
        color: "#5f3d9e",
      },
    ],
    svg: nyxisSvg,
  },
  {
    id: "torvok",
    name: "Torvok",
    species: "Reef Snapper",
    type: "Water",
    role: "Guardian",
    flavor:
      "Its spiked shell is a living reef; tiny fish rent space between the spines and pay in gossip.",
    color: "#4ecfa4",
    stats: { hp: 860, atk: 52, def: 0.18, speed: 185, range: 90, atkSpd: 0.9 },
    abilities: [
      {
        name: "Shell Spikes",
        desc: "Spin, flinging shell spikes at everything nearby.",
        kind: "nova",
        cd: 7,
        dmg: 95,
        radius: 165,
        color: "#e8f4ff",
      },
      {
        name: "Snap Current",
        desc: "A pressured torrent that shoves through foes.",
        kind: "projectile",
        cd: 5,
        dmg: 85,
        range: 360,
        speed: 460,
        pierce: true,
        color: "#7ad4ff",
      },
      {
        name: "Reef Mend",
        desc: "Barnacle regrowth restores 240 HP.",
        kind: "heal",
        cd: 14,
        amount: 240,
        color: "#9ff0d8",
      },
    ],
    svg: torvokSvg,
  },
];

export function creatureById(id: string): Creature {
  const c = CREATURES.find((c) => c.id === id);
  if (!c) throw new Error(`unknown creature: ${id}`);
  return c;
}

export function svgDataUri(svg: string): string {
  return `data:image/svg+xml;utf8,${encodeURIComponent(svg)}`;
}

export function CreatureArt({
  creature,
  className,
}: {
  creature: Creature;
  className?: string;
}) {
  return (
    <div
      className={className}
      role="img"
      aria-label={`${creature.name} the ${creature.species}`}
      dangerouslySetInnerHTML={{ __html: creature.svg }}
    />
  );
}
