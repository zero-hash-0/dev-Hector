-- WorldEffects.client.lua (LocalScript)
-- Animates egg models: gentle bobbing so they feel alive and clickable.

local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService  = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

-- ── Egg bob animation ─────────────────────────────────────────────────────────
-- Each egg model bobs up and down independently, offset in phase so they
-- don't all move in sync (looks more natural).

local BOB_SPEED = 1.1   -- full cycles per second
local BOB_AMP   = 0.28  -- studs of vertical travel

local eggModels = {}

for i, egg in ipairs(GameConfig.EGGS) do
    task.spawn(function()
        local model = workspace:WaitForChild("EggModel_" .. egg.id, 30)
        if not model then return end

        -- Stagger phase so eggs don't move in unison
        local phase = (i - 1) * (math.pi * 2 / #GameConfig.EGGS)
        local baseY = model.Position.Y

        table.insert(eggModels, {
            part  = model,
            baseY = baseY,
            t     = phase,
        })
    end)
end

RunService.Heartbeat:Connect(function(dt)
    for _, e in ipairs(eggModels) do
        if not e.part or not e.part.Parent then continue end
        e.t = e.t + dt * BOB_SPEED
        local newY = e.baseY + math.sin(e.t) * BOB_AMP
        local pos  = e.part.Position
        e.part.CFrame = CFrame.new(pos.X, newY, pos.Z)
    end
end)

-- ── Egg click flash ──────────────────────────────────────────────────────────
-- When a player clicks an egg model, emit a quick colour burst on the
-- ParticleEmitter that's already attached to it.

for _, egg in ipairs(GameConfig.EGGS) do
    task.spawn(function()
        local model = workspace:WaitForChild("EggModel_" .. egg.id, 30)
        if not model then return end
        local cd = model:WaitForChild("ClickDetector", 10)
        if not cd then return end

        local sparkle = model:FindFirstChild("EggSparkle")

        cd.MouseClick:Connect(function()
            if sparkle then sparkle:Emit(20) end
        end)
    end)
end

print("[WorldEffects] Egg animations ready.")
