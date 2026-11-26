--!strict
--[[
	ShopRestockTable
	Trách nhiệm: cấu hình sinh tồn kho mỗi lần restock shop (F2.3, F2.5).
	Số nhạy cảm: đặt trong serverStorage, client không thấy được.
	PLACEHOLDER: toàn bộ số liệu dưới đây là giá trị tạm, doc chưa cung cấp.
]]

-- Định nghĩa một mặt hàng trong lần restock:
--   AppearanceRate: tỉ lệ mặt hàng xuất hiện trong chu kỳ (0 -> 1).
--   MinAmount/MaxAmount: khoảng số lượng lô nếu xuất hiện.
type RestockEntry = {
	AppearanceRate: number,
	MinAmount: number,
	MaxAmount: number,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedConfig = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local BuffConfig = require(sharedConfig:WaitForChild("BuffConfig"))
local WeaponItemConfig = require(sharedConfig:WaitForChild("WeaponItemConfig"))

local ShopRestockTable = {}

ShopRestockTable.BuffRestockByRarity = {
	Common = { AppearanceRate = 0.9, MinAmount = 3, MaxAmount = 5 },
	Uncommon = { AppearanceRate = 0.6, MinAmount = 2, MaxAmount = 4 },
	Rare = { AppearanceRate = 0.35, MinAmount = 1, MaxAmount = 2 },
	Epic = { AppearanceRate = 0.2, MinAmount = 1, MaxAmount = 2 },
	Legendary = { AppearanceRate = 0.1, MinAmount = 1, MaxAmount = 1 },
	Mythic = { AppearanceRate = 0.07, MinAmount = 1, MaxAmount = 1 },
} :: { [string]: RestockEntry }

ShopRestockTable.Entries = {} :: { [string]: RestockEntry }

local function addByRarity(itemId: string, rarity: string)
	local entry = ShopRestockTable.BuffRestockByRarity[rarity]
	if entry == nil then
		warn("[ShopRestockTable] No restock entry for rarity", rarity, "of", itemId)
		return
	end
	ShopRestockTable.Entries[itemId] = table.clone(entry)
end

for _, buff in BuffConfig.Buffs do
	addByRarity(buff.Id, buff.Rarity)
end

for _, item in WeaponItemConfig.Items do
	addByRarity(item.Id, item.Rarity)
end

return ShopRestockTable
