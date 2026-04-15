# Blox-gme

Real-time action PvP — move freely, fight players, steal the Core, escape.

## Core Loop

1. Match starts → **Core spawns** at map center
2. Players **chase and fight** each other in real time
3. One player **grabs the Core** (slowed while carrying)
4. Carrier must **reach their escape zone** before time runs out or getting KO'd
5. Defender KOs carrier → **Core drops**, anyone can pick it up
6. First to escape wins — no winner when time expires

## Controls

| Key | Action |
|-----|--------|
| `F` | Attack nearest player |
| `Shift` | Sprint |
| `Q` | Dash (directional, cooldown) |
| Walk into Core | Pick up Core (ProximityPrompt) |

## Folder Layout

- `ReplicatedStorage/Modules/`
  - `GameConfig.lua` — all tuning values (health, speed, cooldowns, timing)
- `ServerScriptService/`
  - `Main.server.lua` — bootstrap & service wiring
  - `Services/MatchService.lua` — match state machine (Waiting → Countdown → Active → Ended)
  - `Services/CoreService.lua` — Core spawn, pickup, drop, return, escape detection
  - `Services/CombatService.lua` — server-authoritative damage, knockback, stun
  - `Services/MovementService.lua` — sprint & dash, server-validated cooldowns
  - `Services/PlayerService.lua` — join/leave lifecycle, health init, respawn
  - `Services/WorldService.lua` — map build & lighting
- `StarterPlayer/StarterPlayerScripts/`
  - `GameClient.client.lua` — input (attack, sprint, dash), HUD & event display

## Art Style

See [`ART_STYLE.md`](./ART_STYLE.md) for the character card illustration guide.
