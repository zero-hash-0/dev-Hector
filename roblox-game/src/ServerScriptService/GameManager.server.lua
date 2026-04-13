-- GameManager.server.lua (Script)
-- Manages player sessions: loads/saves data, syncs state to clients,
-- maintains the in-game leaderboard, and runs the auto-save loop.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local SyncData  = Remotes:WaitForChild("SyncData")

-- ── Leaderboard setup ────────────────────────────────────────────────────────

local function getOrMakeStat(leaderstats, name, class)
    local s = leaderstats:FindFirstChild(name)
    if not s then
        s = Instance.new(class)
        s.Name   = name
        s.Parent = leaderstats
    end
    return s
end

local function refreshLeaderboard(player: Player)
    local data = PlayerData:Get(player)
    if not data then return end

    local ls = player:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder")
        ls.Name   = "leaderstats"
        ls.Parent = player
    end

    getOrMakeStat(ls, "Coins", "IntValue").Value    = data.coins
    getOrMakeStat(ls, "Lifetime", "IntValue").Value = data.lifetime
    getOrMakeStat(ls, "Pets", "IntValue").Value     = #data.pets
end

-- ── Data sync helper ─────────────────────────────────────────────────────────
-- Sends a trimmed snapshot to the client. We strip BrickColor objects and
-- only send R/G/B so the data can cross the RemoteEvent boundary.

function SyncPlayerData(player: Player)
    local data = PlayerData:Get(player)
    if not data then return end

    -- Trim pets to what the client needs (avoid sending BrickColor userdata)
    local petSnapshot = {}
    for _, pet in ipairs(data.pets) do
        table.insert(petSnapshot, {
            name  = pet.name,
            multi = pet.multi,
            r     = pet.r,
            g     = pet.g,
            b     = pet.b,
        })
    end

    SyncData:FireClient(player, {
        coins    = data.coins,
        lifetime = data.lifetime,
        pets     = petSnapshot,
        upgrades = data.upgrades,
    })

    refreshLeaderboard(player)
end

-- Make accessible to other server scripts.
_G.SyncPlayerData = SyncPlayerData

-- ── Player lifecycle ─────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
    PlayerData:Load(player)
    SyncPlayerData(player)
end

local function onPlayerRemoving(player: Player)
    PlayerData:Save(player)
    PlayerData:Remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, p in ipairs(Players:GetPlayers()) do
    onPlayerAdded(p)
end

-- ── Auto-save loop (every 60 s) ───────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(60)
        for _, p in ipairs(Players:GetPlayers()) do
            PlayerData:Save(p)
        end
    end
end)
