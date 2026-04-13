-- SoundManager.client.lua (LocalScript)
-- Plays sound effects in response to the PlaySound RemoteEvent.
-- All audio is sourced from Roblox's free library; swap IDs from Creator Store.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig        = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local PlaySound  = Remotes:WaitForChild("PlaySound")
local LuckyClick = Remotes:WaitForChild("LuckyClick")

-- Pre-create one Sound instance per effect for zero-latency playback
local sounds: { [string]: Sound } = {}

for name, id in pairs(GameConfig.SOUNDS) do
    local s = Instance.new("Sound")
    s.Name     = name
    s.SoundId  = id  -- already a full path (rbxasset://) or asset ID
    s.Volume   = (name == "click") and 0.35 or 0.6
    s.RollOffMaxDistance = 0
    s.Parent   = game:GetService("SoundService")
    sounds[name] = s
end

PlaySound.OnClientEvent:Connect(function(name: string)
    local s = sounds[name]
    if s then s:Play() end
end)

-- Lucky click also triggers sound (in case server fires both events simultaneously)
LuckyClick.OnClientEvent:Connect(function()
    local s = sounds["lucky"]
    if s then s:Play() end
end)
