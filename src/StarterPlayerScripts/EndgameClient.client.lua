local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local StartEndGameAnimation = ReplicatedStorage.Remotes.UI.EndGameAnimation
local player = game.Players.LocalPlayer
local HelperModule = require(ReplicatedStorage.Helper)

local TimeBetweenPhrases = 2
local skipDialogue = false

local RebirthEvent = ReplicatedStorage.Remotes.UI.RebirthButton
local NoRebirthEvent = ReplicatedStorage.Remotes.UI.noRebirthButton

local phrases = {
	"This journey have been great..",
	"But as you know, everything has an ending, and that is yours.",
	"Yet.. I am a great developer and I'll you give a chance to play again...",
	"Yes, you can rebirth. You'll gain more coins than usual, but lost all your progress and pets.",
	"So, choose what you want to do and don't waste my time anymore, player."
}

local gui = player:WaitForChild("PlayerGui")
local screenGui = gui:WaitForChild("EndGame")
local canvas = screenGui:WaitForChild("NotCanvas")
local blackScreen = canvas:WaitForChild("BlackScreen")
local phrasesText = canvas:WaitForChild("Phrases")
local RebirthButton:TextButton = canvas:WaitForChild("Rebirth")
local NoRebirthButton:TextButton = canvas:WaitForChild("noRebirth")
local SkipDialongButton:TextButton = canvas:WaitForChild("Skip")

RebirthButton.Interactable = false
NoRebirthButton.Interactable = false

local blackScreenTween = TweenService:Create(blackScreen, TweenInfo.new(1), {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0})
local blackScreenFade  = TweenService:Create(blackScreen, TweenInfo.new(1), {BackgroundTransparency = 1})

local phrasesAppear    = TweenService:Create(phrasesText, TweenInfo.new(1), {TextTransparency = 0})
local phrasesFade      = TweenService:Create(phrasesText, TweenInfo.new(1), {TextTransparency = 1})

local RebirthButtonFadeIn  = TweenService:Create(RebirthButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local RebirthButtonFadeOut = TweenService:Create(RebirthButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

local NoRebirthButtonFadeIn  = TweenService:Create(NoRebirthButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local NoRebirthButtonFadeOut = TweenService:Create(NoRebirthButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

local SkipButtonFadeIn = TweenService:Create(SkipDialongButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local SkipButtonFadeOut = TweenService:Create(SkipDialongButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

RebirthButtonFadeIn.Completed:Connect(function() RebirthButton.Interactable = true end)
RebirthButtonFadeOut.Completed:Connect(function() RebirthButton.Interactable = false end)
NoRebirthButtonFadeIn.Completed:Connect(function() NoRebirthButton.Interactable = true end)
NoRebirthButtonFadeOut.Completed:Connect(function() NoRebirthButton.Interactable = false end)

local function disableMovement()
	ContextActionService:BindAction(
		"DisableMovement",
		function() return Enum.ContextActionResult.Sink end,
		false,
		unpack(Enum.PlayerActions:GetEnumItems())
	)
end

local function enableMovement()
	ContextActionService:UnbindAction("DisableMovement")
end

SkipDialongButton.MouseButton1Click:Connect(function()
	skipDialogue = true
	SkipButtonFadeOut:Play()
	SkipDialongButton.Interactable = false
end)

StartEndGameAnimation.OnClientEvent:Connect(function()
	HelperModule.DisableAllUIs()
	disableMovement()
	skipDialogue = false

	blackScreenTween:Play()
	blackScreenTween.Completed:Wait()

	SkipDialongButton.TextTransparency = 1
	SkipDialongButton.BackgroundTransparency = 1
	SkipDialongButton.Interactable = true
	SkipButtonFadeIn:Play()

	for _, line in ipairs(phrases) do
		if skipDialogue then break end

		phrasesText.Text = line
		phrasesText.TextTransparency = 1

		phrasesAppear:Play()
		phrasesAppear.Completed:Wait()

		local elapsed = 0
		while elapsed < TimeBetweenPhrases do
			if skipDialogue then break end
			task.wait(0.1)
			elapsed = elapsed + 0.1
		end

		phrasesFade:Play()
		phrasesFade.Completed:Wait()
	end

	phrasesText.TextTransparency = 1
	SkipButtonFadeOut:Play()
	SkipDialongButton.Interactable = false

	RebirthButtonFadeIn:Play()
	NoRebirthButtonFadeIn:Play()

	local function handleButtonClick(button, event)
		button.Interactable = false
		RebirthButton.Interactable = false
		NoRebirthButton.Interactable = false

		RebirthButtonFadeOut:Play()
		NoRebirthButtonFadeOut:Play()

		HelperModule.EnableAllUIs()
		enableMovement()
		blackScreenFade:Play()

		event:FireServer()
	end

	NoRebirthButton.MouseButton1Click:Connect(function()
		handleButtonClick(NoRebirthButton, NoRebirthEvent)
	end)

	RebirthButton.MouseButton1Click:Connect(function()
		handleButtonClick(RebirthButton, RebirthEvent)
	end)
end)
