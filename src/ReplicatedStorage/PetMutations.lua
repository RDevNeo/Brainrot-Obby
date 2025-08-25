local mutationsTable = {}

mutationsTable.Mutations = {
    ["Shiny"] = {
        name = "Shiny",
        chance = 32,
        buff = 13,
        textColor = Color3.new(0.466667, 0.596078, 0.6)
    },
    ["Frozen"] = {
        name = "Frozen",
        chance = 10,
        buff = 12,
        textColor = Color3.new(0.298039, 0.788235, 0.807843)
    },
    ["Windy"] = {
        name = "Windy",
        chance = 8,
        buff = 13,
        textColor = Color3.new(0.266667, 0.364706, 0.368627)
    },
    ["Mega"] = {
        name = "Mega",
        chance = 7,
        buff = 15,
		textColor = Color3.new(0.792157, 0.341176, 0.341176),
		scale = Vector3.new(0.5, 0.5, 0.5)
    },
    ["Tiny"] = {
        name = "Tiny",
        chance = 7,
        buff = 15,
		textColor = Color3.new(0.694118, 0.337255, 0.486275),
		scale = Vector3.new(0.5, 0.5, 0.5),
    },
    ["Golden"] = {
        name = "Golden",
        chance = 7,
        buff = 15,
        textColor = Color3.new(0.623529, 0.666667, 0.239216)
    },
    ["Rainbow"] = {
        name = "Rainbow",
        chance = 3,
        buff = 20,
        textColor = Color3.new(0.486274, 0.235294, 0.631372)
    },
    ["Shocked"] = {
        name = "Shocked",
        chance = 3,
        buff = 20,
        textColor = Color3.new(1, 0.933333, 0)
    },
}

function mutationsTable.getRandomMutation()
	local totalWeight = 0
	for mutationName, mutationData in pairs(mutationsTable.Mutations) do
		totalWeight = totalWeight + mutationData.chance
	end

	local randomValue = math.random(1, totalWeight)
	local currentWeight = 0

	for mutationName, mutationData in pairs(mutationsTable.Mutations) do
		currentWeight = currentWeight + mutationData.chance
		if randomValue <= currentWeight then
			return mutationData
		end
	end
end

return mutationsTable