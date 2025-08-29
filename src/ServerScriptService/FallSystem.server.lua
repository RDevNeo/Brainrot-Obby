local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local checkpointsFolder = game.Workspace.CheckPoints
local ds = require(game.ReplicatedStorage.DataStore)
local fallStartTimes = {}
local toolStopTimes = {}

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
	if not player.Character then return end
	local humanoid: Humanoid = player.Character:WaitForChild("Humanoid")
	if not humanoid then return end
	local currentTime = tick()

	local playerIsUsingTool = isUsingTool(player)

	if not playerIsUsingTool and not toolStopTimes[player] then
		toolStopTimes[player] = currentTime
	elseif playerIsUsingTool then
		toolStopTimes[player] = nil
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		if not fallStartTimes[player] then
			fallStartTimes[player] = currentTime

		elseif currentTime - fallStartTimes[player] >= 0.8 then
			if playerIsUsingTool then
				return
			elseif toolStopTimes[player] and (currentTime - toolStopTimes[player]) < 2 then
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
	RunService.Heartbeat:Connect(function()
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
end)

SetupCheckpointTeleporter()