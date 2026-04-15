# Testing Blox-gme in Roblox Studio

---

## One-Time Setup (do this once on your machine)

### 1. Install Aftman (Roblox toolchain manager)

**Windows:**
```
https://github.com/LPGhatguy/aftman/releases/latest
→ download aftman-windows.zip → extract → run aftman self-install
```

**Mac:**
```
https://github.com/LPGhatguy/aftman/releases/latest
→ download aftman-macos.zip → extract → run ./aftman self-install
```

### 2. Install Rojo (syncs files → Studio)

In the `roblox/Blox-gme/` folder:
```bash
aftman install
```
This reads `aftman.toml` and installs Rojo 7.4.4 automatically.

### 3. Install the Rojo Studio plugin (one time)

In Roblox Studio:
```
Plugins → Manage Plugins → search "Rojo" → install the one by rojo-rbx
```
Or: https://create.roblox.com/store/asset/13916111975

---

## Every Time You Test

### Step 1 — Start the Rojo server

In terminal, navigate to the game folder:
```bash
cd path/to/dev-Hector/roblox/Blox-gme
rojo serve
```
You'll see: `Rojo server listening on port 34872`

### Step 2 — Open Studio

- Open **Roblox Studio**
- Create a **New Baseplate** (File → New → Baseplate)
- In the Rojo plugin panel (top toolbar), click **Connect**
- Status should say: `Connected to localhost:34872`

All scripts now live-sync. Any save on disk → Studio updates instantly.

### Step 3 — Hit Play

Press **F5** (Play Solo) or the green Play button.

---

## What You Should See

| What | Expected |
|---|---|
| Character select screen | Appears immediately — 6 cards (VIPER, TANK, GHOST, SPARK, SURGE, REAPER) |
| Select a character + Confirm | Card locks in, screen fades |
| Match countdown | "5… 4… 3…" banner |
| Arena | Dark night arena, neon escape zone pads in corners, center platform |
| The Core | Gold glowing sphere bobbing at center |
| Walk up to Core | ProximityPrompt appears — press E to grab |
| Grab Core | Speed slightly reduced, HUD banner changes |
| Walk to your escape zone pad | Win declared |
| Health bar | Bottom left — turns red below 40% HP |
| Timer | Top center |
| Dash cooldown ring | Bottom right |
| Core tracker arrow | Center screen — rotates toward Core |

---

## Known Test Limitations

| Issue | Why | Fix |
|---|---|---|
| No enemies | Solo test = 1 player | Use Studio **Team Test** (2+ clients) or invite a friend |
| DataStore won't save XP | Studio API access off by default | Game Settings → Security → Enable Studio Access to API Services |
| Sounds are wrong/missing | Placeholder Roblox asset IDs | Replace IDs in `SoundConfig.lua` with your custom audio |
| Ability VFX parts stay in Workspace | Debris service may not run in certain test modes | Harmless, clears on server reset |

---

## Testing Multiplayer Locally (2 players, 1 machine)

In Studio:
```
Test tab → Team Test → Start
```
This opens multiple Studio clients on one machine. Works great for testing
combat, Core handoffs, and escape sequences.

---

## Common Issues

**"WaitForChild timed out" error**
→ Rojo didn't sync before Play. Stop the game, check Rojo plugin says Connected, try again.

**Character select appears but Confirm does nothing**
→ Check Output panel for errors. Usually a remote event timing issue — hit Play again.

**Core doesn't spawn**
→ Match needs to reach Active state. Check MIN_PLAYERS_START in GameConfig.lua (should be 1 for solo).

**Arena is missing / just a baseplate**
→ WorldService:BuildMap() runs on server start. Check Output for script errors in Main.server.lua.

---

## Changing Game Feel Fast

All tuning lives in `GameConfig.lua` — change these without touching any other file:

```lua
GameConfig.MATCH_DURATION   = 180   -- shorter for quick tests, e.g. 60
GameConfig.ATTACK_RANGE     = 6     -- increase for easier hitting
GameConfig.CARRIER_PENALTY  = 0.8   -- lower = slower carrier = harder to escape
GameConfig.DASH_COOLDOWN    = 1.2   -- lower = more dashes = faster chaos
GameConfig.BASE_DAMAGE      = 20    -- higher = quicker KOs
```
