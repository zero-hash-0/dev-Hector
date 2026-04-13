-- ClickManager.server.lua (Script)
-- Handles manual click events and the auto-clicker upgrade tick.
-- Awards coins per click = (BASE + click_power level) * rebirth multiplier.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local ClickOrb  = Remotes:WaitForChild("ClickOrb")

-- ── Per-player click cooldown ─────────────────────────────────────────────────

local lastClick: { [number]: number } = {}

local function coinsForClick(player: Player): number
    local level = PlayerData:GetUpgradeLevel(player, "click_power")
    return GameConfig.BASE_COINS_PER_CLICK + level
end

local function handleClick(player: Player)
    local now = tick()
    if (now - (lastClick[player.UserId] or 0)) < GameConfig.CLICK_COOLDOWN then
        return  -- silently ignore; client already throttles
    end
    lastClick[player.UserId] = now

    local earned = coinsForClick(player)
    PlayerData:AddCoins(player, earned)

    -- Sync back immediately so the coin counter feels responsive.
    if _G.SyncPlayerData then _G.SyncPlayerData(player) end
end

ClickOrb.OnServerEvent:Connect(handleClick)

-- ── Auto-clicker upgrade ──────────────────────────────────────────────────────
-- Each level of "auto_click" fires one server-side click per second.

task.spawn(function()
    while true do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            local level = PlayerData:GetUpgradeLevel(player, "auto_click")
            if level > 0 then
                for _ = 1, level do
                    PlayerData:AddCoins(player, coinsForClick(player))
                end
                if _G.SyncPlayerData then _G.SyncPlayerData(player) end
            end
        end
    end
end)

-- ── Cleanup ───────────────────────────────────────────────────────────────────

Players.PlayerRemoving:Connect(function(player)
    lastClick[player.UserId] = nil
end)
