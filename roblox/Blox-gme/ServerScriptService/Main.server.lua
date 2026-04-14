--!strict

-- Entry point — wires all services together.

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Remotes setup
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function ensureRemote(name: string): RemoteEvent
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote :: RemoteEvent
end

local Remotes = {
	HUD   = ensureRemote("HUD"),
	Alert = ensureRemote("Alert"),
}

-- Services
local Services = ServerScriptService:WaitForChild("Services")

local PlayerService = require(Services.PlayerService)
local WorldService  = require(Services.WorldService)

local worldService = WorldService.new()
worldService:BuildMap()
worldService:ApplyLighting()

local playerService = PlayerService.new(Remotes)
playerService:Init()
