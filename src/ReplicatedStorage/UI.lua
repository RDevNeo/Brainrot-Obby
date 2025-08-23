local module = {}

function module.tweenFade(textLabel: TextLabel)
	local TweenService = game:GetService("TweenService")

	local fadeInInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeInGoal = {TextTransparency = 0} 
	local fadeInTween = TweenService:Create(textLabel, fadeInInfo, fadeInGoal)

	fadeInTween:Play()
	fadeInTween.Completed:Connect(function()
		task.wait(2)

		local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local fadeOutGoal = {TextTransparency = 1}
		local fadeOutTween = TweenService:Create(textLabel, fadeOutInfo, fadeOutGoal)
		fadeOutTween:Play()
	end)
end

function module.displayMessage(textLabel: TextLabel, message: string, textColor: Color3)
	textLabel.Text = message
	textLabel.TextColor3 = textColor

	module.tweenFade(textLabel)
end

function module.reachedCheckpoint()
	local rs = game:GetService("ReplicatedStorage")
	local sound:Sound = game.Workspace:WaitForChild("GameConfig").Sounds.CheckpointReached
	
	local text = game.Players.LocalPlayer.PlayerGui.Messages.NotCanvas.Frame.TextLabel
	local message = "CHECKPOINT!"
	local color = Color3.new(0.0666667, 0.360784, 0.486275)

	module.displayMessage(text, message, color)
	sound:Play()
end

function module.TweenActive(guiObject: GuiObject)
	local blur = game.Lighting:FindFirstChild("UIBlur")
	if blur then
		blur.Enabled = true
	end

	if not guiObject then return end
	local TweenService = game:GetService("TweenService")

	local targetPos = UDim2.new(0.5, 0, 0.5, 0)
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local tween = TweenService:Create(guiObject, tweenInfo, {Position = targetPos})
	tween:Play()
end

function module.TweenInactive(guiObject: GuiObject)
	local blur = game.Lighting:FindFirstChild("UIBlur")
	if blur then
		blur.Enabled = false
	end

	if not guiObject then return end
	local TweenService = game:GetService("TweenService")

	local targetPos = UDim2.new(0.5, 0, -1, 0)
	local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	local tween = TweenService:Create(guiObject, tweenInfo, {Position = targetPos})
	tween:Play()
end

function module.HoverTweenPopSound(guiObject: GuiObject)
	if not guiObject then return end

	local TweenService = game:GetService("TweenService")

	local originalSize = guiObject.Size
	local popSize = UDim2.new(
		originalSize.X.Scale * 1.03, originalSize.X.Offset * 1.03,
		originalSize.Y.Scale * 1.03, originalSize.Y.Offset * 1.03
	)

	local TWEEN_TIME = 0.12
	local zoomTween = TweenService:Create(guiObject, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = popSize})
	local normalTween = TweenService:Create(guiObject, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize})

	guiObject.MouseEnter:Connect(function()
		zoomTween:Play()

		local sound = game.Workspace:WaitForChild("GameConfig").Sounds.Hover
		if sound then
			sound:Play()
		end
	end)

	guiObject.MouseLeave:Connect(function()
		normalTween:Play()
	end)
end


function module.ShowCoinsEarned(CoinsEarned: number)
	local TweenService = game:GetService("TweenService")

	local LocalPlayer = game.Players.LocalPlayer
	local CoinFrame = LocalPlayer.PlayerGui.Messages.NotCanvas.Coin
	local Quantity = CoinFrame.Quantity

	local targetPos = UDim2.new(0.65, 0, 0.2, 0)
	local hiddenPos = UDim2.new(0.65, 0, -1, 0)

	CoinFrame.Position = hiddenPos

	Quantity.Text = tostring(CoinsEarned or 0)

	local showInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local showTween = TweenService:Create(CoinFrame, showInfo, {Position = targetPos})
	showTween:Play()

	task.wait(1.5)

	local hideInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local hideTween = TweenService:Create(CoinFrame, hideInfo, {Position = hiddenPos})
	hideTween:Play()
end

function module.PetCollected(petName: string)
	local checkpointModule = require(game.ReplicatedStorage.Checkpoints)
	local Checkpoints = checkpointModule.checkpoints

	local TweenService = game:GetService("TweenService")
	local LocalPlayer = game.Players.LocalPlayer
	local PlayerGui = LocalPlayer.PlayerGui
	local PetTween: ScreenGui = PlayerGui.PetTween
	local Frame: Frame = PetTween.NotCanvas
	local ImageLabel: ImageLabel = Frame.ImageLabel

	local goalPosition = UDim2.new(0.037, 0, 0.562, 0)
	local originalPosition = UDim2.new(0.5, 0, 0.5, 0)
	local originalSize = UDim2.new(0.2, 0, 0.2, 0)
	local targetSize = UDim2.new(0.02, 0, 0.02, 0)
	local animationDuration = 1.5
	local easingStyle = Enum.EasingStyle.Quart
	local easingDirection = Enum.EasingDirection.Out

	local petData = nil
	for checkpoint, data in pairs(Checkpoints) do
		if data.name == petName then
			petData = data
			break
		end
	end

	if not petData then
		warn("[UIModule.PetCollected] Pet data not found for: " .. petName)
		return
	end

	ImageLabel.Image = petData.imageId
	ImageLabel.Position = originalPosition
	ImageLabel.Size = originalSize
	ImageLabel.Visible = true
	ImageLabel.ImageTransparency = 0

	local tweenInfo = TweenInfo.new(
		animationDuration,
		easingStyle,
		easingDirection,
		0, 
		false,
		0
	)

	local positionTween = TweenService:Create(
		ImageLabel,
		tweenInfo,
		{Position = goalPosition}
	)

	local sizeTween = TweenService:Create(
		ImageLabel,
		tweenInfo,
		{Size = targetSize}
	)

	local fadeOutTween = TweenService:Create(
		ImageLabel,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ImageTransparency = 1}
	)

	positionTween:Play()
	sizeTween:Play()

	task.spawn(function()
		task.wait(animationDuration - 0.3)
		fadeOutTween:Play()
	end)

	positionTween.Completed:Connect(function()
		task.wait(0.5)
		ImageLabel.Position = originalPosition
		ImageLabel.Size = originalSize
		ImageLabel.ImageTransparency = 0
		ImageLabel.Visible = false
		ImageLabel.Image = ""
	end)
end

function module.PlayPetSound(petName:string)
	local petFolder = game.Workspace:WaitForChild("GameConfig"):WaitForChild("Sounds"):WaitForChild("PetSounds")
	if not petFolder then warn("[UIModule.PlayPetSound] No PetFolder founded") return end
	
	local sound:Sound = petFolder:FindFirstChild(petName)
	if not sound then warn("[UIModule.PlayPetSound] No sound for " .. petName .. " founded.") return end
	sound:Play()
	
end

return module
