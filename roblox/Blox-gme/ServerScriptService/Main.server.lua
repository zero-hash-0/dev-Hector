--!strict

-- Entry point — wires all services for Blox-gme.
-- Loop: Waiting → Countdown → Active (chase / fight / steal Core) → Ended

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

-- ── Remotes ───────────────────────────────────────────────────────────────────
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
	MatchState    = remote("MatchState"),
	CoreState     = remote("CoreState"),
	AttackRequest = remote("AttackRequest"),
	CombatHit     = remote("CombatHit"),
	SprintRequest = remote("SprintRequest"),
	DashRequest   = remote("DashRequest"),
	HUD           = remote("HUD"),
	Alert         = remote("Alert"),
}

-- ── Services ──────────────────────────────────────────────────────────────────
local Services = ServerScriptService:WaitForChild("Services")

local MatchService    = require(Services.MatchService)
local CoreService     = require(Services.CoreService)
local CombatService   = require(Services.CombatService)
local MovementService = require(Services.MovementService)
local PlayerService   = require(Services.PlayerService)
local WorldService    = require(Services.WorldService)

-- Build world first — escape pads come back for CoreService registration
local worldService  = WorldService.new()
local escapePads    = worldService:BuildMap()
worldService:ApplyLighting()

local matchService    = MatchService.new(Remotes)
local coreService     = CoreService.new(Remotes, matchService)
local combatService   = CombatService.new(Remotes, coreService)
local movementService = MovementService.new(Remotes)
local playerService   = PlayerService.new(Remotes, matchService)

-- Assign escape pads to players round-robin as they join
local padIndex = 0
Players.PlayerAdded:Connect(function(player)
	padIndex = (padIndex % #escapePads) + 1
	local pad = escapePads[padIndex]
	coreService:RegisterEscapeZone(player, pad)
	-- Tell client which pad is theirs
	task.wait(1) -- wait for client to load remotes
	Remotes.HUD:FireClient(player, {
		Event   = "EscapeZone",
		PadPos  = { X = pad.Position.X, Y = pad.Position.Y, Z = pad.Position.Z },
		PadIndex = padIndex,
	})
end)

-- ── Match events ──────────────────────────────────────────────────────────────
matchService:OnStart(function()
	coreService:SpawnCore()
	playerService:RespawnAll()
	Remotes.Alert:FireAllClients({ Type = "System", Message = "Match started — steal the Core!" })
end)

matchService:OnEnd(function(winner)
	if winner then
		Remotes.Alert:FireAllClients({
			Type    = "Win",
			Message = string.format("%s escaped with the Core!", winner.DisplayName),
		})
	else
		Remotes.Alert:FireAllClients({ Type = "System", Message = "Time's up — no winner." })
	end

	-- Reassign pads for next round
	padIndex = 0
	coreService:SpawnCore()
end)

-- ── Init ──────────────────────────────────────────────────────────────────────
matchService:Init()
combatService:Init()
movementService:Init()
playerService:Init()

-- Core escape check every physics step
RunService.Heartbeat:Connect(function()
	coreService:CheckEscape()
end)
