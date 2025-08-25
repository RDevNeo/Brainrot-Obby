local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local StartEndGameAnimation = ReplicatedStorage.Remotes.UI.EndGameAnimation
local player = game.Players.LocalPlayer
local HelperModule = require(ReplicatedStorage.Helper)

local TimeBetweenPhrases = 2
local skipDialogue = false

local WinsEvent = ReplicatedStorage.Remotes.UI.WinsButton
local NoWinsEvent = ReplicatedStorage.Remotes.UI.noWinsButton

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
local WinsButton:TextButton = canvas:WaitForChild("Wins")
local NoWinsButton:TextButton = canvas:WaitForChild("noWins")
local SkipDialongButton:TextButton = canvas:WaitForChild("Skip")

WinsButton.Interactable = false
NoWinsButton.Interactable = false

local blackScreenTween = TweenService:Create(blackScreen, TweenInfo.new(1), {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0})
local blackScreenFade  = TweenService:Create(blackScreen, TweenInfo.new(1), {BackgroundTransparency = 1})

local phrasesAppear    = TweenService:Create(phrasesText, TweenInfo.new(1), {TextTransparency = 0})
local phrasesFade      = TweenService:Create(phrasesText, TweenInfo.new(1), {TextTransparency = 1})

local WinsButtonFadeIn  = TweenService:Create(WinsButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local WinsButtonFadeOut = TweenService:Create(WinsButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

local NoWinsButtonFadeIn  = TweenService:Create(NoWinsButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local NoWinsButtonFadeOut = TweenService:Create(NoWinsButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

local SkipButtonFadeIn = TweenService:Create(SkipDialongButton, TweenInfo.new(1), {TextTransparency = 0, BackgroundTransparency = 0})
local SkipButtonFadeOut = TweenService:Create(SkipDialongButton, TweenInfo.new(1), {TextTransparency = 1, BackgroundTransparency = 1})

WinsButtonFadeIn.Completed:Connect(function() WinsButton.Interactable = true end)
WinsButtonFadeOut.Completed:Connect(function() WinsButton.Interactable = false end)
NoWinsButtonFadeIn.Completed:Connect(function() NoWinsButton.Interactable = true end)
NoWinsButtonFadeOut.Completed:Connect(function() NoWinsButton.Interactable = false end)

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

	WinsButtonFadeIn:Play()
	NoWinsButtonFadeIn:Play()

	local function handleButtonClick(button, event)
		button.Interactable = false
		WinsButton.Interactable = false
		NoWinsButton.Interactable = false

		WinsButtonFadeOut:Play()
		NoWinsButtonFadeOut:Play()

		HelperModule.EnableAllUIs()
		enableMovement()
		blackScreenFade:Play()

		event:FireServer()
	end

	NoWinsButton.MouseButton1Click:Connect(function()
		handleButtonClick(NoWinsButton, NoWinsEvent)
	end)

	WinsButton.MouseButton1Click:Connect(function()
		handleButtonClick(WinsButton, WinsEvent)
	end)
end)
