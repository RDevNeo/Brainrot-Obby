local rs = game:GetService("ReplicatedStorage")
local ShowCoinUIEvent = rs.Remotes.UI.ShowCoinsUI
local UIModule = require(rs.UI)

ShowCoinUIEvent.OnClientEvent:Connect(function(coinQuantity)
	UIModule.ShowCoinsEarned(coinQuantity)
end)