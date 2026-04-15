--!strict

-- Handles sprint and dash abilities server-side.
-- Client sends input; server validates cooldowns and applies forces.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local MovementService = {}
MovementService.__index = MovementService

function MovementService.new(remotes: { [string]: RemoteEvent })
	local self = setmetatable({}, MovementService)
	self._remotes      = remotes
	self._dashCooldown = {} :: { [Player]: number }
	self._sprinting    = {} :: { [Player]: boolean }
	return self
end

function MovementService:Init()
	self._remotes.SprintRequest.OnServerEvent:Connect(function(player, active)
		self:_setSprint(player, active == true)
	end)

	self._remotes.DashRequest.OnServerEvent:Connect(function(player, direction)
		self:_handleDash(player, direction)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._dashCooldown[player] = nil
		self._sprinting[player]    = nil
	end)
end

function MovementService:_setSprint(player: Player, active: boolean)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	self._sprinting[player] = active
	humanoid.WalkSpeed = active and GameConfig.SPRINT_SPEED or GameConfig.WALK_SPEED
end

function MovementService:SetCarrierSpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.WalkSpeed = GameConfig.WALK_SPEED * GameConfig.CARRIER_PENALTY
	self._sprinting[player] = false
end

function MovementService:ResetSpeed(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	humanoid.WalkSpeed = GameConfig.WALK_SPEED
	self._sprinting[player] = false
end

function MovementService:_handleDash(player: Player, direction: any)
	if typeof(direction) ~= "Vector3" then return end

	local now = tick()
	if (self._dashCooldown[player] or 0) + GameConfig.DASH_COOLDOWN > now then return end
	self._dashCooldown[player] = now

	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then return end

	local impulse = Instance.new("BodyVelocity")
	impulse.Velocity  = direction.Unit * GameConfig.DASH_FORCE
	impulse.MaxForce  = Vector3.new(1e5, 0, 1e5)
	impulse.P         = 1e4
	impulse.Parent    = rootPart
	game:GetService("Debris"):AddItem(impulse, 0.18)

	self._remotes.DashRequest:FireClient(player, { Cooldown = GameConfig.DASH_COOLDOWN })
end

return MovementService
