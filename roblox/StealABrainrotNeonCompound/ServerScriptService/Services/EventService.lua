--!strict

local CollectionService = game:GetService("CollectionService")

local EventService = {}
EventService.__index = EventService

local function setAllPromptHoldDurations(duration: number)
	for _, model in ipairs(CollectionService:GetTagged("Brainrot")) do
		local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			prompt.HoldDuration = duration
		end
	end
end

function EventService.new(remotes)
	local self = setmetatable({}, EventService)
	self.Remotes = remotes
	self.EventPool = {
		{
			Name = "Double Income",
			Duration = 45,
			Start = function()
				workspace:SetAttribute("GlobalIncomeMultiplier", 2)
			end,
			Stop = function()
				workspace:SetAttribute("GlobalIncomeMultiplier", 1)
			end,
		},
		{
			Name = "Vault Doors Open",
			Duration = 30,
			Start = function()
				workspace:SetAttribute("InstantSteals", true)
				setAllPromptHoldDurations(0)
			end,
			Stop = function()
				workspace:SetAttribute("InstantSteals", false)
				setAllPromptHoldDurations(0.25)
			end,
		},
		{
			Name = "Chaos Minute",
			Duration = 60,
			Start = function()
				workspace:SetAttribute("ChaosMode", true)
			end,
			Stop = function()
				workspace:SetAttribute("ChaosMode", false)
			end,
		},
	}
	return self
end

function EventService:Init()
	task.spawn(function()
		while true do
			task.wait(180)
			local picked = self.EventPool[math.random(1, #self.EventPool)]
			self.Remotes.Alert:FireAllClients({
				Type = "Event",
				Message = string.format("WORLD EVENT: %s (%ss)", picked.Name, picked.Duration),
			})
			self.Remotes.HUD:FireAllClients({ Event = picked.Name })
			picked.Start()
			task.wait(picked.Duration)
			picked.Stop()
			self.Remotes.HUD:FireAllClients({ Event = "None" })
			self.Remotes.Alert:FireAllClients({
				Type = "Event",
				Message = string.format("%s has ended", picked.Name),
			})
		end
	end)
end

return EventService
