--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UpgradeConfig = require(ReplicatedStorage.Modules.UpgradeConfig)

local STORE_NAME = "NeonCompound_v1"
local AUTOSAVE_SECONDS = 120
local DEFAULT_MONEY = 150

local DataService = {}
DataService.__index = DataService

function DataService.new()
	local self = setmetatable({}, DataService)
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	-- Studio without API access (and some test setups) can't reach DataStores;
	-- the game then runs with session-only progress instead of erroring.
	self.Store = ok and store or nil
	return self
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function DataService:LoadProfile(player: Player)
	local profile = { Money = DEFAULT_MONEY, Upgrades = {} }
	if not self.Store then
		return profile
	end
	local ok, saved = pcall(function()
		return self.Store:GetAsync(keyFor(player))
	end)
	if ok and typeof(saved) == "table" then
		if typeof(saved.Money) == "number" then
			profile.Money = math.max(0, math.floor(saved.Money))
		end
		if typeof(saved.Upgrades) == "table" then
			for _, upgradeId in ipairs(UpgradeConfig.Order) do
				local level = saved.Upgrades[upgradeId]
				if typeof(level) == "number" and level > 0 then
					profile.Upgrades[upgradeId] = math.floor(level)
				end
			end
		end
	end
	return profile
end

function DataService:SaveProfile(player: Player)
	if not self.Store then
		return
	end
	local money = player:GetAttribute("Money")
	local payload = {
		Money = typeof(money) == "number" and math.floor(money) or DEFAULT_MONEY,
		Upgrades = {},
	}
	for _, upgradeId in ipairs(UpgradeConfig.Order) do
		local level = player:GetAttribute("Upgrade_" .. upgradeId)
		if typeof(level) == "number" and level > 0 then
			payload.Upgrades[upgradeId] = level
		end
	end
	pcall(function()
		self.Store:SetAsync(keyFor(player), payload)
	end)
end

function DataService:Init()
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(function()
			self:SaveProfile(player)
		end)
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for _, player in ipairs(Players:GetPlayers()) do
				self:SaveProfile(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveProfile(player)
		end
	end)
end

return DataService
