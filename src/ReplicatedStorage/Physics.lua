local module = {}

local rotationSpeed = 270

function module.KillPart(part: BasePart)
	part.Touched:Connect(function(otherPart)
		local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
		local SpawnLocation = game.Workspace:WaitForChild("SpawnLocation")
		if player and SpawnLocation then
			player.Character:MoveTo(SpawnLocation.Position)
		end
	end)
	
end

function module.FadePart(part:BasePart)
	local TweenService = game:GetService("TweenService")
	local fadeOutInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeOutGoal = {Transparency = 1}
	local fadeOutTween = TweenService:Create(part, fadeOutInfo, fadeOutGoal)
	fadeOutTween:Play()
	wait(fadeOutInfo.Time)
	local FadeInInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local FadeInGoal = {Transparency = 0}
	local FadeInTween = TweenService:Create(part, FadeInInfo, FadeInGoal)
	FadeInTween:Play()
end

function module.getCurrentCheckpoint(player: Player)
	return player.Checkpoint.Value
end

function module.rotatePart(part: BasePart, deltaTime)
	local rotation = CFrame.Angles(0, math.rad(rotationSpeed * deltaTime), 0)
	part.CFrame = part.CFrame * rotation
end

function module.MovePartUp(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(0, moveSpeed * deltaTime, 0)
end

function module.MovePartDown(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(0, -moveSpeed * deltaTime, 0)
end

function module.MoveRight(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(moveSpeed * deltaTime, 0, 0)
end

function module.MoveLeft(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(-moveSpeed * deltaTime, 0, 0)
end

function module.MoveLeftDiagonalUpper(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(moveSpeed * deltaTime, moveSpeed * deltaTime, 0)
end

function module.MoveRightDiagonalUpper(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(-moveSpeed * deltaTime, moveSpeed * deltaTime, 0)
end

function module.MoveLeftDiagonalDown(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(moveSpeed * deltaTime, -moveSpeed * deltaTime, 0)
end

function module.MoveRightDiagonalDown(part: BasePart, deltaTime)
	local moveSpeed = 4
	part.CFrame = part.CFrame * CFrame.new(-moveSpeed * deltaTime, -moveSpeed * deltaTime, 0)
end

return module
