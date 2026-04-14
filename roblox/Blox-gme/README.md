# Blox-gme

New Roblox game — concept TBD.

## Folder Layout

- `ReplicatedStorage/Modules`
  - `GameConfig.lua` — global tuning and constants
- `ServerScriptService`
  - `Main.server.lua` — bootstrap and service wiring
  - `Services/PlayerService.lua` — player join/leave and data init
  - `Services/WorldService.lua` — map setup and environment
- `StarterPlayer/StarterPlayerScripts/GameClient.client.lua` — client HUD and input

## Notes

- Architecture mirrors the modular service pattern from StealABrainrotNeonCompound.
- Game-specific services to be added once core loop is defined.
