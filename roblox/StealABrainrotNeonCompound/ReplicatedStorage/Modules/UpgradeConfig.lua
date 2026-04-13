--!strict

local UpgradeConfig = {
	StorageSlots = {
		{ Cost = 120, Delta = 2 },
		{ Cost = 240, Delta = 2 },
		{ Cost = 480, Delta = 3 },
	},
	IncomeBoost = {
		{ Cost = 160, Multiplier = 1.15 },
		{ Cost = 350, Multiplier = 1.35 },
	},
	CarryStability = {
		{ Cost = 200, DropResistChance = 0.15 },
		{ Cost = 450, DropResistChance = 0.3 },
	},
}

return UpgradeConfig
