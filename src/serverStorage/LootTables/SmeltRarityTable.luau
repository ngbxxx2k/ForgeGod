--!strict
--[[
	SmeltRarityTable
	Trách nhiệm: bảng tỉ lệ ra độ hiếm khi nấu phôi theo tổng điểm quặng
	(F3.2, doc mục 3). Số nhạy cảm: đặt trong serverStorage, client không thấy.
	Weights theo thứ tự độ hiếm: Common, Rare, Epic, Legendary, Mythic.
]]

type Band = {
	MinPoints: number,
	MaxPoints: number,
	Weights: { number }, -- 5 trọng số theo thứ tự độ hiếm
}

local SmeltRarityTable = {}

-- Bảng tỉ lệ mẫu của doc mục 3 (tổng điểm của đúng 5 quặng: 5 đến 50).
SmeltRarityTable.Bands = {
	{ MinPoints = 5, MaxPoints = 14, Weights = { 95, 5, 0, 0, 0 } },
	{ MinPoints = 15, MaxPoints = 24, Weights = { 70, 28, 2, 0, 0 } },
	{ MinPoints = 25, MaxPoints = 34, Weights = { 40, 45, 12, 2.5, 0.5 } },
	{ MinPoints = 35, MaxPoints = 44, Weights = { 15, 50, 25, 8, 2 } },
	{ MinPoints = 45, MaxPoints = 50, Weights = { 0, 40, 40, 15, 5 } },
} :: { Band }

return SmeltRarityTable
