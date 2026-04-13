--!strict

local EventService = {}
EventService.__index = EventService

function EventService.new(remotes)
	local self = setmetatable({}, EventService)
	self.Remotes = remotes
	self.EventPool = {
		{ Name = "Double Income", Duration = 45 },
		{ Name = "Vault Doors Open", Duration = 30 },
		{ Name = "Chaos Minute", Duration = 60 },
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
		end
	end)
end

return EventService
