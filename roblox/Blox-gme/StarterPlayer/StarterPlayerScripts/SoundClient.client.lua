--!strict

-- Plays all in-game sounds in response to remotes.
-- Sounds are pooled under a single SoundGroup so volume can be
-- adjusted globally from Settings without touching each Sound instance.

local Players           = game:GetService("Players")
local SoundService      = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local CombatHit    = Remotes:WaitForChild("CombatHit")    :: RemoteEvent
local CoreState    = Remotes:WaitForChild("CoreState")    :: RemoteEvent
local MatchState   = Remotes:WaitForChild("MatchState")   :: RemoteEvent
local AbilityResult = Remotes:WaitForChild("AbilityResult") :: RemoteEvent
local XPGained     = Remotes:WaitForChild("XPGained")    :: RemoteEvent

local SoundConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundConfig"))

-- ── Sound group ───────────────────────────────────────────────────────────────
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name   = "BloxGmeSFX"
sfxGroup.Volume = 1
sfxGroup.Parent = SoundService

-- ── Sound pool ────────────────────────────────────────────────────────────────
-- Pre-create Sound instances so there's no delay on first play
local pool: { [string]: Sound } = {}

local function getSound(id: string, volume: number): Sound
	if pool[id] then return pool[id] end

	local s = Instance.new("Sound")
	s.SoundId    = id
	s.Volume     = volume
	s.RollOffMaxDistance = 60
	s.Parent     = sfxGroup
	pool[id]     = s
	return s
end

local function play(id: string, volume: number)
	local s = getSound(id, volume)
	-- Clone for overlapping plays
	local clone = s:Clone()
	clone.Parent = sfxGroup
	clone:Play()
	clone.Ended:Connect(function() clone:Destroy() end)
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local IDs = SoundConfig.IDs
local VOL = SoundConfig.Volume

-- ── Remote handlers ───────────────────────────────────────────────────────────

CombatHit.OnClientEvent:Connect(function(data: {
	Attacker: string,
	Target: string,
	KO: boolean?,
})
	local isAttacker = data.Attacker == LocalPlayer.DisplayName
	local isTarget   = data.Target   == LocalPlayer.DisplayName

	if data.KO then
		play(IDs.KO, VOL.KO)
	elseif isAttacker then
		play(IDs.Hit, VOL.Hit)
	elseif isTarget then
		play(IDs.HitReceived, VOL.Hit)
	end
end)

CoreState.OnClientEvent:Connect(function(data: { Event: string, Carrier: string? })
	if data.Event == "PickedUp" then
		play(IDs.CorePickup, VOL.Core)
	elseif data.Event == "Dropped" then
		play(IDs.CoreDrop, VOL.Core)
	elseif data.Event == "Returned" or data.Event == "Spawned" then
		play(IDs.CoreReturn, VOL.Core)
	elseif data.Event == "Escaped" then
		play(IDs.CoreEscape, VOL.Match)
	end
end)

MatchState.OnClientEvent:Connect(function(data: { State: string, Time: number? })
	if data.State == "Active" and data.Time == 180 then   -- match just started
		play(IDs.MatchStart, VOL.Match)
	elseif data.State == "Ended" then
		play(IDs.MatchEnd, VOL.Match)
	elseif data.State == "SuddenDeath" then
		play(IDs.SuddenDeath, VOL.Match)
	elseif data.State == "Countdown" and data.Time and data.Time <= 3 then
		play(IDs.Countdown, VOL.Match)
	end
end)

AbilityResult.OnClientEvent:Connect(function(data: { [string]: any })
	if data.Event ~= "Effect" then return end

	local charId = data.Character :: string?
	if charId == "VIPER" then
		play(IDs.Dash, VOL.Ability)
	elseif charId == "TANK" then
		play(IDs.ShieldBash, VOL.Ability)
	elseif charId == "GHOST" then
		play(IDs.Cloak, VOL.Ability)
	elseif charId == "SPARK" then
		play(IDs.Thunderclap, VOL.Ability)
	elseif charId == "SURGE" then
		play(IDs.BlitzRush, VOL.Ability)
	elseif charId == "REAPER" then
		play(IDs.DeathMark, VOL.Ability)
	end
end)

XPGained.OnClientEvent:Connect(function(data: { delta: number, leveled: boolean? })
	if data.leveled then
		play(IDs.LevelUp, VOL.LevelUp)
	elseif data.delta and data.delta > 0 then
		play(IDs.XPGain, 0.3)
	end
end)
