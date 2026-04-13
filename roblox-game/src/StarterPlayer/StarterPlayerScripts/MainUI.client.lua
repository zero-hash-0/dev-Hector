-- MainUI.client.lua (LocalScript)
-- Full HUD: coin counter, coins/sec, rebirth button, egg shop, upgrades, pet list, toasts.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local SyncData   = Remotes:WaitForChild("SyncData")
local Notification = Remotes:WaitForChild("Notification")
local BuyItem    = Remotes:WaitForChild("BuyItem")
local RebirthRF  = Remotes:WaitForChild("Rebirth")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── State ─────────────────────────────────────────────────────────────────────
local state = { coins=0, lifetime=0, rebirths=0, pets={}, upgrades={} }

-- ── Utilities ─────────────────────────────────────────────────────────────────

local function fmt(n: number): string
    if     n >= 1e12 then return ("%.1fT"):format(n/1e12)
    elseif n >= 1e9  then return ("%.1fB"):format(n/1e9)
    elseif n >= 1e6  then return ("%.1fM"):format(n/1e6)
    elseif n >= 1e3  then return ("%.1fK"):format(n/1e3)
    else   return tostring(math.floor(n)) end
end

local function corner(p, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=p end
local function stroke(p,col,th,tr) local s=Instance.new("UIStroke"); s.Color=col or Color3.new(1,1,1); s.Thickness=th or 1.5; s.Transparency=tr or 0.6; s.Parent=p end

local function mkLabel(parent, text, size, pos, color, font, xalign)
    local l = Instance.new("TextLabel")
    l.Size=size; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.Font=font or Enum.Font.GothamBold
    l.TextScaled=true; l.TextColor3=color or Color3.fromRGB(255,255,255)
    l.Text=text
    if xalign then l.TextXAlignment=xalign end
    l.Parent=parent; return l
end

local function mkFrame(parent, size, pos, bg, bgT)
    local f=Instance.new("Frame"); f.Size=size; f.Position=pos
    f.BackgroundColor3=bg or Color3.fromRGB(15,15,15)
    f.BackgroundTransparency=bgT or 0.3; f.BorderSizePixel=0; f.Parent=parent; return f
end

local function mkButton(parent, text, size, pos, bg)
    local b=Instance.new("TextButton"); b.Size=size; b.Position=pos
    b.BackgroundColor3=bg or Color3.fromRGB(50,180,80); b.BorderSizePixel=0
    b.Font=Enum.Font.GothamBold; b.TextScaled=true
    b.TextColor3=Color3.fromRGB(255,255,255); b.Text=text; b.Parent=parent
    corner(b,8); return b
end

-- ── Root ScreenGui ────────────────────────────────────────────────────────────

local gui = Instance.new("ScreenGui")
gui.Name="SimUI"; gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=playerGui

-- ── Coin counter (top-left) ───────────────────────────────────────────────────

local coinBadge = mkFrame(gui, UDim2.new(0,230,0,68), UDim2.new(0,16,0,16))
corner(coinBadge); stroke(coinBadge, Color3.fromRGB(255,215,0), 2, 0.3)

local coinIcon = mkLabel(coinBadge,"🪙",UDim2.new(0,42,1,0),UDim2.new(0,4,0,0),Color3.fromRGB(255,215,0))
local coinVal  = mkLabel(coinBadge,"0",UDim2.new(1,-50,0.52,0),UDim2.new(0,50,0,4),nil,nil,Enum.TextXAlignment.Left)
local cpsLbl   = mkLabel(coinBadge,"+0/s",UDim2.new(1,-50,0.36,0),UDim2.new(0,50,0.58,0),Color3.fromRGB(160,255,130),Enum.Font.Gotham,Enum.TextXAlignment.Left)

-- Rebirth count badge next to coin counter
local rebirthBadge = mkFrame(gui, UDim2.new(0,110,0,34), UDim2.new(0,254,0,16),Color3.fromRGB(100,0,180), 0.2)
corner(rebirthBadge,8); stroke(rebirthBadge, Color3.fromRGB(200,100,255), 1.5, 0.3)
local rebirthCountLbl = mkLabel(rebirthBadge,"✨ 0 Rebirths",UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Color3.fromRGB(220,150,255))

-- ── Rebirth button (top-right) ────────────────────────────────────────────────

local rebirthBtn = mkButton(gui, "✨ REBIRTH\n🪙 1000",
    UDim2.new(0,160,0,54), UDim2.new(1,-176,0,16),
    Color3.fromRGB(130,0,220))
stroke(rebirthBtn, Color3.fromRGB(200,100,255), 2, 0.2)

rebirthBtn.MouseButton1Click:Connect(function()
    local result = RebirthRF:InvokeServer()
    if not result.success then
        -- Show the error as a toast via Notification
        local notif = Remotes:WaitForChild("Notification")
        -- Notification fires server→client, so show locally
        local badge = mkFrame(gui, UDim2.new(0,280,0,46), UDim2.new(0.5,-140,0,-60),Color3.fromRGB(180,0,0),0.2)
        corner(badge); mkLabel(badge,result.message,UDim2.new(1,0,1,0))
        TweenService:Create(badge,TweenInfo.new(0.3,Enum.EasingStyle.Back),{Position=UDim2.new(0.5,-140,0,70)}):Play()
        task.delay(2, function()
            TweenService:Create(badge,TweenInfo.new(0.3),{Position=UDim2.new(0.5,-140,0,-60)}):Play()
            task.delay(0.3, function() badge:Destroy() end)
        end)
    end
end)

-- ── Panel toggle buttons (bottom-left) ───────────────────────────────────────

local shopBtn    = mkButton(gui,"🥚 Eggs",    UDim2.new(0,110,0,44),UDim2.new(0,16,1,-60),Color3.fromRGB(220,120,20))
local upgradeBtn = mkButton(gui,"⬆ Upgrades",UDim2.new(0,130,0,44),UDim2.new(0,138,1,-60),Color3.fromRGB(30,140,220))

-- ── Egg panel ─────────────────────────────────────────────────────────────────

local eggPanel = mkFrame(gui, UDim2.new(0,340,0,290), UDim2.new(0,16,1,-360),Color3.fromRGB(20,20,20),0.1)
corner(eggPanel,14); stroke(eggPanel,Color3.fromRGB(220,120,20),2,0.2); eggPanel.Visible=false
mkLabel(eggPanel,"🥚 Egg Shop",UDim2.new(1,0,0,36))

local eggScroll = Instance.new("ScrollingFrame")
eggScroll.Size=UDim2.new(1,-12,1,-42); eggScroll.Position=UDim2.new(0,6,0,40)
eggScroll.BackgroundTransparency=1; eggScroll.ScrollBarThickness=4
eggScroll.CanvasSize=UDim2.new(0,0,0,#GameConfig.EGGS*84); eggScroll.Parent=eggPanel
Instance.new("UIListLayout").Parent=eggScroll

local upgButtons = {}

for _, egg in ipairs(GameConfig.EGGS) do
    local row = mkFrame(eggScroll,UDim2.new(1,-8,0,76),UDim2.new(0,0,0,0),Color3.fromRGB(40,40,40),0)
    corner(row,10)
    local sw=Instance.new("Frame"); sw.Size=UDim2.new(0,52,0,52); sw.Position=UDim2.new(0,8,0.5,-26)
    sw.BackgroundColor3=egg.color.Color; sw.BorderSizePixel=0; sw.Parent=row; corner(sw,26)
    mkLabel(row,egg.name,UDim2.new(1,-130,0,28),UDim2.new(0,68,0,8))
    mkLabel(row,"🪙 "..fmt(egg.cost),UDim2.new(1,-130,0,22),UDim2.new(0,68,0,36),Color3.fromRGB(255,215,0),Enum.Font.Gotham)
    local b=mkButton(row,"Hatch",UDim2.new(0,72,0,42),UDim2.new(1,-84,0.5,-21),Color3.fromRGB(220,120,20))
    b.MouseButton1Click:Connect(function() BuyItem:InvokeServer({type="egg",id=egg.id}) end)
end

-- ── Upgrade panel ─────────────────────────────────────────────────────────────

local upgradePanel = mkFrame(gui,UDim2.new(0,340,0,290),UDim2.new(0,16,1,-360),Color3.fromRGB(20,20,20),0.1)
corner(upgradePanel,14); stroke(upgradePanel,Color3.fromRGB(30,140,220),2,0.2); upgradePanel.Visible=false
mkLabel(upgradePanel,"⬆ Upgrades",UDim2.new(1,0,0,36))

local upgScroll = Instance.new("ScrollingFrame")
upgScroll.Size=UDim2.new(1,-12,1,-42); upgScroll.Position=UDim2.new(0,6,0,40)
upgScroll.BackgroundTransparency=1; upgScroll.ScrollBarThickness=4
upgScroll.CanvasSize=UDim2.new(0,0,0,#GameConfig.UPGRADES*84); upgScroll.Parent=upgradePanel
Instance.new("UIListLayout").Parent=upgScroll

local upgCostLabels = {}

for _, upg in ipairs(GameConfig.UPGRADES) do
    local row=mkFrame(upgScroll,UDim2.new(1,-8,0,76),UDim2.new(0,0,0,0),Color3.fromRGB(40,40,40),0)
    corner(row,10)
    mkLabel(row,upg.name,UDim2.new(1,-100,0,26),UDim2.new(0,10,0,8),Color3.fromRGB(180,220,255))
    mkLabel(row,upg.desc,UDim2.new(1,-100,0,20),UDim2.new(0,10,0,32),Color3.fromRGB(160,160,160),Enum.Font.Gotham)
    local cl=mkLabel(row,"🪙 "..fmt(upg.baseCost),UDim2.new(1,-100,0,18),UDim2.new(0,10,0,52),Color3.fromRGB(255,215,0),Enum.Font.Gotham)
    upgCostLabels[upg.id]={lbl=cl, upg=upg}
    local b=mkButton(row,"Buy",UDim2.new(0,70,0,42),UDim2.new(1,-82,0.5,-21),Color3.fromRGB(30,140,220))
    b.MouseButton1Click:Connect(function() BuyItem:InvokeServer({type="upgrade",id=upg.id}) end)
end

-- ── Pet list (right side) ─────────────────────────────────────────────────────

local petPanel=mkFrame(gui,UDim2.new(0,190,0,300),UDim2.new(1,-206,0,16),Color3.fromRGB(15,15,15),0.25)
corner(petPanel,12); stroke(petPanel,Color3.fromRGB(200,200,200),1.5,0.5)
mkLabel(petPanel,"Pets",UDim2.new(1,0,0,32))

local petScroll=Instance.new("ScrollingFrame")
petScroll.Size=UDim2.new(1,-8,1,-36); petScroll.Position=UDim2.new(0,4,0,34)
petScroll.BackgroundTransparency=1; petScroll.ScrollBarThickness=3; petScroll.Parent=petPanel
local petLayout=Instance.new("UIListLayout"); petLayout.Padding=UDim.new(0,4); petLayout.Parent=petScroll

local petRows={}

local function refreshPetList()
    for _,r in ipairs(petRows) do r:Destroy() end
    petRows={}
    petScroll.CanvasSize=UDim2.new(0,0,0,#state.pets*36)
    for i,pet in ipairs(state.pets) do
        local row=mkFrame(petScroll,UDim2.new(1,-4,0,32),UDim2.new(0,0,0,0),Color3.fromRGB(40,40,40),i>GameConfig.MAX_PETS and 0.65 or 0)
        corner(row,6)
        local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,18,0,18); dot.Position=UDim2.new(0,4,0.5,-9)
        dot.BackgroundColor3=Color3.fromRGB(pet.r or 200,pet.g or 200,pet.b or 200); dot.BorderSizePixel=0; dot.Parent=row; corner(dot,9)
        mkLabel(row,pet.name,UDim2.new(1,-60,1,0),UDim2.new(0,26,0,0),Color3.fromRGB(230,230,230),Enum.Font.Gotham,Enum.TextXAlignment.Left)
        mkLabel(row,"+"..fmt(pet.multi).."/s",UDim2.new(0,52,1,0),UDim2.new(1,-56,0,0),Color3.fromRGB(100,255,150),Enum.Font.GothamBold,Enum.TextXAlignment.Right)
        table.insert(petRows,row)
    end
end

-- ── Toast notification ────────────────────────────────────────────────────────

local toast=mkFrame(gui,UDim2.new(0,300,0,50),UDim2.new(0.5,-150,0,-60),Color3.fromRGB(25,25,25),0.1)
corner(toast,12); stroke(toast,Color3.fromRGB(255,215,0),2,0.2)
local toastLbl=mkLabel(toast,"",nil,nil,Color3.fromRGB(255,215,0))
local toastOut=nil

local function showToast(msg)
    if toastOut then toastOut:Cancel() end
    toastLbl.Text=msg
    TweenService:Create(toast,TweenInfo.new(0.3,Enum.EasingStyle.Back),{Position=UDim2.new(0.5,-150,0,16)}):Play()
    task.delay(2.5, function()
        toastOut=TweenService:Create(toast,TweenInfo.new(0.35),{Position=UDim2.new(0.5,-150,0,-60)})
        toastOut:Play()
    end)
end

-- ── Panel toggles ────────────────────────────────────────────────────────────

shopBtn.MouseButton1Click:Connect(function()
    eggPanel.Visible=not eggPanel.Visible; upgradePanel.Visible=false
end)
upgradeBtn.MouseButton1Click:Connect(function()
    upgradePanel.Visible=not upgradePanel.Visible; eggPanel.Visible=false
end)

-- ── SyncData ──────────────────────────────────────────────────────────────────

SyncData.OnClientEvent:Connect(function(snap)
    state.coins    = snap.coins
    state.lifetime = snap.lifetime
    state.rebirths = snap.rebirths or 0
    state.pets     = snap.pets
    state.upgrades = snap.upgrades

    coinVal.Text = fmt(state.coins)
    rebirthCountLbl.Text = "✨ "..state.rebirths.." Rebirth"..(state.rebirths==1 and "" or "s")

    -- Update rebirth button cost
    local cost = math.floor(GameConfig.REBIRTH_BASE_COST * (GameConfig.REBIRTH_COST_MULT ^ state.rebirths))
    rebirthBtn.Text = "✨ REBIRTH\n🪙 "..fmt(cost)

    -- Update upgrade cost labels
    for id, entry in pairs(upgCostLabels) do
        local level = state.upgrades[id] or 0
        local c     = math.floor(entry.upg.baseCost * (entry.upg.costMult ^ level))
        entry.lbl.Text = "🪙 "..fmt(c).." (Lv."..level..")"
    end

    refreshPetList()
end)

-- ── CPS display ───────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function()
    local passive = 0
    for i = 1, math.min(#state.pets, GameConfig.MAX_PETS) do
        passive = passive + (state.pets[i].multi or 0)
    end
    local magnet   = 2 ^ (state.upgrades["passive_boost"] or 0)
    local rebirth  = GameConfig.REBIRTH_BONUS ^ state.rebirths
    cpsLbl.Text = "+"..fmt(passive * magnet * rebirth).."/s"
end)

Notification.OnClientEvent:Connect(showToast)
