--!strict

local WeightedPick = {}

function WeightedPick.Pick(weights: { [string]: number }, rng: Random): string?
	local ids = {}
	local totalWeight = 0
	for id, weight in weights do
		if weight > 0 then
			table.insert(ids, id)
			totalWeight += weight
		end
	end
	if totalWeight <= 0 then
		return nil
	end
	table.sort(ids)
	local roll = rng:NextNumber(0, totalWeight)
	local cumulative = 0
	for _, id in ids do
		cumulative += weights[id]
		if roll < cumulative then
			return id
		end
	end
	return ids[#ids]
end

return WeightedPick
