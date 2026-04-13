-- ClickHandler.client.lua (LocalScript)
-- Detects clicks on the ClickOrb, fires server, plays particle/effects.

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService         = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Effects    = require(script.Parent:WaitForChild("Effects"))

local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local ClickOrb   = Remotes:WaitForChild("ClickOrb")
local LuckyClick = Remotes:WaitForChild("LuckyClick")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local orb: BasePart = workspace:WaitForChild("ClickOrb", 30)
if not orb then return end

local sparkle   = orb:WaitForChild("ClickSparkle")
local luckyBurst = orb:WaitForChild("LuckyBurst")
local originalSize = orb.Size

-- ── Client-side throttle ──────────────────────────────────────────────────────

local lastFire = 0

local function fireClick()
    local now = tick()
    if now - lastFire < GameConfig.CLICK_COOLDOWN then return end
    lastFire = now

    ClickOrb:FireServer()

    -- Orb squeeze animation
    TweenService:Create(orb,
        TweenInfo.new(0.06, Enum.EasingStyle.Quad),
        { Size = originalSize * 1.14 }
    ):Play()
    task.delay(0.06, function()
        TweenService:Create(orb,
            TweenInfo.new(0.14, Enum.EasingStyle.Back),
            { Size = originalSize }
        ):Play()
    end)

    -- Sparkle burst
    sparkle:Emit(12)

    -- Floating coin text near orb
    Effects.floatingText(orb.Position + Vector3.new(0, 4, 0), "+coins",
        Color3.fromRGB(255, 215, 0))
end

-- ── Lucky click visual (server confirms) ────────────────────────────────────

LuckyClick.OnClientEvent:Connect(function(amount: number)
    luckyBurst:Emit(40)
    -- Big spin burst
    TweenService:Create(orb,
        TweenInfo.new(0.1, Enum.EasingStyle.Quad),
        { Size = originalSize * 1.35 }
    ):Play()
    task.delay(0.1, function()
        TweenService:Create(orb,
            TweenInfo.new(0.3, Enum.EasingStyle.Elastic),
            { Size = originalSize }
        ):Play()
    end)

    local fmt = amount >= 1e6 and ("%.1fM"):format(amount/1e6)
             or amount >= 1e3 and ("%.1fK"):format(amount/1e3)
             or tostring(math.floor(amount))

    Effects.luckyFlash("+" .. fmt)
    Effects.floatingText(orb.Position + Vector3.new(0, 6, 0),
        "✨ +" .. fmt, Color3.fromRGB(255, 80, 255))
end)

-- ── Mouse click ───────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
    local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 200)

    if result and result.Instance == orb then
        fireClick()
    end
end)

-- ── Mobile tap ────────────────────────────────────────────────────────────────

ContextActionService:BindAction("TapOrb", function(_, state, _)
    if state ~= Enum.UserInputState.Begin then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp.Position - orb.Position).Magnitude < 20 then
        fireClick()
    end
end, true, Enum.KeyCode.ButtonR2)

-- ── Space bar shortcut ────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode ~= Enum.KeyCode.Space then return end
    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp.Position - orb.Position).Magnitude < 20 then
        fireClick()
    end
end)
