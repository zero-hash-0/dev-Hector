--!strict

-- Handles player join/leave lifecycle and initial data setup.

local Players = game:GetService("Players")

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(remotes: { [string]: RemoteEvent })
	local self = setmetatable({}, PlayerService)
	self._remotes = remotes
	self._playerData = {} :: { [number]: { [string]: any } }
	return self
end

function PlayerService:Init()
	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
end

function PlayerService:_onPlayerAdded(player: Player)
	self._playerData[player.UserId] = {}
	-- TODO: load data store, grant defaults, fire initial HUD update
end

function PlayerService:_onPlayerRemoving(player: Player)
	-- TODO: save player data before cleanup
	self._playerData[player.UserId] = nil
end

function PlayerService:GetData(player: Player): { [string]: any }?
	return self._playerData[player.UserId]
end

return PlayerService
