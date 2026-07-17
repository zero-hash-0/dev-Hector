--!strict

local UpgradeConfig = {
	StorageSlots = {
		DisplayName = "Storage Slots",
		Description = "More room for brainrots in your compound",
		Tiers = {
			{ Cost = 120, Delta = 2 },
			{ Cost = 240, Delta = 2 },
			{ Cost = 480, Delta = 3 },
		},
	},
	IncomeBoost = {
		DisplayName = "Income Boost",
		Description = "Multiplies all passive income from your brainrots",
		Tiers = {
			{ Cost = 160, Multiplier = 1.15 },
			{ Cost = 350, Multiplier = 1.35 },
		},
	},
	CarryStability = {
		DisplayName = "Carry Stability",
		Description = "Chance to hold on to a carried brainrot when hit",
		Tiers = {
			{ Cost = 200, DropResistChance = 0.15 },
			{ Cost = 450, DropResistChance = 0.3 },
		},
	},
}

UpgradeConfig.Order = { "StorageSlots", "IncomeBoost", "CarryStability" }

return UpgradeConfig
