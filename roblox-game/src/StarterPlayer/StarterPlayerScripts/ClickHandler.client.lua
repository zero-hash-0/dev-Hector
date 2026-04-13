-- ClickHandler.client.lua (LocalScript)
-- Detects left-clicks on the ClickOrb part and fires the server remote.
-- Also handles mobile tap via ContextActionService.
-- Client-side throttle matches the server's CLICK_COOLDOWN.

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local UserInputService     = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService         = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local ClickOrb   = Remotes:WaitForChild("ClickOrb")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ── Wait for the orb ─────────────────────────────────────────────────────────

local orb: BasePart = workspace:WaitForChild("ClickOrb", 30)
if not orb then return end

-- ── Client-side throttle ──────────────────────────────────────────────────────

local lastFire = 0
local COOLDOWN = GameConfig.CLICK_COOLDOWN

local function fireClick()
    local now = tick()
    if now - lastFire < COOLDOWN then return end
    lastFire = now
    ClickOrb:FireServer()
    animateOrb()
end

-- ── Orb click animation ───────────────────────────────────────────────────────

local originalSize = orb.Size

function animateOrb()
    TweenService:Create(orb,
        TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = originalSize * 1.12 }
    ):Play()
    task.delay(0.07, function()
        TweenService:Create(orb,
            TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = originalSize }
        ):Play()
    end)
end

-- ── Mouse click detection ─────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    -- Raycast from camera through mouse position
    local unitRay = camera:ScreenPointToRay(input.Position.X, input.Position.Y)
    local result  = workspace:Raycast(
        unitRay.Origin,
        unitRay.Direction * 200,
        RaycastParams.new()
    )

    if result and result.Instance == orb then
        fireClick()
    end
end)

-- ── Mobile / gamepad tap ──────────────────────────────────────────────────────

ContextActionService:BindAction("TapOrb", function(_, state, _)
    if state == Enum.UserInputState.Begin then
        -- On mobile the player is expected to walk up and tap the orb;
        -- any tap while near the orb counts.
        local char = player.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - orb.Position).Magnitude < 20 then
            fireClick()
        end
    end
end, true, Enum.KeyCode.ButtonR2)

-- ── Keyboard shortcut (Space bar near orb) ────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode ~= Enum.KeyCode.Space then return end

    local char = player.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp.Position - orb.Position).Magnitude < 20 then
        fireClick()
    end
end)
