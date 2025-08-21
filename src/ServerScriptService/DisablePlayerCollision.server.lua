local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local playerCollisionGroupName = "Players"

local function setupCollisionGroup()
	if not pcall(function() PhysicsService:RegisterCollisionGroup(playerCollisionGroupName) end) then
	end
	PhysicsService:CollisionGroupSetCollidable(playerCollisionGroupName, playerCollisionGroupName, false)
end

local function setCharacterCollisionGroup(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = playerCollisionGroupName
		end
	end

	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = playerCollisionGroupName
		end
	end)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(setCharacterCollisionGroup)
	if player.Character then
		setCharacterCollisionGroup(player.Character)
	end
end

setupCollisionGroup()

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
