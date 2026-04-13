-- ShopManager.server.lua (Script)
-- Handles the BuyItem RemoteFunction.
-- Supports two purchase types:
--   { type = "egg",     id = "basic" | "super" | "legendary" }
--   { type = "upgrade", id = "click_power" | "auto_click" | "passive_boost" }
-- Returns { success = bool, message = string, pet? = table }

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local BuyItem      = Remotes:WaitForChild("BuyItem")
local Notification = Remotes:WaitForChild("Notification")
local HatchReveal  = Remotes:WaitForChild("HatchReveal")

-- ── Helpers ───────────────────────────────────────────────────────────────────

local rng = Random.new()

-- Weighted random pick from a pet table.
local function rollPet(petTable: { any }): any
    local totalWeight = 0
    for _, p in ipairs(petTable) do totalWeight = totalWeight + p.weight end

    local roll = rng:NextNumber(0, totalWeight)
    local cumulative = 0
    for _, p in ipairs(petTable) do
        cumulative = cumulative + p.weight
        if roll <= cumulative then return p end
    end
    return petTable[#petTable]
end

local function findEgg(id: string)
    for _, egg in ipairs(GameConfig.EGGS) do
        if egg.id == id then return egg end
    end
end

local function findUpgrade(id: string)
    for _, upg in ipairs(GameConfig.UPGRADES) do
        if upg.id == id then return upg end
    end
end

local function upgradeCost(upg, level: number): number
    return math.floor(upg.baseCost * (upg.costMult ^ level))
end

-- ── Purchase handlers ─────────────────────────────────────────────────────────

local function buyEgg(player: Player, id: string)
    local egg = findEgg(id)
    if not egg then return { success = false, message = "Unknown egg." } end

    if not PlayerData:SpendCoins(player, egg.cost) then
        return { success = false, message = "Not enough coins!" }
    end

    local petTemplate = rollPet(egg.pets)
    local color       = petTemplate.color  -- BrickColor

    -- Store as R/G/B so it's serialisable across RemoteEvents.
    local c3 = color.Color
    local petRecord = {
        name  = petTemplate.name,
        multi = petTemplate.multi,
        r     = math.floor(c3.R * 255),
        g     = math.floor(c3.G * 255),
        b     = math.floor(c3.B * 255),
    }

    local data = PlayerData:Get(player)
    table.insert(data.pets, 1, petRecord)  -- newest pet first

    -- Refresh orbit visuals
    if _G.RefreshPetOrbs then _G.RefreshPetOrbs(player) end

    -- Sync data so coin counter and pet list update
    if _G.SyncPlayerData then _G.SyncPlayerData(player) end

    -- Fire dramatic hatch reveal to client
    HatchReveal:FireClient(player, petRecord, egg.id)

    return { success = true, message = "Hatched!", pet = petRecord }
end

local function buyUpgrade(player: Player, id: string)
    local upg = findUpgrade(id)
    if not upg then return { success = false, message = "Unknown upgrade." } end

    local level = PlayerData:GetUpgradeLevel(player, id)
    local cost  = upgradeCost(upg, level)

    if not PlayerData:SpendCoins(player, cost) then
        return { success = false, message = "Not enough coins!" }
    end

    local data = PlayerData:Get(player)
    data.upgrades[id] = level + 1

    if _G.SyncPlayerData then _G.SyncPlayerData(player) end

    Notification:FireClient(player, ("%s upgraded to level %d!"):format(upg.name, level + 1))

    return { success = true, message = "Upgraded!" }
end

-- ── RemoteFunction handler ────────────────────────────────────────────────────

BuyItem.OnServerInvoke = function(player: Player, payload)
    if type(payload) ~= "table" then
        return { success = false, message = "Bad request." }
    end

    if payload.type == "egg" then
        return buyEgg(player, tostring(payload.id))
    elseif payload.type == "upgrade" then
        return buyUpgrade(player, tostring(payload.id))
    end

    return { success = false, message = "Unknown purchase type." }
end
