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

local ShopRestockTable = {}

ShopRestockTable.BuffRestockByRarity = {
	Common = { AppearanceRate = 0.8, MinAmount = 3, MaxAmount = 5 },
	Uncommon = { AppearanceRate = 0.5, MinAmount = 2, MaxAmount = 4 },
	Rare = { AppearanceRate = 0.25, MinAmount = 1, MaxAmount = 2 },
} :: { [string]: RestockEntry }

ShopRestockTable.Entries = {
	-- Quặng: càng hiếm càng khó xuất hiện và lô càng nhỏ (F2.5)
	Copper = { AppearanceRate = 1.0, MinAmount = 30, MaxAmount = 50 },
	Iron = { AppearanceRate = 0.95, MinAmount = 20, MaxAmount = 35 },
	Silver = { AppearanceRate = 0.85, MinAmount = 14, MaxAmount = 25 },
	Gold = { AppearanceRate = 0.7, MinAmount = 10, MaxAmount = 18 },
	Platinum = { AppearanceRate = 0.5, MinAmount = 6, MaxAmount = 12 },
	Emerald = { AppearanceRate = 0.3, MinAmount = 4, MaxAmount = 8 },
	DarkMoonstone = { AppearanceRate = 0.15, MinAmount = 2, MaxAmount = 5 },
	Mithril = { AppearanceRate = 0.05, MinAmount = 1, MaxAmount = 3 },
	GodsCore = { AppearanceRate = 0.02, MinAmount = 1, MaxAmount = 2 },

	MutationEraser = { AppearanceRate = 0.25, MinAmount = 1, MaxAmount = 3 },
} :: { [string]: RestockEntry }

for _, buff in BuffConfig.Buffs do
	local entry = ShopRestockTable.BuffRestockByRarity[buff.Rarity]
	if entry == nil then
		warn("[ShopRestockTable] No restock entry for rarity", buff.Rarity, "of", buff.Id)
	else
		ShopRestockTable.Entries[buff.Id] = table.clone(entry)
	end
end

return ShopRestockTable
