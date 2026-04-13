-- GameManager.server.lua (Script)
-- Bootstraps player sessions: initialises stage data, respawns players at their
-- last checkpoint, and fires RemoteEvents so clients can update their UI.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStage   = RemoteEvents:WaitForChild("UpdateStage")
local GameComplete  = RemoteEvents:WaitForChild("GameComplete")

-- Teleport a character to its current stage checkpoint (called after each respawn).
local function spawnAtCheckpoint(player: Player)
    local character = player.Character
    if not character then return end

    local stage      = PlayerData:GetStage(player)
    local checkpoint = workspace:FindFirstChild("Checkpoint_" .. stage)
    local hrp        = character:FindFirstChild("HumanoidRootPart")

    if checkpoint and hrp then
        hrp.CFrame = checkpoint.CFrame + Vector3.new(0, 5, 0)
    end
end

local function onPlayerAdded(player: Player)
    PlayerData:SetStage(player, 1)

    player.CharacterAdded:Connect(function(_character)
        -- Brief wait for the physics simulation to settle before teleporting.
        task.wait(0.5)
        spawnAtCheckpoint(player)
        UpdateStage:FireClient(player, PlayerData:GetStage(player))
    end)
end

local function onPlayerRemoving(player: Player)
    PlayerData:Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who were already in the server before this script ran.
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
