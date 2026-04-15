--!strict

-- Handles E key input for abilities and drives the cooldown arc UI.
-- Also renders client-side ability VFX (flash, ring, blink trail).

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Camera      = workspace.CurrentCamera

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local AbilityRequest  = Remotes:WaitForChild("AbilityRequest")  :: RemoteEvent
local AbilityResult   = Remotes:WaitForChild("AbilityResult")   :: RemoteEvent
local CharacterSelect = Remotes:WaitForChild("CharacterSelect") :: RemoteEvent

local CharacterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))

-- ── State ─────────────────────────────────────────────────────────────────────
local myCharId      = "VIPER"
local onCooldown    = false
local cooldownEnd   = 0
local isCloaked     = false

-- ── GUI — ability button with cooldown arc ────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "AbilityHUD"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Parent         = PlayerGui

-- Ability button (bottom center)
local abilityFrame = Instance.new("Frame")
abilityFrame.Size             = UDim2.new(0, 72, 0, 72)
abilityFrame.Position         = UDim2.new(0.5, -36, 1, -160)
abilityFrame.BackgroundColor3 = Color3.fromHex("#111128")
abilityFrame.BorderSizePixel  = 0
abilityFrame.Parent           = screen

local aCorner = Instance.new("UICorner")
aCorner.CornerRadius = UDim.new(0, 36)
aCorner.Parent       = abilityFrame

local aStroke = Instance.new("UIStroke")
aStroke.Color     = Color3.fromHex("#00FF88")
aStroke.Thickness = 2.5
aStroke.Parent    = abilityFrame

local aKeyLabel = Instance.new("TextLabel")
aKeyLabel.Size             = UDim2.new(1, 0, 0.5, 0)
aKeyLabel.BackgroundTransparency = 1
aKeyLabel.Font             = Enum.Font.GothamBold
aKeyLabel.TextColor3       = Color3.new(1, 1, 1)
aKeyLabel.TextScaled       = true
aKeyLabel.Text             = "E"
aKeyLabel.Parent           = abilityFrame

local aNameLabel = Instance.new("TextLabel")
aNameLabel.Size             = UDim2.new(1, 0, 0.4, 0)
aNameLabel.Position         = UDim2.new(0, 0, 0.55, 0)
aNameLabel.BackgroundTransparency = 1
aNameLabel.Font             = Enum.Font.GothamBold
aNameLabel.TextColor3       = Color3.fromHex("#00FF88")
aNameLabel.TextTransparency = 0.2
aNameLabel.TextScaled       = true
aNameLabel.Text             = "DASH"
aNameLabel.Parent           = abilityFrame

-- Cooldown dim overlay
local cdOverlay = Instance.new("Frame")
cdOverlay.Size             = UDim2.new(1, 0, 1, 0)
cdOverlay.BackgroundColor3 = Color3.fromHex("#000000")
cdOverlay.BackgroundTransparency = 1
cdOverlay.BorderSizePixel  = 0
cdOverlay.ZIndex           = 2
cdOverlay.Parent           = abilityFrame
local cdCorner = Instance.new("UICorner")
cdCorner.CornerRadius = UDim.new(0, 36)
cdCorner.Parent       = cdOverlay

local cdText = Instance.new("TextLabel")
cdText.Size             = UDim2.new(1, 0, 1, 0)
cdText.BackgroundTransparency = 1
cdText.Font             = Enum.Font.GothamBold
cdText.TextColor3       = Color3.new(1, 1, 1)
cdText.TextScaled       = true
cdText.Text             = ""
cdText.ZIndex           = 3
cdText.Parent           = abilityFrame

-- ── Cloak vignette (for GHOST) ────────────────────────────────────────────────
local vignetteGui = Instance.new("ScreenGui")
vignetteGui.Name           = "CloakVignette"
vignetteGui.ResetOnSpawn   = false
vignetteGui.IgnoreGuiInset = true
vignetteGui.Parent         = PlayerGui

local vignette = Instance.new("Frame")
vignette.Size             = UDim2.new(1, 0, 1, 0)
vignette.BackgroundColor3 = Color3.fromHex("#B8C0FF")
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel  = 0
vignette.Parent           = vignetteGui

-- ── Update ability button to match character ──────────────────────────────────
local function syncCharacter(charId: string)
	myCharId = charId
	local cfg = CharacterConfig.Characters[charId]
	aStroke.Color        = cfg.Color
	aNameLabel.TextColor3 = cfg.Color
	aNameLabel.Text      = cfg.Ability.Name:upper()
	abilityFrame.BackgroundColor3 = Color3.fromHex("#111128")
	onCooldown = false
	cdOverlay.BackgroundTransparency = 1
	cdText.Text = ""
end

-- ── Cooldown tick ─────────────────────────────────────────────────────────────
RunService.RenderStepped:Connect(function()
	if not onCooldown then return end
	local cfg      = CharacterConfig.Characters[myCharId]
	local elapsed  = tick() - (cooldownEnd - cfg.Ability.Cooldown)
	local progress = math.clamp(elapsed / cfg.Ability.Cooldown, 0, 1)
	local remaining = math.max(cooldownEnd - tick(), 0)

	cdOverlay.BackgroundTransparency = 0.45 + 0.55 * progress
	cdText.Text = remaining > 0 and string.format("%.1f", remaining) or ""

	if remaining <= 0 then
		onCooldown = false
		cdOverlay.BackgroundTransparency = 1
		cdText.Text = ""
		-- Ready flash
		TweenService:Create(aStroke,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad),
			{ Thickness = 5 }
		):Play()
		task.delay(0.2, function()
			TweenService:Create(aStroke,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad),
				{ Thickness = 2.5 }
			):Play()
		end)
	end
end)

-- ── VFX helpers ───────────────────────────────────────────────────────────────

local function vfxPhantomDash(origin: Vector3)
	-- Leave a ghost trail at origin position (client-side part that fades)
	local ghost = Instance.new("Part")
	ghost.Anchored    = true
	ghost.CanCollide  = false
	ghost.Size        = Vector3.new(2, 4, 1)
	ghost.Position    = origin
	ghost.Material    = Enum.Material.Neon
	ghost.Color       = Color3.fromHex("#00FF88")
	ghost.Transparency = 0.4
	ghost.CastShadow  = false
	ghost.Parent      = workspace

	TweenService:Create(ghost,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 1, Size = Vector3.new(0.5, 4.5, 0.2) }
	):Play()
	game:GetService("Debris"):AddItem(ghost, 0.55)
end

local function vfxShieldBash(origin: Vector3)
	-- Orange impact ring
	local ring = Instance.new("Part")
	ring.Anchored    = true
	ring.CanCollide  = false
	ring.Size        = Vector3.new(2, 0.4, 2)
	ring.Position    = origin
	ring.Material    = Enum.Material.Neon
	ring.Color       = Color3.fromHex("#FF6B35")
	ring.Transparency = 0.2
	ring.Shape       = Enum.PartType.Cylinder
	ring.CastShadow  = false
	ring.Parent      = workspace

	TweenService:Create(ring,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(28, 0.4, 28), Transparency = 1 }
	):Play()
	game:GetService("Debris"):AddItem(ring, 0.45)
end

local function vfxThunderclap(origin: Vector3)
	-- Yellow flash sphere
	local sphere = Instance.new("Part")
	sphere.Anchored    = true
	sphere.CanCollide  = false
	sphere.Size        = Vector3.new(4, 4, 4)
	sphere.Position    = origin
	sphere.Material    = Enum.Material.Neon
	sphere.Color       = Color3.fromHex("#FFD60A")
	sphere.Transparency = 0.1
	sphere.Shape       = Enum.PartType.Ball
	sphere.CastShadow  = false
	sphere.Parent      = workspace

	TweenService:Create(sphere,
		TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(32, 32, 32), Transparency = 1 }
	):Play()
	game:GetService("Debris"):AddItem(sphere, 0.5)

	-- Camera shake if local player nearby
	local char = LocalPlayer.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and (root.Position - origin).Magnitude < 20 then
			Camera.CFrame = Camera.CFrame * CFrame.new(
				math.random(-2, 2) * 0.1,
				math.random(-2, 2) * 0.1, 0
			)
		end
	end
end

local function vfxCloak(active: boolean)
	if active then
		TweenService:Create(vignette,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.85 }
		):Play()
	else
		TweenService:Create(vignette,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
	end
end

-- ── Input ─────────────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E and not onCooldown then
		AbilityRequest:FireServer()

		-- Save origin for trail VFX
		local char = LocalPlayer.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and myCharId == "VIPER" then
				vfxPhantomDash(root.Position)
			end
		end
	end
end)

-- ── Server events ─────────────────────────────────────────────────────────────

AbilityResult.OnClientEvent:Connect(function(data: { [string]: any })
	local event = data.Event :: string

	if event == "Cooldown" then
		onCooldown  = true
		cooldownEnd = tick() + (data.Duration :: number)
		cdOverlay.BackgroundTransparency = 0.45
	end

	if event == "Cloaked" then
		isCloaked = true
		vfxCloak(true)
	end

	if event == "Uncloaked" then
		isCloaked = false
		vfxCloak(false)
	end

	if event == "Effect" then
		local charId = data.Character :: string
		local origin = data.Origin
		if not origin then return end
		local pos = Vector3.new(origin.X :: number, origin.Y :: number, origin.Z :: number)

		if charId == "VIPER" then
			vfxPhantomDash(pos)
		elseif charId == "TANK" then
			vfxShieldBash(pos)
		elseif charId == "SPARK" then
			vfxThunderclap(pos)
		end
	end
end)

CharacterSelect.OnClientEvent:Connect(function(data: { Confirmed: string? })
	if data.Confirmed then
		syncCharacter(data.Confirmed)
	end
end)
