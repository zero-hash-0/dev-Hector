-- GameManager.server.lua (Script)
-- Player sessions, data sync, leaderboard stat updates, world leaderboard.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local SyncData = Remotes:WaitForChild("SyncData")

-- ── Number formatter (server-side copy) ─────────────────────────────────────

local function fmt(n: number): string
    if     n >= 1e12 then return ("%.1fT"):format(n/1e12)
    elseif n >= 1e9  then return ("%.1fB"):format(n/1e9)
    elseif n >= 1e6  then return ("%.1fM"):format(n/1e6)
    elseif n >= 1e3  then return ("%.1fK"):format(n/1e3)
    else   return tostring(math.floor(n)) end
end

-- ── Leaderstats ───────────────────────────────────────────────────────────────

local function getStat(ls, name, class)
    local s = ls:FindFirstChild(name)
    if not s then s = Instance.new(class); s.Name = name; s.Parent = ls end
    return s
end

local function refreshLeaderboard(player: Player)
    local data = PlayerData:Get(player)
    if not data then return end
    local ls = player:FindFirstChild("leaderstats")
    if not ls then ls = Instance.new("Folder"); ls.Name="leaderstats"; ls.Parent=player end
    getStat(ls,"Coins","IntValue").Value    = data.coins
    getStat(ls,"Lifetime","IntValue").Value = data.lifetime
    getStat(ls,"Rebirths","IntValue").Value = data.rebirths or 0
    getStat(ls,"Pets","IntValue").Value     = #data.pets
end

-- ── Sync helper (accessible to other scripts via _G) ─────────────────────────

function SyncPlayerData(player: Player)
    local data = PlayerData:Get(player)
    if not data then return end

    local petSnap = {}
    for _, pet in ipairs(data.pets) do
        table.insert(petSnap, { name=pet.name, multi=pet.multi, r=pet.r, g=pet.g, b=pet.b })
    end

    SyncData:FireClient(player, {
        coins    = data.coins,
        lifetime = data.lifetime,
        rebirths = data.rebirths or 0,
        pets     = petSnap,
        upgrades = data.upgrades,
    })

    refreshLeaderboard(player)
end

_G.SyncPlayerData = SyncPlayerData

-- ── Player lifecycle ──────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
    PlayerData:Load(player)
    SyncPlayerData(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(p) PlayerData:Save(p); PlayerData:Remove(p) end)

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

-- ── Auto-save (60 s) ──────────────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(60)
        for _, p in ipairs(Players:GetPlayers()) do PlayerData:Save(p) end
    end
end)

-- ── World leaderboard updater (every 10 s) ────────────────────────────────────

task.spawn(function()
    -- Wait for MapGenerator to expose the gui reference
    local gui
    for _ = 1, 20 do
        gui = _G.LeaderboardGui
        if gui then break end
        task.wait(0.5)
    end
    if not gui then return end

    while true do
        -- Collect active player totals
        local entries = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local data = PlayerData:Get(player)
            if data then
                table.insert(entries, {
                    name     = player.Name,
                    lifetime = data.lifetime,
                    rebirths = data.rebirths or 0,
                })
            end
        end

        table.sort(entries, function(a, b) return a.lifetime > b.lifetime end)

        for i = 1, 5 do
            local row = gui:FindFirstChild("Row_" .. i)
            if row then
                local e = entries[i]
                if e then
                    local rebStr = e.rebirths > 0 and (" ✨"..e.rebirths) or ""
                    row.Text = ("#%d  %s%s\n🪙 %s"):format(i, e.name, rebStr, fmt(e.lifetime))
                else
                    row.Text = "#" .. i .. "  ---"
                end
            end
        end

        task.wait(10)
    end
end)
