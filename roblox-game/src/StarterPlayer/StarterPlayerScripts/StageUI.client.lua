-- StageUI.client.lua (LocalScript)
-- Creates and manages the on-screen HUD: stage counter and win notification.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local playerGui  = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStage  = RemoteEvents:WaitForChild("UpdateStage")
local GameComplete = RemoteEvents:WaitForChild("GameComplete")

-- ── ScreenGui ────────────────────────────────────────────────────────────────

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "StageGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent       = playerGui

-- ── Stage badge (top-centre) ─────────────────────────────────────────────────

local badge = Instance.new("Frame")
badge.Name                  = "StageBadge"
badge.Size                  = UDim2.new(0, 180, 0, 50)
badge.Position              = UDim2.new(0.5, -90, 0, 18)
badge.BackgroundColor3      = Color3.fromRGB(15, 15, 15)
badge.BackgroundTransparency = 0.35
badge.BorderSizePixel       = 0
badge.Parent                = screenGui

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 12)
badgeCorner.Parent = badge

local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color     = Color3.fromRGB(255, 255, 255)
badgeStroke.Thickness = 1.5
badgeStroke.Transparency = 0.6
badgeStroke.Parent = badge

local stageLabel = Instance.new("TextLabel")
stageLabel.Name                 = "StageLabel"
stageLabel.Size                 = UDim2.new(1, 0, 1, 0)
stageLabel.BackgroundTransparency = 1
stageLabel.Font                 = Enum.Font.GothamBold
stageLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
stageLabel.TextSize             = 22
stageLabel.Text                 = "Stage 1"
stageLabel.Parent               = badge

-- ── Win banner (hidden until game complete) ──────────────────────────────────

local winBanner = Instance.new("Frame")
winBanner.Name                  = "WinBanner"
winBanner.Size                  = UDim2.new(0, 400, 0, 100)
winBanner.Position              = UDim2.new(0.5, -200, 0.4, 0)
winBanner.BackgroundColor3      = Color3.fromRGB(255, 200, 0)
winBanner.BackgroundTransparency = 0
winBanner.BorderSizePixel       = 0
winBanner.Visible               = false
winBanner.Parent                = screenGui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 16)
winCorner.Parent = winBanner

local winLabel = Instance.new("TextLabel")
winLabel.Size                  = UDim2.new(1, 0, 1, 0)
winLabel.BackgroundTransparency = 1
winLabel.Font                  = Enum.Font.GothamBold
winLabel.TextColor3            = Color3.fromRGB(50, 20, 0)
winLabel.TextSize              = 32
winLabel.Text                  = "You finished the Obby!"
winLabel.Parent                = winBanner

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Flash the stage label gold then fade back to white.
local function flashStage(newStage: number)
    stageLabel.Text = "Stage " .. newStage
    stageLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

    TweenService:Create(
        stageLabel,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextColor3 = Color3.fromRGB(255, 255, 255) }
    ):Play()

    -- Bounce the badge slightly.
    TweenService:Create(
        badge,
        TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.new(0, 200, 0, 58) }
    ):Play()
    task.delay(0.15, function()
        TweenService:Create(
            badge,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0, 180, 0, 50) }
        ):Play()
    end)
end

-- ── Remote event listeners ────────────────────────────────────────────────────

UpdateStage.OnClientEvent:Connect(function(stage: number)
    flashStage(stage)
end)

GameComplete.OnClientEvent:Connect(function()
    winBanner.Visible = true
    -- Auto-hide the banner after 5 seconds (server will reset the player too).
    task.delay(5, function()
        TweenService:Create(
            winBanner,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        ):Play()
        TweenService:Create(
            winLabel,
            TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { TextTransparency = 1 }
        ):Play()
        task.delay(1, function() winBanner.Visible = false end)
    end)
end)
