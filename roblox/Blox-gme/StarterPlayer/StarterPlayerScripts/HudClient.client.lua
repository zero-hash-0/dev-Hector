--!strict

-- Main HUD: health, timer, Core status, tracker arrow, dash ring,
-- kill feed, streak banners, sudden death flash, XP popups, level-up banner.

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local HUD         = Remotes:WaitForChild("HUD")         :: RemoteEvent
local MatchState  = Remotes:WaitForChild("MatchState")  :: RemoteEvent
local CoreState   = Remotes:WaitForChild("CoreState")   :: RemoteEvent
local CombatHit   = Remotes:WaitForChild("CombatHit")   :: RemoteEvent
local StreakEvent  = Remotes:WaitForChild("StreakEvent") :: RemoteEvent
local Alert       = Remotes:WaitForChild("Alert")        :: RemoteEvent
local DashRequest = Remotes:WaitForChild("DashRequest") :: RemoteEvent
local XPGained    = Remotes:WaitForChild("XPGained")    :: RemoteEvent

-- ── Color palette ─────────────────────────────────────────────────────────────
local C = {
	Health    = Color3.fromHex("#00FF88"),
	HealthLow = Color3.fromHex("#FF3333"),
	Timer     = Color3.fromHex("#FFFFFF"),
	TimerLow  = Color3.fromHex("#FF3333"),
	Core      = Color3.fromHex("#FFD700"),
	CoreEnemy = Color3.fromHex("#FF4444"),
	Dash      = Color3.fromHex("#00B4D8"),
	DashEmpty = Color3.fromHex("#1A1A33"),
	BG        = Color3.fromHex("#0D0D1A"),
	Panel     = Color3.fromHex("#14143A"),
	Sudden    = Color3.fromHex("#FF2222"),
	XPColor   = Color3.fromHex("#FFD700"),
	Level     = Color3.fromHex("#00FFFF"),
}

-- ── Root ScreenGui ─────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name            = "HUD"
screen.ResetOnSpawn    = false
screen.IgnoreGuiInset  = true
screen.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screen.Parent          = PlayerGui

local function panel(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel  = 0
	f.BackgroundColor3 = C.Panel
	for k, v in props do (f :: any)[k] = v end
	f.Parent = screen
	return f
end

local function lbl(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel        = 0
	l.Font                   = Enum.Font.GothamBold
	l.TextColor3             = Color3.new(1, 1, 1)
	l.TextScaled             = true
	for k, v in props do (l :: any)[k] = v end
	l.Parent = parent
	return l
end

local function rnd(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

-- ── Health bar ────────────────────────────────────────────────────────────────
local hpPanel = panel({
	Size = UDim2.new(0, 230, 0, 52),
	Position = UDim2.new(0, 20, 1, -84),
	BackgroundTransparency = 0.25,
})
rnd(hpPanel, 8)

local hpBg = Instance.new("Frame")
hpBg.Size             = UDim2.new(1, -16, 0, 12)
hpBg.Position         = UDim2.new(0, 8, 1, -20)
hpBg.BackgroundColor3 = Color3.fromHex("#111122")
hpBg.BorderSizePixel  = 0
hpBg.Parent           = hpPanel
rnd(hpBg, 4)

local hpFill = Instance.new("Frame")
hpFill.Size             = UDim2.new(1, 0, 1, 0)
hpFill.BackgroundColor3 = C.Health
hpFill.BorderSizePixel  = 0
hpFill.Parent           = hpBg
rnd(hpFill, 4)

local hpLabel = lbl(hpPanel, {
	Size = UDim2.new(1, -16, 0, 24),
	Position = UDim2.new(0, 8, 0, 6),
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "HP  100",
})

-- ── XP bar ────────────────────────────────────────────────────────────────────
local xpPanel = panel({
	Size = UDim2.new(0, 230, 0, 18),
	Position = UDim2.new(0, 20, 1, -30),
	BackgroundTransparency = 0.4,
})
rnd(xpPanel, 4)

local xpFill = Instance.new("Frame")
xpFill.Size             = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = C.XPColor
xpFill.BorderSizePixel  = 0
xpFill.Parent           = xpPanel
rnd(xpFill, 4)

local xpLabel = lbl(xpPanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "Lv.1",
	TextColor3 = C.XPColor,
})

-- ── Match timer ────────────────────────────────────────────────────────────────
local timerPanel = panel({
	Size = UDim2.new(0, 148, 0, 54),
	Position = UDim2.new(0.5, -74, 0, 14),
	BackgroundTransparency = 0.18,
})
rnd(timerPanel, 10)

local timerLabel = lbl(timerPanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "3:00",
})

-- ── Core status banner ────────────────────────────────────────────────────────
local corePanel = panel({
	Size = UDim2.new(0, 360, 0, 36),
	Position = UDim2.new(0.5, -180, 0, 76),
	BackgroundTransparency = 0.28,
})
rnd(corePanel, 6)

local coreLbl = lbl(corePanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "● Core at center",
	TextColor3 = C.Core,
})

-- ── Dash cooldown ring ────────────────────────────────────────────────────────
local dashPanel = panel({
	Size = UDim2.new(0, 64, 0, 64),
	Position = UDim2.new(1, -88, 1, -88),
	BackgroundColor3 = C.DashEmpty,
	BackgroundTransparency = 0.2,
})
rnd(dashPanel, 32)

local dashLbl = lbl(dashPanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "DASH",
	TextColor3 = C.Dash,
})

local dashCdActive = false

local function flashDash(duration: number)
	dashCdActive = true
	dashPanel.BackgroundColor3 = C.DashEmpty
	dashLbl.TextColor3         = Color3.fromHex("#445566")

	local start = tick()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((tick() - start) / duration, 0, 1)
		dashPanel.BackgroundColor3 = C.DashEmpty:Lerp(C.Dash, t)
		if t >= 1 then
			dashPanel.BackgroundColor3 = C.Dash
			dashLbl.TextColor3         = Color3.new(1, 1, 1)
			dashCdActive               = false
			conn:Disconnect()
		end
	end)
end

-- ── Core tracker arrow ────────────────────────────────────────────────────────
local trackerOuter = Instance.new("Frame")
trackerOuter.Size             = UDim2.new(0, 52, 0, 52)
trackerOuter.Position         = UDim2.new(0.5, -26, 0.5, -26)
trackerOuter.BackgroundTransparency = 1
trackerOuter.Parent           = screen

local arrowLbl = lbl(trackerOuter, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "▲",
	TextColor3 = C.Core,
	Font = Enum.Font.GothamBold,
})
arrowLbl.Visible = false

-- ── Sudden death border flash ─────────────────────────────────────────────────
local suddenGui = Instance.new("ScreenGui")
suddenGui.Name           = "SuddenDeathOverlay"
suddenGui.ResetOnSpawn   = false
suddenGui.IgnoreGuiInset = true
suddenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
suddenGui.Parent         = PlayerGui

local suddenFrame = Instance.new("Frame")
suddenFrame.Size             = UDim2.new(1, 0, 1, 0)
suddenFrame.BackgroundTransparency = 1
suddenFrame.BorderSizePixel  = 0
suddenFrame.Parent           = suddenGui

local suddenStroke = Instance.new("UIStroke")
suddenStroke.Color           = C.Sudden
suddenStroke.Thickness       = 0
suddenStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
suddenStroke.Parent          = suddenFrame

local suddenLabel = lbl(suddenFrame, {
	Size       = UDim2.new(0, 500, 0, 52),
	Position   = UDim2.new(0.5, -250, 0, 126),
	Text       = "⚡ SUDDEN DEATH ⚡",
	TextColor3 = C.Sudden,
	Font       = Enum.Font.GothamBold,
	TextTransparency = 1,
})

local suddenActive = false

local function activateSuddenDeath()
	if suddenActive then return end
	suddenActive = true

	-- Pulse border
	task.spawn(function()
		while suddenActive do
			TweenService:Create(suddenStroke,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Thickness = 14 }
			):Play()
			task.wait(0.5)
			TweenService:Create(suddenStroke,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Thickness = 4 }
			):Play()
			task.wait(0.5)
		end
		suddenStroke.Thickness = 0
	end)

	TweenService:Create(suddenLabel,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	):Play()
end

local function deactivateSuddenDeath()
	suddenActive = false
	TweenService:Create(suddenLabel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad),
		{ TextTransparency = 1 }
	):Play()
end

-- ── Kill feed (right side) ────────────────────────────────────────────────────
local killFeedContainer = Instance.new("Frame")
killFeedContainer.Size             = UDim2.new(0, 300, 0, 200)
killFeedContainer.Position         = UDim2.new(1, -316, 0, 120)
killFeedContainer.BackgroundTransparency = 1
killFeedContainer.Parent           = screen

local killFeedLayout = Instance.new("UIListLayout")
killFeedLayout.FillDirection        = Enum.FillDirection.Vertical
killFeedLayout.VerticalAlignment    = Enum.VerticalAlignment.Bottom
killFeedLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Right
killFeedLayout.Padding              = UDim.new(0, 4)
killFeedLayout.SortOrder            = Enum.SortOrder.LayoutOrder
killFeedLayout.Parent               = killFeedContainer

local killFeedItems: { Frame } = {}

local function addKillFeedEntry(attacker: string, target: string, ko: boolean)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(0, 280, 0, 28)
	row.BackgroundColor3 = Color3.fromHex("#111128")
	row.BackgroundTransparency = 0.3
	row.BorderSizePixel  = 0
	row.LayoutOrder      = #killFeedItems + 1
	row.Parent           = killFeedContainer
	rnd(row, 4)

	local rowLbl = Instance.new("TextLabel")
	rowLbl.Size             = UDim2.new(1, -8, 1, 0)
	rowLbl.Position         = UDim2.new(0, 4, 0, 0)
	rowLbl.BackgroundTransparency = 1
	rowLbl.Font             = Enum.Font.GothamBold
	rowLbl.TextColor3       = Color3.new(1, 1, 1)
	rowLbl.TextScaled       = true
	rowLbl.TextXAlignment   = Enum.TextXAlignment.Right
	rowLbl.RichText         = true
	local icon              = ko and "💀" or "⚔"
	local attackerColor     = attacker == LocalPlayer.DisplayName and "#00FF88" or "#FFFFFF"
	local targetColor       = target   == LocalPlayer.DisplayName and "#FF4444" or "#AAAACC"
	rowLbl.Text             = string.format(
		'<font color="%s">%s</font>  %s  <font color="%s">%s</font>',
		attackerColor, attacker, icon, targetColor, target
	)
	rowLbl.Parent           = row

	table.insert(killFeedItems, row)
	if #killFeedItems > 5 then
		local oldest = table.remove(killFeedItems, 1)
		oldest:Destroy()
	end

	-- Fade after 4s
	task.delay(4, function()
		if row.Parent then
			TweenService:Create(row,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad),
				{ BackgroundTransparency = 1 }
			):Play()
			TweenService:Create(rowLbl,
				TweenInfo.new(0.4, Enum.EasingStyle.Quad),
				{ TextTransparency = 1 }
			):Play()
			task.delay(0.4, function()
				if row.Parent then row:Destroy() end
			end)
		end
	end)
end

-- ── Streak banner (center) ────────────────────────────────────────────────────
local streakBanner = Instance.new("Frame")
streakBanner.Size             = UDim2.new(0, 460, 0, 64)
streakBanner.Position         = UDim2.new(0.5, -230, 0, 200)
streakBanner.BackgroundColor3 = Color3.fromHex("#111022")
streakBanner.BackgroundTransparency = 0.15
streakBanner.BorderSizePixel  = 0
streakBanner.Visible          = false
streakBanner.Parent           = screen
rnd(streakBanner, 6)

local streakLbl = lbl(streakBanner, {
	Size = UDim2.new(1, 0, 0.65, 0),
	Text = "RAMPAGE",
	TextColor3 = Color3.fromHex("#FF3333"),
})

local streakSubLbl = lbl(streakBanner, {
	Size = UDim2.new(1, 0, 0.35, 0),
	Position = UDim2.new(0, 0, 0.65, 0),
	Text = "",
	TextColor3 = Color3.fromHex("#AAAACC"),
	Font = Enum.Font.Gotham,
})

local function showStreak(playerName: string, label: string, streak: number)
	local isLocal = playerName == LocalPlayer.DisplayName
	streakLbl.Text      = label
	streakSubLbl.Text   = isLocal
		and string.format("YOU — %d KOs in a row!", streak)
		or string.format("%s — %d KOs in a row!", playerName, streak)

	local color = streak >= 5 and Color3.fromHex("#FF3333")
		or streak >= 4 and Color3.fromHex("#FF6B35")
		or streak >= 3 and Color3.fromHex("#FFD700")
		or Color3.fromHex("#00FFCC")

	streakLbl.TextColor3   = color
	streakBanner.Visible   = true
	streakBanner.BackgroundTransparency = 0.1

	TweenService:Create(streakBanner,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{ Size = UDim2.new(0, 490, 0, 68) }
	):Play()

	task.delay(2.4, function()
		TweenService:Create(streakBanner,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad),
			{ BackgroundTransparency = 1 }
		):Play()
		task.delay(0.35, function()
			streakBanner.Visible = false
			streakBanner.Size    = UDim2.new(0, 460, 0, 64)
		end)
	end)
end

-- ── Alert toasts ──────────────────────────────────────────────────────────────
local alertQueue: { { Type: string, Message: string } } = {}
local alertBusy = false

local function runToast(data: { Type: string, Message: string })
	local isWin    = data.Type == "Win"
	local isSudden = data.Type == "SuddenDeath"

	local toast = Instance.new("Frame")
	toast.Size             = UDim2.new(0, 400, 0, 52)
	toast.Position         = UDim2.new(0.5, -200, 0, -60)
	toast.BackgroundColor3 = isWin and Color3.fromHex("#FFD700")
		or isSudden and C.Sudden
		or Color3.fromHex("#1A1A3A")
	toast.BorderSizePixel  = 0
	toast.Parent           = screen
	rnd(toast, 8)

	local msg = Instance.new("TextLabel")
	msg.Size                 = UDim2.new(1, -16, 1, 0)
	msg.Position             = UDim2.new(0, 8, 0, 0)
	msg.BackgroundTransparency = 1
	msg.Font                 = Enum.Font.GothamBold
	msg.TextColor3           = (isWin or isSudden) and Color3.fromHex("#0A0A18") or Color3.new(1, 1, 1)
	msg.TextScaled           = true
	msg.Text                 = data.Message
	msg.Parent               = toast

	TweenService:Create(toast,
		TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -200, 0, 140) }
	):Play():Wait()

	task.wait(2)

	TweenService:Create(toast,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ BackgroundTransparency = 1 }
	):Play()
	TweenService:Create(msg,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	):Play():Wait()
	toast:Destroy()
end

local function drainToasts()
	if alertBusy then return end
	alertBusy = true
	while #alertQueue > 0 do
		runToast(table.remove(alertQueue, 1))
	end
	alertBusy = false
end

-- ── XP popup ─────────────────────────────────────────────────────────────────
local xpLevel   = 1
local xpCurrent = 0

local function showXPPopup(delta: number, reason: string, leveled: boolean)
	if delta <= 0 then return end

	local popup = Instance.new("TextLabel")
	popup.Size             = UDim2.new(0, 200, 0, 28)
	popup.Position         = UDim2.new(0, 14, 1, -106)
	popup.BackgroundTransparency = 1
	popup.Font             = Enum.Font.GothamBold
	popup.TextColor3       = C.XPColor
	popup.TextScaled       = true
	popup.TextXAlignment   = Enum.TextXAlignment.Left
	popup.Text             = string.format("+%d XP  (%s)", delta, reason)
	popup.Parent           = screen

	TweenService:Create(popup,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 14, 1, -140), TextTransparency = 1 }
	):Play()
	game:GetService("Debris"):AddItem(popup, 1.3)

	if leveled then
		task.delay(0.2, function()
			local levelBanner = Instance.new("Frame")
			levelBanner.Size             = UDim2.new(0, 360, 0, 56)
			levelBanner.Position         = UDim2.new(0.5, -180, 1, -150)
			levelBanner.BackgroundColor3 = C.Level
			levelBanner.BorderSizePixel  = 0
			levelBanner.Parent           = screen
			rnd(levelBanner, 8)

			local lvlLbl = lbl(levelBanner, {
				Size = UDim2.new(1, 0, 1, 0),
				Text = string.format("LEVEL UP!  →  Lv.%d", xpLevel),
				TextColor3 = Color3.fromHex("#0D0D1A"),
			})

			TweenService:Create(levelBanner,
				TweenInfo.new(2.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = UDim2.new(0.5, -180, 1, -160), BackgroundTransparency = 0.6 }
			):Play()
			task.delay(2.5, function()
				TweenService:Create(levelBanner,
					TweenInfo.new(0.4),
					{ BackgroundTransparency = 1 }
				):Play()
				TweenService:Create(lvlLbl,
					TweenInfo.new(0.4),
					{ TextTransparency = 1 }
				):Play()
				task.delay(0.4, function() levelBanner:Destroy() end)
			end)
		end)
	end
end

-- ── Damage flash ──────────────────────────────────────────────────────────────
local flashGui = Instance.new("ScreenGui")
flashGui.Name           = "DamageFlash"
flashGui.IgnoreGuiInset = true
flashGui.ResetOnSpawn   = false
flashGui.Parent         = PlayerGui

local flashFr = Instance.new("Frame")
flashFr.Size                    = UDim2.new(1, 0, 1, 0)
flashFr.BackgroundColor3        = Color3.fromHex("#FF0000")
flashFr.BackgroundTransparency  = 1
flashFr.BorderSizePixel         = 0
flashFr.Parent                  = flashGui

local function triggerFlash()
	flashFr.BackgroundTransparency = 0.55
	TweenService:Create(flashFr,
		TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	):Play()
end

-- ── RenderStepped: health sync + tracker arrow ────────────────────────────────
RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end

	-- Health
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		local pct = hum.Health / hum.MaxHealth
		TweenService:Create(hpFill,
			TweenInfo.new(0.1),
			{ Size = UDim2.new(pct, 0, 1, 0) }
		):Play()
		hpFill.BackgroundColor3 = pct > 0.4 and C.Health or C.HealthLow
		hpLabel.Text = string.format("HP  %d / %d", math.ceil(hum.Health), hum.MaxHealth)
	end

	-- Core tracker arrow
	local root    = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local coreObj = workspace:FindFirstChild("TheCore") :: BasePart?
	if root and coreObj then
		arrowLbl.Visible = true
		local cam    = workspace.CurrentCamera
		local wDir   = coreObj.Position - root.Position
		local sDir   = cam.CFrame:VectorToObjectSpace(wDir)
		local angle  = math.deg(math.atan2(-sDir.X, -sDir.Z))
		trackerOuter.Rotation = angle

		local dist = wDir.Magnitude
		arrowLbl.TextColor3 = dist < 20 and C.HealthLow or C.Core
	else
		arrowLbl.Visible = false
	end
end)

-- ── Remote handlers ───────────────────────────────────────────────────────────

MatchState.OnClientEvent:Connect(function(data: {
	State: string,
	Time: number?,
	Message: string?,
	CarrierBoost: boolean?,
})
	if data.State == "Active" or data.State == "SuddenDeath" then
		local t = data.Time or 0
		local mins = math.floor(t / 60)
		local secs = t % 60
		timerLabel.Text       = string.format("%d:%02d", mins, secs)
		timerLabel.TextColor3 = t <= 30 and C.TimerLow or C.Timer
	elseif data.State == "Countdown" and data.Time then
		timerLabel.Text       = string.format("  :%02d", data.Time)
		timerLabel.TextColor3 = C.Core
	elseif data.State == "Waiting" then
		timerLabel.Text       = "–:––"
		timerLabel.TextColor3 = C.Timer
		deactivateSuddenDeath()
	elseif data.State == "Ended" then
		deactivateSuddenDeath()
	end

	if data.State == "SuddenDeath" then
		activateSuddenDeath()
	end

	if data.Message then
		table.insert(alertQueue, { Type = data.State == "SuddenDeath" and "SuddenDeath" or "System", Message = data.Message })
		task.spawn(drainToasts)
	end
end)

CoreState.OnClientEvent:Connect(function(data: { Event: string, Carrier: string?, Player: string? })
	if data.Event == "PickedUp" and data.Carrier then
		local isLocal = data.Carrier == LocalPlayer.DisplayName
		coreLbl.Text      = isLocal
			and string.format("◈  YOU have the Core — RUN!")
			or string.format("◈  %s has the Core!", data.Carrier)
		coreLbl.TextColor3 = isLocal and C.Core or C.CoreEnemy
	elseif data.Event == "Dropped" then
		coreLbl.Text       = "● Core dropped!"
		coreLbl.TextColor3 = C.Core
	elseif data.Event == "Spawned" or data.Event == "Returned" then
		coreLbl.Text       = "● Core at center"
		coreLbl.TextColor3 = C.Core
	elseif data.Event == "Escaped" then
		coreLbl.Text       = string.format("✓  %s escaped!", data.Player or "?")
		coreLbl.TextColor3 = C.Core
	end
end)

CombatHit.OnClientEvent:Connect(function(data: {
	Attacker: string,
	Target: string,
	Damage: number?,
	KO: boolean?,
	Streak: number?,
})
	local isTarget   = data.Target   == LocalPlayer.DisplayName

	if isTarget then triggerFlash() end

	if data.KO then
		addKillFeedEntry(data.Attacker, data.Target, true)
	end
end)

StreakEvent.OnClientEvent:Connect(function(data: { Player: string, Streak: number, Label: string })
	showStreak(data.Player, data.Label, data.Streak)
end)

Alert.OnClientEvent:Connect(function(data: { Type: string, Message: string })
	table.insert(alertQueue, data)
	task.spawn(drainToasts)
end)

DashRequest.OnClientEvent:Connect(function(data: { Cooldown: number? })
	if data.Cooldown then flashDash(data.Cooldown) end
end)

HUD.OnClientEvent:Connect(function(data: { [string]: any })
	if data.Event == "EscapeZone" then
		coreLbl.Text = string.format("● Your escape: Zone %d", data.PadIndex or "?")
		task.delay(3, function()
			coreLbl.Text = "● Core at center"
		end)
	end
end)

XPGained.OnClientEvent:Connect(function(data: {
	xp: number,
	level: number,
	xpToNext: number,
	delta: number,
	reason: string?,
	leveled: boolean?,
	kills: number?,
	wins: number?,
})
	xpLevel   = data.level
	xpCurrent = data.xp

	-- XP bar fill
	local pct = data.xpToNext > 0 and (1 - data.xpToNext / (data.xpToNext + data.xp)) or 1
	TweenService:Create(xpFill,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0) }
	):Play()

	xpLabel.Text = string.format("Lv.%d", data.level)

	if data.delta and data.delta > 0 then
		showXPPopup(data.delta, data.reason or "match", data.leveled == true)
	end
end)
