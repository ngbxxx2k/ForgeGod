--!strict
--[[
	WeaponScaleTable
	Trách nhiệm: tỉ lệ ra hệ số kích thước vũ khí khi nấu phôi.
	Số nhạy cảm: đặt trong serverStorage, client không thấy.
	Mỗi khoảng: Min..Max là hệ số, Weight là trọng số (càng to càng hiếm).
]]

type Band = {
	Min: number,
	Max: number,
	Weight: number,
}

local WeaponScaleTable = {}

-- PLACEHOLDER: tỉ lệ tạm, tổng trọng số 100 = phần trăm
WeaponScaleTable.Bands = {
	Normal = { Min = 1, Max = 2, Weight = 70 },
	Large = { Min = 2, Max = 4, Weight = 20 },
	Huge = { Min = 4, Max = 6, Weight = 7 },
	Giant = { Min = 6, Max = 8, Weight = 2.5 },
	Colossal = { Min = 8, Max = 10, Weight = 0.5 },
} :: { [string]: Band }

return WeaponScaleTable
