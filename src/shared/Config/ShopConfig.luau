--!strict
--[[
	ShopConfig
	Trách nhiệm: số liệu cân bằng shop mà client cũng cần biết (giá hiển thị,
	giới hạn mua mỗi lần, chu kỳ restock).
]]

local BuffConfig = require(script.Parent.BuffConfig)

local MUTATION_ERASER_ID = "MutationEraser"

local ShopConfig = {}

-- Giá bán từng mặt hàng (F2.1 quặng, F2.2 vật phẩm buff).
-- Giá quặng lấy từ doc game-features.md mục 2.
-- PLACEHOLDER: giá các vật phẩm buff chưa có trong doc, đang dùng giá trị tạm.
ShopConfig.ItemPrices = {
	-- Quặng
	Copper = 20,
	Iron = 100,
	Silver = 300,
	Gold = 1000,
	Platinum = 5000,
	Emerald = 15000,
	DarkMoonstone = 60000,
	Mithril = 250000,
	GodsCore = 1000000,

	MutationEraser = 5000,
} :: { [string]: number }

for _, buff in BuffConfig.Buffs do
	ShopConfig.ItemPrices[buff.Id] = buff.Price
end

-- Chu kỳ restock shop (giây) (F2.4). Chia mốc của os.time() theo số này
-- để mọi server tính ra cùng kết quả.
ShopConfig.RestockInterval = 300

-- Số lượng tối đa mỗi yêu cầu mua (chặn mua lố để spam remote).
ShopConfig.MaxBuyPerRequest = 99

-- Thứ tự hiển thị quặng trong UI shop
ShopConfig.OreDisplayOrder = {
	"Copper",
	"Iron",
	"Silver",
	"Gold",
	"Platinum",
	"Emerald",
	"DarkMoonstone",
	"Mithril",
	"GodsCore",
}

ShopConfig.BuffDisplayOrder = {} :: { string }

for _, buff in BuffConfig.Buffs do
	table.insert(ShopConfig.BuffDisplayOrder, buff.Id)
end
table.insert(ShopConfig.BuffDisplayOrder, MUTATION_ERASER_ID)

return ShopConfig
