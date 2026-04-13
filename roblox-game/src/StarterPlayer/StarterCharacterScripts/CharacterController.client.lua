-- CharacterController.client.lua (LocalScript – runs inside each character)
-- Kills the character when it falls below the void height so it respawns at
-- the last checkpoint immediately rather than waiting to sink out of view.

local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local character         = script.Parent
local humanoid          = character:WaitForChild("Humanoid")
local humanoidRootPart  = character:WaitForChild("HumanoidRootPart")

local VOID_Y = GameConfig.VOID_HEIGHT

-- Poll every frame; bail out once the humanoid is dead or the script is destroyed.
local connection: RBXScriptConnection
connection = RunService.Heartbeat:Connect(function()
    if not humanoid or humanoid.Health <= 0 then
        connection:Disconnect()
        return
    end

    if humanoidRootPart.Position.Y < VOID_Y then
        humanoid.Health = 0
        connection:Disconnect()
    end
end)
