--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local UpgradeConfig = require(ReplicatedStorage.Modules.UpgradeConfig)

local ShopService = {}
ShopService.__index = ShopService

function ShopService.new(baseService, brainrotService, currencyService, remotes)
	local self = setmetatable({}, ShopService)
	self.BaseService = baseService
	self.BrainrotService = brainrotService
	self.CurrencyService = currencyService
	self.Remotes = remotes
	return self
end

function ShopService:Init()
	self.Remotes.ShopRequest.OnServerEvent:Connect(function(player, action, id)
		if typeof(action) ~= "string" or typeof(id) ~= "string" then
			return
		end
		if action == "BuyBrainrot" then
			self:TryBuyBrainrot(player, id)
		elseif action == "BuyUpgrade" then
			self:TryBuyUpgrade(player, id)
		end
	end)
end

function ShopService:AlertPlayer(player: Player, message: string)
	self.Remotes.Alert:FireClient(player, { Type = "Shop", Message = message })
end

function ShopService:TryBuyBrainrot(player: Player, brainrotId: string)
	local def = BrainrotConfig[brainrotId]
	if typeof(def) ~= "table" or def.Id ~= brainrotId then
		return
	end
	local base = self.BaseService:GetPlayerBase(player)
	if not base then
		return
	end
	if self.BrainrotService:GetStoredCount(base) >= base.StorageSlots then
		self:AlertPlayer(player, "Storage full — upgrade Storage Slots first")
		return
	end
	if not self.CurrencyService:Spend(player, def.BaseValue) then
		self:AlertPlayer(player, string.format("Need $%d for %s", def.BaseValue, def.DisplayName))
		return
	end
	self.BrainrotService:SpawnForBase(player, brainrotId)
	self.Remotes.Alert:FireAllClients({
		Type = "Shop",
		Message = string.format("%s bought %s", player.DisplayName, def.DisplayName),
	})
end

function ShopService:TryBuyUpgrade(player: Player, upgradeId: string)
	local upgrade = UpgradeConfig[upgradeId]
	if typeof(upgrade) ~= "table" or not upgrade.Tiers then
		return
	end
	local attributeName = "Upgrade_" .. upgradeId
	local level = player:GetAttribute(attributeName)
	if typeof(level) ~= "number" then
		level = 0
	end
	local nextTier = upgrade.Tiers[level + 1]
	if not nextTier then
		self:AlertPlayer(player, upgrade.DisplayName .. " is already maxed")
		return
	end
	if not self.CurrencyService:Spend(player, nextTier.Cost) then
		self:AlertPlayer(player, string.format("Need $%d for %s", nextTier.Cost, upgrade.DisplayName))
		return
	end
	player:SetAttribute(attributeName, level + 1)
	self:ApplyUpgrade(player, upgradeId, nextTier)
	self:AlertPlayer(player, string.format("%s upgraded to tier %d", upgrade.DisplayName, level + 1))
end

-- Re-applies a saved profile's upgrade levels on join. StorageSlots deltas are
-- cumulative across tiers; IncomeBoost/CarryStability just land on the final
-- tier's value since ApplyUpgrade overwrites the attribute each time.
function ShopService:ApplySavedUpgrades(player: Player, upgrades)
	for _, upgradeId in ipairs(UpgradeConfig.Order) do
		local level = upgrades[upgradeId]
		if typeof(level) == "number" and level > 0 then
			local upgrade = UpgradeConfig[upgradeId]
			local cappedLevel = math.min(level, #upgrade.Tiers)
			player:SetAttribute("Upgrade_" .. upgradeId, cappedLevel)
			for tierIndex = 1, cappedLevel do
				self:ApplyUpgrade(player, upgradeId, upgrade.Tiers[tierIndex])
			end
		end
	end
end

function ShopService:ApplyUpgrade(player: Player, upgradeId: string, tier)
	if upgradeId == "StorageSlots" then
		local base = self.BaseService:GetPlayerBase(player)
		if base then
			base.StorageSlots += tier.Delta
			self.BrainrotService:PushStorageCount(player)
		end
	elseif upgradeId == "IncomeBoost" then
		player:SetAttribute("IncomeMultiplier", tier.Multiplier)
	elseif upgradeId == "CarryStability" then
		player:SetAttribute("DropResistChance", tier.DropResistChance)
	end
end

return ShopService
