--!strict

local Players = game:GetService("Players")

local CurrencyService = {}
CurrencyService.__index = CurrencyService

function CurrencyService.new(remotes)
	local self = setmetatable({}, CurrencyService)
	self.Balances = {}
	self.Remotes = remotes
	return self
end

function CurrencyService:Init()
	Players.PlayerAdded:Connect(function(player)
		self.Balances[player] = 150
		player:SetAttribute("Money", 150)
		self.Remotes.HUD:FireClient(player, {
			Money = 150,
		})
	end)

	Players.PlayerRemoving:Connect(function(player)
		self.Balances[player] = nil
	end)
end

function CurrencyService:Get(player: Player): number
	return self.Balances[player] or 0
end

function CurrencyService:Add(player: Player, amount: number)
	local total = self:Get(player) + amount
	self.Balances[player] = total
	player:SetAttribute("Money", total)
	self.Remotes.HUD:FireClient(player, { Money = total })
end

function CurrencyService:Spend(player: Player, amount: number): boolean
	local balance = self:Get(player)
	if balance < amount then
		return false
	end
	local total = balance - amount
	self.Balances[player] = total
	player:SetAttribute("Money", total)
	self.Remotes.HUD:FireClient(player, { Money = total })
	return true
end

return CurrencyService
