--!strict

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new()
	return setmetatable({}, WorldService)
end

local function neonLine(parent: Instance, size: Vector3, cframe: CFrame, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = size
	p.CFrame = cframe
	p.Parent = parent
end

function WorldService:BuildMapBlockout()
	local world = Instance.new("Folder")
	world.Name = "NeonWorld"
	world.Parent = workspace

	local ground = Instance.new("Part")
	ground.Name = "RaidFloor"
	ground.Anchored = true
	ground.Material = Enum.Material.Slate
	ground.Color = GameConfig.Palette.Midnight
	ground.Size = Vector3.new(420, 1, 420)
	ground.Position = Vector3.new(0, -1, 0)
	ground.Parent = world

	local plaza = Instance.new("Part")
	plaza.Name = "CentralPlaza"
	plaza.Anchored = true
	plaza.Material = Enum.Material.Metal
	plaza.Color = GameConfig.Palette.DarkSurface
	plaza.Size = Vector3.new(90, 2, 90)
	plaza.Position = Vector3.new(0, 0, 0)
	plaza.Parent = world

	local reactor = Instance.new("Part")
	reactor.Shape = Enum.PartType.Ball
	reactor.Name = "MemeReactor"
	reactor.Anchored = true
	reactor.Material = Enum.Material.Neon
	reactor.Color = GameConfig.Palette.HotMagenta
	reactor.Size = Vector3.new(14, 14, 14)
	reactor.Position = Vector3.new(0, 10, 0)
	reactor.Parent = world

	for i = 1, 8 do
		local angle = (i / 8) * math.pi * 2
		local pos = Vector3.new(math.cos(angle) * 58, 0.1, math.sin(angle) * 58)
		neonLine(world, Vector3.new(16, 0.2, 2), CFrame.new(pos) * CFrame.Angles(0, angle, 0), GameConfig.Palette.NeonCyan)
	end

	for i = 1, 20 do
		local b = Instance.new("Part")
		b.Name = "SkylineBlock"
		b.Anchored = true
		b.Material = Enum.Material.SmoothPlastic
		b.Color = Color3.fromRGB(18, 20, 38)
		b.Size = Vector3.new(math.random(14, 28), math.random(30, 80), math.random(14, 28))
		b.Position = Vector3.new(math.random(-200, 200), b.Size.Y * 0.5 - 1, math.random(-200, 200))
		b.Parent = world
	end
end

function WorldService:ApplyLighting()
	Lighting.ClockTime = 21.2
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(22, 20, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(15, 16, 30)
	Lighting.FogColor = Color3.fromRGB(27, 16, 48)
	Lighting.FogStart = 120
	Lighting.FogEnd = 520

	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.65
	bloom.Size = 42
	bloom.Threshold = 1.3
	bloom.Parent = Lighting

	local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	colorCorrection.Saturation = 0.18
	colorCorrection.Contrast = 0.12
	colorCorrection.TintColor = Color3.fromRGB(210, 220, 255)
	colorCorrection.Parent = Lighting
end

return WorldService
