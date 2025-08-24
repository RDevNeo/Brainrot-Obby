local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local currentPlayer = Players.LocalPlayer
local petsFolder = Workspace:WaitForChild("PlayerPets")


local module = {}

module.areOthersPetsHidden = false

function module.GetAllCheckpoints()
	local folder = game.Workspace:WaitForChild("CheckPoints")

	local totalCheckpoints = tonumber(#folder:GetChildren())
	return totalCheckpoints
end

function module.GetCheckpoint(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end
	local checkpoint = leaderstats:FindFirstChild("Checkpoint")
	return checkpoint and checkpoint.Value or 0
end

function module.FormatCurrency(amount, symbol)
	symbol = symbol or ""

	amount = tonumber(amount) or 0

	local formatted = tostring(amount):reverse():gsub("(%d%d%d)", "%1,")
	formatted = formatted:gsub(",(%-?)$", "%1")
	formatted = formatted:reverse()

	return symbol .. formatted
end

function module.CountFriendsInServer(player)
	local Players = game:GetService("Players")
	local count:number = 0
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and player:IsFriendsWith(otherPlayer.UserId) then
			count += 1
		end
	end
	return count
end


function module.Setup(guiFrame, dataTable)
	local Players = game:GetService("Players")
	local rs = game:GetService("ReplicatedStorage")
	local RewardEvent = rs.Remotes.UI.Reward
	local player = Players.LocalPlayer

	if not _G.PlayerJoinTime then
		_G.PlayerJoinTime = tick()
		_G.ClaimedRewards = {}
	end

	local function getCurrentSecondsPlayed()
		return math.floor(tick() - _G.PlayerJoinTime)
	end

	local function findButtonById(id)
		for _, descendant in ipairs(guiFrame:GetDescendants()) do
			if descendant:IsA("ImageButton") or descendant:IsA("ImageLabel") then
				if descendant.Name == id then
					return descendant
				end
			end
		end
		return nil
	end

	local function getTimeRemainingText(secondsRequired)
		local currentSeconds = getCurrentSecondsPlayed()
		local remainingSeconds = secondsRequired - currentSeconds
		if remainingSeconds <= 0 then
			return "Claim"
		else
			local minutes = math.floor(remainingSeconds / 60)
			local seconds = remainingSeconds % 60
			return string.format("%02d:%02d", minutes, seconds)
		end
	end

	for _, reward in ipairs(dataTable) do
		local button = findButtonById(reward.id)
		if button then
			local textLabel = button:FindFirstChild("Time")
			local sound = game.Workspace:WaitForChild("GameConfig").Sounds.GotReward
			button.Active = false
			button.AutoButtonColor = false

			local requiredSeconds = reward.minutesRequired * 60
			local claimed = _G.ClaimedRewards[reward.id] or false

			if claimed then
				textLabel.Text = "✅"
			else
				textLabel.Text = getTimeRemainingText(requiredSeconds)
			end

			button.MouseButton1Click:Connect(function()
				if claimed then return end
				local currentSeconds = getCurrentSecondsPlayed()
				if currentSeconds < requiredSeconds then return end

				claimed = true
				_G.ClaimedRewards[reward.id] = true
				button.Active = false
				button.AutoButtonColor = false
				textLabel.Text = "✅"
				if sound then sound:Play() end
				RewardEvent:FireServer(reward.id)
			end)

			if not claimed then
				task.spawn(function()
					while not claimed and not _G.ClaimedRewards[reward.id] do
						task.wait(0.1)

						if _G.ClaimedRewards[reward.id] then
							break
						end

						textLabel.Text = getTimeRemainingText(requiredSeconds)

						local currentSeconds = getCurrentSecondsPlayed()
						if currentSeconds >= requiredSeconds then
							button.Active = true
							button.AutoButtonColor = true
						end
					end
				end)
			end
		else
			warn("Could not find button for reward id: " .. reward.id)
		end
	end
end


function module.DisableSounds()
	local soundsFolder = game.Workspace:WaitForChild("GameConfig").Sounds
	for _, sounds in pairs(soundsFolder:GetChildren()) do
		if sounds:IsA("Sound") then
			sounds.Volume = 0
		end
	end
	
	local petSounds = soundsFolder:WaitForChild("PetSounds")
	
	for _, sounds in pairs(petsFolder:GetChildren()) do
		if sounds:IsA("Sound") then
			sounds.Volume = 0
		end
	end
end

function module.EnableSounds()
	local soundsFolder = game.Workspace:WaitForChild("GameConfig").Sounds

	for _, sound in ipairs(soundsFolder:GetChildren()) do
		if sound:IsA("Sound") then
			if sound.Name == "Ambient" then
				sound.Volume = 0.1
			else
				sound.Volume = 0.5
			end
		end
	end
	
	local petSounds = soundsFolder:WaitForChild("PetSounds")

	for _, sounds in pairs(petsFolder:GetChildren()) do
		if sounds:IsA("Sound") then
			sounds.Volume = 0.5
		end
	end
end


function module.DisablePlayersVisually()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						if part:FindFirstChildOfClass("Decal") then
							part:FindFirstChildOfClass("Decal").Transparency = 1
						end
					elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
						part.Handle.Transparency = 1
					end
				end
			end
		end
	end
end

function module.EnablePlayersVisually()
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0
						if part:FindFirstChildOfClass("Decal") then
							part:FindFirstChildOfClass("Decal").Transparency = 0
						end
					elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
						part.Handle.Transparency = 0
					end
				end
			end
		end
	end
end


function module.SetDay()
	local Lighting = game:GetService("Lighting")
	local LightFolder = game.Workspace.GameConfig.Light

	-- If Day is already active in Lighting, do nothing
	if Lighting:FindFirstChild("Day") then return end

	-- Move any effect currently inside Lighting back into LightFolder (e.g., Night)
	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "Day" or child.Name == "Night" then
			child.Parent = LightFolder
		end
	end

	-- Move Day from the folder into Lighting (if it's not there by default, adjust here)
	local DayEffect = LightFolder:FindFirstChild("Day") or Lighting:FindFirstChild("Day")
	if DayEffect then
		DayEffect.Parent = Lighting
	end
end

-- Activate Night
function module.SetNight()
	local Lighting = game:GetService("Lighting")
	local LightFolder = game.Workspace.GameConfig.Light

	-- If Night is already active in Lighting, do nothing
	if Lighting:FindFirstChild("Night") then return end

	-- Move any effect currently inside Lighting back into LightFolder (e.g., Day)
	for _, child in ipairs(Lighting:GetChildren()) do
		if child.Name == "Day" or child.Name == "Night" then
			child.Parent = LightFolder
		end
	end

	-- Move Night from folder into Lighting
	local NightEffect = LightFolder:FindFirstChild("Night")
	if NightEffect then
		NightEffect.Parent = Lighting
	end
end

-- Utility to set transparency for a model
local function setModelTransparency(model, transparency)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = transparency
			for _, decal in ipairs(part:GetChildren()) do
				if decal:IsA("Decal") then
					decal.Transparency = transparency
				end
			end
		elseif part:IsA("Accessory") and part:FindFirstChild("Handle") then
			part.Handle.Transparency = transparency
		end
	end
end

function module.HideOthersPets()
	if module.areOthersPetsHidden then return end
	module.areOthersPetsHidden = true
	
	
	for _, folder in ipairs(petsFolder:GetChildren()) do
		if folder:IsA("Folder") and folder.Name ~= currentPlayer.Name then
			for _, petModel in ipairs(folder:GetChildren()) do
				if petModel:IsA("Model") then
					setModelTransparency(petModel, 1)
				end
			end
			-- Listen for new pets added to this folder
			if not folder:FindFirstChild("HideListener") then
				local listener = Instance.new("BoolValue")
				listener.Name = "HideListener"
				listener.Parent = folder
				folder.ChildAdded:Connect(function(petModel)
					if petModel:IsA("Model") then
						setModelTransparency(petModel, 1)
					end
				end)
			end
		end
	end

	-- Listen for new player folders
	if not petsFolder:FindFirstChild("FolderListener") then
		local listener = Instance.new("BoolValue")
		listener.Name = "FolderListener"
		listener.Parent = petsFolder
		petsFolder.ChildAdded:Connect(function(folder)
			if folder:IsA("Folder") and folder.Name ~= currentPlayer.Name then
				for _, petModel in ipairs(folder:GetChildren()) do
					if petModel:IsA("Model") then
						setModelTransparency(petModel, 1)
					end
				end
				-- Also listen for pets added later
				if not folder:FindFirstChild("HideListener") then
					local listener2 = Instance.new("BoolValue")
					listener2.Name = "HideListener"
					listener2.Parent = folder
					folder.ChildAdded:Connect(function(petModel)
						if petModel:IsA("Model") then
							setModelTransparency(petModel, 1)
						end
					end)
				end
			end
		end)
	end
end



function module.ShowOthersPets()
	if not module.areOthersPetsHidden then return end
	module.areOthersPetsHidden = false
	
	for _, folder in ipairs(petsFolder:GetChildren()) do
		if folder:IsA("Folder") and folder.Name ~= currentPlayer.Name then
			for _, petModel in ipairs(folder:GetChildren()) do
				if petModel:IsA("Model") then
					setModelTransparency(petModel, 0)
				end
			end
			
			if not folder:FindFirstChild("ShowListener") then
				local listener = Instance.new("BoolValue")
				listener.Name = "ShowListener"
				listener.Parent = folder
				folder.ChildAdded:Connect(function(petModel)
					if petModel:IsA("Model") then
						setModelTransparency(petModel, 0)
					end
				end)
			end
		end
	end

	if not petsFolder:FindFirstChild("FolderListenerShow") then
		local listener = Instance.new("BoolValue")
		listener.Name = "FolderListenerShow"
		listener.Parent = petsFolder
		petsFolder.ChildAdded:Connect(function(folder)
			if folder:IsA("Folder") and folder.Name ~= currentPlayer.Name then
				for _, petModel in ipairs(folder:GetChildren()) do
					if petModel:IsA("Model") then
						setModelTransparency(petModel, 0)
					end
				end
				
				if not folder:FindFirstChild("ShowListener") then
					local listener2 = Instance.new("BoolValue")
					listener2.Name = "ShowListener"
					listener2.Parent = folder
					folder.ChildAdded:Connect(function(petModel)
						if petModel:IsA("Model") then
							setModelTransparency(petModel, 0)
						end
					end)
				end
			end
		end)
	end
end


function module.DisableAllUIs()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "EndGame" then
			gui.Enabled = false
		end
	end
end

function module.EnableAllUIs()
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name ~= "EndGame" then
			gui.Enabled = true
		end
	end
end

function module.PlayRandomPetSound()
	local player = game.Players.LocalPlayer
	local petsSoundFolder = game.Workspace:WaitForChild("GameConfig").Sounds.PetSounds
	local playerPetFolder = game.Workspace.PlayerPets:WaitForChild(player.Name)

	if not petsSoundFolder or not playerPetFolder then
		warn("Pet sound folder or player pet folder not found.")
		return
	end

	while true do
		local randomTime = math.random(15, 40)
		local pets = playerPetFolder:GetChildren()
		if #pets == 0 then
			warn("No pets found for the player, waiting for pets...")
			task.wait(5)
			continue
		end
		local randomIndex = math.random(1, #pets)
		local randomPet = pets[randomIndex]

		local sound = petsSoundFolder:FindFirstChild(randomPet.Name)
		if sound then
			sound:Play()
		else
			warn("Sound not found for pet: " .. randomPet.Name)
		end
		task.wait(randomTime)
	end
end

return module

