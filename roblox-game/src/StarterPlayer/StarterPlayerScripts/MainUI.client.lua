-- MainUI.client.lua (LocalScript)
-- Full HUD: coin counter, coins/sec display, notification toasts,
-- egg shop panel, and upgrades panel.
-- All UI is created in code – no Studio-placed instances required.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local SyncData   = Remotes:WaitForChild("SyncData")
local Notification = Remotes:WaitForChild("Notification")
local BuyItem    = Remotes:WaitForChild("BuyItem")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Cached state ──────────────────────────────────────────────────────────────

local state = { coins = 0, lifetime = 0, pets = {}, upgrades = {} }
local prevCoins = 0
local cps = 0  -- coins per second (smoothed)

-- ── Utility ───────────────────────────────────────────────────────────────────

local function fmt(n: number): string
    if n >= 1e12 then return ("%.1fT"):format(n / 1e12)
    elseif n >= 1e9  then return ("%.1fB"):format(n / 1e9)
    elseif n >= 1e6  then return ("%.1fM"):format(n / 1e6)
    elseif n >= 1e3  then return ("%.1fK"):format(n / 1e3)
    else  return tostring(math.floor(n))
    end
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or Color3.fromRGB(255,255,255)
    s.Thickness    = thickness or 1.5
    s.Transparency = transparency or 0.6
    s.Parent       = parent
end

local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.Size                  = size or UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Font                  = font or Enum.Font.GothamBold
    l.TextScaled            = true
    l.TextColor3            = color or Color3.fromRGB(255,255,255)
    l.Text                  = text
    l.Parent                = parent
    return l
end

local function frame(parent, size, pos, bg, bgTrans)
    local f = Instance.new("Frame")
    f.Size                  = size
    f.Position              = pos
    f.BackgroundColor3      = bg or Color3.fromRGB(15,15,15)
    f.BackgroundTransparency = bgTrans or 0.3
    f.BorderSizePixel       = 0
    f.Parent                = parent
    return f
end

local function textButton(parent, text, size, pos, bg)
    local b = Instance.new("TextButton")
    b.Size             = size
    b.Position         = pos
    b.BackgroundColor3 = bg or Color3.fromRGB(50, 180, 80)
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.TextScaled       = true
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.Text             = text
    b.Parent           = parent
    corner(b, 8)
    return b
end

-- ── Root ScreenGui ────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name           = "SimUI"
gui.ResetOnSpawn   = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent         = playerGui

-- ── Coin counter (top-left) ───────────────────────────────────────────────────

local coinBadge = frame(gui,
    UDim2.new(0, 220, 0, 64),
    UDim2.new(0, 16, 0, 16))
corner(coinBadge)
stroke(coinBadge, Color3.fromRGB(255,215,0), 2, 0.3)

local coinIcon = Instance.new("TextLabel")
coinIcon.Size                  = UDim2.new(0, 44, 1, 0)
coinIcon.Position               = UDim2.new(0, 4, 0, 0)
coinIcon.BackgroundTransparency = 1
coinIcon.Font                  = Enum.Font.GothamBold
coinIcon.TextScaled             = true
coinIcon.TextColor3             = Color3.fromRGB(255, 215, 0)
coinIcon.Text                   = "🪙"
coinIcon.Parent                 = coinBadge

local coinValueLabel = Instance.new("TextLabel")
coinValueLabel.Size                  = UDim2.new(1, -48, 0.55, 0)
coinValueLabel.Position               = UDim2.new(0, 48, 0, 4)
coinValueLabel.BackgroundTransparency = 1
coinValueLabel.Font                  = Enum.Font.GothamBold
coinValueLabel.TextScaled             = true
coinValueLabel.TextXAlignment         = Enum.TextXAlignment.Left
coinValueLabel.TextColor3             = Color3.fromRGB(255,255,255)
coinValueLabel.Text                   = "0"
coinValueLabel.Parent                 = coinBadge

local cpsLabel = Instance.new("TextLabel")
cpsLabel.Size                  = UDim2.new(1, -48, 0.38, 0)
cpsLabel.Position               = UDim2.new(0, 48, 0.58, 0)
cpsLabel.BackgroundTransparency = 1
cpsLabel.Font                  = Enum.Font.Gotham
cpsLabel.TextScaled             = true
cpsLabel.TextXAlignment         = Enum.TextXAlignment.Left
cpsLabel.TextColor3             = Color3.fromRGB(180, 255, 140)
cpsLabel.Text                   = "+0/s"
cpsLabel.Parent                 = coinBadge

-- ── Shop button (bottom-left) ─────────────────────────────────────────────────

local shopBtn = textButton(gui, "🥚 Eggs",
    UDim2.new(0, 120, 0, 46),
    UDim2.new(0, 16, 1, -62),
    Color3.fromRGB(220, 120, 20))

local upgradeBtn = textButton(gui, "⬆ Upgrades",
    UDim2.new(0, 140, 0, 46),
    UDim2.new(0, 148, 1, -62),
    Color3.fromRGB(30, 140, 220))

-- ── Egg shop panel ────────────────────────────────────────────────────────────

local eggPanel = frame(gui,
    UDim2.new(0, 340, 0, 280),
    UDim2.new(0, 16, 1, -350),
    Color3.fromRGB(20,20,20), 0.1)
corner(eggPanel, 14)
stroke(eggPanel, Color3.fromRGB(220,120,20), 2, 0.2)
eggPanel.Visible = false

label(eggPanel, "Egg Shop", UDim2.new(1,0,0,36))

local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Size                = UDim2.new(1,-12,1,-44)
eggScroll.Position            = UDim2.new(0,6,0,40)
eggScroll.BackgroundTransparency = 1
eggScroll.ScrollBarThickness  = 4
eggScroll.CanvasSize          = UDim2.new(0,0,0, #GameConfig.EGGS * 82)
eggScroll.Parent              = eggPanel

local eggLayout = Instance.new("UIListLayout")
eggLayout.Padding    = UDim.new(0, 8)
eggLayout.Parent     = eggScroll

local eggButtons = {}

for _, egg in ipairs(GameConfig.EGGS) do
    local row = frame(eggScroll,
        UDim2.new(1,-8,0,72),
        UDim2.new(0,0,0,0),
        Color3.fromRGB(40,40,40), 0)
    corner(row, 10)

    -- Colour swatch
    local swatch = Instance.new("Frame")
    swatch.Size             = UDim2.new(0,54,0,54)
    swatch.Position         = UDim2.new(0,8,0.5,-27)
    swatch.BackgroundColor3 = egg.color.Color
    swatch.BorderSizePixel  = 0
    swatch.Parent           = row
    corner(swatch, 27)

    local nameL = label(row, egg.name,
        UDim2.new(1,-130,0,28), Color3.fromRGB(255,255,255))
    nameL.Position      = UDim2.new(0,70,0,8)
    nameL.TextXAlignment = Enum.TextXAlignment.Left

    local costL = label(row, "🪙 " .. fmt(egg.cost),
        UDim2.new(1,-130,0,22), Color3.fromRGB(255,215,0))
    costL.Position      = UDim2.new(0,70,0,36)
    costL.TextXAlignment = Enum.TextXAlignment.Left

    local buyB = textButton(row, "Hatch",
        UDim2.new(0,70,0,40),
        UDim2.new(1,-82,0.5,-20),
        Color3.fromRGB(220,120,20))

    eggButtons[egg.id] = { button = buyB, costLabel = costL, egg = egg }

    buyB.MouseButton1Click:Connect(function()
        local result = BuyItem:InvokeServer({ type = "egg", id = egg.id })
        -- Notification arrives via RemoteEvent
    end)
end

-- ── Upgrade panel ─────────────────────────────────────────────────────────────

local upgradePanel = frame(gui,
    UDim2.new(0, 340, 0, 280),
    UDim2.new(0, 16, 1, -350),
    Color3.fromRGB(20,20,20), 0.1)
corner(upgradePanel, 14)
stroke(upgradePanel, Color3.fromRGB(30,140,220), 2, 0.2)
upgradePanel.Visible = false

label(upgradePanel, "Upgrades", UDim2.new(1,0,0,36))

local upgScroll = Instance.new("ScrollingFrame")
upgScroll.Size                = UDim2.new(1,-12,1,-44)
upgScroll.Position            = UDim2.new(0,6,0,40)
upgScroll.BackgroundTransparency = 1
upgScroll.ScrollBarThickness  = 4
upgScroll.CanvasSize          = UDim2.new(0,0,0, #GameConfig.UPGRADES * 82)
upgScroll.Parent              = upgradePanel

Instance.new("UIListLayout").Parent = upgScroll

local upgButtons = {}

for _, upg in ipairs(GameConfig.UPGRADES) do
    local row = frame(upgScroll,
        UDim2.new(1,-8,0,72),
        UDim2.new(0,0,0,0),
        Color3.fromRGB(40,40,40), 0)
    corner(row, 10)

    local nameL = label(row, upg.name,
        UDim2.new(1,-100,0,28), Color3.fromRGB(180,220,255))
    nameL.Position       = UDim2.new(0,10,0,8)
    nameL.TextXAlignment = Enum.TextXAlignment.Left

    local descL = label(row, upg.desc,
        UDim2.new(1,-100,0,20), Color3.fromRGB(160,160,160), Enum.Font.Gotham)
    descL.Position       = UDim2.new(0,10,0,32)
    descL.TextXAlignment = Enum.TextXAlignment.Left

    local costL = label(row, "🪙 " .. fmt(upg.baseCost),
        UDim2.new(1,-100,0,18), Color3.fromRGB(255,215,0), Enum.Font.Gotham)
    costL.Position       = UDim2.new(0,10,0,52)
    costL.TextXAlignment = Enum.TextXAlignment.Left

    local buyB = textButton(row, "Buy",
        UDim2.new(0,70,0,40),
        UDim2.new(1,-82,0.5,-20),
        Color3.fromRGB(30,140,220))

    upgButtons[upg.id] = { button = buyB, costLabel = costL, upg = upg }

    buyB.MouseButton1Click:Connect(function()
        BuyItem:InvokeServer({ type = "upgrade", id = upg.id })
    end)
end

-- ── Pet list panel (right side) ───────────────────────────────────────────────

local petPanel = frame(gui,
    UDim2.new(0, 190, 0, 300),
    UDim2.new(1, -206, 0, 16),
    Color3.fromRGB(15,15,15), 0.25)
corner(petPanel, 12)
stroke(petPanel, Color3.fromRGB(200,200,200), 1.5, 0.5)

label(petPanel, "Pets", UDim2.new(1,0,0,32))

local petScroll = Instance.new("ScrollingFrame")
petScroll.Size                = UDim2.new(1,-8,1,-36)
petScroll.Position            = UDim2.new(0,4,0,34)
petScroll.BackgroundTransparency = 1
petScroll.ScrollBarThickness  = 3
petScroll.Parent              = petPanel

local petListLayout = Instance.new("UIListLayout")
petListLayout.Padding = UDim.new(0, 4)
petListLayout.Parent  = petScroll

local petRowPool = {}  -- reused pet rows

local function refreshPetList()
    -- Clear old rows
    for _, r in ipairs(petRowPool) do r:Destroy() end
    petRowPool = {}

    petScroll.CanvasSize = UDim2.new(0,0,0, #state.pets * 36)

    for i, pet in ipairs(state.pets) do
        local row = frame(petScroll,
            UDim2.new(1,-4,0,32),
            UDim2.new(0,0,0,0),
            Color3.fromRGB(40,40,40), 0)
        corner(row, 6)

        -- Colour dot
        local dot = Instance.new("Frame")
        dot.Size             = UDim2.new(0,18,0,18)
        dot.Position         = UDim2.new(0,4,0.5,-9)
        dot.BackgroundColor3 = Color3.fromRGB(pet.r or 200, pet.g or 200, pet.b or 200)
        dot.BorderSizePixel  = 0
        dot.Parent           = row
        corner(dot, 9)

        local nameL = Instance.new("TextLabel")
        nameL.Size                  = UDim2.new(1,-60,1,0)
        nameL.Position               = UDim2.new(0,26,0,0)
        nameL.BackgroundTransparency = 1
        nameL.Font                  = Enum.Font.Gotham
        nameL.TextScaled             = true
        nameL.TextXAlignment         = Enum.TextXAlignment.Left
        nameL.TextColor3             = Color3.fromRGB(230,230,230)
        nameL.Text                   = pet.name
        nameL.Parent                 = row

        local multiL = Instance.new("TextLabel")
        multiL.Size                  = UDim2.new(0,50,1,0)
        multiL.Position               = UDim2.new(1,-54,0,0)
        multiL.BackgroundTransparency = 1
        multiL.Font                  = Enum.Font.GothamBold
        multiL.TextScaled             = true
        multiL.TextXAlignment         = Enum.TextXAlignment.Right
        multiL.TextColor3             = Color3.fromRGB(100,255,150)
        multiL.Text                   = "+" .. fmt(pet.multi) .. "/s"
        multiL.Parent                 = row

        -- Dim inactive pets beyond MAX_PETS
        if i > GameConfig.MAX_PETS then
            row.BackgroundTransparency = 0.7
        end

        table.insert(petRowPool, row)
    end
end

-- ── Notification toast (top-centre) ──────────────────────────────────────────

local toast = frame(gui,
    UDim2.new(0, 280, 0, 50),
    UDim2.new(0.5, -140, 0, -60),
    Color3.fromRGB(30,30,30), 0.1)
corner(toast, 12)
stroke(toast, Color3.fromRGB(255,215,0), 2, 0.2)

local toastLabel = label(toast, "")
toastLabel.TextColor3 = Color3.fromRGB(255,215,0)

local toastTween = nil

local function showToast(msg: string)
    if toastTween then toastTween:Cancel() end

    toastLabel.Text            = msg
    toast.Position             = UDim2.new(0.5, -140, 0, -60)
    toast.BackgroundTransparency = 0.1

    -- Slide in
    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, -140, 0, 16)
    }):Play()

    -- Slide out after 2.5 s
    task.delay(2.5, function()
        toastTween = TweenService:Create(toast, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            Position = UDim2.new(0.5, -140, 0, -60)
        })
        toastTween:Play()
    end)
end

-- ── Panel toggle logic ────────────────────────────────────────────────────────

shopBtn.MouseButton1Click:Connect(function()
    eggPanel.Visible     = not eggPanel.Visible
    upgradePanel.Visible = false
end)

upgradeBtn.MouseButton1Click:Connect(function()
    upgradePanel.Visible = not upgradePanel.Visible
    eggPanel.Visible     = false
end)

-- Close panels on outside click
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        -- Panels close themselves via toggle; no extra logic needed
    end
end)

-- ── Upgrade cost labels (update when state syncs) ─────────────────────────────

local function refreshUpgradeCosts()
    for id, entry in pairs(upgButtons) do
        local level = state.upgrades[id] or 0
        local cost  = math.floor(entry.upg.baseCost * (entry.upg.costMult ^ level))
        entry.costLabel.Text = "🪙 " .. fmt(cost) .. " (Lv." .. level .. ")"
    end
end

-- ── SyncData handler ──────────────────────────────────────────────────────────

SyncData.OnClientEvent:Connect(function(snapshot)
    -- Update CPS based on delta since last sync
    local delta = snapshot.coins - prevCoins
    if delta > 0 then
        cps = cps * 0.7 + delta * 0.3  -- exponential smoothing
    end
    prevCoins = snapshot.coins

    state.coins    = snapshot.coins
    state.lifetime = snapshot.lifetime
    state.pets     = snapshot.pets
    state.upgrades = snapshot.upgrades

    coinValueLabel.Text = fmt(state.coins)
    refreshPetList()
    refreshUpgradeCosts()
end)

-- ── CPS display update ────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function()
    -- Compute passive from pets so we display accurately between server ticks
    local passive = 0
    for i = 1, math.min(#state.pets, GameConfig.MAX_PETS) do
        passive = passive + (state.pets[i].multi or 0)
    end
    local magnet = 2 ^ ((state.upgrades["passive_boost"] or 0))
    cpsLabel.Text = "+" .. fmt(passive * magnet) .. "/s"
end)

-- ── Notification event ────────────────────────────────────────────────────────

Notification.OnClientEvent:Connect(showToast)
