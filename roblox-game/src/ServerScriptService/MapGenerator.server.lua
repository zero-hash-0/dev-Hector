-- MapGenerator.server.lua (Script)
-- Builds the entire game world at runtime using only coloured BaseParts.
-- No custom assets needed – everything is Roblox primitives.
--
-- Layout (top-down):
--   Centre  → Giant glowing click orb (the main interactive object)
--   Inner ring → 3 egg pads  (Basic / Super / Legendary)
--   Outer ring → Upgrade shop pad
--   Floor   → Colourful tile grid

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function part(props): Part
    local p = Instance.new("Part")
    p.Anchored      = true
    p.CanCollide    = props.collide ~= false
    p.TopSurface    = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do
        if k ~= "collide" then
            (p :: any)[k] = v
        end
    end
    p.Parent = workspace
    return p
end

local function billboard(parent, text, yOffset, textColor)
    local bg = Instance.new("BillboardGui")
    bg.Size         = UDim2.new(0, 160, 0, 40)
    bg.StudsOffset  = Vector3.new(0, yOffset, 0)
    bg.AlwaysOnTop  = false
    bg.Parent       = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font                  = Enum.Font.GothamBold
    lbl.TextScaled            = true
    lbl.TextColor3            = textColor or Color3.fromRGB(255, 255, 255)
    lbl.Text                  = text
    lbl.Parent                = bg
end

local function neonLight(parent, color, brightness, range)
    local l = Instance.new("PointLight")
    l.Color      = color
    l.Brightness = brightness or 3
    l.Range      = range or 20
    l.Parent     = parent
end

-- ── Floor tiles ───────────────────────────────────────────────────────────────

local TILE_SIZE  = 8
local GRID_HALF  = 8  -- tiles in each direction → 17×17 grid

local tileColors = {
    Color3.fromRGB(80,  180, 255),
    Color3.fromRGB(120, 220, 120),
    Color3.fromRGB(255, 200,  80),
    Color3.fromRGB(255, 120, 180),
    Color3.fromRGB(180, 120, 255),
}

for tx = -GRID_HALF, GRID_HALF do
    for tz = -GRID_HALF, GRID_HALF do
        local colorIndex = ((math.abs(tx) + math.abs(tz)) % #tileColors) + 1
        part {
            Name     = "Tile",
            Size     = Vector3.new(TILE_SIZE, 1, TILE_SIZE),
            Position = Vector3.new(tx * TILE_SIZE, -0.5, tz * TILE_SIZE),
            Color    = tileColors[colorIndex],
            Material = Enum.Material.SmoothPlastic,
        }
    end
end

-- ── Click Orb (centre) ────────────────────────────────────────────────────────

local orb = part {
    Name     = "ClickOrb",
    Shape    = Enum.PartType.Ball,
    Size     = Vector3.new(6, 6, 6),
    Position = Vector3.new(0, 5, 0),
    Color    = Color3.fromRGB(255, 215, 0),
    Material = Enum.Material.Neon,
}
neonLight(orb, Color3.fromRGB(255, 200, 0), 5, 30)
billboard(orb, "CLICK ME!", 5, Color3.fromRGB(255, 255, 0))

-- Slow spin via BodyAngularVelocity (cosmetic)
local bav = Instance.new("BodyAngularVelocity")
bav.AngularVelocity = Vector3.new(0, 0.8, 0)
bav.MaxTorque       = Vector3.new(0, math.huge, 0)
bav.Parent          = orb

-- ── Egg pads (inner ring, radius 18) ─────────────────────────────────────────

local EGG_RADIUS = 18
local eggAngles  = { 90, 210, 330 }  -- degrees

for i, egg in ipairs(GameConfig.EGGS) do
    local angle = math.rad(eggAngles[i])
    local x     = math.cos(angle) * EGG_RADIUS
    local z     = math.sin(angle) * EGG_RADIUS

    -- Platform
    local pad = part {
        Name     = "EggPad_" .. egg.id,
        Size     = Vector3.new(10, 1, 10),
        Position = Vector3.new(x, 0, z),
        BrickColor = egg.color,
        Material = Enum.Material.SmoothPlastic,
    }
    neonLight(pad, egg.color.Color, 2, 14)

    -- Egg model (sphere sitting on pad)
    part {
        Name     = "EggModel_" .. egg.id,
        Shape    = Enum.PartType.Ball,
        Size     = Vector3.new(3, 3.6, 3),
        Position = Vector3.new(x, 3, z),
        BrickColor = egg.color,
        Material = Enum.Material.Neon,
        collide  = false,
    }

    billboard(pad, egg.name .. "\n" .. egg.cost .. " coins", 6,
        Color3.fromRGB(255, 255, 255))
end

-- ── Upgrade shop pad (outer ring) ────────────────────────────────────────────

local shopPad = part {
    Name     = "ShopPad",
    Size     = Vector3.new(12, 1, 12),
    Position = Vector3.new(0, 0, EGG_RADIUS + 10),
    Color    = Color3.fromRGB(80, 200, 255),
    Material = Enum.Material.SmoothPlastic,
}
neonLight(shopPad, Color3.fromRGB(80, 200, 255), 2, 16)

-- Shop sign
part {
    Name     = "ShopSign",
    Size     = Vector3.new(6, 3, 0.5),
    Position = Vector3.new(0, 3.5, EGG_RADIUS + 10),
    Color    = Color3.fromRGB(30, 30, 30),
    Material = Enum.Material.SmoothPlastic,
}
billboard(shopPad, "UPGRADES SHOP", 7, Color3.fromRGB(80, 255, 255))

-- ── Spawn pad ─────────────────────────────────────────────────────────────────

part {
    Name     = "SpawnBase",
    Size     = Vector3.new(14, 1, 14),
    Position = Vector3.new(0, 0, -EGG_RADIUS - 10),
    Color    = Color3.fromRGB(100, 220, 130),
    Material = Enum.Material.SmoothPlastic,
}

-- ── Sky void barrier ──────────────────────────────────────────────────────────

part {
    Name     = "VoidBarrier",
    Size     = Vector3.new(1000, 1, 1000),
    Position = Vector3.new(0, -80, 0),
    Color    = Color3.fromRGB(10, 10, 10),
    collide  = false,
}

print("[MapGenerator] World ready.")
