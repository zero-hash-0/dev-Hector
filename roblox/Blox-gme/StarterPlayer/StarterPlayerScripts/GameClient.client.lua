--!strict

-- Client entry point — handles HUD and input.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HUDRemote   = Remotes:WaitForChild("HUD")   :: RemoteEvent
local AlertRemote = Remotes:WaitForChild("Alert") :: RemoteEvent

-- HUD updates from server
HUDRemote.OnClientEvent:Connect(function(data: { [string]: any })
	-- TODO: update HUD ScreenGui elements with data
	print("[HUD]", data)
end)

-- Alert messages from server
AlertRemote.OnClientEvent:Connect(function(data: { Type: string, Message: string })
	-- TODO: display toast/notification in UI
	print(string.format("[%s] %s", data.Type, data.Message))
end)
