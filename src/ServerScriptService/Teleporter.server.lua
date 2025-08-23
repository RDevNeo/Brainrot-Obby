local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local checkpointFolder = Workspace:WaitForChild("CheckPoints")
local forwardEvent = ReplicatedStorage:WaitForChild("Remotes").UI.FowardButton
local backwardsEvent = ReplicatedStorage:WaitForChild("Remotes").UI.BackwardsButton
local dsModule = require(ReplicatedStorage.DataStore)

local playerCurrentPosition = {}

local function getCheckpointPart(checkpoint)
	if checkpoint:IsA("Model") then
		if checkpoint.PrimaryPart then
			return checkpoint.PrimaryPart
		else
			for _, child in ipairs(checkpoint:GetChildren()) do
				if child:IsA("BasePart") then
					return child
				end
			end
		end
	elseif checkpoint:IsA("BasePart") then
		return checkpoint
	end
	return nil
end

local function teleportPlayerToCheckpoint(player, checkpointNumber)
	local checkpointModel = checkpointFolder:FindFirstChild(tostring(checkpointNumber))
	if not checkpointModel then return false end

	local part = getCheckpointPart(checkpointModel)
	if not part then return false end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end

	local humanoidRootPart = player.Character.HumanoidRootPart
	local humanoid = player.Character:FindFirstChild("Humanoid")

	local targetPosition = part.Position + Vector3.new(0, 5, 0)
	humanoidRootPart.CFrame = CFrame.new(targetPosition, targetPosition + part.CFrame.LookVector)
	if humanoidRootPart:FindFirstChild("BodyVelocity") then
		humanoidRootPart.BodyVelocity:Destroy()
	end

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.Sit = false
	end

	task.wait(0.1)

	playerCurrentPosition[player.UserId] = checkpointNumber

	return true
end

local function onPlayerAdded(player)
	playerCurrentPosition[player.UserId] = dsModule.GetCheckpoint(player)
end

local function onPlayerRemoving(player)
	playerCurrentPosition[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

forwardEvent.OnServerEvent:Connect(function(player)
	if not player then return end

	local maxCheckpoint = dsModule.GetCheckpoint(player)
	local currentPosition = playerCurrentPosition[player.UserId] or maxCheckpoint
	local nextPosition = currentPosition + 1

	if nextPosition <= maxCheckpoint and checkpointFolder:FindFirstChild(tostring(nextPosition)) then
		teleportPlayerToCheckpoint(player, nextPosition)
	end
end)

backwardsEvent.OnServerEvent:Connect(function(player)
	if not player then return end

	local currentPosition = playerCurrentPosition[player.UserId] or dsModule.GetCheckpoint(player)
	local prevPosition = currentPosition - 1

	if prevPosition >= 1 and checkpointFolder:FindFirstChild(tostring(prevPosition)) then
		teleportPlayerToCheckpoint(player, prevPosition)
	end
end)