--!strict

-- Match state machine: Waiting → Countdown → Active → SuddenDeath → Ended.
--
-- Sudden Death rule: when the clock hits 0, whoever is HOLDING the Core wins.
-- If nobody holds it — no winner. This creates maximum clutch tension.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local SUDDEN_DEATH_WARNING = 30  -- seconds before end to warn players
local SUDDEN_DEATH_BOOST   = 15  -- seconds before end to boost carrier speed

export type MatchState = "Waiting" | "Countdown" | "Active" | "SuddenDeath" | "Ended"

local MatchService = {}
MatchService.__index = MatchService

function MatchService.new(remotes: { [string]: RemoteEvent })
	local self = setmetatable({}, MatchService)
	self._remotes       = remotes
	self._state         = "Waiting" :: MatchState
	self._timeLeft      = 0
	self._onStart       = nil :: (() -> ())?
	self._onEnd         = nil :: ((winner: Player?) -> ())?
	self._onSuddenDeath = nil :: (() -> ())?
	return self
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

function MatchService:OnStart(fn: () -> ())         self._onStart       = fn end
function MatchService:OnEnd(fn: (Player?) -> ())    self._onEnd         = fn end
function MatchService:OnSuddenDeath(fn: () -> ())   self._onSuddenDeath = fn end

function MatchService:GetState(): MatchState
	return self._state
end

function MatchService:GetTimeLeft(): number
	return self._timeLeft
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function MatchService:Init()
	Players.PlayerAdded:Connect(function()
		if self._state == "Waiting"
			and #Players:GetPlayers() >= GameConfig.MIN_PLAYERS_START then
			self:_beginCountdown()
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if (self._state == "Active" or self._state == "SuddenDeath")
			and #Players:GetPlayers() < GameConfig.MIN_PLAYERS_START then
			self:_endMatch(nil)
		end
	end)
end

-- ── State transitions ─────────────────────────────────────────────────────────

function MatchService:_beginCountdown()
	self._state = "Countdown"
	self._remotes.MatchState:FireAllClients({ State = "Countdown", Time = GameConfig.COUNTDOWN })

	task.delay(GameConfig.COUNTDOWN, function()
		if self._state == "Countdown" then
			self:_beginMatch()
		end
	end)
end

function MatchService:_beginMatch()
	self._state    = "Active"
	self._timeLeft = GameConfig.MATCH_DURATION
	self._remotes.MatchState:FireAllClients({ State = "Active", Time = self._timeLeft })

	if self._onStart then self._onStart() end

	task.spawn(function()
		while self._timeLeft > 0
			and (self._state == "Active" or self._state == "SuddenDeath") do
			task.wait(1)
			self._timeLeft -= 1

			-- Sudden death warning at 30s
			if self._timeLeft == SUDDEN_DEATH_WARNING and self._state == "Active" then
				self._state = "SuddenDeath"
				self._remotes.MatchState:FireAllClients({
					State   = "SuddenDeath",
					Time    = self._timeLeft,
					Message = "SUDDEN DEATH — carrier wins at 0:00!",
				})
				if self._onSuddenDeath then self._onSuddenDeath() end
			end

			-- Speed boost carrier at 15s
			if self._timeLeft == SUDDEN_DEATH_BOOST then
				self._remotes.MatchState:FireAllClients({
					State   = self._state,
					Time    = self._timeLeft,
					Message = "FINAL PUSH — Core carrier gets a speed boost!",
					CarrierBoost = true,
				})
			end

			self._remotes.MatchState:FireAllClients({
				State = self._state,
				Time  = self._timeLeft,
			})
		end

		-- Time expired
		if self._state == "Active" or self._state == "SuddenDeath" then
			-- Winner resolved externally by CoreService calling DeclareWinner,
			-- or here as nil (nobody escaped in time)
			self:_endMatch(nil)
		end
	end)
end

function MatchService:DeclareWinner(player: Player)
	if self._state ~= "Active" and self._state ~= "SuddenDeath" then return end
	self:_endMatch(player)
end

-- Called at 0:00 by the timer loop — CoreService checks who holds the Core
-- and calls this. If nobody holds it, Main calls with nil.
function MatchService:DeclareCarrierWinner(player: Player?)
	if self._state ~= "SuddenDeath" then return end
	self:_endMatch(player)
end

function MatchService:_endMatch(winner: Player?)
	if self._state == "Ended" then return end
	self._state = "Ended"

	local winnerName = winner and winner.DisplayName or nil
	self._remotes.MatchState:FireAllClients({
		State   = "Ended",
		Winner  = winnerName,
		Message = winnerName
			and string.format("%s escaped with the Core!", winnerName)
			or "Time's up — no winner.",
	})

	if self._onEnd then self._onEnd(winner) end

	-- Reset to Waiting after 8s (enough for summary screen)
	task.delay(8, function()
		self._state = "Waiting"
		self._remotes.MatchState:FireAllClients({ State = "Waiting" })
	end)
end

return MatchService
