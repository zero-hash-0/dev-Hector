-- ProximityHandler.client.lua (LocalScript)
-- Listens for ProximityPrompt triggers on pads and opens the correct UI panel.
-- Uses BindableEvents to talk to MainUI (same PlayerScripts folder).

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local RebirthRF  = Remotes:WaitForChild("Rebirth")
local Notification = Remotes:WaitForChild("Notification")

local player = Players.LocalPlayer

-- Wait for pads to exist in workspace
local function waitForPad(name)
    return workspace:WaitForChild(name, 30)
end

-- ── Egg pads → open egg panel in MainUI ──────────────────────────────────────
-- We fire a BindableEvent that MainUI listens to.

local openEggPanel  = Instance.new("BindableEvent"); openEggPanel.Name  = "OpenEggPanel";  openEggPanel.Parent  = script
local openUpgPanel  = Instance.new("BindableEvent"); openUpgPanel.Name  = "OpenUpgPanel";  openUpgPanel.Parent  = script
local doRebirth     = Instance.new("BindableEvent"); doRebirth.Name     = "DoRebirth";     doRebirth.Parent     = script

for _, egg in ipairs(GameConfig.EGGS) do
    task.spawn(function()
        local pad    = waitForPad("EggPad_" .. egg.id)
        if not pad then return end
        local prompt = pad:WaitForChild("ProximityPrompt", 10)
        if not prompt then return end
        prompt.Triggered:Connect(function(trigPlayer)
            if trigPlayer ~= player then return end
            openEggPanel:Fire(egg.id)
        end)
    end)
end

-- ── Upgrade shop pad ─────────────────────────────────────────────────────────

task.spawn(function()
    local pad    = waitForPad("ShopPad")
    if not pad then return end
    local prompt = pad:WaitForChild("ProximityPrompt", 10)
    if not prompt then return end
    prompt.Triggered:Connect(function(trigPlayer)
        if trigPlayer ~= player then return end
        openUpgPanel:Fire()
    end)
end)

-- ── Rebirth pad ───────────────────────────────────────────────────────────────

task.spawn(function()
    local pad    = waitForPad("RebirthPad")
    if not pad then return end
    local prompt = pad:WaitForChild("ProximityPrompt", 10)
    if not prompt then return end
    prompt.Triggered:Connect(function(trigPlayer)
        if trigPlayer ~= player then return end
        doRebirth:Fire()
    end)
end)

-- ── MainUI wires up these events on its end (see MainUI.client.lua) ──────────
-- Expose so MainUI can require/find this script's events.
_G.ProximityEvents = {
    openEggPanel = openEggPanel,
    openUpgPanel = openUpgPanel,
    doRebirth    = doRebirth,
}
