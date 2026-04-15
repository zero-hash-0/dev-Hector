--!strict

-- Handles character selection, passive stat application, and ability execution.
-- All ability logic is server-authoritative.

local Players           = game:GetService("Players")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))
local GameConfig      = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local BASH_RANGE     = 16
local BASH_CONE_DOT  = 0.3   -- cosine threshold for "in front"
local SPARK_RANGE    = 14
local PHANTOM_DIST   = 22
local CLOAK_DURATION = 2.5
local BLITZ_DURATION = 3
local BLITZ_SPEED    = 42    -- 140% of sprint speed (~30)
local MARK_DURATION  = 3
local MARK_RANGE     = 16
local MOMENTUM_TICK  = 0.5   -- speed gained per second sprinting
local MOMENTUM_MAX   = 6     -- max bonus

local AbilityService = {}
AbilityService.__index = AbilityService

function AbilityService.new(remotes: { [string]: RemoteEvent }, combatService: any)
	local self = setmetatable({}, AbilityService)
	self._remotes      = remotes
	self._combat       = combatService
	self._selections   = {} :: { [Player]: string }   -- characterId per player
	self._cooldowns    = {} :: { [Player]: number }   -- last ability use tick
	self._cloaked      = {} :: { [Player]: boolean }
	self._sparkBonus   = {} :: { [Player]: boolean }  -- Live Wire first-hit bonus
	self._blitzing     = {} :: { [Player]: boolean }  -- SURGE blitz active
	self._momentumBonus = {} :: { [Player]: number }  -- SURGE accumulated speed
	self._marked       = {} :: { [Player]: number }   -- REAPER mark expiry tick
	return self
end

-- ── Public ────────────────────────────────────────────────────────────────────

function AbilityService:GetCharacter(player: Player): string
	return self._selections[player] or "VIPER"
end

function AbilityService:IsCloaked(player: Player): boolean
	return self._cloaked[player] == true
end

-- Called by CombatService to check if target is Death Marked (REAPER)
function AbilityService:IsMarked(player: Player): boolean
	local expiry = self._marked[player]
	if expiry and tick() < expiry then return true end
	self._marked[player] = nil
	return false
end

-- Called by CombatService to check/consume the SPARK first-hit bonus
function AbilityService:ConsumeSparkBonus(player: Player): boolean
	if self._sparkBonus[player] then
		self._sparkBonus[player] = nil
		return true
	end
	return false
end

-- Called by CoreService to check TANK passive
function AbilityService:HasIronCarry(player: Player): boolean
	return self._selections[player] == "TANK"
end

function AbilityService:Init()
	-- Character selection (during Waiting/Countdown)
	self._remotes.CharacterSelect.OnServerEvent:Connect(function(player, charId)
		if typeof(charId) ~= "string" then return end
		if not CharacterConfig.Characters[charId] then return end
		self._selections[player] = charId
		self._remotes.CharacterSelect:FireClient(player, { Confirmed = charId })
	end)

	-- Ability activation
	self._remotes.AbilityRequest.OnServerEvent:Connect(function(player)
		self:_handleAbility(player)
	end)

	-- Re-apply passives on every respawn
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:_applyPassive(player, character)
		end)
	end)

	-- Clean up on leave
	Players.PlayerRemoving:Connect(function(player)
		self._selections[player]    = nil
		self._cooldowns[player]     = nil
		self._cloaked[player]       = nil
		self._sparkBonus[player]    = nil
		self._blitzing[player]      = nil
		self._momentumBonus[player] = nil
		self._marked[player]        = nil
	end)
end

-- ── Passive application ───────────────────────────────────────────────────────

function AbilityService:_applyPassive(player: Player, character: Model)
	local charId = self._selections[player] or "VIPER"
	local cfg    = CharacterConfig.Characters[charId]

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = math.floor(GameConfig.BASE_HEALTH * cfg.Stats.HealthMult)
	humanoid.Health    = humanoid.MaxHealth
	humanoid.WalkSpeed = math.floor(GameConfig.WALK_SPEED * cfg.Stats.SpeedMult)

	-- SPARK passive: grant first-hit bonus each life
	if charId == "SPARK" then
		self._sparkBonus[player] = true
	end

	-- VIPER passive: slow-zone trail
	if charId == "VIPER" then
		self:_startSlipTrail(player, character)
	end

	-- SURGE passive: momentum speed buildup while sprinting
	if charId == "SURGE" then
		self._momentumBonus[player] = 0
		self:_startMomentumLoop(player, character, humanoid)
	end

	-- REAPER passive: heal on KO (wired via CombatService callback in Main)
	-- Nothing to set up per-spawn here; handled in _handleKO hook

	-- Nameplate billboard
	self:_buildNameplate(player, character, cfg)
end

function AbilityService:_buildNameplate(player: Player, character: Model, cfg: any)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local bb = Instance.new("BillboardGui")
	bb.Size        = UDim2.new(0, 150, 0, 44)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = root

	local nameL = Instance.new("TextLabel")
	nameL.Size                 = UDim2.new(1, 0, 0.55, 0)
	nameL.BackgroundTransparency = 1
	nameL.Font                 = Enum.Font.GothamBold
	nameL.TextColor3           = cfg.Color
	nameL.TextScaled           = true
	nameL.Text                 = player.DisplayName
	nameL.TextStrokeTransparency = 0.4
	nameL.Parent               = bb

	local charL = Instance.new("TextLabel")
	charL.Size                 = UDim2.new(1, 0, 0.45, 0)
	charL.Position             = UDim2.new(0, 0, 0.55, 0)
	charL.BackgroundTransparency = 1
	charL.Font                 = Enum.Font.GothamBold
	charL.TextColor3           = cfg.Color
	charL.TextTransparency     = 0.35
	charL.TextScaled           = true
	charL.Text                 = "[ " .. cfg.DisplayName .. " ]"
	charL.TextStrokeTransparency = 0.6
	charL.Parent               = bb
end

function AbilityService:_startSlipTrail(player: Player, character: Model)
	local root    = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	task.spawn(function()
		while character.Parent and humanoid.Health > 0 do
			task.wait(0.35)
			if humanoid.WalkSpeed < 2 then continue end -- standing still, no trail

			local zone = Instance.new("Part")
			zone.Anchored    = true
			zone.CanCollide  = false
			zone.Size        = Vector3.new(6, 0.3, 6)
			zone.Position    = root.Position - Vector3.new(0, 3, 0)
			zone.Material    = Enum.Material.Neon
			zone.Color       = Color3.fromHex("#00FF88")
			zone.Transparency = 0.6
			zone.Parent      = workspace

			-- Slow anyone standing in it (server-side proximity check)
			task.spawn(function()
				local elapsed = 0
				while elapsed < 1.5 do
					task.wait(0.1)
					elapsed += 0.1
					for _, p in Players:GetPlayers() do
						if p == player then continue end
						local pChar = p.Character
						if not pChar then continue end
						local pRoot = pChar:FindFirstChild("HumanoidRootPart") :: BasePart?
						local pHum  = pChar:FindFirstChildOfClass("Humanoid")
						if not pRoot or not pHum then continue end
						if (pRoot.Position - zone.Position).Magnitude < 4 then
							local orig = pHum.WalkSpeed
							pHum.WalkSpeed = math.max(orig * 0.45, 4)
							task.delay(0.3, function()
								if pChar.Parent then pHum.WalkSpeed = orig end
							end)
						end
					end
				end
				zone:Destroy()
			end)
		end
	end)
end

-- ── Ability dispatch ──────────────────────────────────────────────────────────

function AbilityService:_handleAbility(player: Player)
	local charId = self._selections[player]
	if not charId then return end

	local cfg     = CharacterConfig.Characters[charId]
	local now     = tick()
	local last    = self._cooldowns[player] or 0
	if now - last < cfg.Ability.Cooldown then return end

	-- GHOST can't attack while cloaked — don't block ability use, just let cloak run
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	self._cooldowns[player] = now

	if charId == "VIPER" then
		self:_abilityViper(player, root)
	elseif charId == "TANK" then
		self:_abilityTank(player, root)
	elseif charId == "GHOST" then
		self:_abilityGhost(player, character)
	elseif charId == "SPARK" then
		self:_abilitySpark(player, root)
	elseif charId == "SURGE" then
		self:_abilitySurge(player, character)
	elseif charId == "REAPER" then
		self:_abilityReaper(player, root)
	end

	-- Tell all clients to play the effect
	self._remotes.AbilityResult:FireAllClients({
		Event     = "Effect",
		Character = charId,
		Player    = player.DisplayName,
		Origin    = { X = root.Position.X, Y = root.Position.Y, Z = root.Position.Z },
	})
	-- Tell the caster their cooldown
	self._remotes.AbilityResult:FireClient(player, {
		Event    = "Cooldown",
		Duration = cfg.Ability.Cooldown,
	})
end

function AbilityService:_abilityViper(player: Player, root: BasePart)
	-- Blink forward 22 studs, skip through any obstacle
	local newPos = root.CFrame + root.CFrame.LookVector * PHANTOM_DIST
	root.CFrame  = newPos
end

function AbilityService:_abilityTank(_player: Player, root: BasePart)
	for _, target in Players:GetPlayers() do
		local tChar = target.Character
		if not tChar then continue end
		local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local tHum  = tChar:FindFirstChildOfClass("Humanoid")
		if not tRoot or not tHum or tHum.Health <= 0 then continue end

		local toTarget = tRoot.Position - root.Position
		if toTarget.Magnitude > BASH_RANGE then continue end
		if root.CFrame.LookVector:Dot(toTarget.Unit) < BASH_CONE_DOT then continue end

		-- Knockback
		local bv = Instance.new("BodyVelocity")
		bv.Velocity  = (toTarget.Unit + Vector3.new(0, 0.4, 0)) * 85
		bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
		bv.P         = 1e4
		bv.Parent    = tRoot
		Debris:AddItem(bv, 0.2)

		tHum.Health -= 15
	end
end

function AbilityService:_abilityGhost(player: Player, character: Model)
	if self._cloaked[player] then return end
	self._cloaked[player] = true

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			(part :: BasePart).Transparency = 0.92
			(part :: BasePart).CastShadow   = false
		end
	end

	self._remotes.AbilityResult:FireClient(player, {
		Event    = "Cloaked",
		Duration = CLOAK_DURATION,
	})

	task.delay(CLOAK_DURATION, function()
		self._cloaked[player] = nil
		if not character.Parent then return end
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				(part :: BasePart).Transparency = 0
				(part :: BasePart).CastShadow   = true
			end
		end
		self._remotes.AbilityResult:FireClient(player, { Event = "Uncloaked" })
	end)
end

function AbilityService:_abilitySpark(player: Player, root: BasePart)
	for _, target in Players:GetPlayers() do
		if target == player then continue end
		local tChar = target.Character
		if not tChar then continue end
		local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		local tHum  = tChar:FindFirstChildOfClass("Humanoid")
		if not tRoot or not tHum or tHum.Health <= 0 then continue end
		if (tRoot.Position - root.Position).Magnitude > SPARK_RANGE then continue end

		self._combat:ApplyStun(target)
		tHum.Health -= 10
	end
end

-- ── SURGE ─────────────────────────────────────────────────────────────────────

function AbilityService:_startMomentumLoop(player: Player, character: Model, humanoid: Humanoid)
	task.spawn(function()
		while character.Parent and humanoid.Health > 0 do
			task.wait(1)
			if self._blitzing[player] then continue end
			local isMoving = humanoid.MoveDirection.Magnitude > 0.1
				and humanoid.WalkSpeed >= 20  -- sprinting threshold
			if isMoving then
				local bonus = math.min(
					(self._momentumBonus[player] or 0) + MOMENTUM_TICK,
					MOMENTUM_MAX
				)
				self._momentumBonus[player] = bonus
				-- Apply on top of base sprint speed
				humanoid.WalkSpeed = math.floor(20 * 1.05 + bonus)  -- base sprint * SURGE mult + momentum
			else
				-- Decay on stop
				local bonus = math.max((self._momentumBonus[player] or 0) - MOMENTUM_TICK * 2, 0)
				self._momentumBonus[player] = bonus
			end
		end
	end)
end

function AbilityService:_abilitySurge(player: Player, character: Model)
	if self._blitzing[player] then return end
	self._blitzing[player] = true

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then self._blitzing[player] = nil return end

	local origSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = BLITZ_SPEED

	-- Collision knockback: poll nearby players while blitzing
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	task.spawn(function()
		local elapsed   = 0
		local hitAlready = {} :: { [Player]: boolean }
		while elapsed < BLITZ_DURATION do
			elapsed += task.wait(0.05)
			if not root or not character.Parent then break end
			for _, target in Players:GetPlayers() do
				if target == player or hitAlready[target] then continue end
				local tChar = target.Character
				if not tChar then continue end
				local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				local tHum  = tChar:FindFirstChildOfClass("Humanoid")
				if not tRoot or not tHum or tHum.Health <= 0 then continue end
				if (root.Position - tRoot.Position).Magnitude > 5 then continue end

				-- Knockback
				local bv = Instance.new("BodyVelocity")
				bv.Velocity  = (tRoot.Position - root.Position).Unit * 70 + Vector3.new(0, 15, 0)
				bv.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
				bv.P         = 1e4
				bv.Parent    = tRoot
				game:GetService("Debris"):AddItem(bv, 0.2)
				tHum.Health -= 12
				hitAlready[target] = true

				self._remotes.CombatHit:FireAllClients({
					Attacker = player.DisplayName,
					Target   = target.DisplayName,
					Damage   = 12,
					KO       = tHum.Health <= 0,
				})
				if tHum.Health <= 0 then
					self._combat:_handleKO(self._combat, player, target)
				end
			end
		end
		self._blitzing[player] = nil
		if character.Parent then
			humanoid.WalkSpeed = origSpeed
		end
	end)
end

-- ── REAPER ────────────────────────────────────────────────────────────────────

function AbilityService:_abilityReaper(player: Player, root: BasePart)
	-- Mark nearest enemy within range
	local nearest: Player? = nil
	local nearestDist = MARK_RANGE

	for _, target in Players:GetPlayers() do
		if target == player then continue end
		local tChar = target.Character
		if not tChar then continue end
		local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not tRoot then continue end
		local dist = (root.Position - tRoot.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearest     = target
		end
	end

	if not nearest then return end

	self._marked[nearest] = tick() + MARK_DURATION

	-- Visual indicator on the marked player (BillboardGui)
	task.spawn(function()
		local tChar = nearest and nearest.Character
		if not tChar then return end
		local tRoot = tChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not tRoot then return end

		local bb = Instance.new("BillboardGui")
		bb.Size        = UDim2.new(0, 60, 0, 60)
		bb.StudsOffset = Vector3.new(0, 5, 0)
		bb.AlwaysOnTop = true
		bb.Parent      = tRoot

		local skull = Instance.new("TextLabel")
		skull.Size             = UDim2.new(1, 0, 1, 0)
		skull.BackgroundTransparency = 1
		skull.Font             = Enum.Font.GothamBold
		skull.TextColor3       = Color3.fromHex("#A855F7")
		skull.TextScaled       = true
		skull.Text             = "💀"
		skull.Parent           = bb

		task.delay(MARK_DURATION, function() bb:Destroy() end)
	end)

	self._remotes.AbilityResult:FireAllClients({
		Event    = "Effect",
		Character = "REAPER",
		Player   = player.DisplayName,
		Target   = nearest.DisplayName,
		Origin   = { X = root.Position.X, Y = root.Position.Y, Z = root.Position.Z },
	})
end

-- REAPER soul harvest — called from Main.server.lua KO hook
function AbilityService:OnKill(killer: Player)
	if self._selections[killer] ~= "REAPER" then return end
	local char = killer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	hum.Health = math.min(hum.Health + 25, hum.MaxHealth)
end

return AbilityService
