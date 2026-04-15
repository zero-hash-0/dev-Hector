--!strict

-- Generates the full arena: floor, walls, cover pillars, center platform,
-- escape zone pads. Returns escape zone parts indexed by slot (1–4).

local Lighting  = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

-- Map constants
local ARENA      = 220   -- total floor size (studs)
local WALL_H     = 24
local WALL_T     = 4
local PAD_RADIUS = 10    -- escape zone pad half-size
local PAD_OFFSET = 88    -- distance from center to pad

local PALETTE = {
	Floor     = Color3.fromHex("#1A1A2E"),
	Wall      = Color3.fromHex("#16213E"),
	Pillar    = Color3.fromHex("#0F3460"),
	Center    = Color3.fromHex("#533483"),
	EscapePad = Color3.fromHex("#00B4D8"),
	Accent    = Color3.fromHex("#E94560"),
}

function WorldService.new()
	return setmetatable({}, WorldService)
end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function makePart(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored    = true
	p.CanCollide  = true
	p.CastShadow  = true
	p.Material    = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = Workspace
	return p
end

local function addNeon(part: BasePart, color: Color3, thickness: number)
	local neon = Instance.new("SelectionBox")
	neon.Adornee   = part
	neon.Color3    = color
	neon.LineThickness = thickness
	neon.Parent    = part
end

-- ── Build sections ────────────────────────────────────────────────────────────

local function buildFloor()
	makePart({
		Name      = "Floor",
		Size      = Vector3.new(ARENA, 2, ARENA),
		Position  = Vector3.new(0, -1, 0),
		Color     = PALETTE.Floor,
	})
end

local function buildWalls()
	local half = ARENA / 2
	local specs = {
		{ pos = Vector3.new(0, WALL_H/2, -half),  sz = Vector3.new(ARENA + WALL_T*2, WALL_H, WALL_T) },
		{ pos = Vector3.new(0, WALL_H/2,  half),  sz = Vector3.new(ARENA + WALL_T*2, WALL_H, WALL_T) },
		{ pos = Vector3.new(-half, WALL_H/2, 0),  sz = Vector3.new(WALL_T, WALL_H, ARENA) },
		{ pos = Vector3.new( half, WALL_H/2, 0),  sz = Vector3.new(WALL_T, WALL_H, ARENA) },
	}
	for _, s in specs do
		makePart({ Name = "Wall", Size = s.sz, Position = s.pos, Color = PALETTE.Wall })
	end
end

local function buildCenterPlatform()
	-- Raised platform where Core spawns
	makePart({
		Name     = "CenterPlatform",
		Size     = Vector3.new(20, 3, 20),
		Position = Vector3.new(0, 1.5, 0),
		Color    = PALETTE.Center,
		Material = Enum.Material.Neon,
	})
	-- Low outer ring
	makePart({
		Name     = "CenterRing",
		Size     = Vector3.new(36, 1, 36),
		Position = Vector3.new(0, 0.5, 0),
		Color    = PALETTE.Pillar,
	})
end

local function buildPillars()
	-- Symmetric cover: 4 clusters of 2 pillars each at mid-range
	local positions = {
		Vector3.new( 40, 0,  40),
		Vector3.new(-40, 0,  40),
		Vector3.new( 40, 0, -40),
		Vector3.new(-40, 0, -40),
		Vector3.new( 60, 0,   0),
		Vector3.new(-60, 0,   0),
		Vector3.new(  0, 0,  60),
		Vector3.new(  0, 0, -60),
	}
	for _, pos in positions do
		-- Main pillar
		makePart({
			Name     = "Pillar",
			Size     = Vector3.new(6, 18, 6),
			Position = pos + Vector3.new(0, 9, 0),
			Color    = PALETTE.Pillar,
			Material = Enum.Material.SmoothPlastic,
		})
		-- Low cover block beside it
		makePart({
			Name     = "Cover",
			Size     = Vector3.new(10, 5, 4),
			Position = pos + Vector3.new(7, 2.5, 0),
			Color    = PALETTE.Wall,
		})
	end
end

local function buildEscapePads(): { BasePart }
	-- 4 pads in the corners — assigned to players by slot index
	local corners = {
		Vector3.new( PAD_OFFSET, 0,  PAD_OFFSET),
		Vector3.new(-PAD_OFFSET, 0,  PAD_OFFSET),
		Vector3.new( PAD_OFFSET, 0, -PAD_OFFSET),
		Vector3.new(-PAD_OFFSET, 0, -PAD_OFFSET),
	}

	local pads = {}
	for i, pos in corners do
		local pad = makePart({
			Name     = "EscapeZone_" .. i,
			Size     = Vector3.new(PAD_RADIUS * 2, 1, PAD_RADIUS * 2),
			Position = pos + Vector3.new(0, 0.5, 0),
			Color    = PALETTE.EscapePad,
			Material = Enum.Material.Neon,
		})
		-- Billboard label
		local billboard = Instance.new("BillboardGui")
		billboard.Size           = UDim2.new(0, 120, 0, 40)
		billboard.StudsOffset    = Vector3.new(0, 4, 0)
		billboard.AlwaysOnTop    = false
		billboard.Parent         = pad

		local label = Instance.new("TextLabel")
		label.Size            = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text            = "ESCAPE " .. i
		label.TextColor3      = Color3.new(1, 1, 1)
		label.Font            = Enum.Font.GothamBold
		label.TextScaled      = true
		label.Parent          = billboard

		pads[i] = pad
	end
	return pads
end

-- ── Public API ─────────────────────────────────────────────────────────────────

function WorldService:BuildMap(): { BasePart }
	-- Clear any existing arena pieces
	for _, child in Workspace:GetChildren() do
		if child.Name == "Floor" or child.Name == "Wall"
			or child.Name == "Pillar" or child.Name == "Cover"
			or child.Name == "CenterPlatform" or child.Name == "CenterRing"
			or child.Name:find("EscapeZone") then
			child:Destroy()
		end
	end

	buildFloor()
	buildWalls()
	buildCenterPlatform()
	buildPillars()
	local pads = buildEscapePads()
	self._escapePads = pads
	return pads
end

function WorldService:GetEscapePads(): { BasePart }
	return self._escapePads or {}
end

function WorldService:ApplyLighting()
	Lighting.Ambient        = Color3.fromRGB(10, 10, 20)
	Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
	Lighting.Brightness     = 0.8
	Lighting.ClockTime      = 0   -- night
	Lighting.FogEnd         = 400
	Lighting.FogColor       = Color3.fromHex("#0D0D1A")

	-- Remove old atmosphere/bloom
	for _, fx in Lighting:GetChildren() do fx:Destroy() end

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size      = 24
	bloom.Threshold = 0.8
	bloom.Parent    = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density   = 0.4
	atmosphere.Haze      = 0
	atmosphere.Glare     = 0.1
	atmosphere.Parent    = Lighting
end

return WorldService
