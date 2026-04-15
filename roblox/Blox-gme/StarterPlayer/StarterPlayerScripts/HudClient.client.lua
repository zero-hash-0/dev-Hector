--!strict

-- Builds and drives the in-game HUD:
--   • Health bar (bottom left)
--   • Match timer (top center)
--   • Core status banner (center top)
--   • Dash cooldown ring (bottom right)
--   • Core tracker arrow (points toward Core or carrier)
--   • Alert toasts

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
local Alert       = Remotes:WaitForChild("Alert")        :: RemoteEvent
local DashRequest = Remotes:WaitForChild("DashRequest") :: RemoteEvent

-- ── Colors ─────────────────────────────────────────────────────────────────────
local C = {
	Health    = Color3.fromHex("#00FF88"),
	HealthLow = Color3.fromHex("#FF3333"),
	Timer     = Color3.fromHex("#FFFFFF"),
	Core      = Color3.fromHex("#FFD700"),
	Dash      = Color3.fromHex("#00B4D8"),
	DashEmpty = Color3.fromHex("#333355"),
	Alert     = Color3.fromHex("#E94560"),
	Win       = Color3.fromHex("#FFD700"),
	BG        = Color3.fromHex("#0D0D1A"),
	Panel     = Color3.fromHex("#16213E"),
}

-- ── Root ScreenGui ─────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name            = "HUD"
screen.ResetOnSpawn    = false
screen.IgnoreGuiInset  = true
screen.Parent          = PlayerGui

local function frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = C.BG
	for k, v in props do (f :: any)[k] = v end
	f.Parent = screen
	return f
end

local function label(parent: Instance, props: { [string]: any }): TextLabel
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

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- ── Health Bar ────────────────────────────────────────────────────────────────
local healthPanel = frame({
	Size              = UDim2.new(0, 220, 0, 48),
	Position          = UDim2.new(0, 20, 1, -80),
	BackgroundColor3  = C.Panel,
	BackgroundTransparency = 0.3,
})
corner(healthPanel, 8)

local healthBg = Instance.new("Frame")
healthBg.Size             = UDim2.new(1, -16, 0, 14)
healthBg.Position         = UDim2.new(0, 8, 1, -22)
healthBg.BackgroundColor3 = Color3.fromHex("#111122")
healthBg.BorderSizePixel  = 0
healthBg.Parent           = healthPanel
corner(healthBg, 4)

local healthFill = Instance.new("Frame")
healthFill.Size            = UDim2.new(1, 0, 1, 0)
healthFill.BackgroundColor3 = C.Health
healthFill.BorderSizePixel = 0
healthFill.Parent          = healthBg
corner(healthFill, 4)

local healthLabel = label(healthPanel, {
	Size     = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 6),
	Text     = "HP  100",
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- ── Match Timer ───────────────────────────────────────────────────────────────
local timerPanel = frame({
	Size             = UDim2.new(0, 140, 0, 52),
	Position         = UDim2.new(0.5, -70, 0, 16),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.2,
})
corner(timerPanel, 10)

local timerLabel = label(timerPanel, {
	Size = UDim2.new(1, 0, 1, 0),
	Text = "3:00",
	TextColor3 = C.Timer,
})

-- ── Core Status Banner ────────────────────────────────────────────────────────
local coreBanner = frame({
	Size             = UDim2.new(0, 340, 0, 40),
	Position         = UDim2.new(0.5, -170, 0, 76),
	BackgroundColor3 = C.Panel,
	BackgroundTransparency = 0.3,
})
corner(coreBanner, 6)

local coreLabel = label(coreBanner, {
	Size       = UDim2.new(1, 0, 1, 0),
	Text       = "● Core at center",
	TextColor3 = C.Core,
})

-- ── Dash Cooldown Ring ────────────────────────────────────────────────────────
local dashPanel = frame({
	Size             = UDim2.new(0, 64, 0, 64),
	Position         = UDim2.new(1, -84, 1, -84),
	BackgroundColor3 = C.DashEmpty,
	BackgroundTransparency = 0.2,
})
corner(dashPanel, 32)

local dashReady = label(dashPanel, {
	Size       = UDim2.new(1, 0, 1, 0),
	Text       = "DASH",
	TextColor3 = C.Dash,
})

local dashCooldownActive = false

local function flashDashCooldown(duration: number)
	dashCooldownActive = true
	dashPanel.BackgroundColor3 = C.DashEmpty
	dashReady.TextColor3       = Color3.fromHex("#555577")

	local start = tick()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - start
		local t       = math.clamp(elapsed / duration, 0, 1)
		dashPanel.BackgroundColor3 = C.DashEmpty:Lerp(C.Dash, t)
		if t >= 1 then
			dashPanel.BackgroundColor3 = C.Dash
			dashReady.TextColor3       = Color3.new(1, 1, 1)
			dashCooldownActive         = false
			conn:Disconnect()
		end
	end)
end

-- ── Core Tracker Arrow ────────────────────────────────────────────────────────
local trackerFrame = frame({
	Size             = UDim2.new(0, 48, 0, 48),
	Position         = UDim2.new(0.5, -24, 0.5, -24),
	BackgroundTransparency = 1,
})

local arrowLabel = label(trackerFrame, {
	Size       = UDim2.new(1, 0, 1, 0),
	Text       = "▲",
	TextColor3 = C.Core,
	Font       = Enum.Font.GothamBold,
})

-- Rotate arrow toward Core each frame
local trackedPart: BasePart? = nil

RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local coreObj = trackedPart or (workspace:FindFirstChild("TheCore") :: BasePart?)
	if not coreObj then
		arrowLabel.Visible = false
		return
	end

	arrowLabel.Visible = true
	local cam     = workspace.CurrentCamera
	local worldDir = (coreObj.Position - root.Position)
	local screenDir = cam.CFrame:VectorToObjectSpace(worldDir)
	local angle   = math.deg(math.atan2(-screenDir.X, -screenDir.Z))
	trackerFrame.Rotation = angle

	-- Health sync
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local pct = humanoid.Health / humanoid.MaxHealth
		healthFill.Size      = UDim2.new(pct, 0, 1, 0)
		healthFill.BackgroundColor3 = pct > 0.4 and C.Health or C.HealthLow
		healthLabel.Text     = string.format("HP  %d", math.ceil(humanoid.Health))
	end
end)

-- ── Alert Toasts ─────────────────────────────────────────────────────────────
local alertQueue: { { Type: string, Message: string } } = {}
local alertActive = false

local function showAlert(data: { Type: string, Message: string })
	local toastColor = data.Type == "Win" and C.Win or C.Alert

	local toast = Instance.new("Frame")
	toast.Size             = UDim2.new(0, 380, 0, 52)
	toast.Position         = UDim2.new(0.5, -190, 0, -60)
	toast.BackgroundColor3 = toastColor
	toast.BorderSizePixel  = 0
	toast.Parent           = screen
	corner(toast, 8)

	local msg = Instance.new("TextLabel")
	msg.Size                 = UDim2.new(1, -16, 1, 0)
	msg.Position             = UDim2.new(0, 8, 0, 0)
	msg.BackgroundTransparency = 1
	msg.Font                 = Enum.Font.GothamBold
	msg.TextColor3           = Color3.new(0.05, 0.05, 0.1)
	msg.TextScaled           = true
	msg.Text                 = data.Message
	msg.Parent               = toast

	-- Slide in
	local slideIn = TweenService:Create(toast,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -190, 0, 130) }
	)
	slideIn:Play()
	slideIn.Completed:Wait()
	task.wait(2.2)

	-- Fade out
	local fadeOut = TweenService:Create(toast,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ BackgroundTransparency = 1 }
	)
	TweenService:Create(msg,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }
	):Play()
	fadeOut:Play()
	fadeOut.Completed:Wait()
	toast:Destroy()
end

local function drainAlertQueue()
	if alertActive then return end
	alertActive = true
	while #alertQueue > 0 do
		local next = table.remove(alertQueue, 1)
		showAlert(next)
	end
	alertActive = false
end

-- ── Remote handlers ───────────────────────────────────────────────────────────

MatchState.OnClientEvent:Connect(function(data: { State: string, Time: number?, Winner: string? })
	if data.State == "Active" and data.Time then
		local mins = math.floor(data.Time / 60)
		local secs = data.Time % 60
		timerLabel.Text      = string.format("%d:%02d", mins, secs)
		timerLabel.TextColor3 = data.Time <= 30 and C.HealthLow or C.Timer
	elseif data.State == "Countdown" and data.Time then
		timerLabel.Text      = string.format(":%02d", data.Time)
		timerLabel.TextColor3 = C.Core
	elseif data.State == "Waiting" then
		timerLabel.Text      = "–:––"
		timerLabel.TextColor3 = C.Timer
	end
end)

CoreState.OnClientEvent:Connect(function(data: { Event: string, Carrier: string? })
	if data.Event == "PickedUp" and data.Carrier then
		coreLabel.Text = string.format("◈  %s has the Core!", data.Carrier)
		if data.Carrier == LocalPlayer.DisplayName then
			coreLabel.TextColor3 = C.Win
		else
			coreLabel.TextColor3 = C.Alert
		end
	elseif data.Event == "Dropped" then
		coreLabel.Text       = "● Core dropped!"
		coreLabel.TextColor3 = C.Core
	elseif data.Event == "Spawned" or data.Event == "Returned" then
		coreLabel.Text       = "● Core at center"
		coreLabel.TextColor3 = C.Core
		trackedPart          = nil
	end
end)

CombatHit.OnClientEvent:Connect(function(data: { Attacker: string, Target: string, Damage: number?, KO: boolean? })
	if data.KO and data.Target == LocalPlayer.DisplayName then
		table.insert(alertQueue, { Type = "Alert", Message = "You were knocked out!" })
		task.spawn(drainAlertQueue)
	end
end)

Alert.OnClientEvent:Connect(function(data: { Type: string, Message: string })
	table.insert(alertQueue, data)
	task.spawn(drainAlertQueue)
end)

DashRequest.OnClientEvent:Connect(function(data: { Cooldown: number? })
	if data.Cooldown then
		flashDashCooldown(data.Cooldown)
	end
end)

HUD.OnClientEvent:Connect(function(data: { [string]: any })
	if data.Event == "EscapeZone" then
		-- Flash player's escape zone pad on minimap / banner
		coreLabel.Text = string.format("● Your escape: Zone %d", data.PadIndex or "?")
		task.delay(3, function()
			coreLabel.Text = "● Core at center"
		end)
	end
end)
