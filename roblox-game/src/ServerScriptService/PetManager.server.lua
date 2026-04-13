-- PetManager.server.lua (Script)
-- Passive income from pets, rebirth multiplier applied, orbiting pet visuals.

local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService          = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

-- ── Passive income tick ───────────────────────────────────────────────────────

task.spawn(function()
    while true do
        task.wait(GameConfig.PASSIVE_TICK)
        for _, player in ipairs(Players:GetPlayers()) do
            local data = PlayerData:Get(player)
            if not data then continue end

            local totalMulti = 0
            local cap = math.min(#data.pets, GameConfig.MAX_PETS)
            for i = 1, cap do
                totalMulti = totalMulti + (data.pets[i].multi or 0)
            end

            local magnetLevel  = PlayerData:GetUpgradeLevel(player, "passive_boost")
            local magnetMult   = 2 ^ magnetLevel
            local rebirthMult  = GameConfig.REBIRTH_BONUS ^ (data.rebirths or 0)

            local earned = math.floor(totalMulti * magnetMult * rebirthMult)
            if earned > 0 then
                PlayerData:AddCoins(player, earned)
                if _G.SyncPlayerData then _G.SyncPlayerData(player) end
            end
        end
    end
end)

-- ── Pet orbit visuals ─────────────────────────────────────────────────────────

local petParts: { [number]: { Part } } = {}

local function removePetParts(userId: number)
    if petParts[userId] then
        for _, p in ipairs(petParts[userId]) do p:Destroy() end
        petParts[userId] = nil
    end
end

local function spawnPetParts(player: Player)
    removePetParts(player.UserId)
    local data = PlayerData:Get(player)
    if not data then return end

    local parts = {}
    local cap   = math.min(#data.pets, GameConfig.MAX_PETS)

    for i = 1, cap do
        local pet  = data.pets[i]
        local part = Instance.new("Part")
        part.Name       = "PetOrb_" .. pet.name
        part.Shape      = Enum.PartType.Ball
        part.Size       = Vector3.new(1.5, 1.5, 1.5)
        part.Color      = Color3.fromRGB(pet.r or 200, pet.g or 200, pet.b or 200)
        part.Material   = Enum.Material.Neon
        part.Anchored   = false
        part.CanCollide = false
        part.CastShadow = false
        part.Parent     = workspace

        -- Name label
        local bg  = Instance.new("BillboardGui")
        bg.Size         = UDim2.new(0, 60, 0, 18)
        bg.StudsOffset  = Vector3.new(0, 1.4, 0)
        bg.AlwaysOnTop  = false
        bg.Parent       = part

        local lbl = Instance.new("TextLabel")
        lbl.Size                  = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font                  = Enum.Font.GothamBold
        lbl.TextScaled            = true
        lbl.TextColor3            = Color3.fromRGB(255, 255, 255)
        lbl.Text                  = pet.name
        lbl.Parent                = bg

        parts[i] = part
    end

    petParts[player.UserId] = parts
end

local TAU = math.pi * 2

RunService.Heartbeat:Connect(function()
    local t = tick()
    for _, player in ipairs(Players:GetPlayers()) do
        local parts = petParts[player.UserId]
        if not parts then continue end
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local origin = hrp.Position + Vector3.new(0, 1, 0)
        local count  = #parts
        for i, part in ipairs(parts) do
            local angle = TAU * (i - 1) / count + t * 1.2
            local x = origin.X + math.cos(angle) * 3.5
            local z = origin.Z + math.sin(angle) * 3.5
            local y = origin.Y + math.sin(t * 2 + i) * 0.4
            part.CFrame = CFrame.new(x, y, z)
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        spawnPetParts(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePetParts(player.UserId)
end)

_G.RefreshPetOrbs = spawnPetParts
