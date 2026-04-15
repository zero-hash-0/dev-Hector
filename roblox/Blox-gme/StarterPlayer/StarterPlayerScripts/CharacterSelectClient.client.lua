--!strict

-- Character selection screen shown during Waiting / Countdown states.
-- Card-game aesthetic — matches ART_STYLE.md visual identity.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local MatchState      = Remotes:WaitForChild("MatchState")      :: RemoteEvent
local CharacterSelect = Remotes:WaitForChild("CharacterSelect") :: RemoteEvent

local CharacterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))

-- ── Colors ─────────────────────────────────────────────────────────────────────
local BG        = Color3.fromHex("#0D0D1A")
local PANEL     = Color3.fromHex("#12122A")
local SELECTED  = Color3.fromHex("#FFFFFF")

-- ── State ─────────────────────────────────────────────────────────────────────
local selectedId: string = "VIPER"
local confirmed          = false
local cardFrames: { [string]: Frame } = {}

-- ── Root GUI ──────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "CharacterSelect"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Enabled        = true
screen.Parent         = PlayerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Size             = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = BG
overlay.BackgroundTransparency = 0.08
overlay.BorderSizePixel  = 0
overlay.Parent           = screen

-- Title
local title = Instance.new("TextLabel")
title.Size             = UDim2.new(0, 600, 0, 60)
title.Position         = UDim2.new(0.5, -300, 0, 40)
title.BackgroundTransparency = 1
title.Font             = Enum.Font.GothamBold
title.TextColor3       = Color3.new(1, 1, 1)
title.TextScaled       = true
title.Text             = "SELECT YOUR FIGHTER"
title.TextStrokeTransparency = 0.6
title.Parent           = overlay

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Size             = UDim2.new(0, 500, 0, 30)
subtitle.Position         = UDim2.new(0.5, -250, 0, 100)
subtitle.BackgroundTransparency = 1
subtitle.Font             = Enum.Font.Gotham
subtitle.TextColor3       = Color3.fromHex("#8888AA")
subtitle.TextScaled       = true
subtitle.Text             = "Pick your playstyle — ability on E"
subtitle.Parent           = overlay

-- Cards container
local container = Instance.new("Frame")
container.Size             = UDim2.new(0, 880, 0, 360)
container.Position         = UDim2.new(0.5, -440, 0.5, -160)
container.BackgroundTransparency = 1
container.Parent           = overlay

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment   = Enum.VerticalAlignment.Center
layout.Padding             = UDim.new(0, 16)
layout.Parent              = container

-- ── Build a character card ────────────────────────────────────────────────────

local function buildCard(charId: string)
	local cfg = CharacterConfig.Characters[charId]

	local card = Instance.new("Frame")
	card.Size             = UDim2.new(0, 196, 0, 340)
	card.BackgroundColor3 = PANEL
	card.BorderSizePixel  = 0
	card.Parent           = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = card

	-- Color accent bar (top)
	local bar = Instance.new("Frame")
	bar.Size             = UDim2.new(1, 0, 0, 6)
	bar.BackgroundColor3 = cfg.Color
	bar.BorderSizePixel  = 0
	bar.Parent           = card
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 10)
	barCorner.Parent = bar

	-- Character name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size             = UDim2.new(1, -16, 0, 44)
	nameLabel.Position         = UDim2.new(0, 8, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font             = Enum.Font.GothamBold
	nameLabel.TextColor3       = cfg.Color
	nameLabel.TextScaled       = true
	nameLabel.Text             = cfg.DisplayName
	nameLabel.TextXAlignment   = Enum.TextXAlignment.Left
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Parent           = card

	-- Tagline
	local tagline = Instance.new("TextLabel")
	tagline.Size             = UDim2.new(1, -16, 0, 22)
	tagline.Position         = UDim2.new(0, 8, 0, 58)
	tagline.BackgroundTransparency = 1
	tagline.Font             = Enum.Font.GothamBold
	tagline.TextColor3       = Color3.fromHex("#888899")
	tagline.TextScaled       = true
	tagline.Text             = cfg.Tagline
	tagline.TextXAlignment   = Enum.TextXAlignment.Left
	tagline.Parent           = card

	-- Divider
	local divider = Instance.new("Frame")
	divider.Size             = UDim2.new(1, -16, 0, 1)
	divider.Position         = UDim2.new(0, 8, 0, 90)
	divider.BackgroundColor3 = Color3.fromHex("#2A2A44")
	divider.BorderSizePixel  = 0
	divider.Parent           = card

	-- Passive section
	local passiveHeader = Instance.new("TextLabel")
	passiveHeader.Size             = UDim2.new(1, -16, 0, 16)
	passiveHeader.Position         = UDim2.new(0, 8, 0, 100)
	passiveHeader.BackgroundTransparency = 1
	passiveHeader.Font             = Enum.Font.GothamBold
	passiveHeader.TextColor3       = Color3.fromHex("#555577")
	passiveHeader.TextScaled       = true
	passiveHeader.Text             = "PASSIVE"
	passiveHeader.TextXAlignment   = Enum.TextXAlignment.Left
	passiveHeader.Parent           = card

	local passiveName = Instance.new("TextLabel")
	passiveName.Size             = UDim2.new(1, -16, 0, 18)
	passiveName.Position         = UDim2.new(0, 8, 0, 118)
	passiveName.BackgroundTransparency = 1
	passiveName.Font             = Enum.Font.GothamBold
	passiveName.TextColor3       = cfg.Color
	passiveName.TextTransparency = 0.1
	passiveName.TextScaled       = true
	passiveName.Text             = cfg.Passive.Name
	passiveName.TextXAlignment   = Enum.TextXAlignment.Left
	passiveName.Parent           = card

	local passiveDesc = Instance.new("TextLabel")
	passiveDesc.Size             = UDim2.new(1, -16, 0, 36)
	passiveDesc.Position         = UDim2.new(0, 8, 0, 138)
	passiveDesc.BackgroundTransparency = 1
	passiveDesc.Font             = Enum.Font.Gotham
	passiveDesc.TextColor3       = Color3.fromHex("#9999BB")
	passiveDesc.TextScaled       = true
	passiveDesc.TextWrapped      = true
	passiveDesc.Text             = cfg.Passive.Description
	passiveDesc.TextXAlignment   = Enum.TextXAlignment.Left
	passiveDesc.Parent           = card

	-- Divider 2
	local div2 = divider:Clone()
	div2.Position = UDim2.new(0, 8, 0, 182)
	div2.Parent   = card

	-- Ability section
	local abilityHeader = Instance.new("TextLabel")
	abilityHeader.Size             = UDim2.new(1, -16, 0, 16)
	abilityHeader.Position         = UDim2.new(0, 8, 0, 192)
	abilityHeader.BackgroundTransparency = 1
	abilityHeader.Font             = Enum.Font.GothamBold
	abilityHeader.TextColor3       = Color3.fromHex("#555577")
	abilityHeader.TextScaled       = true
	abilityHeader.Text             = "ABILITY  [E]"
	abilityHeader.TextXAlignment   = Enum.TextXAlignment.Left
	abilityHeader.Parent           = card

	local abilityName = Instance.new("TextLabel")
	abilityName.Size             = UDim2.new(1, -16, 0, 18)
	abilityName.Position         = UDim2.new(0, 8, 0, 210)
	abilityName.BackgroundTransparency = 1
	abilityName.Font             = Enum.Font.GothamBold
	abilityName.TextColor3       = cfg.Color
	abilityName.TextScaled       = true
	abilityName.Text             = cfg.Ability.Name
	abilityName.TextXAlignment   = Enum.TextXAlignment.Left
	abilityName.Parent           = card

	local abilityDesc = Instance.new("TextLabel")
	abilityDesc.Size             = UDim2.new(1, -16, 0, 40)
	abilityDesc.Position         = UDim2.new(0, 8, 0, 230)
	abilityDesc.BackgroundTransparency = 1
	abilityDesc.Font             = Enum.Font.Gotham
	abilityDesc.TextColor3       = Color3.fromHex("#9999BB")
	abilityDesc.TextScaled       = true
	abilityDesc.TextWrapped      = true
	abilityDesc.Text             = cfg.Ability.Description
	abilityDesc.TextXAlignment   = Enum.TextXAlignment.Left
	abilityDesc.Parent           = card

	-- Cooldown badge
	local cdBadge = Instance.new("TextLabel")
	cdBadge.Size             = UDim2.new(0, 80, 0, 20)
	cdBadge.Position         = UDim2.new(0, 8, 0, 276)
	cdBadge.BackgroundColor3 = Color3.fromHex("#1A1A3A")
	cdBadge.BorderSizePixel  = 0
	cdBadge.Font             = Enum.Font.GothamBold
	cdBadge.TextColor3       = cfg.Color
	cdBadge.TextTransparency = 0.2
	cdBadge.TextScaled       = true
	cdBadge.Text             = string.format("%.1fs CD", cfg.Ability.Cooldown)
	cdBadge.Parent           = card
	local cdCorner = Instance.new("UICorner")
	cdCorner.CornerRadius = UDim.new(0, 4)
	cdCorner.Parent = cdBadge

	-- Stats bar (speed / health)
	local statsBar = Instance.new("TextLabel")
	statsBar.Size             = UDim2.new(1, -16, 0, 18)
	statsBar.Position         = UDim2.new(0, 8, 0, 308)
	statsBar.BackgroundTransparency = 1
	statsBar.Font             = Enum.Font.Gotham
	statsBar.TextColor3       = Color3.fromHex("#666688")
	statsBar.TextScaled       = true
	statsBar.Text             = string.format("SPD ×%.2f  |  HP ×%.2f",
		cfg.Stats.SpeedMult, cfg.Stats.HealthMult)
	statsBar.TextXAlignment   = Enum.TextXAlignment.Left
	statsBar.Parent           = card

	-- Selection border (hidden by default)
	local border = Instance.new("UIStroke")
	border.Color     = cfg.Color
	border.Thickness = 0
	border.Parent    = card

	cardFrames[charId] = card

	-- Click to select
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text             = ""
	btn.Parent           = card
	btn.MouseButton1Click:Connect(function()
		if confirmed then return end
		selectedId = charId
		updateSelection()
	end)
end

-- ── Selection visual update ───────────────────────────────────────────────────

local function updateSelection()
	for id, cardFrame in cardFrames do
		local cfg    = CharacterConfig.Characters[id]
		local stroke = cardFrame:FindFirstChildOfClass("UIStroke")
		if id == selectedId then
			cardFrame.BackgroundColor3 = Color3.fromHex("#1A1A3A")
			if stroke then
				stroke.Thickness = 2.5
				stroke.Color     = cfg.Color
			end
			TweenService:Create(cardFrame,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad),
				{ Size = UDim2.new(0, 206, 0, 352) }
			):Play()
		else
			cardFrame.BackgroundColor3 = PANEL
			if stroke then stroke.Thickness = 0 end
			TweenService:Create(cardFrame,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad),
				{ Size = UDim2.new(0, 196, 0, 340) }
			):Play()
		end
	end
end

-- ── Confirm button ────────────────────────────────────────────────────────────

local confirmBtn = Instance.new("TextButton")
confirmBtn.Size             = UDim2.new(0, 220, 0, 52)
confirmBtn.Position         = UDim2.new(0.5, -110, 0, 0)
confirmBtn.AnchorPoint      = Vector2.new(0, 0)
-- Position below cards
confirmBtn.Position         = UDim2.new(0.5, -110, 0.5, 210)
confirmBtn.BackgroundColor3 = Color3.fromHex("#00FF88")
confirmBtn.BorderSizePixel  = 0
confirmBtn.Font             = Enum.Font.GothamBold
confirmBtn.TextColor3       = Color3.fromHex("#0D0D1A")
confirmBtn.TextScaled       = true
confirmBtn.Text             = "CONFIRM →"
confirmBtn.Parent           = overlay

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = confirmBtn

confirmBtn.MouseButton1Click:Connect(function()
	if confirmed then return end
	confirmed = true
	CharacterSelect:FireServer(selectedId)
	confirmBtn.Text             = "✓  " .. selectedId .. " LOCKED IN"
	confirmBtn.BackgroundColor3 = Color3.fromHex("#333355")
	confirmBtn.TextColor3       = Color3.new(1, 1, 1)

	-- Fade out after 1.5s
	task.delay(1.5, function()
		TweenService:Create(overlay,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		):Play()
		task.delay(0.5, function()
			screen.Enabled = false
		end)
	end)
end)

-- ── Build all cards ───────────────────────────────────────────────────────────

for _, charId in CharacterConfig.Order do
	buildCard(charId)
end
updateSelection()

-- ── Auto-dismiss when match goes Active ──────────────────────────────────────

MatchState.OnClientEvent:Connect(function(data: { State: string })
	if data.State == "Active" or data.State == "SuddenDeath" then
		if not confirmed then
			-- Auto-lock current selection
			confirmed = true
			CharacterSelect:FireServer(selectedId)
		end
		screen.Enabled = false
	end
	if data.State == "Waiting" then
		-- Reset for next round
		confirmed = false
		screen.Enabled = true
		updateSelection()
	end
end)
