--!strict

-- Defines all playable characters.
-- Stats are multipliers applied on top of GameConfig base values.

local CharacterConfig = {}

CharacterConfig.Characters = {

	VIPER = {
		DisplayName = "VIPER",
		Tagline     = "Strike from nowhere.",
		Color       = Color3.fromHex("#00FF88"),
		Description = "A ghost-step assassin who blinks through the chaos. Low health, maximum surprise.",
		Passive     = {
			Name        = "Slip",
			Description = "Leaves a slow-zone trail for 1.5s wherever she walks.",
		},
		Ability = {
			Name        = "Phantom Dash",
			Description = "Blink 22 studs forward instantly.",
			Cooldown    = 3,
			Key         = "E",
		},
		Stats = { SpeedMult = 1.08, HealthMult = 0.85 },
	},

	TANK = {
		DisplayName = "TANK",
		Tagline     = "Carry the Core. Break the line.",
		Color       = Color3.fromHex("#FF6B35"),
		Description = "Armored brawler built for holding the Core and punching through defenders.",
		Passive     = {
			Name        = "Iron Carry",
			Description = "No speed penalty while holding the Core.",
		},
		Ability = {
			Name        = "Shield Bash",
			Description = "Blast all enemies in a forward cone — knockback + 15 damage.",
			Cooldown    = 5,
			Key         = "E",
		},
		Stats = { SpeedMult = 0.9, HealthMult = 1.35 },
	},

	GHOST = {
		DisplayName = "GHOST",
		Tagline     = "Disappear. Reappear. Win.",
		Color       = Color3.fromHex("#B8C0FF"),
		Description = "A phantom striker who vanishes at will. Impossible to track, deadly to ignore.",
		Passive     = {
			Name        = "Silent Step",
			Description = "Footstep sounds muted. Slightly smaller nameplate.",
		},
		Ability = {
			Name        = "Cloak",
			Description = "Become near-invisible for 2.5 seconds. Cannot attack while cloaked.",
			Cooldown    = 8,
			Key         = "E",
		},
		Stats = { SpeedMult = 1.1, HealthMult = 0.8 },
	},

	SPARK = {
		DisplayName = "SPARK",
		Tagline     = "One zap. Everyone drops.",
		Color       = Color3.fromHex("#FFD60A"),
		Description = "High-energy disruptor who freezes entire squads. Average stats, zero forgiveness.",
		Passive     = {
			Name        = "Live Wire",
			Description = "+8 damage on the first hit each life.",
		},
		Ability = {
			Name        = "Thunderclap",
			Description = "Stun + 10 damage to all enemies within 14 studs.",
			Cooldown    = 7,
			Key         = "E",
		},
		Stats = { SpeedMult = 1.0, HealthMult = 1.0 },
	},
}

-- Deterministic order for UI display
CharacterConfig.Order = { "VIPER", "TANK", "GHOST", "SPARK" }

return CharacterConfig
