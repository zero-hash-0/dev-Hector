--!strict

-- Owns the match state machine: Waiting → Countdown → Active → Ended.
-- Tells other services when to start/stop.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

export type MatchState = "Waiting" | "Countdown" | "Active" | "Ended"

local MatchService = {}
MatchService.__index = MatchService

function MatchService.new(remotes: { [string]: RemoteEvent })
	local self = setmetatable({}, MatchService)
	self._remotes  = remotes
	self._state    = "Waiting" :: MatchState
	self._timeLeft = 0
	self._onStart  = nil :: (() -> ())?
	self._onEnd    = nil :: ((winner: Player?) -> ())?
	return self
end

function MatchService:OnStart(fn: () -> ())
	self._onStart = fn
end

function MatchService:OnEnd(fn: (winner: Player?) -> ())
	self._onEnd = fn
end

function MatchService:GetState(): MatchState
	return self._state
end

function MatchService:Init()
	Players.PlayerAdded:Connect(function()
		if self._state == "Waiting" and #Players:GetPlayers() >= GameConfig.MIN_PLAYERS_START then
			self:_beginCountdown()
		end
	end)

	Players.PlayerRemoving:Connect(function()
		if self._state == "Active" and #Players:GetPlayers() < GameConfig.MIN_PLAYERS_START then
			self:_endMatch(nil)
		end
	end)
end

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

	-- Countdown timer
	task.spawn(function()
		while self._state == "Active" and self._timeLeft > 0 do
			task.wait(1)
			self._timeLeft -= 1
			self._remotes.MatchState:FireAllClients({ State = "Active", Time = self._timeLeft })
		end
		if self._state == "Active" then
			self:_endMatch(nil) -- time expired, no winner
		end
	end)
end

function MatchService:DeclareWinner(player: Player)
	if self._state ~= "Active" then return end
	self:_endMatch(player)
end

function MatchService:_endMatch(winner: Player?)
	self._state = "Ended"
	local winnerName = winner and winner.DisplayName or "Nobody"
	self._remotes.MatchState:FireAllClients({ State = "Ended", Winner = winnerName })

	if self._onEnd then self._onEnd(winner) end

	-- Reset to Waiting after a short pause
	task.delay(5, function()
		self._state = "Waiting"
		self._remotes.MatchState:FireAllClients({ State = "Waiting" })
	end)
end

return MatchService
