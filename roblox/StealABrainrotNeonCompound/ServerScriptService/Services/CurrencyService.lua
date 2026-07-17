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
	Players.PlayerRemoving:Connect(function(player)
		self.Balances[player] = nil
	end)
end

-- Starting balance comes from the player's saved profile (see DataService),
-- so there is no PlayerAdded default here.
function CurrencyService:SetBalance(player: Player, amount: number)
	self.Balances[player] = amount
	player:SetAttribute("Money", amount)
	self.Remotes.HUD:FireClient(player, { Money = amount })
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
