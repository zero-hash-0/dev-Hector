--!strict

-- Client: HUD updates, input for combat/movement, visual feedback.

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchState    = Remotes:WaitForChild("MatchState")    :: RemoteEvent
local CoreState     = Remotes:WaitForChild("CoreState")     :: RemoteEvent
local CombatHit     = Remotes:WaitForChild("CombatHit")     :: RemoteEvent
local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local SprintRequest = Remotes:WaitForChild("SprintRequest") :: RemoteEvent
local DashRequest   = Remotes:WaitForChild("DashRequest")   :: RemoteEvent
local HUD           = Remotes:WaitForChild("HUD")           :: RemoteEvent
local Alert         = Remotes:WaitForChild("Alert")         :: RemoteEvent

-- ── Input state ──────────────────────────────────────────────────────────────
local isSprinting = false
local attackCooldownActive = false

-- ── Attack (F key) ───────────────────────────────────────────────────────────
local function findNearestPlayer(): Player?
	local character = LocalPlayer.Character
	if not character then return nil end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end

	local nearest: Player? = nil
	local nearestDist = math.huge

	for _, player in Players:GetPlayers() do
		if player == LocalPlayer then continue end
		local char = player.Character
		if not char then continue end
		local otherRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not otherRoot then continue end
		local dist = (root.Position - otherRoot.Position).Magnitude
		if dist < nearestDist then
			nearestDist = dist
			nearest     = player
		end
	end
	return nearest
end

-- ── Sprint (Shift hold) ──────────────────────────────────────────────────────
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Sprint on
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		SprintRequest:FireServer(true)
	end

	-- Attack
	if input.KeyCode == Enum.KeyCode.F and not attackCooldownActive then
		local target = findNearestPlayer()
		if target then
			AttackRequest:FireServer(target)
			attackCooldownActive = true
			task.delay(0.4, function() attackCooldownActive = false end)
		end
	end

	-- Dash (Q + movement direction from camera look)
	if input.KeyCode == Enum.KeyCode.Q then
		local move = UserInputService:GetKeysPressed()
		local dir  = Camera.CFrame.LookVector * Vector3.new(1, 0, 1)
		DashRequest:FireServer(dir.Unit)
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		SprintRequest:FireServer(false)
	end
end)

-- ── Server events ─────────────────────────────────────────────────────────────
MatchState.OnClientEvent:Connect(function(data: { State: string, Time: number?, Winner: string? })
	-- TODO: update match timer UI, state banner
	print(string.format("[Match] %s", data.State), data.Time or "", data.Winner or "")
end)

CoreState.OnClientEvent:Connect(function(data: { Event: string, Carrier: string? })
	if data.Event == "PickedUp" then
		print(string.format("[Core] %s picked up the Core!", data.Carrier or "?"))
	elseif data.Event == "Dropped" then
		print("[Core] Core was dropped!")
	elseif data.Event == "Returned" then
		print("[Core] Core returned to center.")
	end
	-- TODO: update Core tracker arrow / HUD icon
end)

CombatHit.OnClientEvent:Connect(function(data: { Attacker: string, Target: string, Damage: number?, KO: boolean? })
	if data.KO then
		print(string.format("[KO] %s knocked out %s!", data.Attacker, data.Target))
	else
		print(string.format("[Hit] %s hit %s for %d", data.Attacker, data.Target, data.Damage or 0))
	end
	-- TODO: screen flash / hit marker / KO banner
end)

HUD.OnClientEvent:Connect(function(data: { [string]: any })
	-- TODO: sync HUD elements (health bar, Core status, match timer)
	print("[HUD]", data)
end)

Alert.OnClientEvent:Connect(function(data: { Type: string, Message: string })
	print(string.format("[%s] %s", data.Type, data.Message))
	-- TODO: toast notification UI
end)
