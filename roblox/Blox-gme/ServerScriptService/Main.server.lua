--!strict

-- Entry point — wires all services for Blox-gme.
-- Loop: Waiting → Countdown → Active (chase / fight / steal Core) → Ended

local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

-- Remotes
local remotesFolder = Instance.new("Folder")
remotesFolder.Name   = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name   = name
	r.Parent = remotesFolder
	return r
end

local Remotes = {
	-- Match
	MatchState    = remote("MatchState"),
	-- Core
	CoreState     = remote("CoreState"),
	-- Combat
	AttackRequest = remote("AttackRequest"),
	CombatHit     = remote("CombatHit"),
	-- Movement
	SprintRequest = remote("SprintRequest"),
	DashRequest   = remote("DashRequest"),
	-- HUD / alerts
	HUD           = remote("HUD"),
	Alert         = remote("Alert"),
}

-- Services
local Services = ServerScriptService:WaitForChild("Services")

local MatchService    = require(Services.MatchService)
local CoreService     = require(Services.CoreService)
local CombatService   = require(Services.CombatService)
local MovementService = require(Services.MovementService)
local PlayerService   = require(Services.PlayerService)
local WorldService    = require(Services.WorldService)

local worldService    = WorldService.new()
worldService:BuildMap()
worldService:ApplyLighting()

local matchService    = MatchService.new(Remotes)
local coreService     = CoreService.new(Remotes, matchService)
local combatService   = CombatService.new(Remotes, coreService)
local movementService = MovementService.new(Remotes)
local playerService   = PlayerService.new(Remotes, matchService)

-- Wire match events
matchService:OnStart(function()
	coreService:SpawnCore()
	playerService:RespawnAll()
end)

matchService:OnEnd(function(winner)
	if winner then
		Remotes.Alert:FireAllClients({
			Type    = "System",
			Message = string.format("%s escaped with the Core!", winner.DisplayName),
		})
	else
		Remotes.Alert:FireAllClients({ Type = "System", Message = "Time's up — no winner!" })
	end
	coreService:SpawnCore() -- reset Core for next round
end)

-- Init all services
matchService:Init()
combatService:Init()
movementService:Init()
playerService:Init()

-- Core escape check every frame
RunService.Heartbeat:Connect(function()
	coreService:CheckEscape()
end)
