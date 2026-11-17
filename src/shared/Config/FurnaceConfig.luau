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
	Common = 500,
	Rare = 2500,
	Epic = 20000,
	Legendary = 200000,
	Mythic = 1200000,
}

-- Hệ số giá phôi: giá phôi = giá gốc x hệ số random trong khoảng này
-- (F3.3, doc mục 3: hệ số trong khoảng 1 đến 2).
FurnaceConfig.MinValueMultiplier = 1
FurnaceConfig.MaxValueMultiplier = 2

return FurnaceConfig
