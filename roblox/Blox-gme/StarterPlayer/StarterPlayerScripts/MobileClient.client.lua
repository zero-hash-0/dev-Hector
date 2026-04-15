--!strict

-- On-screen touch controls for mobile players.
-- Only renders when UserInputService.TouchEnabled is true.
-- Roblox handles movement joystick natively; this adds:
--   • Attack button  (right thumb zone)
--   • Ability button (right thumb zone, above attack)
--   • Sprint toggle  (left thumb zone)

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Only load on touch devices
if not UserInputService.TouchEnabled then return end

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes       = ReplicatedStorage:WaitForChild("Remotes")
local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local SprintRequest = Remotes:WaitForChild("SprintRequest") :: RemoteEvent
local AbilityRequest = Remotes:WaitForChild("AbilityRequest") :: RemoteEvent

local CharacterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))
local CharacterSelect = Remotes:WaitForChild("CharacterSelect") :: RemoteEvent

-- ── State ─────────────────────────────────────────────────────────────────────
local sprintOn      = false
local attackCooldown = false
local myCharId      = "VIPER"

-- ── Root GUI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "MobileHUD"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent         = PlayerGui

-- ── Helper ────────────────────────────────────────────────────────────────────

local function touchBtn(props: {
	size    : UDim2,
	pos     : UDim2,
	color   : Color3,
	text    : string,
	alpha   : number?,
}): TextButton

	local btn = Instance.new("TextButton")
	btn.Size             = props.size
	btn.Position         = props.pos
	btn.BackgroundColor3 = props.color
	btn.BackgroundTransparency = props.alpha or 0.25
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextColor3       = Color3.new(1, 1, 1)
	btn.TextScaled       = true
	btn.Text             = props.text
	btn.AutoButtonColor  = false
	btn.Parent           = screen

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.5, 0)
	c.Parent       = btn

	return btn
end

local function flash(btn: TextButton, color: Color3)
	btn.BackgroundTransparency = 0.05
	btn.BackgroundColor3       = color
	TweenService:Create(btn,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad),
		{ BackgroundTransparency = 0.3 }
	):Play()
	task.delay(0.25, function()
		btn.BackgroundColor3 = color
	end)
end

-- ── Attack button ─────────────────────────────────────────────────────────────
-- Bottom-right quadrant, large target
local attackBtn = touchBtn({
	size  = UDim2.new(0, 100, 0, 100),
	pos   = UDim2.new(1, -120, 1, -130),
	color = Color3.fromHex("#FF3333"),
	text  = "⚔",
})

attackBtn.MouseButton1Down:Connect(function()
	if attackCooldown then return end

	-- Find nearest enemy client-side (server re-validates)
	local character = LocalPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local nearest: Player? = nil
	local nearestDist = 10

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

	if nearest then
		AttackRequest:FireServer(nearest)
		attackCooldown = true
		flash(attackBtn, Color3.fromHex("#FF6666"))
		task.delay(0.4, function()
			attackCooldown = false
		end)
	end
end)

-- ── Ability button ────────────────────────────────────────────────────────────
local abilityBtn = touchBtn({
	size  = UDim2.new(0, 80, 0, 80),
	pos   = UDim2.new(1, -220, 1, -160),
	color = Color3.fromHex("#00FF88"),
	text  = "E",
})

abilityBtn.MouseButton1Down:Connect(function()
	AbilityRequest:FireServer()
	flash(abilityBtn, Color3.fromHex("#88FFBB"))
end)

-- ── Sprint toggle ─────────────────────────────────────────────────────────────
local sprintBtn = touchBtn({
	size  = UDim2.new(0, 80, 0, 80),
	pos   = UDim2.new(0, 140, 1, -150),
	color = Color3.fromHex("#00B4D8"),
	text  = "RUN",
	alpha = 0.3,
})

sprintBtn.MouseButton1Down:Connect(function()
	sprintOn = not sprintOn
	SprintRequest:FireServer(sprintOn)
	sprintBtn.BackgroundColor3       = sprintOn
		and Color3.fromHex("#00B4D8")
		or Color3.fromHex("#334455")
	sprintBtn.BackgroundTransparency = sprintOn and 0.1 or 0.4
	sprintBtn.Text                   = sprintOn and "STOP" or "RUN"
end)

-- ── Sync ability button color to selected character ───────────────────────────
local function syncCharColor(charId: string)
	myCharId = charId
	local cfg = CharacterConfig.Characters[charId]
	if cfg then
		abilityBtn.BackgroundColor3 = cfg.Color
	end
end

CharacterSelect.OnClientEvent:Connect(function(data: { Confirmed: string? })
	if data.Confirmed then syncCharColor(data.Confirmed) end
end)

-- ── Hide buttons when character select is open, show during match ─────────────
local MatchState = Remotes:WaitForChild("MatchState") :: RemoteEvent

MatchState.OnClientEvent:Connect(function(data: { State: string })
	local visible = data.State == "Active" or data.State == "SuddenDeath"
	attackBtn.Visible  = visible
	abilityBtn.Visible = visible
	sprintBtn.Visible  = visible

	if not visible then
		-- Reset sprint on match end
		sprintOn = false
		SprintRequest:FireServer(false)
	end
end)

-- Start hidden until match begins
attackBtn.Visible  = false
abilityBtn.Visible = false
sprintBtn.Visible  = false
