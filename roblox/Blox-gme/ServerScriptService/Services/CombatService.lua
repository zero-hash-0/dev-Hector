--!strict

-- Real-time melee combat: damage, knockback, stun, cooldowns.
-- Client sends AttackRequest; server validates range and cooldown then applies result.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(remotes: { [string]: RemoteEvent }, coreService: any)
	local self = setmetatable({}, CombatService)
	self._remotes     = remotes
	self._coreService = coreService
	self._cooldowns   = {} :: { [Player]: number } -- last attack tick
	self._stunned     = {} :: { [Player]: boolean }
	return self
end

function CombatService:Init()
	self._remotes.AttackRequest.OnServerEvent:Connect(function(attacker, targetPlayer)
		self:_handleAttack(attacker, targetPlayer)
	end)
end

function CombatService:_handleAttack(attacker: Player, target: any)
	-- Type-guard target
	if typeof(target) ~= "Instance" or not target:IsA("Player") then return end
	local targetPlayer = target :: Player

	if attacker == targetPlayer then return end
	if self._stunned[attacker] then return end

	-- Cooldown check
	local now = tick()
	if (self._cooldowns[attacker] or 0) + GameConfig.ATTACK_COOLDOWN > now then return end
	self._cooldowns[attacker] = now

	-- Range check (server-authoritative)
	local aChar = attacker.Character
	local tChar = targetPlayer.Character
	if not aChar or not tChar then return end

	local aRoot = aChar:FindFirstChild("HumanoidRootPart")
	local tRoot = tChar:FindFirstChild("HumanoidRootPart")
	if not aRoot or not tRoot then return end

	if (aRoot.Position - tRoot.Position).Magnitude > GameConfig.ATTACK_RANGE then return end

	-- Apply damage
	local humanoid = tChar:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	humanoid.Health -= GameConfig.BASE_DAMAGE

	-- Knockback
	local direction = (tRoot.Position - aRoot.Position).Unit
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity       = direction * GameConfig.KNOCKBACK_FORCE
	bodyVelocity.MaxForce       = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.P              = 1e4
	bodyVelocity.Parent         = tRoot
	game:GetService("Debris"):AddItem(bodyVelocity, 0.15)

	-- Stun
	self._stunned[targetPlayer] = true
	task.delay(GameConfig.STUN_DURATION, function()
		self._stunned[targetPlayer] = nil
	end)

	-- Notify clients
	self._remotes.CombatHit:FireAllClients({
		Attacker = attacker.DisplayName,
		Target   = targetPlayer.DisplayName,
		Damage   = GameConfig.BASE_DAMAGE,
	})

	-- KO handling
	if humanoid.Health <= 0 then
		self._coreService:HandleCarrierKO(targetPlayer)
		self._remotes.CombatHit:FireAllClients({
			Attacker = attacker.DisplayName,
			Target   = targetPlayer.DisplayName,
			KO       = true,
		})
	end
end

return CombatService
