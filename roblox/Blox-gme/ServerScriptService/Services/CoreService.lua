--!strict

-- Manages the Core: spawn, pickup, carry, drop, return, escape detection.
-- Tracks carry time per player for match summary and XP rewards.

local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local CoreService = {}
CoreService.__index = CoreService

function CoreService.new(remotes: { [string]: RemoteEvent }, matchService: any, abilityService: any?)
	local self = setmetatable({}, CoreService)
	self._remotes        = remotes
	self._matchService   = matchService
	self._abilityService = abilityService
	self._core           = nil  :: BasePart?
	self._carrier        = nil  :: Player?
	self._returnTimer    = nil  :: thread?
	self._escapeZones    = {}   :: { [Player]: BasePart }
	-- Carry time tracking
	self._carryStart     = {}   :: { [Player]: number }   -- tick() when pickup started
	self._carryTotal     = {}   :: { [Player]: number }   -- total seconds carried this match
	return self
end

-- ── Carry time API ────────────────────────────────────────────────────────────

function CoreService:GetCarryTime(player: Player): number
	return self._carryTotal[player] or 0
end

function CoreService:ResetCarryStats()
	self._carryTotal = {}
	self._carryStart = {}
end

function CoreService:GetCurrentCarrier(): Player?
	return self._carrier
end

-- ── Escape zones ──────────────────────────────────────────────────────────────

function CoreService:RegisterEscapeZone(player: Player, zone: BasePart)
	self._escapeZones[player] = zone
end

-- ── Core spawn ────────────────────────────────────────────────────────────────

function CoreService:SpawnCore()
	if self._core then self._core:Destroy() end

	local core = Instance.new("Part")
	core.Name      = "TheCore"
	core.Size      = Vector3.new(3.5, 3.5, 3.5)
	core.Shape     = Enum.PartType.Ball
	core.BrickColor = BrickColor.new("Bright yellow")
	core.Material  = Enum.Material.Neon
	core.Anchored  = true
	core.Position  = Vector3.new(0, GameConfig.CORE_SPAWN_HEIGHT + 2, 0)
	core.CastShadow = true
	core.Parent    = Workspace

	-- Idle bob animation
	task.spawn(function()
		local t = 0
		while core.Parent and not self._carrier do
			t += task.wait(0.05)
			core.Position = Vector3.new(0, (GameConfig.CORE_SPAWN_HEIGHT + 2) + math.sin(t * 2) * 0.6, 0)
		end
	end)

	-- Proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText              = "THE CORE"
	prompt.ActionText              = "Grab"
	prompt.MaxActivationDistance   = GameConfig.ATTACK_RANGE + 2
	prompt.HoldDuration            = 0
	prompt.Parent                  = core

	prompt.Triggered:Connect(function(player)
		self:_onPickup(player)
	end)

	self._core    = core
	self._carrier = nil
	self._remotes.CoreState:FireAllClients({ Event = "Spawned" })
end

-- ── Pickup ────────────────────────────────────────────────────────────────────

function CoreService:_onPickup(player: Player)
	if self._carrier then return end
	if self._matchService:GetState() ~= "Active"
		and self._matchService:GetState() ~= "SuddenDeath" then return end

	self._carrier              = player
	self._carryStart[player]   = tick()

	local core = self._core
	if not core then return end
	core.Anchored = false

	-- Weld Core to player's torso
	local char = player.Character
	if not char then return end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then
		local weld = Instance.new("WeldConstraint")
		weld.Part0  = torso
		weld.Part1  = core
		weld.Parent = core
		core.Position = torso.Position + Vector3.new(0, 2.5, 0)
		core.Parent   = char
	end

	-- Speed penalty (unless TANK)
	local isIronCarry = self._abilityService and self._abilityService:HasIronCarry(player)
	if not isIronCarry then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = hum.WalkSpeed * GameConfig.CARRIER_PENALTY end
	end

	-- Cancel return timer
	if self._returnTimer then task.cancel(self._returnTimer) self._returnTimer = nil end

	self._remotes.CoreState:FireAllClients({
		Event   = "PickedUp",
		Carrier = player.DisplayName,
	})
end

-- ── Drop ──────────────────────────────────────────────────────────────────────

function CoreService:DropCore(fromPlayer: Player)
	if self._carrier ~= fromPlayer then return end
	self:_detach(fromPlayer, false)
	self._remotes.CoreState:FireAllClients({ Event = "Dropped" })
	self:_startReturnTimer()
end

function CoreService:_detach(player: Player, escaped: boolean)
	-- Accumulate carry time
	local start = self._carryStart[player]
	if start then
		local duration = tick() - start
		self._carryTotal[player] = (self._carryTotal[player] or 0) + duration
		self._carryStart[player] = nil
	end

	self._carrier = nil

	-- Restore speed
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local cfg = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))
			local charId = self._abilityService and self._abilityService:GetCharacter(player) or "VIPER"
			local charCfg = cfg.Characters[charId]
			hum.WalkSpeed = math.floor(GameConfig.WALK_SPEED * charCfg.Stats.SpeedMult)
		end
	end

	if not escaped then
		local core = self._core
		if core then
			-- Remove weld, drop to world
			for _, c in core:GetChildren() do
				if c:IsA("WeldConstraint") then c:Destroy() end
			end
			core.Parent   = Workspace
			core.Anchored = false
		end
	end
end

function CoreService:_startReturnTimer()
	self._returnTimer = task.delay(GameConfig.CORE_RETURN_DELAY, function()
		self:SpawnCore()
		self._remotes.CoreState:FireAllClients({ Event = "Returned" })
	end)
end

-- ── Sudden death carrier boost ────────────────────────────────────────────────

function CoreService:BoostCarrier()
	if not self._carrier then return end
	local char = self._carrier.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = math.min(hum.WalkSpeed + 8, GameConfig.SPRINT_SPEED)
	end
end

-- ── Escape detection (called every Heartbeat) ─────────────────────────────────

function CoreService:CheckEscape()
	if not self._carrier then return end
	local zone = self._escapeZones[self._carrier]
	local core = self._core
	if not zone or not core then return end

	local carrier = self._carrier
	local char    = carrier.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	if (root.Position - zone.Position).Magnitude < (zone.Size.Magnitude / 2) then
		self:_triggerEscape(carrier)
	end
end

function CoreService:_triggerEscape(carrier: Player)
	self._matchService:DeclareWinner(carrier)
	self:_detach(carrier, true)

	if self._core then self._core:Destroy() self._core = nil end
	self._remotes.CoreState:FireAllClients({
		Event  = "Escaped",
		Player = carrier.DisplayName,
	})
end

-- Called at match end (time expiry) — whoever holds Core wins
function CoreService:ResolveTimeExpiry()
	local carrier = self._carrier
	self._matchService:DeclareCarrierWinner(carrier)
	if carrier then
		self:_detach(carrier, false)
	end
end

-- ── KO handling ───────────────────────────────────────────────────────────────

function CoreService:HandleCarrierKO(player: Player)
	if self._carrier ~= player then return end
	if GameConfig.CORE_DROP_ON_DEATH then
		self:DropCore(player)
	end
end

return CoreService
