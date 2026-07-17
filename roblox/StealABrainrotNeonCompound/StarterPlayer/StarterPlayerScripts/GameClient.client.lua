--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local modules = ReplicatedStorage:WaitForChild("Modules")

local BrainrotConfig = require(modules.BrainrotConfig)
local UpgradeConfig = require(modules.UpgradeConfig)
local GameConfig = require(modules.GameConfig)

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
panel.Size = UDim2.fromOffset(360, 240)
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
local eventLabel = makeLabel(panel, "Event", 5)

local hintLabel = makeLabel(panel, "Hint", 6)
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextSize = 15
hintLabel.TextColor3 = Color3.fromRGB(150, 165, 200)
hintLabel.Text = "E steal | Q deposit | F attack | B shop"

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
	Event = "None",
}

local function render()
	moneyLabel.Text = string.format("Money: $%d", hudState.Money)
	storageLabel.Text = string.format("Storage: %d/%d", hudState.Storage, hudState.StorageSlots)
	carryLabel.Text = string.format("Carry: %s", hudState.Carrying)
	baseLabel.Text = string.format("Base: %s", hudState.BaseName)
	eventLabel.Text = string.format("Event: %s", hudState.Event)
	eventLabel.TextColor3 = hudState.Event ~= "None" and Color3.fromRGB(255, 214, 90) or Color3.fromRGB(229, 238, 255)
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

-- Shop panel -----------------------------------------------------------------

local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.Size = UDim2.fromOffset(340, 470)
shopPanel.AnchorPoint = Vector2.new(1, 0)
shopPanel.Position = UDim2.new(1, -16, 0, 16)
shopPanel.BackgroundColor3 = Color3.fromRGB(9, 14, 30)
shopPanel.BackgroundTransparency = 0.08
shopPanel.Visible = false
shopPanel.Parent = screen

Instance.new("UICorner", shopPanel).CornerRadius = UDim.new(0, 12)

local shopStroke = Instance.new("UIStroke")
shopStroke.Thickness = 2
shopStroke.Color = Color3.fromRGB(255, 72, 158)
shopStroke.Transparency = 0.2
shopStroke.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 36)
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.TextColor3 = Color3.fromRGB(229, 238, 255)
shopTitle.TextSize = 22
shopTitle.Text = "NEON SHOP"
shopTitle.Parent = shopPanel

local shopList = Instance.new("ScrollingFrame")
shopList.Size = UDim2.new(1, -16, 1, -48)
shopList.Position = UDim2.fromOffset(8, 42)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 4
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 6)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

local function makeShopRow(order: number, title: string, subtitle: string, accent: Color3, buttonText: string?, onBuy: (() -> ())?)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 54)
	row.LayoutOrder = order
	row.BackgroundColor3 = Color3.fromRGB(16, 22, 44)
	row.BackgroundTransparency = 0.1
	row.Parent = shopList

	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -92, 0, 24)
	nameLabel.Position = UDim2.fromOffset(10, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 17
	nameLabel.TextColor3 = accent
	nameLabel.Text = title
	nameLabel.Parent = row

	local subLabel = Instance.new("TextLabel")
	subLabel.Size = UDim2.new(1, -92, 0, 20)
	subLabel.Position = UDim2.fromOffset(10, 28)
	subLabel.BackgroundTransparency = 1
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.Font = Enum.Font.Gotham
	subLabel.TextSize = 14
	subLabel.TextColor3 = Color3.fromRGB(150, 165, 200)
	subLabel.Text = subtitle
	subLabel.Parent = row

	if buttonText and onBuy then
		local buy = Instance.new("TextButton")
		buy.Size = UDim2.fromOffset(72, 34)
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -8, 0.5, 0)
		buy.BackgroundColor3 = Color3.fromRGB(255, 72, 158)
		buy.Font = Enum.Font.GothamBold
		buy.TextSize = 15
		buy.TextColor3 = Color3.new(1, 1, 1)
		buy.Text = buttonText
		buy.Parent = row
		Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 8)
		buy.Activated:Connect(onBuy)
	end

	return row
end

local function makeShopHeader(order: number, text: string)
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -6, 0, 26)
	header.LayoutOrder = order
	header.BackgroundTransparency = 1
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.GothamBlack
	header.TextSize = 16
	header.TextColor3 = Color3.fromRGB(73, 228, 255)
	header.Text = text
	header.Parent = shopList
end

local sortedBrainrots = {}
for _, def in pairs(BrainrotConfig) do
	if typeof(def) == "table" and def.Id then
		table.insert(sortedBrainrots, def)
	end
end
table.sort(sortedBrainrots, function(a, b)
	return a.BaseValue < b.BaseValue
end)

local function renderShop()
	for _, child in ipairs(shopList:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local order = 0
	order += 1
	makeShopHeader(order, "BRAINROTS")
	for _, def in ipairs(sortedBrainrots) do
		order += 1
		makeShopRow(
			order,
			def.DisplayName,
			string.format("%s | +$%d/s", def.Rarity, def.IncomePerSecond),
			GameConfig.RarityColors[def.Rarity],
			string.format("$%d", def.BaseValue),
			function()
				remotes.ShopRequest:FireServer("BuyBrainrot", def.Id)
			end
		)
	end

	order += 1
	makeShopHeader(order, "UPGRADES")
	for _, upgradeId in ipairs(UpgradeConfig.Order) do
		local upgrade = UpgradeConfig[upgradeId]
		local level = localPlayer:GetAttribute("Upgrade_" .. upgradeId) or 0
		local nextTier = upgrade.Tiers[level + 1]
		order += 1
		if nextTier then
			makeShopRow(
				order,
				string.format("%s (Tier %d/%d)", upgrade.DisplayName, level, #upgrade.Tiers),
				upgrade.Description,
				Color3.fromRGB(229, 238, 255),
				string.format("$%d", nextTier.Cost),
				function()
					remotes.ShopRequest:FireServer("BuyUpgrade", upgradeId)
				end
			)
		else
			makeShopRow(
				order,
				string.format("%s (MAX)", upgrade.DisplayName),
				upgrade.Description,
				Color3.fromRGB(153, 255, 86),
				nil,
				nil
			)
		end
	end
end

for _, upgradeId in ipairs(UpgradeConfig.Order) do
	localPlayer:GetAttributeChangedSignal("Upgrade_" .. upgradeId):Connect(function()
		if shopPanel.Visible then
			renderShop()
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		remotes.AttackRequest:FireServer()
	elseif input.KeyCode == Enum.KeyCode.Q then
		remotes.DepositRequest:FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		shopPanel.Visible = not shopPanel.Visible
		if shopPanel.Visible then
			renderShop()
		end
	end
end)

render()

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	local brainrotModel = prompt.Parent and prompt.Parent.Parent
	if brainrotModel and brainrotModel:IsA("Model") then
		remotes.StealRequest:FireServer(brainrotModel)
	end
end)
