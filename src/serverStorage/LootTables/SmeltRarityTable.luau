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
	{ MinPoints = 5, MaxPoints = 14, Weights = { 75, 20, 5, 0, 0, 0 } },
	{ MinPoints = 15, MaxPoints = 24, Weights = { 45, 30, 23, 2, 0, 0 } },
	{ MinPoints = 25, MaxPoints = 34, Weights = { 20, 30, 35, 12, 2.5, 0.5 } },
	{ MinPoints = 35, MaxPoints = 44, Weights = { 5, 20, 40, 25, 8, 2 } },
	{ MinPoints = 45, MaxPoints = 50, Weights = { 0, 10, 30, 40, 15, 5 } },
} :: { Band }

return SmeltRarityTable
