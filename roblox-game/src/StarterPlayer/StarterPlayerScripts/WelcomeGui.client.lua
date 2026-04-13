-- WelcomeGui.client.lua (LocalScript)
-- Compact 4-step "How to Play" card on first join.

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name           = "WelcomeGui"
gui.ResetOnSpawn   = false
gui.DisplayOrder   = 100
gui.IgnoreGuiInset = true
gui.Parent         = playerGui

-- Dim background
local bg = Instance.new("Frame")
bg.Size                   = UDim2.new(1,0,1,0)
bg.BackgroundColor3       = Color3.fromRGB(0,0,0)
bg.BackgroundTransparency = 0.45
bg.BorderSizePixel        = 0
bg.Parent                 = gui

-- Card
local CARD_W, CARD_H = 440, 330
local card = Instance.new("Frame")
card.Size                   = UDim2.new(0, CARD_W, 0, CARD_H)
card.AnchorPoint            = Vector2.new(0.5, 0.5)
card.Position               = UDim2.new(0.5, 0, 0.5, 0)
card.BackgroundColor3       = Color3.fromRGB(16, 16, 26)
card.BackgroundTransparency = 0
card.BorderSizePixel        = 0
card.Parent                 = gui

local cCorner = Instance.new("UICorner")
cCorner.CornerRadius = UDim.new(0, 18)
cCorner.Parent = card

local cStroke = Instance.new("UIStroke")
cStroke.Color     = Color3.fromRGB(255, 215, 0)
cStroke.Thickness = 2.5
cStroke.Parent    = card

-- Title
local title = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, -20, 0, 52)
title.Position               = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Font                   = Enum.Font.GothamBold
title.TextSize               = 26
title.TextColor3             = Color3.fromRGB(255, 215, 0)
title.Text                   = "🪙  Coin & Pet Simulator"
title.Parent                 = card

-- Sub-title
local sub = Instance.new("TextLabel")
sub.Size                   = UDim2.new(1,-20,0,22)
sub.Position               = UDim2.new(0,10,0,56)
sub.BackgroundTransparency = 1
sub.Font                   = Enum.Font.Gotham
sub.TextSize               = 15
sub.TextColor3             = Color3.fromRGB(160,160,180)
sub.Text                   = "Here's all you need to know:"
sub.Parent                 = card

-- 4 steps
local steps = {
    { icon = "🟡", text = "Click the golden orb to earn coins" },
    { icon = "🥚", text = "Click an egg to hatch a pet — pets earn coins for you!" },
    { icon = "⬆",  text = "Buy upgrades on the blue pad to earn even faster" },
    { icon = "✨",  text = "Rebirth at 500 coins to permanently 2× all income" },
}

for i, step in ipairs(steps) do
    local row = Instance.new("Frame")
    row.Size                   = UDim2.new(1, -28, 0, 40)
    row.Position               = UDim2.new(0, 14, 0, 84 + (i-1) * 46)
    row.BackgroundColor3       = Color3.fromRGB(28, 28, 42)
    row.BackgroundTransparency = 0
    row.BorderSizePixel        = 0
    row.Parent                 = card
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,8); rc.Parent = row

    local icon = Instance.new("TextLabel")
    icon.Size                   = UDim2.new(0, 34, 1, 0)
    icon.Position               = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Font                   = Enum.Font.GothamBold
    icon.TextSize               = 20
    icon.TextColor3             = Color3.fromRGB(255, 215, 0)
    icon.Text                   = step.icon
    icon.Parent                 = row

    local lbl = Instance.new("TextLabel")
    lbl.Size                   = UDim2.new(1, -42, 1, 0)
    lbl.Position               = UDim2.new(0, 38, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                   = Enum.Font.Gotham
    lbl.TextSize               = 16
    lbl.TextXAlignment         = Enum.TextXAlignment.Left
    lbl.TextColor3             = Color3.fromRGB(220, 220, 235)
    lbl.Text                   = step.text
    lbl.TextWrapped            = true
    lbl.Parent                 = row
end

-- Play button
local playBtn = Instance.new("TextButton")
playBtn.Size             = UDim2.new(0, 200, 0, 48)
playBtn.AnchorPoint      = Vector2.new(0.5, 0)
playBtn.Position         = UDim2.new(0.5, 0, 1, -62)
playBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
playBtn.BorderSizePixel  = 0
playBtn.Font             = Enum.Font.GothamBold
playBtn.TextSize         = 20
playBtn.TextColor3       = Color3.fromRGB(0, 0, 0)
playBtn.Text             = "▶  Let's Play!"
playBtn.Parent           = card

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = playBtn

-- Animate card in from below
card.Position = UDim2.new(0.5, 0, 1.6, 0)
TweenService:Create(card,
    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(0.5, 0, 0.5, 0) }
):Play()

-- Close
playBtn.MouseButton1Click:Connect(function()
    TweenService:Create(card,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5, 0, 1.6, 0) }
    ):Play()
    TweenService:Create(bg,
        TweenInfo.new(0.3),
        { BackgroundTransparency = 1 }
    ):Play()
    task.delay(0.35, function() gui:Destroy() end)
end)
