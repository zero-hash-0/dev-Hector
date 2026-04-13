-- PlayerData.lua (ModuleScript – lives in ServerScriptService)
-- Central store for per-player game state.
-- Require this module from any server script that needs to read or write stage data.

local PlayerData = {}

local data = {}  -- [userId] = { stage = number }

--- Set the current stage for a player.
function PlayerData:SetStage(player: Player, stage: number)
    if not data[player.UserId] then
        data[player.UserId] = {}
    end
    data[player.UserId].stage = stage
end

--- Get the current stage for a player (defaults to 1 if not set).
function PlayerData:GetStage(player: Player): number
    return data[player.UserId] and data[player.UserId].stage or 1
end

--- Clean up when a player leaves.
function PlayerData:Remove(player: Player)
    data[player.UserId] = nil
end

return PlayerData
