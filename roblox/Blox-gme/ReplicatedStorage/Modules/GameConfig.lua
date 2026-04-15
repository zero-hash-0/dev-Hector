--!strict

-- Central tuning for Blox-gme.
-- All numbers live here — touch this file, not the services.

local GameConfig = {}

-- Match
GameConfig.MAX_PLAYERS      = 12
GameConfig.MIN_PLAYERS_START = 2   -- minimum to begin a match
GameConfig.MATCH_DURATION   = 180  -- seconds
GameConfig.COUNTDOWN        = 5    -- pre-match countdown seconds

-- Core
GameConfig.CORE_SPAWN_HEIGHT   = 5    -- studs above map center
GameConfig.CORE_DROP_ON_DEATH  = true -- carrier drops Core on KO
GameConfig.CORE_RETURN_DELAY   = 10   -- seconds before uncarried Core resets to center

-- Combat
GameConfig.BASE_HEALTH      = 100
GameConfig.BASE_DAMAGE      = 20
GameConfig.KNOCKBACK_FORCE  = 60   -- studs/sec
GameConfig.STUN_DURATION    = 0.6  -- seconds
GameConfig.ATTACK_COOLDOWN  = 0.4  -- seconds
GameConfig.ATTACK_RANGE     = 6    -- studs

-- Movement
GameConfig.WALK_SPEED       = 16
GameConfig.SPRINT_SPEED     = 26
GameConfig.DASH_FORCE       = 80
GameConfig.DASH_COOLDOWN    = 1.2  -- seconds
GameConfig.CARRIER_PENALTY  = 0.8  -- speed multiplier while holding Core

-- Escape zones (assigned per team/player at match start)
GameConfig.ESCAPE_ZONE_SIZE = Vector3.new(12, 10, 12)

-- Colors
GameConfig.Colors = {
	Core      = Color3.fromHex("#FFD700"),
	Highlight = Color3.fromHex("#00FFFF"),
	Danger    = Color3.fromHex("#FF3333"),
	Neutral   = Color3.fromHex("#FFFFFF"),
}

return GameConfig
