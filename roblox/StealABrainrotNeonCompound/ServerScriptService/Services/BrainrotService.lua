--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotConfig = require(ReplicatedStorage.Modules.BrainrotConfig)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local BrainrotService = {}
BrainrotService.__index = BrainrotService

function BrainrotService.new(baseService, currencyService, remotes)
	local self = setmetatable({}, BrainrotService)
	self.BaseService = baseService
	self.CurrencyService = currencyService
	self.Remotes = remotes
	self.BrainrotsByBase = {}
	self.ActiveIncome = {}
	return self
end

local function makePrompt(part: BasePart)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = "Brainrot"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.25
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = part
	return prompt
end

function BrainrotService:CreateBrainrotModel(def, base, slotIndex)
	local model = Instance.new("Model")
	model.Name = def.Id

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.Shape = def.Shape
	core.Material = Enum.Material.Neon
	core.Size = def.Size
	core.Color = GameConfig.RarityColors[def.Rarity]
	core.Parent = model

	local slotOffset = Vector3.new(((slotIndex - 1) % 3) * 8 - 8, 2.4, math.floor((slotIndex - 1) / 3) * 8)
	core.Position = base.StorageAnchor.Position + slotOffset

	local rarityRing = Instance.new("Highlight")
	rarityRing.FillTransparency = 0.86
	rarityRing.OutlineColor = GameConfig.RarityColors[def.Rarity]
	rarityRing.Parent = model

	local prompt = makePrompt(core)
	prompt.ObjectText = def.DisplayName

	model:SetAttribute("BrainrotId", def.Id)
	model:SetAttribute("Rarity", def.Rarity)
	model:SetAttribute("Income", def.IncomePerSecond)
	model:SetAttribute("Value", def.BaseValue)
	model:SetAttribute("OwnerUserId", base.Owner and base.Owner.UserId or 0)
	CollectionService:AddTag(model, "Brainrot")

	model.Parent = workspace:FindFirstChild("Brainrots") or Instance.new("Folder", workspace)
	model.Parent.Name = "Brainrots"

	return model
end

function BrainrotService:GrantStarterSet(player: Player)
	local base = self.BaseService:GetPlayerBase(player)
	if not base then
		return
	end
	self.BrainrotsByBase[base] = self.BrainrotsByBase[base] or {}
	for _, brainrotId in ipairs(BrainrotConfig.StarterSet) do
		local def = BrainrotConfig[brainrotId]
		local model = self:CreateBrainrotModel(def, base, #self.BrainrotsByBase[base] + 1)
		table.insert(self.BrainrotsByBase[base], model)
	end
	self:PushStorageCount(player)
end

function BrainrotService:PushStorageCount(player: Player)
	local base = self.BaseService:GetPlayerBase(player)
	if not base then return end
	local list = self.BrainrotsByBase[base] or {}
	self.Remotes.HUD:FireClient(player, {
		Storage = #list,
		StorageSlots = base.StorageSlots,
	})
end

function BrainrotService:GetOwner(model: Model): Player?
	local ownerId = model:GetAttribute("OwnerUserId")
	if typeof(ownerId) ~= "number" then return nil end
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		if plr.UserId == ownerId then return plr end
	end
	return nil
end

function BrainrotService:StartIncomeLoop()
	self.ActiveIncome = self.ActiveIncome or {}
	task.spawn(function()
		while true do
			task.wait(GameConfig.IncomeTickSeconds)
			for base, list in pairs(self.BrainrotsByBase) do
				local owner = base.Owner
				if owner and list then
					local income = 0
					for _, model in ipairs(list) do
						if model.Parent then
							income += model:GetAttribute("Income") or 0
						end
					end
					if income > 0 then
						self.CurrencyService:Add(owner, income)
					end
				end
			end
		end
	end)

	RunService.Heartbeat:Connect(function(timeStep)
		for _, tagged in ipairs(CollectionService:GetTagged("Brainrot")) do
			local core = tagged:FindFirstChild("Core")
			if core and core:IsA("BasePart") and not tagged:GetAttribute("CarriedBy") then
				local spin = BrainrotConfig[tagged:GetAttribute("BrainrotId")].SpinSpeed
				core.CFrame *= CFrame.Angles(0, math.rad(spin * timeStep), 0)
			end
		end
	end)
end

return BrainrotService
