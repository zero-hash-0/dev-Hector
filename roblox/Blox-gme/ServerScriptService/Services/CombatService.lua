--!strict

-- Server-authoritative melee combat.
-- Tracks kill streaks, damage dealt, and exposes ApplyStun for AbilityService.

local Players           = game:GetService("Players")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

-- Streak tier labels
local STREAK_LABELS: { [number]: string } = {
	[2] = "DOUBLE KO",
	[3] = "TRIPLE KO",
	[4] = "RAMPAGE",
	[5] = "UNSTOPPABLE",
}

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(remotes: { [string]: RemoteEvent }, coreService: any, abilityService: any)
	local self = setmetatable({}, CombatService)
	self._remotes       = remotes
	self._coreService   = coreService
	self._abilityService = abilityService

	self._cooldowns   = {} :: { [Player]: number }
	self._stunned     = {} :: { [Player]: boolean }
	self._streaks     = {} :: { [Player]: number }   -- current kill streak
	self._dmgDealt    = {} :: { [Player]: number }   -- total damage this match
	return self
end

-- ── Public ────────────────────────────────────────────────────────────────────

-- Called by AbilityService (SPARK Thunderclap) and internally on KO
function CombatService:ApplyStun(target: Player)
	if self._stunned[target] then return end
	self._stunned[target] = true
	local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local orig = humanoid.WalkSpeed
		humanoid.WalkSpeed = 0
		task.delay(GameConfig.STUN_DURATION, function()
			self._stunned[target] = nil
			if target.Character then humanoid.WalkSpeed = orig end
		end)
	else
		task.delay(GameConfig.STUN_DURATION, function()
			self._stunned[target] = nil
		end)
	end
end

function CombatService:GetDamageDealt(player: Player): number
	return self._dmgDealt[player] or 0
end

function CombatService:ResetMatchStats()
	self._dmgDealt  = {}
	self._streaks   = {}
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function CombatService:Init()
	self._remotes.AttackRequest.OnServerEvent:Connect(function(attacker, targetVal)
		self:_handleAttack(attacker, targetVal)
	end)

	Players.PlayerRemoving:Connect(function(p)
		self._cooldowns[p] = nil
		self._stunned[p]   = nil
		self._streaks[p]   = nil
		self._dmgDealt[p]  = nil
	end)

	-- Reset streaks on character respawn (KO breaks streak)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			self._stunned[p]  = nil
		end)
	end)
end

-- ── Attack handling ───────────────────────────────────────────────────────────

function CombatService:_handleAttack(attacker: Player, targetVal: any)
	if typeof(targetVal) ~= "Instance" or not targetVal:IsA("Player") then return end
	local target = targetVal :: Player
	if attacker == target then return end

	-- Cannot attack while stunned
	if self._stunned[attacker] then return end

	-- GHOST cloaked: cannot attack
	if self._abilityService:IsCloaked(attacker) then return end

	-- Cooldown
	local now = tick()
	if (self._cooldowns[attacker] or 0) + GameConfig.ATTACK_COOLDOWN > now then return end
	self._cooldowns[attacker] = now

	-- Range check
	local aChar = attacker.Character
	local tChar = target.Character
	if not aChar or not tChar then return end
	local aRoot = aChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not aRoot or not tRoot then return end
	if (aRoot.Position - tRoot.Position).Magnitude > GameConfig.ATTACK_RANGE then return end

	-- Damage (SPARK Live Wire bonus + REAPER Death Mark multiplier)
	local damage = GameConfig.BASE_DAMAGE
	if self._abilityService:ConsumeSparkBonus(attacker) then
		damage += 8
	end
	if self._abilityService:IsMarked(target) then
		damage = math.floor(damage * 1.5)
	end

	local humanoid = tChar:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	humanoid.Health -= damage

	-- Track damage
	self._dmgDealt[attacker] = (self._dmgDealt[attacker] or 0) + damage

	-- Knockback
	local dir = (tRoot.Position - aRoot.Position).Unit
	local bv  = Instance.new("BodyVelocity")
	bv.Velocity  = dir * GameConfig.KNOCKBACK_FORCE
	bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
	bv.P         = 1e4
	bv.Parent    = tRoot
	Debris:AddItem(bv, 0.15)

	-- Light stun on every hit
	self._stunned[target] = true
	task.delay(GameConfig.STUN_DURATION, function()
		self._stunned[target] = nil
	end)

	local isKO = humanoid.Health <= 0

	-- Notify all clients
	self._remotes.CombatHit:FireAllClients({
		Attacker = attacker.DisplayName,
		Target   = target.DisplayName,
		Damage   = damage,
		KO       = isKO,
	})

	if isKO then
		self:_handleKO(attacker, target)
	end
end

function CombatService:_handleKO(attacker: Player, target: Player)
	-- Drop Core if target was carrying
	self._coreService:HandleCarrierKO(target)

	-- Streak tracking
	self._streaks[target]   = 0  -- victim loses streak
	local streak = (self._streaks[attacker] or 0) + 1
	self._streaks[attacker] = streak

	local streakLabel = STREAK_LABELS[math.min(streak, 5)]
	if streakLabel then
		self._remotes.StreakEvent:FireAllClients({
			Player = attacker.DisplayName,
			Streak = streak,
			Label  = streakLabel,
		})
	end

	-- Award XP via progression (injected after init, lazy-resolved via remote data)
	-- ProgressionService wires itself via Main.server.lua callbacks
	self._remotes.CombatHit:FireAllClients({
		Attacker = attacker.DisplayName,
		Target   = target.DisplayName,
		KO       = true,
		Streak   = streak,
	})
end

return CombatService
