-- MapGenerator.server.lua (Script)
-- Builds the entire game world at runtime using only coloured BaseParts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- Remove the default white Baseplate so colored tiles show correctly
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function part(props): Part
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = props.collide ~= false
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do
        if k ~= "collide" then (p :: any)[k] = v end
    end
    p.Parent = workspace
    return p
end

local function neonLight(parent, color, brightness, range)
    local l = Instance.new("PointLight")
    l.Color = color; l.Brightness = brightness or 3; l.Range = range or 20
    l.Parent = parent
end

local function padLabel(parent, text, yOffset, color)
    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 180, 0, 44); bg.StudsOffset = Vector3.new(0, yOffset, 0)
    bg.AlwaysOnTop = false; bg.Parent = parent
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold; lbl.TextScaled = true
    lbl.TextColor3 = color or Color3.fromRGB(255,255,255); lbl.Text = text
    lbl.Parent = bg
end

-- ── Floor tiles ───────────────────────────────────────────────────────────────

local tileColors = {
    Color3.fromRGB(80,180,255), Color3.fromRGB(120,220,120),
    Color3.fromRGB(255,200,80), Color3.fromRGB(255,120,180),
    Color3.fromRGB(180,120,255),
}
for tx = -8, 8 do
    for tz = -8, 8 do
        local ci = ((math.abs(tx)+math.abs(tz)) % #tileColors) + 1
        part { Name="Tile", Size=Vector3.new(8,1,8),
               Position=Vector3.new(tx*8,-0.5,tz*8), Color=tileColors[ci],
               Material=Enum.Material.SmoothPlastic }
    end
end

-- ── Click Orb (centre) ────────────────────────────────────────────────────────

local orb = part {
    Name="ClickOrb", Shape=Enum.PartType.Ball, Size=Vector3.new(6,6,6),
    Position=Vector3.new(0,5,0), Color=Color3.fromRGB(255,215,0),
    Material=Enum.Material.Neon,
}
neonLight(orb, Color3.fromRGB(255,200,0), 5, 30)
padLabel(orb, "✨ CLICK ME! ✨", 6, Color3.fromRGB(255,255,0))

-- Slow spin
local bav = Instance.new("BodyAngularVelocity")
bav.AngularVelocity = Vector3.new(0, 1.2, 0)
bav.MaxTorque = Vector3.new(0, math.huge, 0)
bav.Parent = orb

-- Gold sparkle particles (client calls :Emit() on click)
local sparkle = Instance.new("ParticleEmitter")
sparkle.Name         = "ClickSparkle"
sparkle.Texture      = "rbxasset://textures/particles/sparkles_main.dds"
sparkle.Rate         = 0
sparkle.SpreadAngle  = Vector2.new(180, 180)
sparkle.Speed        = NumberRange.new(8, 22)
sparkle.Lifetime     = NumberRange.new(0.3, 0.7)
sparkle.Size         = NumberSequence.new{ NumberSequenceKeypoint.new(0,0.4), NumberSequenceKeypoint.new(1,0) }
sparkle.Color        = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,215,0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,120,0)),
}
sparkle.LightEmission = 1
sparkle.Parent = orb

-- Lucky burst particles (larger, rainbow)
local luckyBurst = Instance.new("ParticleEmitter")
luckyBurst.Name         = "LuckyBurst"
luckyBurst.Texture      = "rbxasset://textures/particles/sparkles_main.dds"
luckyBurst.Rate         = 0
luckyBurst.SpreadAngle  = Vector2.new(180, 180)
luckyBurst.Speed        = NumberRange.new(15, 40)
luckyBurst.Lifetime     = NumberRange.new(0.5, 1.2)
luckyBurst.Size         = NumberSequence.new{ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }
luckyBurst.Color        = ColorSequence.new{
    ColorSequenceKeypoint.new(0,  Color3.fromRGB(255,0,255)),
    ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,255)),
    ColorSequenceKeypoint.new(1,  Color3.fromRGB(255,255,0)),
}
luckyBurst.LightEmission = 1
luckyBurst.Parent = orb

-- ── Egg pads (inner ring, radius 18) ─────────────────────────────────────────

local EGG_RADIUS = 18
local eggAngles  = { 90, 210, 330 }

local function addPrompt(parent, action, object, distance)
    local p = Instance.new("ProximityPrompt")
    p.ActionText            = action
    p.ObjectText            = object
    p.HoldDuration          = 0
    p.MaxActivationDistance = distance or 12
    p.RequiresLineOfSight   = false
    p.Parent                = parent
    return p
end

for i, egg in ipairs(GameConfig.EGGS) do
    local angle = math.rad(eggAngles[i])
    local x, z  = math.cos(angle) * EGG_RADIUS, math.sin(angle) * EGG_RADIUS

    local pad = part { Name="EggPad_"..egg.id, Size=Vector3.new(10,1,10),
                       Position=Vector3.new(x,0,z), BrickColor=egg.color,
                       Material=Enum.Material.SmoothPlastic }
    neonLight(pad, egg.color.Color, 2, 14)

    local eggModel = part { Name="EggModel_"..egg.id, Shape=Enum.PartType.Ball,
           Size=Vector3.new(3,3.6,3), Position=Vector3.new(x,3,z),
           BrickColor=egg.color, Material=Enum.Material.Neon, collide=false }
    local cd = Instance.new("ClickDetector")
    cd.MaxActivationDistance = 20
    cd.Parent = eggModel

    padLabel(pad, egg.name.."\n🪙 "..egg.cost, 6)
    addPrompt(pad, "Open Shop", egg.name)
end

-- ── Upgrade shop pad ─────────────────────────────────────────────────────────

local shopPad = part { Name="ShopPad", Size=Vector3.new(12,1,12),
    Position=Vector3.new(0,0,EGG_RADIUS+10), Color=Color3.fromRGB(80,200,255),
    Material=Enum.Material.SmoothPlastic }
neonLight(shopPad, Color3.fromRGB(80,200,255), 2, 16)
padLabel(shopPad, "⬆ UPGRADES SHOP", 7, Color3.fromRGB(80,255,255))
addPrompt(shopPad, "Open Shop", "Upgrades")

-- ── Rebirth pad ───────────────────────────────────────────────────────────────

local rebirthPad = part { Name="RebirthPad", Size=Vector3.new(12,1,12),
    Position=Vector3.new(0,0,-(EGG_RADIUS+10)), Color=Color3.fromRGB(180,0,255),
    Material=Enum.Material.Neon }
neonLight(rebirthPad, Color3.fromRGB(180,0,255), 4, 20)
padLabel(rebirthPad, "✨ REBIRTH\n(doubles all income)", 7, Color3.fromRGB(220,100,255))
addPrompt(rebirthPad, "Rebirth", "2× All Income")

-- Swirling rebirth particles (always-on, low rate)
local rebirthParticle = Instance.new("ParticleEmitter")
rebirthParticle.Texture      = "rbxasset://textures/particles/sparkles_main.dds"
rebirthParticle.Rate         = 8
rebirthParticle.SpreadAngle  = Vector2.new(60, 60)
rebirthParticle.Speed        = NumberRange.new(3, 8)
rebirthParticle.Lifetime     = NumberRange.new(1, 2)
rebirthParticle.Color        = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200,0,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,200,255)),
}
rebirthParticle.LightEmission = 0.8
rebirthParticle.Parent = rebirthPad

-- ── World leaderboard board ───────────────────────────────────────────────────

local board = part { Name="LeaderboardBoard", Size=Vector3.new(16,20,0.6),
    Position=Vector3.new(-35,10,0), Color=Color3.fromRGB(15,15,30),
    Material=Enum.Material.SmoothPlastic }

local surfGui = Instance.new("SurfaceGui")
surfGui.Name        = "LeaderboardGui"
surfGui.Face        = Enum.NormalId.Front
surfGui.SizingMode  = Enum.SurfaceGuiSizingMode.PixelsPerStud
surfGui.PixelsPerStud = 50
surfGui.Parent      = board

-- Title bar
local titleLbl = Instance.new("TextLabel")
titleLbl.Name                  = "Title"
titleLbl.Size                  = UDim2.new(1,0,0,60)
titleLbl.Position               = UDim2.new(0,0,0,0)
titleLbl.BackgroundColor3      = Color3.fromRGB(255,215,0)
titleLbl.BackgroundTransparency = 0
titleLbl.Font                  = Enum.Font.GothamBold
titleLbl.TextScaled             = true
titleLbl.TextColor3             = Color3.fromRGB(0,0,0)
titleLbl.Text                   = "🏆  TOP PLAYERS"
titleLbl.Parent                 = surfGui

local rowColors = { Color3.fromRGB(40,35,60), Color3.fromRGB(30,25,50) }

for i = 1, 5 do
    local row = Instance.new("TextLabel")
    row.Name                  = "Row_"..i
    row.Size                  = UDim2.new(1,0,0,56)
    row.Position               = UDim2.new(0,0,0, 60+(i-1)*58)
    row.BackgroundColor3      = rowColors[(i%2)+1]
    row.BackgroundTransparency = 0
    row.Font                  = Enum.Font.GothamBold
    row.TextScaled             = true
    row.TextColor3             = Color3.fromRGB(200,200,220)
    row.Text                   = "#"..i.."  ---"
    row.Parent                 = surfGui
end

-- Expose gui reference for GameManager to update
_G.LeaderboardGui = surfGui

-- ── Spawn pad & void barrier ──────────────────────────────────────────────────

part { Name="SpawnBase", Size=Vector3.new(14,1,14),
       Position=Vector3.new(30,0,0), Color=Color3.fromRGB(100,220,130),
       Material=Enum.Material.SmoothPlastic }

part { Name="VoidBarrier", Size=Vector3.new(1000,1,1000),
       Position=Vector3.new(0,-80,0), Color=Color3.fromRGB(10,10,10), collide=false }

print("[MapGenerator] World ready.")
