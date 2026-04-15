--!strict

-- Player lifecycle: join, leave, respawn, health init.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(remotes: { [string]: RemoteEvent }, matchService: any)
	local self = setmetatable({}, PlayerService)
	self._remotes      = remotes
	self._matchService = matchService
	return self
end

function PlayerService:Init()
	Players.PlayerAdded:Connect(function(player)
		self:_onAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:_onRemoving(player)
	end)
end

function PlayerService:_onAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.MaxHealth = GameConfig.BASE_HEALTH
		humanoid.Health    = GameConfig.BASE_HEALTH
		humanoid.WalkSpeed = GameConfig.WALK_SPEED
	end)

	self._remotes.HUD:FireClient(player, { State = self._matchService:GetState() })
	self._remotes.Alert:FireAllClients({
		Type    = "System",
		Message = string.format("%s joined", player.DisplayName),
	})
end

function PlayerService:_onRemoving(player: Player)
	self._remotes.Alert:FireAllClients({
		Type    = "System",
		Message = string.format("%s left", player.DisplayName),
	})
end

function PlayerService:RespawnAll()
	for _, player in Players:GetPlayers() do
		player:LoadCharacter()
	end
end

return PlayerService
