--!strict

local GameConfig = {
	MaxPlayers = 6,
	IncomeTickSeconds = 1,
	CarrySpeedMultiplier = 0.72,
	CarryJumpPowerMultiplier = 0.85,
	AttackCooldown = 0.6,
	AttackRange = 9,
	AttackDamage = 5,
	BaseRadius = 140,
	CompoundSize = Vector3.new(56, 1, 56),
	StorageSlotsDefault = 6,
	WorldCenter = Vector3.new(0, 0, 0),
	Palette = {
		Midnight = Color3.fromRGB(20, 13, 45),
		ElectricBlue = Color3.fromRGB(40, 84, 255),
		NeonCyan = Color3.fromRGB(70, 240, 255),
		HotMagenta = Color3.fromRGB(255, 70, 196),
		ToxicLime = Color3.fromRGB(153, 255, 86),
		DarkSurface = Color3.fromRGB(10, 11, 17),
		BrightLine = Color3.fromRGB(230, 238, 255),
	},
	TeamAccents = {
		Color3.fromRGB(70, 240, 255),
		Color3.fromRGB(255, 70, 196),
		Color3.fromRGB(153, 255, 86),
		Color3.fromRGB(255, 148, 66),
		Color3.fromRGB(155, 95, 255),
		Color3.fromRGB(255, 73, 73),
	},
	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" },
	RarityColors = {
		Common = Color3.fromRGB(205, 215, 225),
		Uncommon = Color3.fromRGB(125, 236, 116),
		Rare = Color3.fromRGB(70, 212, 255),
		Epic = Color3.fromRGB(204, 122, 255),
		Legendary = Color3.fromRGB(255, 166, 74),
		Mythic = Color3.fromRGB(255, 76, 180),
	},
}

return GameConfig
