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
}

local Services = ServerScriptService:WaitForChild("Services")

local BaseService = require(Services.BaseService)
local CurrencyService = require(Services.CurrencyService)
local BrainrotService = require(Services.BrainrotService)
local RaidService = require(Services.RaidService)
local CombatService = require(Services.CombatService)
local EventService = require(Services.EventService)
local WorldService = require(Services.WorldService)

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

Players.PlayerAdded:Connect(function(player)
	local base = baseService:ClaimBase(player)
	if not base then
		Remotes.Alert:FireClient(player, { Type = "System", Message = "All compounds occupied. Queueing..." })
		return
	end

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
