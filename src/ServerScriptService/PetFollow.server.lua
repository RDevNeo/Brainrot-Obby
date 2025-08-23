local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PetFolder = Workspace:WaitForChild("PlayerPets")

local PetsPerRow = 5
local HorizontalSpacing = 2
local RowSpacing = 2
local VerticalOffset = -2.5
local SpringFreq = 10
local MIN_LOOK_MAG = 1e-6
local petState = setmetatable({}, { __mode = "k" })

local function springStepVec3(current, velocity, target, freq, dt)
	local wd = freq * dt
	local f = 1 + wd + 0.48 * wd * wd + 0.235 * wd * wd * wd
	local change = current - target
	local temp = (velocity + change * freq) * dt
	velocity = (velocity - temp * freq) / f
	current = target + (change + temp) / f
	return current, velocity
end

RunService.Heartbeat:Connect(function(dt)
	if dt <= 0 then return end

	for _, playerPetFolder in pairs(PetFolder:GetChildren()) do
		local owner = Players:FindFirstChild(playerPetFolder.Name)
		if not owner then
			continue
		end

		local character = owner.Character
		if not character then
			continue
		end

		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			continue
		end

		local pets = {}
		for _, p in ipairs(playerPetFolder:GetChildren()) do
			if p:IsA("Model") and p.PrimaryPart then
				table.insert(pets, p)
			end
		end

		if #pets == 0 then
			continue
		end

		local targets = {}
		for i = 1, #pets do
			local rowIndex = math.ceil(i / PetsPerRow)
			local colIndex = ((i - 1) % PetsPerRow) + 1

			local xOffset = (colIndex - 1) * HorizontalSpacing - ((PetsPerRow - 1) * HorizontalSpacing) / 2
			local zOffset = ((rowIndex - 1) * RowSpacing)

			local localOffset = Vector3.new(xOffset, 0, zOffset)
			local worldOffset = hrp.CFrame:VectorToWorldSpace(localOffset)
			local basePos = hrp.Position + worldOffset

			local targetPos = Vector3.new(basePos.X, hrp.Position.Y + VerticalOffset, basePos.Z)
			targets[i] = targetPos
		end

		for i, pet in ipairs(pets) do
			local prim = pet.PrimaryPart
			if not prim then
				continue
			end

			local state = petState[pet]
			if not state then
				state = {
					posVel = Vector3.new(0,0,0),
					lookVel = Vector3.new(0,0,0),
				}
				petState[pet] = state
			end

			local curPos = prim.Position
			local tgtPos = targets[i]
			local newPos, newPosVel = springStepVec3(curPos, state.posVel, tgtPos, SpringFreq, dt)
			state.posVel = newPosVel

			local curLook = prim.CFrame.LookVector
			local curLookH = Vector3.new(curLook.X, 0, curLook.Z)
			if curLookH.Magnitude < MIN_LOOK_MAG then
				curLookH = Vector3.new(0, 0, 1)
			else
				curLookH = curLookH.Unit
			end

			local hrpLook = hrp.CFrame.LookVector
			local tgtLookH = Vector3.new(hrpLook.X, 0, hrpLook.Z)
			if tgtLookH.Magnitude < MIN_LOOK_MAG then
				tgtLookH = curLookH
			else
				tgtLookH = tgtLookH.Unit
			end

			local lookCurrentVec = Vector3.new(curLookH.X, 0, curLookH.Z)
			local lookTargetVec = Vector3.new(tgtLookH.X, 0, tgtLookH.Z)
			local newLookVec, newLookVel = springStepVec3(lookCurrentVec, state.lookVel, lookTargetVec, SpringFreq, dt)
			state.lookVel = newLookVel

			if newLookVec.Magnitude < MIN_LOOK_MAG then
				newLookVec = Vector3.new(0, 0, 1)
			else
				newLookVec = Vector3.new(newLookVec.X, 0, newLookVec.Z).Unit
			end

			local finalCF = CFrame.new(newPos, newPos + newLookVec)
			pet:PivotTo(finalCF)
		end

	end
end)
