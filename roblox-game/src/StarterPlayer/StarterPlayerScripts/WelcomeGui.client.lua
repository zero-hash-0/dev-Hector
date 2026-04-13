-- WelcomeGui.client.lua (LocalScript)
-- Shows a "How to Play" screen on first join that explains the game loop.

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
bg.Size                  = UDim2.new(1,0,1,0)
bg.BackgroundColor3      = Color3.fromRGB(0,0,0)
bg.BackgroundTransparency = 0.4
bg.BorderSizePixel       = 0
bg.Parent                = gui

-- Card
local card = Instance.new("Frame")
card.Size                  = UDim2.new(0,480,0,400)
card.Position              = UDim2.new(0.5,-240,0.5,-200)
card.BackgroundColor3      = Color3.fromRGB(18,18,28)
card.BackgroundTransparency = 0
card.BorderSizePixel       = 0
card.Parent                = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,18)
corner.Parent = card

local stroke = Instance.new("UIStroke")
stroke.Color      = Color3.fromRGB(255,215,0)
stroke.Thickness  = 2.5
stroke.Parent     = card

-- Title
local title = Instance.new("TextLabel")
title.Size                  = UDim2.new(1,0,0,60)
title.Position               = UDim2.new(0,0,0,12)
title.BackgroundTransparency = 1
title.Font                  = Enum.Font.GothamBold
title.TextSize              = 30
title.TextColor3            = Color3.fromRGB(255,215,0)
title.Text                   = "🪙 Coin & Pet Simulator"
title.Parent                 = card

-- Steps
local steps = {
    { icon="🟡", text="Click the golden orb to earn coins" },
    { icon="🥚", text="Walk to an egg pad and hatch pets" },
    { icon="🐾", text="Pets earn coins automatically every second" },
    { icon="⬆",  text="Buy upgrades to click and earn faster" },
    { icon="✨",  text="Rebirth to permanently 2× all your income" },
    { icon="🏆",  text="Compete on the leaderboard for the top spot!" },
}

for i, step in ipairs(steps) do
    local row = Instance.new("TextLabel")
    row.Size                  = UDim2.new(1,-40,0,34)
    row.Position               = UDim2.new(0,20,0,58+(i-1)*36)
    row.BackgroundTransparency = 1
    row.Font                  = Enum.Font.Gotham
    row.TextSize              = 17
    row.TextXAlignment         = Enum.TextXAlignment.Left
    row.TextColor3            = Color3.fromRGB(220,220,235)
    row.Text                   = step.icon .. "  " .. step.text
    row.Parent                 = card
end

-- Play button
local playBtn = Instance.new("TextButton")
playBtn.Size             = UDim2.new(0,200,0,50)
playBtn.Position         = UDim2.new(0.5,-100,1,-68)
playBtn.BackgroundColor3 = Color3.fromRGB(255,215,0)
playBtn.BorderSizePixel  = 0
playBtn.Font             = Enum.Font.GothamBold
playBtn.TextSize         = 22
playBtn.TextColor3       = Color3.fromRGB(0,0,0)
playBtn.Text             = "▶  Let's Play!"
playBtn.Parent           = card

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0,12)
btnCorner.Parent = playBtn

-- Animate card in
card.Position = UDim2.new(0.5,-240,1.5,0)
TweenService:Create(card,
    TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    { Position = UDim2.new(0.5,-240,0.5,-200) }
):Play()

-- Close on button press
playBtn.MouseButton1Click:Connect(function()
    TweenService:Create(card,
        TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = UDim2.new(0.5,-240,1.5,0) }
    ):Play()
    TweenService:Create(bg,
        TweenInfo.new(0.3),
        { BackgroundTransparency = 1 }
    ):Play()
    task.delay(0.35, function() gui:Destroy() end)
end)
