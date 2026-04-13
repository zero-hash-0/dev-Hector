-- MapGenerator.server.lua
-- Builds the entire world from coloured BaseParts — no custom assets needed.
-- Zone layout (top-down):
--   East  → Spawn pad + "START HERE" sign
--   Centre → Click Orb (gold)
--   Ring  → 3 Egg pads
--   North → Upgrade shop pad (blue)
--   South → Rebirth milestone pad (purple)
--   West  → World leaderboard board

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Remove default Baseplate so coloured tiles show correctly
local bp = workspace:FindFirstChild("Baseplate")
if bp then bp:Destroy() end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function part(props): Part
    local p = Instance.new("Part")
    p.Anchored = true; p.CanCollide = props.collide ~= false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do
        if k ~= "collide" then (p :: any)[k] = v end
    end
    p.Parent = workspace
    return p
end

local function glow(parent, color, brightness, range)
    local l = Instance.new("PointLight")
    l.Color = color; l.Brightness = brightness or 3; l.Range = range or 20
    l.Parent = parent
end

local function floatLabel(parent, text, yOffset, textColor, textSize)
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 52)
    bg.StudsOffset = Vector3.new(0, yOffset or 4, 0)
    bg.AlwaysOnTop = false; bg.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true
    lbl.TextSize = textSize or 18
    lbl.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    lbl.Text = text; lbl.Parent = bg
    return lbl
end

local function addPrompt(parent, action, object, distance)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action; p.ObjectText = object
    p.HoldDuration = 0; p.MaxActivationDistance = distance or 12
    p.RequiresLineOfSight = false; p.Parent = parent
    return p
end

-- ── Coloured floor tiles ──────────────────────────────────────────────────────

local tileColors = {
    Color3.fromRGB(80, 180, 255), Color3.fromRGB(120, 220, 120),
    Color3.fromRGB(255, 200, 80), Color3.fromRGB(255, 120, 180),
    Color3.fromRGB(180, 120, 255),
}
for tx = -9, 9 do
    for tz = -9, 9 do
        local ci = ((math.abs(tx) + math.abs(tz)) % #tileColors) + 1
        part { Name = "Tile", Size = Vector3.new(8, 1, 8),
               Position = Vector3.new(tx * 8, -0.5, tz * 8),
               Color = tileColors[ci], Material = Enum.Material.SmoothPlastic }
    end
end

-- Glowing path tiles from spawn (east) toward the orb (center)
local pathColor = Color3.fromRGB(255, 230, 80)
for i = 1, 3 do
    local px = 30 - i * 8
    local pathTile = part { Name = "PathTile_"..i, Size = Vector3.new(8, 1.1, 8),
                             Position = Vector3.new(px, -0.4, 0),
                             Color = pathColor, Material = Enum.Material.Neon }
    glow(pathTile, pathColor, 1, 10)
end

-- ── Click Orb ─────────────────────────────────────────────────────────────────

local orb = part { Name = "ClickOrb", Shape = Enum.PartType.Ball,
    Size = Vector3.new(7, 7, 7), Position = Vector3.new(0, 5, 0),
    Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon }
glow(orb, Color3.fromRGB(255, 200, 0), 6, 35)
floatLabel(orb, "🪙  CLICK ME!", 6, Color3.fromRGB(255, 255, 100), 20)

local bav = Instance.new("BodyAngularVelocity")
bav.AngularVelocity = Vector3.new(0, 1.2, 0)
bav.MaxTorque = Vector3.new(0, math.huge, 0); bav.Parent = orb

local sparkle = Instance.new("ParticleEmitter")
sparkle.Name = "ClickSparkle"
sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
sparkle.Rate = 0; sparkle.SpreadAngle = Vector2.new(180, 180)
sparkle.Speed = NumberRange.new(8, 22); sparkle.Lifetime = NumberRange.new(0.3, 0.7)
sparkle.Size = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }
sparkle.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 0)),
}
sparkle.LightEmission = 1; sparkle.Parent = orb

local luckyBurst = Instance.new("ParticleEmitter")
luckyBurst.Name = "LuckyBurst"
luckyBurst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
luckyBurst.Rate = 0; luckyBurst.SpreadAngle = Vector2.new(180, 180)
luckyBurst.Speed = NumberRange.new(15, 40); luckyBurst.Lifetime = NumberRange.new(0.5, 1.2)
luckyBurst.Size = NumberSequence.new{ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }
luckyBurst.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 0)),
}
luckyBurst.LightEmission = 1; luckyBurst.Parent = orb

-- ── EGG ZONE sign ─────────────────────────────────────────────────────────────

local eggZoneSign = part { Name = "EggZoneSign", Size = Vector3.new(22, 0.5, 0.5),
    Position = Vector3.new(0, 0.1, -10), Color = Color3.fromRGB(255, 215, 0),
    Material = Enum.Material.Neon, collide = false }
glow(eggZoneSign, Color3.fromRGB(255, 215, 0), 1.5, 12)
floatLabel(eggZoneSign, "🥚  EGG ZONE  —  Click an egg to hatch a pet!", 3,
    Color3.fromRGB(255, 230, 100), 16)

-- ── Egg pads ──────────────────────────────────────────────────────────────────

local EGG_RADIUS = 18
local eggAngles  = { 90, 210, 330 }

for i, egg in ipairs(GameConfig.EGGS) do
    local angle = math.rad(eggAngles[i])
    local x, z  = math.cos(angle) * EGG_RADIUS, math.sin(angle) * EGG_RADIUS

    local pad = part { Name = "EggPad_"..egg.id, Size = Vector3.new(10, 1, 10),
                       Position = Vector3.new(x, 0, z), BrickColor = egg.color,
                       Material = Enum.Material.SmoothPlastic }
    glow(pad, egg.color.Color, 2, 14)

    -- Egg model ball with ClickDetector
    local eggModel = part { Name = "EggModel_"..egg.id, Shape = Enum.PartType.Ball,
        Size = Vector3.new(3.5, 4.2, 3.5), Position = Vector3.new(x, 3.5, z),
        BrickColor = egg.color, Material = Enum.Material.Neon, collide = false }
    glow(eggModel, egg.color.Color, 3, 12)

    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 22; cd.Parent = eggModel

    -- Sparkle emitter on egg
    local eggSpark = Instance.new("ParticleEmitter")
    eggSpark.Name = "EggSparkle"
    eggSpark.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    eggSpark.Rate = 4; eggSpark.SpreadAngle = Vector2.new(60, 60)
    eggSpark.Speed = NumberRange.new(2, 5); eggSpark.Lifetime = NumberRange.new(0.4, 0.8)
    eggSpark.Size = NumberSequence.new{ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }
    eggSpark.Color = ColorSequence.new(egg.color.Color)
    eggSpark.LightEmission = 0.8; eggSpark.Parent = eggModel

    -- Floating label: name + cost + "CLICK TO HATCH"
    floatLabel(eggModel, egg.name.."\n🪙 "..egg.cost.." coins\nCLICK TO HATCH", 5,
        Color3.fromRGB(255, 255, 255), 14)

    addPrompt(pad, "Hatch Egg", egg.name, 14)
end

-- ── Upgrade shop pad ─────────────────────────────────────────────────────────

local shopPad = part { Name = "ShopPad", Size = Vector3.new(12, 1, 12),
    Position = Vector3.new(0, 0, EGG_RADIUS + 12),
    Color = Color3.fromRGB(60, 180, 255), Material = Enum.Material.SmoothPlastic }
glow(shopPad, Color3.fromRGB(60, 180, 255), 2, 18)
floatLabel(shopPad, "⬆  UPGRADES\nClick faster · Earn more", 7,
    Color3.fromRGB(120, 220, 255), 16)
addPrompt(shopPad, "Open Upgrades", "Shop", 16)

-- ── Rebirth milestone pad ────────────────────────────────────────────────────

local rebirthPad = part { Name = "RebirthPad", Size = Vector3.new(14, 1, 14),
    Position = Vector3.new(0, 0, -(EGG_RADIUS + 14)),
    Color = Color3.fromRGB(160, 0, 255), Material = Enum.Material.Neon }
glow(rebirthPad, Color3.fromRGB(160, 0, 255), 5, 24)
floatLabel(rebirthPad,
    "✨  REBIRTH ZONE\nSpend "..GameConfig.REBIRTH_BASE_COST.." coins → 2× ALL income forever",
    8, Color3.fromRGB(220, 120, 255), 14)
addPrompt(rebirthPad, "Rebirth  (2× income)", "✨ Milestone", 18)

local rebirthFx = Instance.new("ParticleEmitter")
rebirthFx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
rebirthFx.Rate = 10; rebirthFx.SpreadAngle = Vector2.new(70, 70)
rebirthFx.Speed = NumberRange.new(3, 9); rebirthFx.Lifetime = NumberRange.new(1, 2.5)
rebirthFx.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 255)),
}
rebirthFx.LightEmission = 0.9; rebirthFx.Parent = rebirthPad

-- ── Spawn area ────────────────────────────────────────────────────────────────

local spawnPad = part { Name = "SpawnBase", Size = Vector3.new(16, 1, 16),
    Position = Vector3.new(32, 0, 0),
    Color = Color3.fromRGB(80, 220, 120), Material = Enum.Material.SmoothPlastic }
glow(spawnPad, Color3.fromRGB(80, 220, 120), 1.5, 14)
floatLabel(spawnPad,
    "👋 START HERE\n🪙 Click the golden orb →", 7,
    Color3.fromRGB(150, 255, 160), 16)

-- ── World leaderboard ─────────────────────────────────────────────────────────

local board = part { Name = "LeaderboardBoard", Size = Vector3.new(18, 22, 0.6),
    Position = Vector3.new(-38, 11, 0),
    Color = Color3.fromRGB(12, 12, 22), Material = Enum.Material.SmoothPlastic }

local surfGui = Instance.new("SurfaceGui")
surfGui.Name = "LeaderboardGui"; surfGui.Face = Enum.NormalId.Front
surfGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surfGui.PixelsPerStud = 50; surfGui.Parent = board

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"; titleBar.Size = UDim2.new(1, 0, 0, 65)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
titleBar.BackgroundTransparency = 0; titleBar.BorderSizePixel = 0
titleBar.Parent = surfGui

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 1, 0); titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextScaled = true
titleLbl.TextColor3 = Color3.fromRGB(0, 0, 0); titleLbl.Text = "🏆  TOP PLAYERS"
titleLbl.Parent = titleBar

local rowBg = { Color3.fromRGB(35, 28, 55), Color3.fromRGB(28, 22, 44) }
for i = 1, 5 do
    local row = Instance.new("TextLabel")
    row.Name = "Row_"..i; row.Size = UDim2.new(1, 0, 0, 58)
    row.Position = UDim2.new(0, 0, 0, 65 + (i-1)*60)
    row.BackgroundColor3 = rowBg[(i%2)+1]; row.BackgroundTransparency = 0
    row.BorderSizePixel = 0; row.Font = Enum.Font.GothamBold
    row.TextScaled = true; row.TextColor3 = Color3.fromRGB(210, 200, 235)
    row.Text = "#"..i.."  —"; row.Parent = surfGui
end

_G.LeaderboardGui = surfGui

-- ── Void barrier ─────────────────────────────────────────────────────────────

part { Name = "VoidBarrier", Size = Vector3.new(1200, 1, 1200),
       Position = Vector3.new(0, -80, 0),
       Color = Color3.fromRGB(8, 8, 8), collide = false }

print("[MapGenerator] World ready.")
