--!strict

-- End-of-match MVP card screen.
-- Displays ranked player results in the trading card aesthetic from ART_STYLE.md.

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local MatchSummary = Remotes:WaitForChild("MatchSummary") :: RemoteEvent
local MatchState   = Remotes:WaitForChild("MatchState")   :: RemoteEvent

local CharacterConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CharacterConfig"))

-- ── Root ──────────────────────────────────────────────────────────────────────
local screen = Instance.new("ScreenGui")
screen.Name           = "MatchSummary"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Enabled        = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent         = PlayerGui

local BG = Color3.fromHex("#0A0A18")

-- Full overlay
local overlay = Instance.new("Frame")
overlay.Size             = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = BG
overlay.BackgroundTransparency = 0.1
overlay.BorderSizePixel  = 0
overlay.Parent           = screen

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function label(parent: Instance, props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.BorderSizePixel        = 0
	l.Font                   = Enum.Font.GothamBold
	l.TextColor3             = Color3.new(1, 1, 1)
	l.TextScaled             = true
	for k, v in props do (l :: any)[k] = v end
	l.Parent = parent
	return l
end

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

-- ── Summary screen builder ────────────────────────────────────────────────────

local function buildSummary(data: {
	rankings: { any },
	mvp: any,
	winner: string?,
})
	-- Clear previous
	for _, child in overlay:GetChildren() do child:Destroy() end

	local mvp         = data.mvp
	local rankings    = data.rankings
	local winner      = data.winner
	local mvpCfg      = CharacterConfig.Characters[mvp.character] or CharacterConfig.Characters["VIPER"]

	-- ── Header ─────────────────────────────────────────────────────────────────
	label(overlay, {
		Size     = UDim2.new(0, 500, 0, 56),
		Position = UDim2.new(0.5, -250, 0, 28),
		Text     = winner and "CORE ESCAPED" or "MATCH OVER",
		TextColor3 = winner and Color3.fromHex("#FFD700") or Color3.fromHex("#FF3333"),
		Font     = Enum.Font.GothamBold,
	})

	label(overlay, {
		Size     = UDim2.new(0, 400, 0, 30),
		Position = UDim2.new(0.5, -200, 0, 82),
		Text     = winner and string.format("%s escaped with the Core!", winner) or "Nobody escaped in time.",
		TextColor3 = Color3.fromHex("#9999BB"),
		Font     = Enum.Font.Gotham,
	})

	-- ── MVP Card (left) ────────────────────────────────────────────────────────
	local card = Instance.new("Frame")
	card.Size             = UDim2.new(0, 220, 0, 380)
	card.Position         = UDim2.new(0.5, -440, 0.5, -190)
	card.BackgroundColor3 = Color3.fromHex("#12122A")
	card.BorderSizePixel  = 0
	card.Parent           = overlay
	corner(card, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color     = mvpCfg.Color
	stroke.Thickness = 2.5
	stroke.Parent    = card

	-- MVP badge
	local badge = Instance.new("Frame")
	badge.Size             = UDim2.new(0, 80, 0, 28)
	badge.Position         = UDim2.new(0, -4, 0, 12)
	badge.BackgroundColor3 = mvpCfg.Color
	badge.BorderSizePixel  = 0
	badge.Parent           = card
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 4)
	badgeCorner.Parent = badge
	label(badge, {
		Size = UDim2.new(1, 0, 1, 0),
		Text = "★ MVP",
		TextColor3 = Color3.fromHex("#0D0D1A"),
		Font = Enum.Font.GothamBold,
	})

	-- Color bar
	local cbar = Instance.new("Frame")
	cbar.Size             = UDim2.new(1, 0, 0, 5)
	cbar.Position         = UDim2.new(0, 0, 0, 0)
	cbar.BackgroundColor3 = mvpCfg.Color
	cbar.BorderSizePixel  = 0
	cbar.Parent           = card
	corner(cbar, 12)

	-- Character name
	label(card, {
		Size         = UDim2.new(1, -16, 0, 52),
		Position     = UDim2.new(0, 8, 0, 16),
		Text         = mvpCfg.DisplayName,
		TextColor3   = mvpCfg.Color,
		Font         = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0.5,
	})

	-- Player name
	label(card, {
		Size         = UDim2.new(1, -16, 0, 24),
		Position     = UDim2.new(0, 8, 0, 68),
		Text         = mvp.player,
		TextColor3   = Color3.fromHex("#AAAACC"),
		Font         = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Divider
	local div = Instance.new("Frame")
	div.Size             = UDim2.new(1, -16, 0, 1)
	div.Position         = UDim2.new(0, 8, 0, 100)
	div.BackgroundColor3 = Color3.fromHex("#2A2A44")
	div.BorderSizePixel  = 0
	div.Parent           = card

	-- Stats
	local statData = {
		{ "KOs",       tostring(mvp.kills) },
		{ "DAMAGE",    tostring(mvp.damage) },
		{ "CORE TIME", string.format("%ds", mvp.coreTime) },
		{ "SCORE",     tostring(mvp.score) },
	}

	for i, s in statData do
		local yOff = 110 + (i - 1) * 54

		label(card, {
			Size         = UDim2.new(1, -16, 0, 18),
			Position     = UDim2.new(0, 8, 0, yOff),
			Text         = s[1],
			TextColor3   = Color3.fromHex("#555577"),
			Font         = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		label(card, {
			Size         = UDim2.new(1, -16, 0, 30),
			Position     = UDim2.new(0, 8, 0, yOff + 18),
			Text         = s[2],
			TextColor3   = mvpCfg.Color,
			Font         = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	-- Vertical Japanese-style accent text (card aesthetic)
	label(card, {
		Size         = UDim2.new(0, 18, 0, 200),
		Position     = UDim2.new(1, -26, 0.5, -100),
		Text         = "BLOX-GME",
		TextColor3   = mvpCfg.Color,
		TextTransparency = 0.6,
		Font         = Enum.Font.GothamBold,
		Rotation     = 90,
	})

	-- ── Rankings table (right) ─────────────────────────────────────────────────
	local tableFrame = Instance.new("Frame")
	tableFrame.Size             = UDim2.new(0, 540, 0, 380)
	tableFrame.Position         = UDim2.new(0.5, -200, 0.5, -190)
	tableFrame.BackgroundColor3 = Color3.fromHex("#0E0E22")
	tableFrame.BorderSizePixel  = 0
	tableFrame.Parent           = overlay
	corner(tableFrame, 12)

	label(tableFrame, {
		Size     = UDim2.new(1, -24, 0, 36),
		Position = UDim2.new(0, 12, 0, 10),
		Text     = "MATCH RESULTS",
		TextColor3 = Color3.fromHex("#555577"),
		Font     = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	-- Column headers
	local cols = { "#", "PLAYER", "CHAR", "KOs", "DMG", "CORE", "SCORE" }
	local colX = { 12, 44, 172, 266, 306, 356, 420 }

	for i, col in cols do
		label(tableFrame, {
			Size       = UDim2.new(0, 80, 0, 20),
			Position   = UDim2.new(0, colX[i], 0, 48),
			Text       = col,
			TextColor3 = Color3.fromHex("#444466"),
			Font       = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	-- Rows
	for rank, entry in rankings do
		if rank > 8 then break end
		local yOff    = 72 + (rank - 1) * 36
		local isLocal = entry.player == LocalPlayer.DisplayName
		local entryColor = isLocal
			and Color3.fromHex("#00FF88")
			or Color3.new(0.85, 0.85, 0.9)
		local charCfg = CharacterConfig.Characters[entry.character] or CharacterConfig.Characters["VIPER"]

		if isLocal then
			local highlight = Instance.new("Frame")
			highlight.Size             = UDim2.new(1, -8, 0, 30)
			highlight.Position         = UDim2.new(0, 4, 0, yOff - 4)
			highlight.BackgroundColor3 = Color3.fromHex("#1A2A1A")
			highlight.BorderSizePixel  = 0
			highlight.Parent           = tableFrame
			corner(highlight, 4)
		end

		local rowData = {
			tostring(rank),
			entry.player,
			entry.character,
			tostring(entry.kills),
			tostring(entry.damage),
			string.format("%ds", entry.coreTime),
			tostring(entry.score),
		}

		for i, val in rowData do
			local color = i == 3 and charCfg.Color or entryColor
			label(tableFrame, {
				Size       = UDim2.new(0, 100, 0, 24),
				Position   = UDim2.new(0, colX[i], 0, yOff),
				Text       = val,
				TextColor3 = color,
				Font       = i == 1 and Enum.Font.GothamBold or Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		end
	end

	-- ── Dismiss countdown ──────────────────────────────────────────────────────
	local dismissLabel = label(overlay, {
		Size     = UDim2.new(0, 300, 0, 30),
		Position = UDim2.new(0.5, -150, 1, -52),
		Text     = "Next match in 8s...",
		TextColor3 = Color3.fromHex("#555577"),
		Font     = Enum.Font.Gotham,
	})

	task.spawn(function()
		for i = 8, 1, -1 do
			task.wait(1)
			if dismissLabel.Parent then
				dismissLabel.Text = string.format("Next match in %ds...", i - 1)
			end
		end
	end)

	-- Entrance animation — slide up from below
	overlay.Position = UDim2.new(0, 0, 1, 0)
	TweenService:Create(overlay,
		TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, 0, 0, 0) }
	):Play()
end

-- ── Remote handlers ───────────────────────────────────────────────────────────

MatchSummary.OnClientEvent:Connect(function(data: any)
	screen.Enabled = true
	buildSummary(data)
end)

MatchState.OnClientEvent:Connect(function(data: { State: string })
	if data.State == "Waiting" or data.State == "Countdown" then
		-- Slide out
		TweenService:Create(overlay,
			TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(0, 0, 1, 0) }
		):Play()
		task.delay(0.4, function()
			screen.Enabled = false
		end)
	end
end)
