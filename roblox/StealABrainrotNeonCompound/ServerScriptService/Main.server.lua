--!strict

-- Bootstraps all systems for the STEAL A BRAINROT: NEON COMPOUND vertical slice.
-- Services are wired here so each module can stay focused and easy to expand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local function ensureFolder(parent: Instance, name: string)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local modulesFolder = ensureFolder(ReplicatedStorage, "Modules")
local remotesFolder = ensureFolder(ReplicatedStorage, "Remotes")

local function ensureRemote(name: string)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local Remotes = {
	HUD = ensureRemote("HUD"),
	Alert = ensureRemote("Alert"),
	StealRequest = ensureRemote("StealRequest"),
	DepositRequest = ensureRemote("DepositRequest"),
	AttackRequest = ensureRemote("AttackRequest"),
	ShopRequest = ensureRemote("ShopRequest"),
}

local Services = ServerScriptService:WaitForChild("Services")

local BaseService = require(Services.BaseService)
local CurrencyService = require(Services.CurrencyService)
local BrainrotService = require(Services.BrainrotService)
local RaidService = require(Services.RaidService)
local CombatService = require(Services.CombatService)
local EventService = require(Services.EventService)
local WorldService = require(Services.WorldService)
local ShopService = require(Services.ShopService)
local DataService = require(Services.DataService)

local baseService = BaseService.new()
baseService:StartSingleton()
baseService:Init()

local worldService = WorldService.new()
worldService:BuildMapBlockout()
worldService:ApplyLighting()

local currencyService = CurrencyService.new(Remotes)
currencyService:Init()

local brainrotService = BrainrotService.new(baseService, currencyService, Remotes)
brainrotService:StartIncomeLoop()

local raidService = RaidService.new(baseService, brainrotService, Remotes)
raidService:StartSingleton()
raidService:Init()

local combatService = CombatService.new(raidService, Remotes)
combatService:Init()

local eventService = EventService.new(Remotes)
eventService:Init()

local shopService = ShopService.new(baseService, brainrotService, currencyService, Remotes)
shopService:Init()

local dataService = DataService.new()
dataService:Init()

local function buildLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local moneyStat = Instance.new("IntValue")
	moneyStat.Name = "Money"
	moneyStat.Parent = leaderstats

	local brainrotStat = Instance.new("IntValue")
	brainrotStat.Name = "Brainrots"
	brainrotStat.Parent = leaderstats

	player:GetAttributeChangedSignal("Money"):Connect(function()
		local money = player:GetAttribute("Money")
		moneyStat.Value = typeof(money) == "number" and money or 0
	end)

	leaderstats.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	buildLeaderstats(player)

	-- LoadProfile yields on the DataStore, so claim the base afterwards to
	-- avoid holding a compound for a player who disconnects mid-load.
	local profile = dataService:LoadProfile(player)
	if player.Parent ~= Players then
		return
	end

	local base = baseService:ClaimBase(player)
	if not base then
		Remotes.Alert:FireClient(player, { Type = "System", Message = "All compounds occupied. Queueing..." })
		return
	end

	currencyService:SetBalance(player, profile.Money)
	shopService:ApplySavedUpgrades(player, profile.Upgrades)
	brainrotService:GrantStarterSet(player)
	Remotes.HUD:FireClient(player, {
		BaseName = string.format("Compound %d", base.Index),
		Carrying = "None",
	})
	Remotes.Alert:FireAllClients({
		Type = "System",
		Message = string.format("%s entered the Neon Compound", player.DisplayName),
	})
end)
