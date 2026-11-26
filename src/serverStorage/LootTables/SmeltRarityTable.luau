--!strict
--[[
	SmeltRarityTable
	Trách nhiệm: bảng tỉ lệ ra độ hiếm khi nấu phôi theo tổng điểm quặng
	(F3.2, doc mục 3). Số nhạy cảm: đặt trong serverStorage, client không thấy.
	Weights theo thứ tự độ hiếm: Common, Uncommon, Rare, Epic, Legendary, Mythic.
]]

type Band = {
	MinPoints: number,
	MaxPoints: number,
	Weights: { number }, -- 6 trọng số theo thứ tự độ hiếm
}

local SmeltRarityTable = {}

-- Bảng tỉ lệ mẫu của doc mục 3 (tổng điểm của đúng 5 quặng: 5 đến 50).
SmeltRarityTable.Bands = {
	{ MinPoints = 5, MaxPoints = 14, Weights = { 60, 27, 10, 2.9, 0.1, 0 } },
	{ MinPoints = 15, MaxPoints = 24, Weights = { 35, 32, 25, 6.5, 1.3, 0.2 } },
	{ MinPoints = 25, MaxPoints = 34, Weights = { 15, 27, 35, 17, 5, 1 } },
	{ MinPoints = 35, MaxPoints = 44, Weights = { 4, 15, 36, 30, 12, 3 } },
	{ MinPoints = 45, MaxPoints = 50, Weights = { 0, 6, 26, 40, 21, 7 } },
} :: { Band }

return SmeltRarityTable
