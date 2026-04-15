--!strict

-- Input handler: attack, sprint, dash.
-- Visual feedback: damage flash, hit markers.
-- HUD is handled separately in HudClient.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local SprintRequest = Remotes:WaitForChild("SprintRequest") :: RemoteEvent
local DashRequest   = Remotes:WaitForChild("DashRequest")   :: RemoteEvent
local CombatHit     = Remotes:WaitForChild("CombatHit")     :: RemoteEvent

-- ── Damage flash overlay ──────────────────────────────────────────────────────
local flashGui = Instance.new("ScreenGui")
flashGui.Name           = "DamageFlash"
flashGui.IgnoreGuiInset = true
flashGui.ResetOnSpawn   = false
flashGui.Parent         = PlayerGui

local flashFrame = Instance.new("Frame")
flashFrame.Size                = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3    = Color3.fromHex("#FF0000")
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel     = 0
flashFrame.Parent              = flashGui

local function triggerDamageFlash()
	flashFrame.BackgroundTransparency = 0.55
	TweenService:Create(flashFrame,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
end

-- ── Hit marker (brief cross on screen) ───────────────────────────────────────
local hitGui = Instance.new("ScreenGui")
hitGui.Name           = "HitMarker"
hitGui.IgnoreGuiInset = true
hitGui.ResetOnSpawn   = false
hitGui.Parent         = PlayerGui

local hitMarker = Instance.new("TextLabel")
hitMarker.Size                   = UDim2.new(0, 60, 0, 60)
hitMarker.Position               = UDim2.new(0.5, -30, 0.5, -30)
hitMarker.BackgroundTransparency = 1
hitMarker.Font                   = Enum.Font.GothamBold
hitMarker.Text                   = "✕"
hitMarker.TextColor3             = Color3.new(1, 1, 1)
hitMarker.TextTransparency       = 1
hitMarker.TextScaled             = true
hitMarker.Parent                 = hitGui

local function triggerHitMarker(ko: boolean)
	hitMarker.TextColor3    = ko and Color3.fromHex("#FFD700") or Color3.new(1, 1, 1)
	hitMarker.Text          = ko and "KO!" or "✕"
	hitMarker.TextTransparency = 0
	TweenService:Create(hitMarker,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 1 }
	):Play()
end

-- ── Nearest enemy lookup ──────────────────────────────────────────────────────
local ATTACK_RANGE = 8  -- client-side pre-filter (server re-validates)

local function findNearestEnemy(): Player?
	local character = LocalPlayer.Character
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end

	local nearest: Player? = nil
	local nearestDist = ATTACK_RANGE

	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		local char = player.Character
		if not char then continue end
		local otherRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not otherRoot then continue end
		local dist = (root.Position - otherRoot.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearest     = player
		end
	end
	return nearest
end

-- ── Input state ───────────────────────────────────────────────────────────────
local attackCooldown = false

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then return end

	-- Attack — F
	if input.KeyCode == Enum.KeyCode.F and not attackCooldown then
		local target = findNearestEnemy()
		if target then
			AttackRequest:FireServer(target)
			attackCooldown = true
			task.delay(0.4, function() attackCooldown = false end)
		end
	end

	-- Sprint — Left Shift
	if input.KeyCode == Enum.KeyCode.LeftShift then
		SprintRequest:FireServer(true)
	end

	-- Dash — Q
	if input.KeyCode == Enum.KeyCode.Q then
		local cam  = workspace.CurrentCamera
		local look = cam.CFrame.LookVector
		local dir  = Vector3.new(look.X, 0, look.Z).Unit
		DashRequest:FireServer(dir)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _processed: boolean)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		SprintRequest:FireServer(false)
	end
end)

-- ── Server feedback ───────────────────────────────────────────────────────────
CombatHit.OnClientEvent:Connect(function(data: { Attacker: string, Target: string, Damage: number?, KO: boolean? })
	local isAttacker = data.Attacker == LocalPlayer.DisplayName
	local isTarget   = data.Target   == LocalPlayer.DisplayName

	if isAttacker then
		triggerHitMarker(data.KO == true)
	end
	if isTarget then
		triggerDamageFlash()
	end
end)
