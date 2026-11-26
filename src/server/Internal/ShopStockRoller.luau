--!strict

local ServerStorage = game:GetService("ServerStorage")

local ShopRestockTable = require(ServerStorage:WaitForChild("LootTables"):WaitForChild("ShopRestockTable"))

local ShopStockRoller = {}

local function getSortedIds(): { string }
	local ids = {}
	for id in ShopRestockTable.Entries do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

function ShopStockRoller.Roll(rng: Random): { [string]: number }
	local stock: { [string]: number } = {}
	for _, id in getSortedIds() do
		local entry = ShopRestockTable.Entries[id]
		if rng:NextNumber() < entry.AppearanceRate then
			stock[id] = rng:NextInteger(entry.MinAmount, entry.MaxAmount)
		end
	end
	return stock
end

return ShopStockRoller
