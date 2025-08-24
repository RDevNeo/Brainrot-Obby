local checkpointsFolder = game.Workspace:WaitForChild("CheckPoints")
local player = game.Players.LocalPlayer
local Checkpoint = player:WaitForChild("leaderstats"):WaitForChild("Checkpoint")

local TweenService = game:GetService("TweenService")
local activeTweens = {}

local function UpdateVisibility()
    for _, models in pairs(checkpointsFolder:GetChildren()) do
        local billboardGui = models:WaitForChild("BillboardArrow")
        local currentCheckpoint = Checkpoint.Value

        if tonumber(billboardGui.Parent.Name) == currentCheckpoint + 1 then
            if not billboardGui.Enabled then
                billboardGui.Enabled = true
                
                local imageLabel = billboardGui:WaitForChild("ImageLabel")
                
                --tween logic
                if activeTweens[imageLabel] then
                    activeTweens[imageLabel]:Cancel()
                end
                
                local originalPosition = imageLabel.Position
                imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Ensure it starts from a centered position
                
                local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true, 0)
                
                local bounceTween = TweenService:Create(imageLabel, tweenInfo, {Position = UDim2.new(0.5, 0, 0.3, 0)}) -- Tween to a slightly higher position
                bounceTween:Play()
                activeTweens[imageLabel] = bounceTween
            end
        else
            if billboardGui.Enabled then
                local imageLabel = billboardGui:WaitForChild("ImageLabel")

                if activeTweens[imageLabel] then
                    activeTweens[imageLabel]:Cancel()
                    activeTweens[imageLabel] = nil
                end
                billboardGui.Enabled = false
                imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
        end

    end
end

UpdateVisibility()


Checkpoint.Changed:Connect(function()
    UpdateVisibility()
end)