-- Brainrot Collector — server.
-- Spawns Italian-brainrot characters on the arena pads, awards points when a
-- player touches one, respawns it on a random free pad, and runs 120-second
-- rounds with a winner announcement. State the client needs lives in
-- ReplicatedStorage.GameState (TimeLeft, Announcement) and the CollectEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ROUND_LENGTH = 120
local RESPAWN_DELAY = 4
local BOB_AMPLITUDE = 0.4

local BRAINROTS = {
	{ name = "Tung Tung Tung Sahur", points = 10, body = Color3.fromRGB(150, 100, 50), head = Color3.fromRGB(120, 80, 40), feature = "bat" },
	{ name = "Tralalero Tralala", points = 15, body = Color3.fromRGB(70, 140, 220), head = Color3.fromRGB(50, 110, 190), feature = "fin" },
	{ name = "Bombardiro Crocodilo", points = 20, body = Color3.fromRGB(60, 170, 90), head = Color3.fromRGB(45, 140, 75), feature = "wings" },
	{ name = "Brr Brr Patapim", points = 10, body = Color3.fromRGB(120, 85, 50), head = Color3.fromRGB(100, 70, 40), feature = "leaf" },
	{ name = "Lirili Larila", points = 15, body = Color3.fromRGB(90, 190, 110), head = Color3.fromRGB(70, 160, 90), feature = "trunk" },
	{ name = "Chimpanzini Bananini", points = 25, body = Color3.fromRGB(240, 210, 60), head = Color3.fromRGB(120, 85, 50), feature = "banana" },
}

-- Shared state the client reads.
local gameState = Instance.new("Folder")
gameState.Name = "GameState"
gameState.Parent = ReplicatedStorage

local timeLeft = Instance.new("IntValue")
timeLeft.Name = "TimeLeft"
timeLeft.Value = ROUND_LENGTH
timeLeft.Parent = gameState

local announcement = Instance.new("StringValue")
announcement.Name = "Announcement"
announcement.Value = ""
announcement.Parent = gameState

local collectEvent = Instance.new("RemoteEvent")
collectEvent.Name = "CollectEvent"
collectEvent.Parent = ReplicatedStorage

-- Leaderstats for every player (the leaderboard the client reads).
local function setupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = 0
	points.Parent = stats
	local collected = Instance.new("IntValue")
	collected.Name = "Collected"
	collected.Value = 0
	collected.Parent = stats
	stats.Parent = player
end

Players.PlayerAdded:Connect(setupLeaderstats)
for _, player in ipairs(Players:GetPlayers()) do
	if not player:FindFirstChild("leaderstats") then
		setupLeaderstats(player)
	end
end

-- The six spawn pads from the Rojo project (Workspace.SpawnPads, Pad1..Pad6).
-- Each pad's spawn height is the top of its lighter top plate (PadNTop), or the
-- pad itself when a top plate is missing.
local padsFolder = Workspace:WaitForChild("SpawnPads")
local pads = {}
for _, child in ipairs(padsFolder:GetChildren()) do
	if child:IsA("BasePart") and child.Name:match("^Pad%d+$") then
		local top = padsFolder:FindFirstChild(child.Name .. "Top")
		local topY
		if top and top:IsA("BasePart") then
			topY = top.Position.Y + top.Size.Y / 2
		else
			topY = child.Position.Y + child.Size.Y / 2
		end
		table.insert(pads, { part = child, topY = topY, occupant = nil })
	end
end
table.sort(pads, function(a, b) return a.part.Name < b.part.Name end)

-- One small part helper: every character is built from anchored, non-colliding
-- parts, so players walk through them and the touch is what collects.
local function addPart(model, name, size, color, position, shape, cframe)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	if shape then
		part.Shape = shape
	end
	if cframe then
		part.CFrame = cframe
	else
		part.Position = position
	end
	part.Parent = model
	return part
end

local function buildCharacter(def, padTopY, x, z)
	local model = Instance.new("Model")
	model.Name = def.name

	local body = addPart(model, "Body", Vector3.new(3, 3.5, 2), def.body,
		Vector3.new(x, padTopY + 1.75, z))
	local head = addPart(model, "Head", Vector3.new(2.5, 2.5, 2.5), def.head,
		Vector3.new(x, padTopY + 4.75, z))

	-- One or two signature features per brainrot, so each reads differently.
	if def.feature == "bat" then
		-- Sahur's wooden bat, held at his side.
		addPart(model, "Bat", Vector3.new(0.6, 3.5, 0.6), Color3.fromRGB(90, 60, 30),
			nil, nil, CFrame.new(x + 2, padTopY + 2, z) * CFrame.Angles(0, 0, math.rad(25)))
	elseif def.feature == "fin" then
		-- Tralala's shark fin on top of his head.
		local fin = Instance.new("WedgePart")
		fin.Name = "Fin"
		fin.Size = Vector3.new(1.5, 1.5, 2)
		fin.Color = Color3.fromRGB(40, 90, 170)
		fin.Material = Enum.Material.SmoothPlastic
		fin.Anchored = true
		fin.CanCollide = false
		fin.Position = Vector3.new(x, padTopY + 6.75, z)
		fin.Parent = model
	elseif def.feature == "wings" then
		-- Crocodilo's plane wings plus his snout.
		addPart(model, "WingLeft", Vector3.new(2.5, 0.3, 1.2), Color3.fromRGB(200, 200, 200),
			Vector3.new(x - 2.6, padTopY + 2.8, z))
		addPart(model, "WingRight", Vector3.new(2.5, 0.3, 1.2), Color3.fromRGB(200, 200, 200),
			Vector3.new(x + 2.6, padTopY + 2.8, z))
		addPart(model, "Snout", Vector3.new(1.2, 0.8, 1), def.head,
			Vector3.new(x, padTopY + 4.5, z + 1.6))
	elseif def.feature == "leaf" then
		-- Patapim's little tree: trunk and leaf ball on his head.
		addPart(model, "TreeTrunk", Vector3.new(0.5, 1.5, 0.5), Color3.fromRGB(120, 80, 40),
			Vector3.new(x, padTopY + 6.5, z))
		addPart(model, "Leaf", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(60, 200, 90),
			Vector3.new(x, padTopY + 8, z), Enum.PartType.Ball)
	elseif def.feature == "trunk" then
		-- Lirili's elephant trunk and cactus arms.
		addPart(model, "Trunk", Vector3.new(0.8, 0.8, 2), def.head,
			Vector3.new(x, padTopY + 4.5, z + 1.8))
		addPart(model, "ArmLeft", Vector3.new(0.6, 1.5, 0.6), def.body,
			Vector3.new(x - 1.8, padTopY + 2, z))
		addPart(model, "ArmRight", Vector3.new(0.6, 1.5, 0.6), def.body,
			Vector3.new(x + 1.8, padTopY + 2, z))
	elseif def.feature == "banana" then
		-- Bananini's banana on top of his head.
		addPart(model, "Banana", Vector3.new(0.8, 2.5, 0.8), Color3.fromRGB(250, 225, 70),
			nil, nil, CFrame.new(x, padTopY + 7, z) * CFrame.Angles(0, 0, math.rad(-25)))
	end

	-- The invisible hitbox that detects a touch.
	addPart(model, "Hitbox", Vector3.new(5, 7, 5), Color3.fromRGB(255, 255, 255),
		Vector3.new(x, padTopY + 3.5, z)).Transparency = 1

	-- Floating name tag with the point value.
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.new(0, 140, 0, 60)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	tag.AlwaysOnTop = true
	tag.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = def.name .. "\n" .. def.points .. " pts"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = tag

	model.PrimaryPart = body
	return model
end

-- Live characters: { model, def, pad, basePivot, phase, collected }.
local alive = {}

local function freePads()
	local free = {}
	for _, pad in ipairs(pads) do
		if not pad.occupant then
			table.insert(free, pad)
		end
	end
	return free
end

local function onTouched(entry, otherPart)
	if entry.collected then
		return
	end
	local character = otherPart.Parent
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	entry.collected = true

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local points = stats:FindFirstChild("Points")
		local collected = stats:FindFirstChild("Collected")
		if points then
			points.Value = points.Value + entry.def.points
		end
		if collected then
			collected.Value = collected.Value + 1
		end
	end
	collectEvent:FireClient(player, entry.def.name, entry.def.points)

	entry.pad.occupant = nil
	for i, e in ipairs(alive) do
		if e == entry then
			table.remove(alive, i)
			break
		end
	end
	entry.model:Destroy()

	-- A (possibly different) brainrot comes back on a random free pad.
	task.delay(RESPAWN_DELAY, function()
		local free = freePads()
		if #free == 0 then
			return
		end
		local pad = free[math.random(1, #free)]
		local def = BRAINROTS[math.random(1, #BRAINROTS)]
		spawnCharacter(def, pad)
	end)
end

function spawnCharacter(def, pad)
	local model = buildCharacter(def, pad.topY, pad.part.Position.X, pad.part.Position.Z)
	model.Parent = Workspace
	local entry = {
		model = model,
		def = def,
		pad = pad,
		basePivot = model:GetPivot(),
		phase = math.random() * math.pi * 2,
		collected = false,
	}
	pad.occupant = entry
	table.insert(alive, entry)
	model:FindFirstChild("Hitbox").Touched:Connect(function(otherPart)
		onTouched(entry, otherPart)
	end)
	return entry
end

-- Gentle bobbing so the characters feel alive.
RunService.Heartbeat:Connect(function()
	local now = os.clock()
	for _, entry in ipairs(alive) do
		if entry.model.Parent and not entry.collected then
			entry.model:PivotTo(entry.basePivot
				* CFrame.new(0, math.sin(now * 2 + entry.phase) * BOB_AMPLITUDE, 0))
		end
	end
end)

local function startRound()
	for _, entry in ipairs(alive) do
		if entry.model.Parent then
			entry.model:Destroy()
		end
	end
	alive = {}
	for _, pad in ipairs(pads) do
		pad.occupant = nil
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local points = stats:FindFirstChild("Points")
			local collected = stats:FindFirstChild("Collected")
			if points then
				points.Value = 0
			end
			if collected then
				collected.Value = 0
			end
		end
	end
	-- One brainrot per pad, in a shuffled order.
	local defs = {}
	for i, def in ipairs(BRAINROTS) do
		defs[i] = def
	end
	for i = #defs, 2, -1 do
		local j = math.random(1, i)
		defs[i], defs[j] = defs[j], defs[i]
	end
	for i, pad in ipairs(pads) do
		spawnCharacter(defs[i], pad)
	end
end

task.spawn(function()
	while true do
		startRound()
		announcement.Value = "New round! Collect the brainrots!"
		task.wait(3)
		announcement.Value = ""
		for t = ROUND_LENGTH, 1, -1 do
			timeLeft.Value = t
			task.wait(1)
		end
		timeLeft.Value = 0
		local winner = nil
		local best = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local stats = player:FindFirstChild("leaderstats")
			local points = stats and stats:FindFirstChild("Points")
			local value = points and points.Value or 0
			if value > best then
				best = value
				winner = player
			end
		end
		if winner then
			announcement.Value = "Winner: " .. winner.Name .. " — " .. best .. " points!"
		else
			announcement.Value = "Round over! No winner this time."
		end
		task.wait(5)
	end
end)
