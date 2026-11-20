-- Brainrot Collector — client HUD + scripted movement.
-- WASD and the arrow keys move your character. We drive the Humanoid
-- ourselves: DevComputerMovementMode is Scriptable, and we read the keys with
-- UserInputService:IsKeyDown every frame, which the default camera scripts
-- cannot eat the way they eat InputBegan for Left/Right. Shift sprints.
-- (Touch keeps the default thumbstick.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

player.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable

local gameState = ReplicatedStorage:WaitForChild("GameState")
local timeLeft = gameState:WaitForChild("TimeLeft")
local announcementValue = gameState:WaitForChild("Announcement")
local collectEvent = ReplicatedStorage:WaitForChild("CollectEvent")

local WALK_SPEED = 16
local SPRINT_SPEED = 26

-- HUD -----------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makePanel(parent, name, size, position, anchor)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.AnchorPoint = anchor or Vector2.new(0, 0)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.35
	panel.BorderSizePixel = 0
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

local function makeLabel(parent, name, text, size, position, textSize, color, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.Parent = parent
	return label
end

makeLabel(gui, "Title", "BRAINROT COLLECTOR",
	UDim2.new(0, 460, 0, 40), UDim2.new(0.5, 0, 0, 12), 30,
	Color3.fromRGB(255, 220, 60), Vector2.new(0.5, 0))

local scorePanel = makePanel(gui, "ScorePanel",
	UDim2.new(0, 250, 0, 64), UDim2.new(0, 12, 0, 12))
local scoreLabel = makeLabel(scorePanel, "Score", "Points: 0",
	UDim2.new(1, -16, 0, 28), UDim2.new(0, 8, 0, 6), 22)
local collectedLabel = makeLabel(scorePanel, "Collected", "Collected: 0",
	UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 32), 18,
	Color3.fromRGB(200, 230, 255))

local timerPanel = makePanel(gui, "TimerPanel",
	UDim2.new(0, 150, 0, 52), UDim2.new(1, -12, 0, 12), Vector2.new(1, 0))
local timerLabel = makeLabel(timerPanel, "Timer", "Time: 2:00",
	UDim2.new(1, -12, 1, 0), UDim2.new(0, 6, 0, 0), 24)

local boardPanel = makePanel(gui, "BoardPanel",
	UDim2.new(0, 230, 0, 132), UDim2.new(1, -12, 0, 76), Vector2.new(1, 0))
makeLabel(boardPanel, "BoardTitle", "TOP COLLECTORS",
	UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 6), 18,
	Color3.fromRGB(255, 220, 60))
local boardLabels = {}
for i = 1, 3 do
	boardLabels[i] = makeLabel(boardPanel, "Rank" .. i, i .. ". —",
		UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 6 + i * 30), 18)
end

local lastLabel = makeLabel(gui, "LastCollected", "Last: —",
	UDim2.new(0, 460, 0, 34), UDim2.new(0.5, 0, 1, -56), 20,
	Color3.fromRGB(200, 255, 200), Vector2.new(0.5, 1))
local hintLabel = makeLabel(gui, "Hint", "WASD / arrows to move — Shift to sprint",
	UDim2.new(0, 460, 0, 28), UDim2.new(0.5, 0, 1, -18), 16,
	Color3.fromRGB(220, 220, 220), Vector2.new(0.5, 1))

local announceLabel = makeLabel(gui, "Announcement", "",
	UDim2.new(0, 640, 0, 56), UDim2.new(0.5, 0, 0, 120), 32,
	Color3.fromRGB(255, 220, 60), Vector2.new(0.5, 0))

-- Live values ---------------------------------------------------------------

local leaderstats = player:WaitForChild("leaderstats")
local pointsValue = leaderstats:WaitForChild("Points")
local collectedValue = leaderstats:WaitForChild("Collected")

local function refreshScore()
	scoreLabel.Text = "Points: " .. pointsValue.Value
	collectedLabel.Text = "Collected: " .. collectedValue.Value
end
pointsValue:GetPropertyChangedSignal("Value"):Connect(refreshScore)
collectedValue:GetPropertyChangedSignal("Value"):Connect(refreshScore)
refreshScore()

local function formatTime(seconds)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function refreshTimer()
	timerLabel.Text = "Time: " .. formatTime(timeLeft.Value)
end
timeLeft:GetPropertyChangedSignal("Value"):Connect(refreshTimer)
refreshTimer()

collectEvent.OnClientEvent:Connect(function(name, points)
	lastLabel.Text = "Last: " .. name .. " (+" .. points .. " pts)"
end)

announcementValue:GetPropertyChangedSignal("Value"):Connect(function()
	announceLabel.Text = announcementValue.Value
end)
announceLabel.Text = announcementValue.Value

local function refreshBoard()
	local entries = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local stats = other:FindFirstChild("leaderstats")
		local points = stats and stats:FindFirstChild("Points")
		table.insert(entries, { name = other.Name, points = points and points.Value or 0 })
	end
	table.sort(entries, function(a, b) return a.points > b.points end)
	for i = 1, 3 do
		local entry = entries[i]
		if entry then
			boardLabels[i].Text = i .. ". " .. entry.name .. " — " .. entry.points
		else
			boardLabels[i].Text = i .. ". —"
		end
	end
end
task.spawn(function()
	while true do
		refreshBoard()
		task.wait(1)
	end
end)

-- Movement ------------------------------------------------------------------

local humanoid = nil
local function bindCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = WALK_SPEED
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	bindCharacter(player.Character)
end

RunService.RenderStepped:Connect(function()
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local fwd = camera.CFrame.LookVector
	fwd = Vector3.new(fwd.X, 0, fwd.Z)
	if fwd.Magnitude < 0.01 then
		fwd = Vector3.new(0, 0, -1)
	else
		fwd = fwd.Unit
	end
	local right = Vector3.new(-fwd.Z, 0, fwd.X)
	local move = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		move = move + fwd
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		move = move - fwd
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		move = move + right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		move = move - right
	end
	if move.Magnitude > 1 then
		move = move.Unit
	end
	humanoid:Move(move, false)
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
		humanoid.WalkSpeed = SPRINT_SPEED
	else
		humanoid.WalkSpeed = WALK_SPEED
	end
end)
