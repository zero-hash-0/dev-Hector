-- RebirthManager.server.lua (Script)
-- Handles rebirth requests from clients.
-- Each rebirth: costs coins, resets to 0, grants a permanent income multiplier.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local RebirthRF    = Remotes:WaitForChild("Rebirth")
local Notification = Remotes:WaitForChild("Notification")
local PlaySound    = Remotes:WaitForChild("PlaySound")

local function rebirthCost(rebirths: number): number
    return math.floor(GameConfig.REBIRTH_BASE_COST * (GameConfig.REBIRTH_COST_MULT ^ rebirths))
end

-- Expose cost so MainUI can display it without a round-trip.
_G.GetRebirthCost = rebirthCost

RebirthRF.OnServerInvoke = function(player: Player)
    local data = PlayerData:Get(player)
    if not data then return { success = false, message = "Data not loaded." } end

    local cost = rebirthCost(data.rebirths)

    if data.coins < cost then
        return { success = false, message = ("Need %d coins to rebirth!"):format(cost) }
    end

    -- Apply rebirth: wipe coins, keep pets/upgrades, increment counter.
    data.coins    = 0
    data.rebirths = data.rebirths + 1

    PlaySound:FireClient(player, "rebirth")
    Notification:FireClient(player,
        ("✨ Rebirth #%d! All income is now %d×!"):format(
            data.rebirths,
            GameConfig.REBIRTH_BONUS ^ data.rebirths
        )
    )

    if _G.SyncPlayerData then _G.SyncPlayerData(player) end

    return { success = true, rebirths = data.rebirths }
end
