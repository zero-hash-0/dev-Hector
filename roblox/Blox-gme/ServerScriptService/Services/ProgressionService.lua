--!strict

-- Persistent XP, levels, wins, kills via DataStore.
-- Fires XPGained remote so the client can show popups and level-up banners.

local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")

-- XP required to reach each level (index = level)
local LEVEL_XP: { number } = {
	0,     -- 1
	120,   -- 2
	300,   -- 3
	600,   -- 4
	1100,  -- 5
	2000,  -- 6
	3500,  -- 7
	6000,  -- 8
	10000, -- 9
	16000, -- 10  (prestige threshold)
}

local XP_REWARDS = {
	kill    = 25,
	assist  = 10,
	win     = 100,
	escape  = 150,  -- the player who actually escapes with the Core
	carrier = 2,    -- per second holding Core (awarded on drop/escape)
}

local function getLevel(xp: number): number
	local level = 1
	for i = #LEVEL_XP, 1, -1 do
		if xp >= LEVEL_XP[i] then
			level = i
			break
		end
	end
	return level
end

local function xpToNextLevel(xp: number): number
	local level = getLevel(xp)
	local next  = LEVEL_XP[level + 1]
	return next and (next - xp) or 0
end

-- ── Service ───────────────────────────────────────────────────────────────────

local ProgressionService = {}
ProgressionService.__index = ProgressionService

type PlayerData = {
	xp        : number,
	level     : number,
	wins      : number,
	kills     : number,
	totalGames: number,
}

function ProgressionService.new(remotes: { [string]: RemoteEvent })
	local self = setmetatable({}, ProgressionService)
	self._remotes = remotes
	self._store   = DataStoreService:GetDataStore("BloxGmeProgress_v2")
	self._cache   = {} :: { [number]: PlayerData }   -- keyed by UserId
	return self
end

function ProgressionService:Init()
	Players.PlayerAdded:Connect(function(p)   self:_load(p)   end)
	Players.PlayerRemoving:Connect(function(p) self:_save(p)  end)

	-- Auto-save every 2 minutes
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in Players:GetPlayers() do
				self:_save(player)
			end
		end
	end)
end

-- ── Load / Save ───────────────────────────────────────────────────────────────

function ProgressionService:_load(player: Player)
	local default: PlayerData = { xp = 0, level = 1, wins = 0, kills = 0, totalGames = 0 }

	local ok, data = pcall(function()
		return self._store:GetAsync("p_" .. player.UserId)
	end)

	self._cache[player.UserId] = (ok and data) and data or default

	-- Sync level in case XP thresholds changed between sessions
	local cached = self._cache[player.UserId]
	cached.level = getLevel(cached.xp)

	self._remotes.XPGained:FireClient(player, {
		xp         = cached.xp,
		level      = cached.level,
		xpToNext   = xpToNextLevel(cached.xp),
		delta      = 0,
		kills      = cached.kills,
		wins       = cached.wins,
	})
end

function ProgressionService:_save(player: Player)
	local data = self._cache[player.UserId]
	if not data then return end
	pcall(function()
		self._store:SetAsync("p_" .. player.UserId, data)
	end)
	self._cache[player.UserId] = nil
end

-- ── Public XP award API ───────────────────────────────────────────────────────

function ProgressionService:AddXP(player: Player, amount: number, reason: string)
	local data = self._cache[player.UserId]
	if not data then return end

	local oldLevel = data.level
	data.xp       += amount
	data.level     = getLevel(data.xp)
	local leveled  = data.level > oldLevel

	self._remotes.XPGained:FireClient(player, {
		xp       = data.xp,
		level    = data.level,
		xpToNext = xpToNextLevel(data.xp),
		delta    = amount,
		reason   = reason,
		leveled  = leveled,
	})
end

function ProgressionService:AddKill(player: Player)
	local data = self._cache[player.UserId]
	if data then data.kills += 1 end
	self:AddXP(player, XP_REWARDS.kill, "kill")
end

function ProgressionService:AddWin(player: Player)
	local data = self._cache[player.UserId]
	if data then data.wins += 1 end
	self:AddXP(player, XP_REWARDS.win, "win")
end

function ProgressionService:AddEscape(player: Player)
	self:AddXP(player, XP_REWARDS.escape, "escape")
end

function ProgressionService:AddCoreCarryTime(player: Player, seconds: number)
	local amount = math.floor(seconds * XP_REWARDS.carrier)
	if amount > 0 then
		self:AddXP(player, amount, "carrier")
	end
end

function ProgressionService:EndGame(player: Player)
	local data = self._cache[player.UserId]
	if data then data.totalGames += 1 end
end

function ProgressionService:GetData(player: Player): PlayerData?
	return self._cache[player.UserId]
end

return ProgressionService
