--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local CombatService = {}
CombatService.__index = CombatService

function CombatService.new(raidService, remotes)
	local self = setmetatable({}, CombatService)
	self.RaidService = raidService
	self.Remotes = remotes
	self.LastAttackAt = {}
	return self
end

function CombatService:Init()
	self.Remotes.AttackRequest.OnServerEvent:Connect(function(player)
		self:TryAttack(player)
	end)
end

function CombatService:TryAttack(attacker: Player)
	local now = os.clock()
	if (self.LastAttackAt[attacker] or 0) + GameConfig.AttackCooldown > now then return end
	self.LastAttackAt[attacker] = now

	local character = attacker.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local root = character.HumanoidRootPart

	for _, victim in ipairs(game:GetService("Players"):GetPlayers()) do
		if victim ~= attacker and victim.Character and victim.Character:FindFirstChild("HumanoidRootPart") then
			local targetRoot = victim.Character.HumanoidRootPart
			if (targetRoot.Position - root.Position).Magnitude <= GameConfig.AttackRange then
				local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid:TakeDamage(GameConfig.AttackDamage)
					targetRoot.AssemblyLinearVelocity += (targetRoot.Position - root.Position).Unit * 18 + Vector3.new(0, 8, 0)
				end
				if self.RaidService.CarriedByPlayer[victim] then
					self.RaidService:DropCarried(victim)
					self.Remotes.Alert:FireAllClients({
						Type = "Interrupt",
						Message = string.format("%s interrupted %s", attacker.DisplayName, victim.DisplayName),
					})
				end
			end
		end
	end
end

return CombatService
