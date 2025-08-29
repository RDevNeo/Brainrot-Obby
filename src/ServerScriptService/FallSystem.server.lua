local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local checkpointsFolder = game.Workspace.CheckPoints
local ds = require(game.ReplicatedStorage.DataStore)
local TrussFolder = workspace:WaitForChild("TrussFolder")
local fallStartTimes = {}
local toolStopTimes = {}

local PROXIMITY_THRESHOLD = 3
local TRUSS_CLEAR_DELAY = 2

local touchedCounts = {}
local pendingClearTokens = {}
local partConns = {}
local trussParts = {}

local function getPlayerFromTouchPart(part)
	local current = part
	for i = 1, 10 do
		if not current then break end
		local player = Players:GetPlayerFromCharacter(current)
		if player then return player end
		current = current.Parent
	end
	return nil
end

local function addTrussPartToCache(part)
	if not part or not part:IsA("BasePart") then return end
	trussParts[#trussParts + 1] = part
end

local function removeTrussPartFromCache(part)
	for i = #trussParts, 1, -1 do
		if trussParts[i] == part then
			table.remove(trussParts, i)
		end
	end
end

local function onPartTouched(otherPart)
	local player = getPlayerFromTouchPart(otherPart)
	if not player then
		return
	end

	local id = player.UserId

	if pendingClearTokens[id] then
		pendingClearTokens[id] = nil
	end

	touchedCounts[id] = (touchedCounts[id] or 0) + 1
end

local function onPartTouchEnded(otherPart)
	local player = getPlayerFromTouchPart(otherPart)
	if not player then
		return
	end

	local id = player.UserId
	local newCount = (touchedCounts[id] or 0) - 1

	if newCount > 0 then
		touchedCounts[id] = newCount
	else
		touchedCounts[id] = nil
		local token = tick()
		pendingClearTokens[id] = token

		task.spawn(function()
			task.wait(TRUSS_CLEAR_DELAY)
			if pendingClearTokens[id] == token and (touchedCounts[id] or 0) == 0 then
				pendingClearTokens[id] = nil
			end
		end)
	end
end

local function connectTrussPart(part)
	if not part or not part:IsA("BasePart") or partConns[part] then return end

	local tConn = part.Touched:Connect(onPartTouched)

	local teConn = nil
	local ok, conOrErr = pcall(function() return part.TouchEnded:Connect(onPartTouchEnded) end)
	if ok then teConn = conOrErr end

	partConns[part] = {Touched = tConn, TouchEnded = teConn}
	addTrussPartToCache(part)
end

local function disconnectTrussPart(part)
	local conns = partConns[part]
	if not conns then return end
	if conns.Touched and conns.Touched.Connected then
		pcall(function() conns.Touched:Disconnect() end)
	end
	if conns.TouchEnded and conns.TouchEnded.Connected then
		pcall(function() conns.TouchEnded:Disconnect() end)
	end
	partConns[part] = nil
	removeTrussPartFromCache(part)
end

for _, desc in ipairs(TrussFolder:GetDescendants()) do
	if desc:IsA("BasePart") then
		connectTrussPart(desc)
	end
end

TrussFolder.DescendantAdded:Connect(function(desc)
	if desc:IsA("BasePart") then connectTrussPart(desc) end
end)
TrussFolder.DescendantRemoving:Connect(function(desc)
	if desc:IsA("BasePart") then disconnectTrussPart(desc) end
end)

Players.PlayerRemoving:Connect(function(player)
	touchedCounts[player.UserId] = nil
	pendingClearTokens[player.UserId] = nil
end)

local function isPlayerTouchingTruss(player)
	if not player or not player.Character then return false end
	local id = player.UserId

	if (touchedCounts[id] or 0) > 0 then
		return true
	end

	if pendingClearTokens[id] then
		return true
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local ok, state = pcall(function() return humanoid:GetState() end)
		if ok and state == Enum.HumanoidStateType.Climbing then
			return true
		end
	end

	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	for _, part in ipairs(trussParts) do
		if part and part.Parent and part:IsA("BasePart") then
			local distance = (hrp.Position - part.Position).Magnitude
			if distance <= PROXIMITY_THRESHOLD then
				print(("[TrussDetect] proximity hit for %s (dist=%.2f) -> part=%s")
					:format(player.Name, distance, part:GetFullName()))
				return true
			end
		end
	end

	return false
end

local function isUsingTool(player: Player)
	return player.Character and player.Character:FindFirstChildWhichIsA("Tool") ~= nil
end

local function TeleportToCheckpoint(player: Player)
	if not player.Character then return end
	local modelToTeleport = player:WaitForChild("AcumulativeCheckpoint")
	local targetCheckpoint
	if modelToTeleport.Value == 0 then
		targetCheckpoint = "1"
	else
		targetCheckpoint = tostring(modelToTeleport.Value)
	end
	local PhysicalModel:Model = checkpointsFolder:FindFirstChild(targetCheckpoint)
	if not PhysicalModel or not PhysicalModel.PrimaryPart then return end
	local humanoid = player.Character:WaitForChild("Humanoid")
	local humanoidRootPart:BasePart = player.Character:WaitForChild("HumanoidRootPart")
	humanoidRootPart.CFrame = PhysicalModel.PrimaryPart.CFrame + Vector3.new(0, 2, 0)
end

local function SetupCheckpointTeleporter()
	local validCheckpoints = {10, 20, 30, 40, 50, 60, 70, 80}
	local validCheckpointsSet = {}
	for _, checkpoint in pairs(validCheckpoints) do
		validCheckpointsSet[checkpoint] = true
	end
	for _, model in pairs(checkpointsFolder:GetChildren()) do
		if model:IsA("Model") and tonumber(model.Name) then
			for _, part in pairs(model:GetChildren()) do
				if part:IsA("BasePart") then
					part.Touched:Connect(function(hit)
						local player = Players:GetPlayerFromCharacter(hit.Parent)
						if player then
							local lastCheckpoint = player:WaitForChild("AcumulativeCheckpoint")
							if not lastCheckpoint then return end
							local actualCheckpoint = ds.GetCheckpoint(player)
							local touchedCheckpoint = tonumber(model.Name)
							if validCheckpointsSet[touchedCheckpoint] 
								and touchedCheckpoint <= (actualCheckpoint + 1)
								and touchedCheckpoint > lastCheckpoint.Value then
								lastCheckpoint.Value = touchedCheckpoint
							end
						end
					end)
				end
			end
		end
	end
end

local function CheckFalling(player: Player)
	if not player or not player.Character then return end
	local humanoid: Humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then return end
	local currentTime = tick()

	local playerIsUsingTool = isUsingTool(player)

	if not playerIsUsingTool and not toolStopTimes[player] then
		toolStopTimes[player] = currentTime
	elseif playerIsUsingTool then
		toolStopTimes[player] = nil
	end

	local touching = isPlayerTouchingTruss(player)
	local fallSince = fallStartTimes[player] and (currentTime - fallStartTimes[player]) or nil
	local toolSince = toolStopTimes[player] and (currentTime - toolStopTimes[player]) or nil

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not fallStartTimes[player] then
			fallStartTimes[player] = currentTime
		elseif currentTime - fallStartTimes[player] >= 1.2 then
			if playerIsUsingTool then
				return
			elseif toolStopTimes[player] and (currentTime - toolStopTimes[player]) < 2 then
				return
			elseif touching then
				return
			else
				TeleportToCheckpoint(player)
				fallStartTimes[player] = currentTime
				toolStopTimes[player] = nil
			end
		end
	else
		fallStartTimes[player] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not player.Parent then
			if conn and conn.Connected then conn:Disconnect() end
			return
		end
		CheckFalling(player)
	end)

	local acumulativeCheckpoint = Instance.new("NumberValue")
	acumulativeCheckpoint.Parent = player
	acumulativeCheckpoint.Name = "AcumulativeCheckpoint"
	acumulativeCheckpoint.Value = 0
end)

Players.PlayerRemoving:Connect(function(player)
	fallStartTimes[player] = nil
	toolStopTimes[player] = nil
	touchedCounts[player.UserId] = nil
	pendingClearTokens[player.UserId] = nil
end)

SetupCheckpointTeleporter()
