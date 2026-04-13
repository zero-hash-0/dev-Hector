--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local RaidService = {}
RaidService.__index = RaidService

function RaidService.new(baseService, brainrotService, remotes)
	local self = setmetatable({}, RaidService)
	self.BaseService = baseService
	self.BrainrotService = brainrotService
	self.Remotes = remotes
	self.CarriedByPlayer = {}
	return self
end

function RaidService:Init()
	self.Remotes.StealRequest.OnServerEvent:Connect(function(player, brainrotModel)
		self:TryPickup(player, brainrotModel)
	end)

	self.Remotes.DepositRequest.OnServerEvent:Connect(function(player)
		self:TryDeposit(player)
	end)
end

function RaidService:ApplyCarryStats(player: Player, carrying: boolean)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if carrying then
		humanoid.WalkSpeed = 16 * GameConfig.CarrySpeedMultiplier
		humanoid.JumpPower = 50 * GameConfig.CarryJumpPowerMultiplier
	else
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end

function RaidService:TryPickup(player: Player, brainrotModel: Model)
	if not brainrotModel or self.CarriedByPlayer[player] then return end
	if brainrotModel:GetAttribute("CarriedBy") then return end
	local owner = self.BrainrotService:GetOwner(brainrotModel)
	if owner == player then return end
	brainrotModel:SetAttribute("CarriedBy", player.UserId)
	self.CarriedByPlayer[player] = brainrotModel

	local core = brainrotModel:FindFirstChild("Core")
	if core and core:IsA("BasePart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		core.Anchored = false
		core.CanCollide = false
		local weld = Instance.new("WeldConstraint")
		weld.Name = "CarryWeld"
		weld.Part0 = core
		weld.Part1 = player.Character.HumanoidRootPart
		weld.Parent = core
		core.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
	end

	self:ApplyCarryStats(player, true)
	self.Remotes.Alert:FireAllClients({
		Type = "Steal",
		Message = string.format("%s stole %s!", player.DisplayName, brainrotModel.Name),
	})
	self.Remotes.HUD:FireClient(player, { Carrying = brainrotModel.Name })
end

function RaidService:DropCarried(player: Player)
	local model = self.CarriedByPlayer[player]
	if not model then return end
	self.CarriedByPlayer[player] = nil
	model:SetAttribute("CarriedBy", nil)

	local core = model:FindFirstChild("Core")
	if core and core:IsA("BasePart") then
		local weld = core:FindFirstChild("CarryWeld")
		if weld then weld:Destroy() end
		core.Anchored = true
		core.CanCollide = true
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			core.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 1, -4)
		end
	end

	self:ApplyCarryStats(player, false)
	self.Remotes.HUD:FireClient(player, { Carrying = "None" })
end

function RaidService:TryDeposit(player: Player)
	local carrying = self.CarriedByPlayer[player]
	local base = self.BaseService:GetPlayerBase(player)
	if not carrying or not base or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local dist = (player.Character.HumanoidRootPart.Position - base.DepositPad.Position).Magnitude
	if dist > 12 then return end

	local previousOwner = self.BrainrotService:GetOwner(carrying)
	if previousOwner then
		local oldBase = self.BaseService:GetPlayerBase(previousOwner)
		if oldBase and self.BrainrotService.BrainrotsByBase[oldBase] then
			local kept = {}
			for _, item in ipairs(self.BrainrotService.BrainrotsByBase[oldBase]) do
				if item ~= carrying then table.insert(kept, item) end
			end
			self.BrainrotService.BrainrotsByBase[oldBase] = kept
			self.BrainrotService:PushStorageCount(previousOwner)
		end
	end

	self.CarriedByPlayer[player] = nil
	carrying:SetAttribute("OwnerUserId", player.UserId)
	carrying:SetAttribute("CarriedBy", nil)
	local core = carrying:FindFirstChild("Core")
	if core and core:IsA("BasePart") then
		local weld = core:FindFirstChild("CarryWeld")
		if weld then weld:Destroy() end
		core.Anchored = true
		core.CanCollide = true
		core.Position = base.StorageAnchor.Position + Vector3.new(math.random(-8, 8), 2.4, math.random(-8, 8))
	end
	self.BrainrotService.BrainrotsByBase[base] = self.BrainrotService.BrainrotsByBase[base] or {}
	table.insert(self.BrainrotService.BrainrotsByBase[base], carrying)
	self.BrainrotService:PushStorageCount(player)
	self:ApplyCarryStats(player, false)
	self.Remotes.HUD:FireClient(player, { Carrying = "None" })
	self.Remotes.Alert:FireAllClients({
		Type = "Deposit",
		Message = string.format("%s secured %s", player.DisplayName, carrying.Name),
	})
end

Players.PlayerRemoving:Connect(function(player)
	if RaidService.Instance then
		RaidService.Instance:DropCarried(player)
	end
end)

function RaidService:StartSingleton()
	RaidService.Instance = self
end

return RaidService
