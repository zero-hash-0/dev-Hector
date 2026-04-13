--!strict

local BrainrotConfig = {
	ScreamingCube = {
		Id = "ScreamingCube",
		DisplayName = "Screaming Cube",
		Rarity = "Common",
		BaseValue = 20,
		IncomePerSecond = 3,
		Shape = Enum.PartType.Block,
		Size = Vector3.new(2.4, 2.4, 2.4),
		SpinSpeed = 24,
	},
	GlitchOrb = {
		Id = "GlitchOrb",
		DisplayName = "Glitch Orb",
		Rarity = "Rare",
		BaseValue = 80,
		IncomePerSecond = 9,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.8, 2.8, 2.8),
		SpinSpeed = 38,
	},
	DancingNoobIdol = {
		Id = "DancingNoobIdol",
		DisplayName = "Dancing Noob Idol",
		Rarity = "Epic",
		BaseValue = 160,
		IncomePerSecond = 16,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2.3, 3.6, 2.3),
		SpinSpeed = 55,
	},
	CryingEmojiCore = {
		Id = "CryingEmojiCore",
		DisplayName = "Crying Emoji Core",
		Rarity = "Legendary",
		BaseValue = 300,
		IncomePerSecond = 28,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3.2, 3.2, 3.2),
		SpinSpeed = 67,
	},
	UnstableBananaRelic = {
		Id = "UnstableBananaRelic",
		DisplayName = "Unstable Banana Relic",
		Rarity = "Mythic",
		BaseValue = 640,
		IncomePerSecond = 52,
		Shape = Enum.PartType.Block,
		Size = Vector3.new(1.8, 4.2, 1.8),
		SpinSpeed = 86,
	},
}

BrainrotConfig.StarterSet = {
	"ScreamingCube",
	"GlitchOrb",
}

return BrainrotConfig
