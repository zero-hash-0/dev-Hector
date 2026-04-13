-- ClickManager.server.lua (Script)
-- Awards coins on click with rebirth multiplier and lucky click chance.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local ClickOrb    = Remotes:WaitForChild("ClickOrb")
local LuckyClick  = Remotes:WaitForChild("LuckyClick")
local PlaySound   = Remotes:WaitForChild("PlaySound")

local lastClick: { [number]: number } = {}

local function rebirthMult(data): number
    return GameConfig.REBIRTH_BONUS ^ (data.rebirths or 0)
end

local function baseClickCoins(player: Player): number
    local level = PlayerData:GetUpgradeLevel(player, "click_power")
    return GameConfig.BASE_COINS_PER_CLICK + level
end

local function handleClick(player: Player)
    local now = tick()
    if (now - (lastClick[player.UserId] or 0)) < GameConfig.CLICK_COOLDOWN then return end
    lastClick[player.UserId] = now

    local data = PlayerData:Get(player)
    if not data then return end

    local earned = baseClickCoins(player) * rebirthMult(data)

    -- Lucky click check
    local isLucky = math.random() < GameConfig.LUCKY_CHANCE
    if isLucky then
        earned = earned * GameConfig.LUCKY_MULT
        LuckyClick:FireClient(player, earned)
        PlaySound:FireClient(player, "lucky")
    else
        PlaySound:FireClient(player, "click")
    end

    earned = math.max(1, math.floor(earned))
    PlayerData:AddCoins(player, earned)

    if _G.SyncPlayerData then _G.SyncPlayerData(player) end
end

ClickOrb.OnServerEvent:Connect(handleClick)

-- ── Auto-clicker upgrade tick ────────────────────────────────────────────────
task.spawn(function()
    while true do
        task.wait(1)
        for _, player in ipairs(Players:GetPlayers()) do
            local level = PlayerData:GetUpgradeLevel(player, "auto_click")
            if level > 0 then
                local data = PlayerData:Get(player)
                if data then
                    local earned = math.floor(baseClickCoins(player) * level * rebirthMult(data))
                    PlayerData:AddCoins(player, earned)
                    if _G.SyncPlayerData then _G.SyncPlayerData(player) end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) lastClick[p.UserId] = nil end)
