-- PlayerData.lua (ModuleScript – ServerScriptService)
-- In-memory player state with optional DataStore persistence.
-- Gracefully degrades to session-only if DataStore is unavailable.

local DataStoreService = game:GetService("DataStoreService")

local PlayerData = {}

-- ── Storage ───────────────────────────────────────────────────────────────────

local cache: { [number]: any } = {}

local ok, store = pcall(function()
    return DataStoreService:GetDataStore("CoinSim_v1")
end)
if not ok then store = nil end

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function defaultData()
    return {
        coins    = 0,
        lifetime = 0,   -- total coins ever earned (used for leaderboard)
        pets     = {},  -- array of { name, multi, r, g, b }
        upgrades = {},  -- { [upgradeId] = level }
    }
end

local function merge(base, saved)
    -- Carry saved values into a fresh default so new keys always exist.
    for k, v in pairs(saved) do
        base[k] = v
    end
    return base
end

-- ── Public API ────────────────────────────────────────────────────────────────

function PlayerData:Load(player: Player)
    local data = defaultData()

    if store then
        local saveOk, saved = pcall(function()
            return store:GetAsync("p_" .. player.UserId)
        end)
        if saveOk and type(saved) == "table" then
            data = merge(data, saved)
        end
    end

    cache[player.UserId] = data
    return data
end

function PlayerData:Save(player: Player)
    local data = cache[player.UserId]
    if not data or not store then return end
    pcall(function() store:SetAsync("p_" .. player.UserId, data) end)
end

function PlayerData:Get(player: Player)
    return cache[player.UserId]
end

function PlayerData:Remove(player: Player)
    cache[player.UserId] = nil
end

-- Convenience: add coins and update lifetime total.
function PlayerData:AddCoins(player: Player, amount: number)
    local data = cache[player.UserId]
    if not data then return end
    data.coins    = data.coins    + amount
    data.lifetime = data.lifetime + amount
end

-- Convenience: deduct coins; returns false if not enough.
function PlayerData:SpendCoins(player: Player, amount: number): boolean
    local data = cache[player.UserId]
    if not data or data.coins < amount then return false end
    data.coins = data.coins - amount
    return true
end

-- Convenience: get upgrade level (defaults to 0).
function PlayerData:GetUpgradeLevel(player: Player, id: string): number
    local data = cache[player.UserId]
    if not data then return 0 end
    return data.upgrades[id] or 0
end

return PlayerData
