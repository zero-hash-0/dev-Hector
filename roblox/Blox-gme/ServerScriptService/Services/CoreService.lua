--!strict

-- Manages the Core object: spawn, pickup, drop, return timer, and escape detection.
-- The Core is the win condition — carrier must reach their escape zone.

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local CoreService = {}
CoreService.__index = CoreService

function CoreService.new(remotes: { [string]: RemoteEvent }, matchService: any)
	local self = setmetatable({}, CoreService)
	self._remotes      = remotes
	self._matchService = matchService
	self._core         = nil  :: BasePart?
	self._carrier      = nil  :: Player?
	self._returnTimer  = nil  :: thread?
	self._escapezones  = {}   :: { [Player]: BasePart }
	return self
end

function CoreService:SpawnCore()
	-- Remove old Core if present
	if self._core then
		self._core:Destroy()
		self._core = nil
	end

	local core = Instance.new("Part")
	core.Name      = "TheCore"
	core.Size      = Vector3.new(3, 3, 3)
	core.Shape     = Enum.PartType.Ball
	core.BrickColor = BrickColor.new("Bright yellow")
	core.Material  = Enum.Material.Neon
	core.Anchored  = true
	core.Position  = Vector3.new(0, GameConfig.CORE_SPAWN_HEIGHT, 0)
	core.Parent    = Workspace

	-- Pickup proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText   = "The Core"
	prompt.ActionText   = "Grab"
	prompt.MaxActivationDistance = GameConfig.ATTACK_RANGE
	prompt.Parent = core

	prompt.Triggered:Connect(function(player)
		self:_onPickup(player)
	end)

	self._core = core
	self._remotes.CoreState:FireAllClients({ Event = "Spawned" })
end

function CoreService:RegisterEscapeZone(player: Player, zone: BasePart)
	self._escapezones[player] = zone
end

function CoreService:_onPickup(player: Player)
	if self._carrier ~= nil then return end  -- already carried
	if self._matchService:GetState() ~= "Active" then return end

	self._carrier = player
	if self._core then
		self._core.Anchored = false
		self._core.Parent   = player.Character or Workspace
	end

	-- Apply speed penalty to carrier
	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.WalkSpeed = GameConfig.WALK_SPEED * GameConfig.CARRIER_PENALTY
	end

	-- Cancel any return timer
	if self._returnTimer then task.cancel(self._returnTimer) end

	self._remotes.CoreState:FireAllClients({ Event = "PickedUp", Carrier = player.DisplayName })
end

function CoreService:DropCore(fromPlayer: Player)
	if self._carrier ~= fromPlayer then return end
	self:_detach(fromPlayer)
	self._remotes.CoreState:FireAllClients({ Event = "Dropped" })
	self:_startReturnTimer()
end

function CoreService:_detach(player: Player)
	self._carrier = nil

	local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.WalkSpeed = GameConfig.WALK_SPEED
	end

	if self._core then
		self._core.Anchored = false
		self._core.Parent   = Workspace
	end
end

function CoreService:_startReturnTimer()
	self._returnTimer = task.delay(GameConfig.CORE_RETURN_DELAY, function()
		self:SpawnCore()
		self._remotes.CoreState:FireAllClients({ Event = "Returned" })
	end)
end

-- Call each frame (or on Touched) to check if carrier reached escape zone
function CoreService:CheckEscape()
	if not self._carrier then return end
	local zone = self._escapezones[self._carrier]
	if not zone or not self._core then return end

	local dist = (self._core.Position - zone.Position).Magnitude
	if dist < (zone.Size.Magnitude / 2) then
		self._matchService:DeclareWinner(self._carrier)
		self:_detach(self._carrier)
	end
end

function CoreService:HandleCarrierKO(player: Player)
	if self._carrier ~= player then return end
	if GameConfig.CORE_DROP_ON_DEATH then
		self:DropCore(player)
	end
end

return CoreService
