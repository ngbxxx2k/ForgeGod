--!strict
--[[
	FurnaceConfig
	Trách nhiệm: số liệu cân bằng lò nấu (F3) mà client cũng cần biết
	(số quặng mỗi công thức, giá gốc theo độ hiếm).
]]

local FurnaceConfig = {}

-- Số quặng mỗi công thức nấu (F3.2, doc mục 3: dùng 5 quặng).
FurnaceConfig.RecipeSize = 5

-- Giá gốc vũ khí/phôi theo độ hiếm (doc mục 2, lựa chọn của người dùng).
FurnaceConfig.BaseValues = {
	Common = 50,
	Uncommon = 120,
	Rare = 250,
	Epic = 2000,
	Legendary = 20000,
	Mythic = 120000,
}

return FurnaceConfig
