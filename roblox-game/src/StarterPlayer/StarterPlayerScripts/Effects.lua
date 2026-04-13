-- Effects.lua (ModuleScript)
-- Visual effects helpers: floating coin text, lucky screen flash.
-- Required by ClickHandler and MainUI.

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Effects = {}

-- ── Floating text ─────────────────────────────────────────────────────────────
-- Shows "+N" text that rises from worldPosition and fades out.

function Effects.floatingText(worldPosition: Vector3, text: string, color: Color3?)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name           = "FloatText"
    screenGui.ResetOnSpawn   = false
    screenGui.DisplayOrder   = 10
    screenGui.IgnoreGuiInset = true
    screenGui.Parent         = playerGui

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(0, 120, 0, 36)
    lbl.AnchorPoint           = Vector2.new(0.5, 0.5)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextSize              = 26
    lbl.TextColor3            = color or Color3.fromRGB(255, 215, 0)
    lbl.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
    lbl.TextStrokeTransparency = 0.4
    lbl.Text                  = text
    lbl.Parent                = screenGui

    -- Convert world → screen position
    local camera   = workspace.CurrentCamera
    local screenPos, onScreen = camera:WorldToScreenPoint(worldPosition)

    if not onScreen then
        screenGui:Destroy()
        return
    end

    lbl.Position = UDim2.new(0, screenPos.X + math.random(-30, 30), 0, screenPos.Y)

    -- Float up and fade
    TweenService:Create(lbl, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position         = UDim2.new(0, screenPos.X + math.random(-20, 20), 0, screenPos.Y - 80),
        TextTransparency = 1,
        TextStrokeTransparency = 1,
    }):Play()

    game:GetService("Debris"):AddItem(screenGui, 1)
end

-- ── Lucky screen flash ────────────────────────────────────────────────────────

local flashGui = Instance.new("ScreenGui")
flashGui.Name           = "LuckyFlash"
flashGui.ResetOnSpawn   = false
flashGui.IgnoreGuiInset = true
flashGui.DisplayOrder   = 20
flashGui.Parent         = playerGui

local flashFrame = Instance.new("Frame")
flashFrame.Size                 = UDim2.new(1, 0, 1, 0)
flashFrame.BackgroundColor3     = Color3.fromRGB(255, 215, 0)
flashFrame.BackgroundTransparency = 1
flashFrame.BorderSizePixel      = 0
flashFrame.Parent               = flashGui

local luckyLabel = Instance.new("TextLabel")
luckyLabel.Size                  = UDim2.new(0, 400, 0, 80)
luckyLabel.Position               = UDim2.new(0.5, -200, 0.35, 0)
luckyLabel.BackgroundTransparency = 1
luckyLabel.Font                  = Enum.Font.GothamBold
luckyLabel.TextSize              = 52
luckyLabel.TextColor3            = Color3.fromRGB(255, 215, 0)
luckyLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
luckyLabel.TextStrokeTransparency = 0
luckyLabel.TextTransparency      = 1
luckyLabel.Text                  = "✨ LUCKY! ✨"
luckyLabel.Parent                = flashGui

function Effects.luckyFlash(coinText: string?)
    -- Flash the screen gold
    TweenService:Create(flashFrame,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad),
        { BackgroundTransparency = 0.55 }
    ):Play()
    task.delay(0.08, function()
        TweenService:Create(flashFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Quad),
            { BackgroundTransparency = 1 }
        ):Play()
    end)

    -- Show LUCKY text
    luckyLabel.Text             = coinText and ("✨ LUCKY!  +" .. coinText) or "✨ LUCKY! ✨"
    luckyLabel.TextTransparency = 0
    TweenService:Create(luckyLabel,
        TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { TextTransparency = 1 }
    ):Play()
end

return Effects
