--!strict

-- Blox-gme bootstrap.
-- Wires all services, builds remotes, handles match callbacks.

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
	-- Match
	MatchState      = remote("MatchState"),
	-- Core
	CoreState       = remote("CoreState"),
	-- Combat
	AttackRequest   = remote("AttackRequest"),
	CombatHit       = remote("CombatHit"),
	StreakEvent     = remote("StreakEvent"),
	-- Movement
	SprintRequest   = remote("SprintRequest"),
	DashRequest     = remote("DashRequest"),
	-- Abilities
	CharacterSelect = remote("CharacterSelect"),
	AbilityRequest  = remote("AbilityRequest"),
	AbilityResult   = remote("AbilityResult"),
	-- Progression
	XPGained        = remote("XPGained"),
	-- Match summary
	MatchSummary    = remote("MatchSummary"),
	-- HUD / alerts
	HUD             = remote("HUD"),
	Alert           = remote("Alert"),
}

-- ── Services ──────────────────────────────────────────────────────────────────

local Services = ServerScriptService:WaitForChild("Services")

local MatchService      = require(Services.MatchService)
local CoreService       = require(Services.CoreService)
local CombatService     = require(Services.CombatService)
local MovementService   = require(Services.MovementService)
local AbilityService    = require(Services.AbilityService)
local ProgressionService = require(Services.ProgressionService)
local PlayerService     = require(Services.PlayerService)
local WorldService      = require(Services.WorldService)

-- Build world — escape pads come back for CoreService
local worldService  = WorldService.new()
local escapePads    = worldService:BuildMap()
worldService:ApplyLighting()

-- Instantiate in dependency order
local matchService       = MatchService.new(Remotes)
-- CombatService needs abilityService; create placeholder, inject after
local abilityServiceRef: any = nil

local coreService        = CoreService.new(Remotes, matchService, setmetatable({}, {
	__index = function(_, k) return function(...) if abilityServiceRef then return (abilityServiceRef :: any)[k](abilityServiceRef, ...) end end end
}))

local combatService      = CombatService.new(Remotes, coreService, setmetatable({}, {
	__index = function(_, k) return function(...) if abilityServiceRef then return (abilityServiceRef :: any)[k](abilityServiceRef, ...) end end
}))

local abilityService     = AbilityService.new(Remotes, combatService)
abilityServiceRef        = abilityService

local progressionService = ProgressionService.new(Remotes)
local movementService    = MovementService.new(Remotes)
local playerService      = PlayerService.new(Remotes, matchService)

-- ── Escape zone assignment ────────────────────────────────────────────────────

local padIndex = 0
Players.PlayerAdded:Connect(function(player)
	padIndex = (padIndex % #escapePads) + 1
	local pad = escapePads[padIndex]
	coreService:RegisterEscapeZone(player, pad)

	-- Tell client their escape zone after a moment (remotes may not be ready)
	task.delay(1.5, function()
		Remotes.HUD:FireClient(player, {
			Event    = "EscapeZone",
			PadPos   = { X = pad.Position.X, Y = pad.Position.Y, Z = pad.Position.Z },
			PadIndex = padIndex,
		})
	end)
end)

-- ── Match callbacks ───────────────────────────────────────────────────────────

matchService:OnStart(function()
	coreService:SpawnCore()
	coreService:ResetCarryStats()
	combatService:ResetMatchStats()
	playerService:RespawnAll()

	Remotes.Alert:FireAllClients({
		Type    = "System",
		Message = "Match started — steal the Core!",
	})
end)

matchService:OnSuddenDeath(function()
	coreService:BoostCarrier()
	Remotes.Alert:FireAllClients({
		Type    = "SuddenDeath",
		Message = "SUDDEN DEATH — carrier wins at 0:00!",
	})
end)

matchService:OnEnd(function(winner: Player?)
	-- Award XP
	if winner then
		progressionService:AddWin(winner)
		progressionService:AddEscape(winner)
		Remotes.Alert:FireAllClients({
			Type    = "Win",
			Message = string.format("%s escaped with the Core!", winner.DisplayName),
		})
	else
		Remotes.Alert:FireAllClients({
			Type    = "System",
			Message = "Time's up — no winner.",
		})
	end

	-- Award Core carry XP to everyone who held it
	for _, player in Players:GetPlayers() do
		local carryTime = coreService:GetCarryTime(player)
		if carryTime > 0 then
			progressionService:AddCoreCarryTime(player, carryTime)
		end
		progressionService:EndGame(player)
	end

	-- Build match summary
	local rankings: { any } = {}
	for _, player in Players:GetPlayers() do
		local data = progressionService:GetData(player)
		local kills  = 0
		local damage = combatService:GetDamageDealt(player)
		local ctime  = coreService:GetCarryTime(player)
		if data then kills = data.kills end
		local score  = kills * 100 + damage + math.floor(ctime) * 5

		table.insert(rankings, {
			player    = player.DisplayName,
			character = abilityService:GetCharacter(player),
			kills     = kills,
			damage    = damage,
			coreTime  = math.floor(ctime),
			score     = score,
		})
	end

	table.sort(rankings, function(a, b) return a.score > b.score end)

	Remotes.MatchSummary:FireAllClients({
		rankings = rankings,
		mvp      = rankings[1],
		winner   = winner and winner.DisplayName or nil,
	})

	-- Reset pad assignment for next round
	padIndex = 0
end)

-- ── Wire KO → progression ────────────────────────────────────────────────────

-- CombatHit is also listened to by clients; we listen server-side here for XP
Remotes.CombatHit.OnServerEvent:Connect(function() end)  -- prevent default passthrough
-- Instead, wire via a server-side BindableEvent approach:
-- CombatService fires this remote to clients AND signals internally.
-- We hook it by wrapping the KO path in Main via the remote:
local function onCombatHit(_remoteData: any) end  -- clients only; XP awarded below

-- Simpler: override CombatService KO callback with a wrapper in Main
-- by monkey-patching _handleKO to also award XP.
-- This avoids circular dependencies cleanly.
local origKO = combatService._handleKO
combatService._handleKO = function(self: any, attacker: Player, target: Player)
	origKO(self, attacker, target)
	progressionService:AddKill(attacker)
end

-- ── Sudden death time expiry resolution ──────────────────────────────────────

RunService.Heartbeat:Connect(function()
	coreService:CheckEscape()

	-- When match timer hits exactly 0 in SuddenDeath, resolve by carrier
	if matchService:GetState() == "SuddenDeath" and matchService:GetTimeLeft() <= 0 then
		coreService:ResolveTimeExpiry()
	end
end)

-- ── Init all services ─────────────────────────────────────────────────────────

matchService:Init()
combatService:Init()
movementService:Init()
abilityService:Init()
progressionService:Init()
playerService:Init()
