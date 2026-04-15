--!strict

-- Sound ID registry. Swap asset IDs here without touching SoundClient.
-- All IDs are free Roblox catalog audio — replace with custom tracks before launch.

local SoundConfig = {}

SoundConfig.IDs = {
	-- Combat
	Hit          = "rbxassetid://188959318",   -- short punch impact
	KO           = "rbxassetid://111624261",   -- knockdown thud
	HitReceived  = "rbxassetid://131070686",   -- player getting hit

	-- Abilities
	Dash         = "rbxassetid://182765513",   -- VIPER phantom dash whoosh
	ShieldBash   = "rbxassetid://186311262",   -- TANK bash boom
	Cloak        = "rbxassetid://131070686",   -- GHOST cloak shimmer
	Thunderclap  = "rbxassetid://154965962",   -- SPARK crack
	BlitzRush    = "rbxassetid://182765513",   -- SURGE rush wind
	DeathMark    = "rbxassetid://130826403",   -- REAPER mark curse

	-- Core
	CorePickup   = "rbxassetid://131076114",   -- grab
	CoreDrop     = "rbxassetid://131070686",   -- drop clunk
	CoreReturn   = "rbxassetid://131076114",   -- respawn hum
	CoreEscape   = "rbxassetid://134978101",   -- victory sting

	-- Match
	MatchStart   = "rbxassetid://132514059",   -- start bell
	MatchEnd     = "rbxassetid://131070695",   -- end horn
	SuddenDeath  = "rbxassetid://154965962",   -- alarm
	Countdown    = "rbxassetid://135654657",   -- tick

	-- Progression
	LevelUp      = "rbxassetid://527072669",   -- level up chime
	XPGain       = "rbxassetid://131070686",   -- small tick
}

SoundConfig.Volume = {
	Hit         = 0.5,
	KO          = 0.7,
	Ability     = 0.6,
	Core        = 0.65,
	Match       = 0.8,
	LevelUp     = 0.9,
}

return SoundConfig
