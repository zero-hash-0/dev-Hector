--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local function makeLabel(parent: Instance, name: string, order: number)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, 32)
	label.Position = UDim2.fromOffset(0, (order - 1) * 34)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(229, 238, 255)
	label.TextSize = 21
	label.Text = name .. ": --"
	label.Parent = parent
	return label
end

local screen = Instance.new("ScreenGui")
screen.Name = "HUD"
screen.ResetOnSpawn = false
screen.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(360, 170)
panel.Position = UDim2.fromOffset(16, 16)
panel.BackgroundColor3 = Color3.fromRGB(9, 14, 30)
panel.BackgroundTransparency = 0.15
panel.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(73, 228, 255)
stroke.Transparency = 0.2
stroke.Parent = panel

local moneyLabel = makeLabel(panel, "Money", 1)
local storageLabel = makeLabel(panel, "Storage", 2)
local carryLabel = makeLabel(panel, "Carry", 3)
local baseLabel = makeLabel(panel, "Base", 4)

local alert = Instance.new("TextLabel")
alert.Size = UDim2.new(0.5, 0, 0, 44)
alert.AnchorPoint = Vector2.new(0.5, 0)
alert.Position = UDim2.fromScale(0.5, 0.04)
alert.BackgroundColor3 = Color3.fromRGB(255, 72, 158)
alert.BackgroundTransparency = 0.18
alert.TextColor3 = Color3.new(1, 1, 1)
alert.Font = Enum.Font.GothamBlack
alert.TextScaled = true
alert.Text = ""
alert.Visible = false
alert.Parent = screen

Instance.new("UICorner", alert).CornerRadius = UDim.new(0, 10)

local hudState = {
	Money = 0,
	Storage = 0,
	StorageSlots = 0,
	Carrying = "None",
	BaseName = "Unassigned",
}

local function render()
	moneyLabel.Text = string.format("Money: $%d", hudState.Money)
	storageLabel.Text = string.format("Storage: %d/%d", hudState.Storage, hudState.StorageSlots)
	carryLabel.Text = string.format("Carry: %s", hudState.Carrying)
	baseLabel.Text = string.format("Base: %s", hudState.BaseName)
end

remotes.HUD.OnClientEvent:Connect(function(payload)
	for key, value in pairs(payload) do
		hudState[key] = value
	end
	render()
end)

remotes.Alert.OnClientEvent:Connect(function(payload)
	alert.Text = payload.Message
	alert.Visible = true
	task.delay(2.2, function()
		if alert.Text == payload.Message then
			alert.Visible = false
		end
	end)
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		remotes.AttackRequest:FireServer()
	elseif input.KeyCode == Enum.KeyCode.Q then
		remotes.DepositRequest:FireServer()
	end
end)

render()

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local brainrotModel = prompt.Parent and prompt.Parent.Parent
	if brainrotModel and brainrotModel:IsA("Model") then
		remotes.StealRequest:FireServer(brainrotModel)
	end
end)
