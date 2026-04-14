--!strict

-- Responsible for map setup and environment/lighting configuration.

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new()
	local self = setmetatable({}, WorldService)
	return self
end

function WorldService:BuildMap()
	-- TODO: generate or configure map geometry
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.BrickColor = BrickColor.new("Dark stone grey")
	end
end

function WorldService:ApplyLighting()
	Lighting.Ambient        = Color3.fromRGB(30, 30, 40)
	Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 70)
	Lighting.Brightness     = 1.5
	Lighting.ClockTime      = 14
	Lighting.FogEnd         = 1000
end

return WorldService
