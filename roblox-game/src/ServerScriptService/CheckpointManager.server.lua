-- CheckpointManager.server.lua (Script)
-- Listens for players touching checkpoint parts and advances their stage.
-- Checkpoint parts must be named "Checkpoint_N" (e.g. Checkpoint_1, Checkpoint_2).

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local UpdateStage  = RemoteEvents:WaitForChild("UpdateStage")
local GameComplete = RemoteEvents:WaitForChild("GameComplete")

-- Per-player cooldown table to prevent the Touched event firing dozens of times.
local cooldowns: { [string]: boolean } = {}

local function onCheckpointTouched(stageNumber: number, hit: BasePart)
    local character = hit.Parent
    local player    = Players:GetPlayerFromCharacter(character)
    if not player then return end

    -- Debounce: one fire per player per checkpoint per second.
    local key = tostring(player.UserId) .. "_" .. stageNumber
    if cooldowns[key] then return end
    cooldowns[key] = true
    task.delay(1, function() cooldowns[key] = nil end)

    local currentStage = PlayerData:GetStage(player)

    -- Only advance when the player touches the *next* checkpoint in sequence.
    if stageNumber ~= currentStage + 1 then return end

    PlayerData:SetStage(player, stageNumber)
    UpdateStage:FireClient(player, stageNumber)
    print(("[Checkpoint] %s reached stage %d"):format(player.Name, stageNumber))

    -- Win condition: player finished the last stage.
    if stageNumber >= GameConfig.MAX_STAGES then
        GameComplete:FireClient(player)
        print(("[Checkpoint] %s COMPLETED THE OBBY!"):format(player.Name))

        -- Reset the player to stage 1 after a short celebration pause.
        task.delay(5, function()
            if player.Parent then  -- still in game
                PlayerData:SetStage(player, 1)
                UpdateStage:FireClient(player, 1)
                player:LoadCharacter()
            end
        end)
    end
end

-- Wire up Touched connections for a single checkpoint part.
local function connectCheckpoint(part: BasePart)
    local stageNumber = tonumber(part.Name:match("^Checkpoint_(%d+)$"))
    if not stageNumber then return end
    part.Touched:Connect(function(hit) onCheckpointTouched(stageNumber, hit) end)
end

-- Wait for MapGenerator to finish placing parts before scanning.
task.wait(2)

for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        connectCheckpoint(obj)
    end
end

-- Also connect any checkpoints added dynamically after the initial scan.
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") then
        connectCheckpoint(obj)
    end
end)
