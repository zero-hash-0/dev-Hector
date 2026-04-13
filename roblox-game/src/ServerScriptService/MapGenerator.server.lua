-- MapGenerator.server.lua (Script)
-- Procedurally generates the obby map at runtime so the game works without
-- needing manually placed parts in Studio.
--
-- Layout:
--   • A spawn platform at X = -25
--   • 10 stage sections spaced STAGE_SPACING studs apart along the X axis
--   • Each section has a large green "Checkpoint_N" pad at the far end
--   • Platforms between sections get progressively smaller / more offset
--     to increase difficulty as stages go up

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

local SPACING = GameConfig.STAGE_SPACING

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function makePart(name: string, size: Vector3, position: Vector3, color: BrickColor, parent: Instance?): Part
    local p = Instance.new("Part")
    p.Name         = name
    p.Size         = size
    p.Position     = position
    p.BrickColor   = color
    p.Material     = Enum.Material.SmoothPlastic
    p.Anchored     = true
    p.TopSurface   = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent        = parent or workspace
    return p
end

local function addGlow(part: Part, color: Color3)
    local light = Instance.new("PointLight")
    light.Brightness = 2
    light.Range      = 16
    light.Color      = color
    light.Parent     = part
end

-- ── Spawn platform ────────────────────────────────────────────────────────────

makePart(
    "SpawnPlatform",
    Vector3.new(20, 1, 20),
    Vector3.new(-25, 0, 0),
    BrickColor.new("Bright blue")
)

-- ── Stage sections ────────────────────────────────────────────────────────────

local rng = Random.new()

for stage = 1, GameConfig.MAX_STAGES do
    local color      = GameConfig.STAGE_COLORS[stage] or BrickColor.new("Medium stone grey")
    local baseX      = (stage - 1) * SPACING   -- X origin of this stage's section
    local checkX     = baseX + SPACING - 5      -- checkpoint sits near the end of the section

    -- ── Checkpoint platform ──────────────────────────────────────────────────
    local checkpoint = makePart(
        "Checkpoint_" .. stage,
        Vector3.new(12, 1, 12),
        Vector3.new(checkX, 0, 0),
        BrickColor.new("Bright green")
    )
    addGlow(checkpoint, Color3.fromRGB(0, 255, 80))

    -- Stage label (BillboardGui on the checkpoint)
    local billboard = Instance.new("BillboardGui")
    billboard.Size       = UDim2.new(0, 80, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent      = checkpoint

    local label = Instance.new("TextLabel")
    label.Size              = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font              = Enum.Font.GothamBold
    label.TextScaled        = true
    label.TextColor3        = Color3.fromRGB(255, 255, 255)
    label.Text              = "Stage " .. stage
    label.Parent            = billboard

    -- ── Jumping platforms between this checkpoint and the previous one ────────
    -- Skip platforms before stage 1 (player spawns directly on Checkpoint_1).
    if stage > 1 then
        local prevCheckX  = (stage - 2) * SPACING + SPACING - 5
        local sectionLen  = checkX - prevCheckX          -- distance to cover
        local numPlatforms = 3 + stage                   -- more platforms = more jumps (harder)

        for j = 1, numPlatforms do
            local t = j / (numPlatforms + 1)
            local x = prevCheckX + t * sectionLen

            -- Height variation increases with stage difficulty
            local yVariance = math.min(stage * 0.4, 4)
            local y = rng:NextNumber(-yVariance, yVariance)

            -- Lateral (Z) spread increases with stage
            local zSpread = math.min(4 + stage * 0.5, 10)
            local z = rng:NextNumber(-zSpread, zSpread)

            -- Platform size shrinks with stage (harder = smaller platforms)
            local width = math.max(2.5, 8 - stage * 0.45)

            makePart(
                ("Platform_%d_%d"):format(stage, j),
                Vector3.new(width, 1, width),
                Vector3.new(x, y, z),
                color
            )
        end
    end
end

-- ── Void floor (visual boundary so the sky-box isn't empty below) ────────────
makePart(
    "VoidFloor",
    Vector3.new(2000, 1, 2000),
    Vector3.new(SPACING * GameConfig.MAX_STAGES / 2, GameConfig.VOID_HEIGHT + 10, 0),
    BrickColor.new("Really black")
)

print(("[MapGenerator] Map ready – %d stages generated."):format(GameConfig.MAX_STAGES))
