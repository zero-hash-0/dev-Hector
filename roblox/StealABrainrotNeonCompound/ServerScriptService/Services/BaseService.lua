--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local BaseService = {}
BaseService.__index = BaseService

function BaseService.new()
	local self = setmetatable({}, BaseService)
	self.BasesByPlayer = {}
	self.OpenBases = {}
	self.BaseFolder = workspace:FindFirstChild("Compounds") or Instance.new("Folder")
	self.BaseFolder.Name = "Compounds"
	self.BaseFolder.Parent = workspace
	return self
end

local function makeLabel(parent: Instance, text: string, color: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 64)
	bb.AlwaysOnTop = true
	bb.StudsOffset = Vector3.new(0, 8, 0)
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(10, 10, 22)
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.Parent = bb
end

function BaseService:BuildCompound(index: number)
	local angle = ((index - 1) / GameConfig.MaxPlayers) * math.pi * 2
	local center = GameConfig.WorldCenter + Vector3.new(math.cos(angle) * GameConfig.BaseRadius, 0, math.sin(angle) * GameConfig.BaseRadius)

	local model = Instance.new("Model")
	model.Name = string.format("Compound_%d", index)

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Material = Enum.Material.Metal
	floor.Color = GameConfig.Palette.DarkSurface
	floor.Size = GameConfig.CompoundSize
	floor.Position = center
	floor.Parent = model

	local gate = Instance.new("Part")
	gate.Name = "Gate"
	gate.Anchored = true
	gate.Size = Vector3.new(18, 12, 2)
	gate.Position = center + Vector3.new(0, 6, -GameConfig.CompoundSize.Z * 0.5 + 1)
	gate.Material = Enum.Material.Neon
	gate.Color = GameConfig.Palette.ElectricBlue
	gate.Parent = model

	local storageAnchor = Instance.new("Part")
	storageAnchor.Name = "StorageAnchor"
	storageAnchor.Transparency = 1
	storageAnchor.Anchored = true
	storageAnchor.CanCollide = false
	storageAnchor.Size = Vector3.new(2, 2, 2)
	storageAnchor.Position = center + Vector3.new(0, 2, 6)
	storageAnchor.Parent = model

	local depositPad = Instance.new("Part")
	depositPad.Name = "DepositPad"
	depositPad.Shape = Enum.PartType.Cylinder
	depositPad.Orientation = Vector3.new(0, 0, 90)
	depositPad.Anchored = true
	depositPad.Material = Enum.Material.Neon
	depositPad.Color = GameConfig.Palette.NeonCyan
	depositPad.Size = Vector3.new(1.4, 8, 8)
	depositPad.Position = center + Vector3.new(-16, 0.7, 0)
	depositPad.Parent = model

	model.PrimaryPart = floor
	model.Parent = self.BaseFolder

	makeLabel(gate, "UNCLAIMED", GameConfig.Palette.BrightLine)

	return {
		Index = index,
		Model = model,
		Center = center,
		Owner = nil,
		StorageAnchor = storageAnchor,
		DepositPad = depositPad,
		StorageSlots = GameConfig.StorageSlotsDefault,
	}
end

function BaseService:Init()
	for i = 1, GameConfig.MaxPlayers do
		table.insert(self.OpenBases, self:BuildCompound(i))
	end
end

function BaseService:ClaimBase(player: Player)
	if self.BasesByPlayer[player] then
		return self.BasesByPlayer[player]
	end
	local base = table.remove(self.OpenBases, 1)
	if not base then
		return nil
	end
	base.Owner = player
	self.BasesByPlayer[player] = base
	base.Model.Gate.Color = GameConfig.TeamAccents[((base.Index - 1) % #GameConfig.TeamAccents) + 1]
	local labelGui = base.Model.Gate:FindFirstChildOfClass("BillboardGui")
	if labelGui and labelGui:FindFirstChildOfClass("TextLabel") then
		labelGui.TextLabel.Text = player.DisplayName .. "'s Compound"
		labelGui.TextLabel.TextColor3 = base.Model.Gate.Color
	end
	player:SetAttribute("BaseIndex", base.Index)
	return base
end

function BaseService:GetPlayerBase(player: Player)
	return self.BasesByPlayer[player]
end

function BaseService:ReleaseBase(player: Player)
	local base = self.BasesByPlayer[player]
	if not base then
		return
	end
	base.Owner = nil
	self.BasesByPlayer[player] = nil
	base.Model.Gate.Color = GameConfig.Palette.ElectricBlue
	table.insert(self.OpenBases, base)
end

Players.PlayerRemoving:Connect(function(player)
	if BaseService.Instance then
		BaseService.Instance:ReleaseBase(player)
	end
end)

function BaseService:StartSingleton()
	BaseService.Instance = self
end

return BaseService
