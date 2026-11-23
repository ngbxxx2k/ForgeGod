--!strict

local WeaponWeightConfig = {}

-- Hệ số kích thước vũ khí: nhỏ nhất x1 (kích thước mặc định), lớn nhất x10
-- Giá vũ khí = giá gốc theo cấp x hệ số kích thước
WeaponWeightConfig.MinScale = 1
WeaponWeightConfig.MaxScale = 10
-- Số chữ số thập phân khi lưu hệ số (2 -> ví dụ x3.47)
WeaponWeightConfig.ScaleDecimals = 2

-- PLACEHOLDER: cân nặng gốc (kg) theo họ vũ khí ở hệ số x1; cân nặng = cân nặng gốc x hệ số
WeaponWeightConfig.BaseWeights = {
	Sword = 3,
	Axe = 5,
	Spear = 4,
	Dagger = 1,
	Hammer = 8,
} :: { [string]: number }

-- Cân nặng gốc khi họ vũ khí không có trong bảng trên
WeaponWeightConfig.DefaultBaseWeight = 3

-- Số chữ số thập phân khi hiển thị cân nặng và định dạng hiển thị
WeaponWeightConfig.WeightDecimals = 1
WeaponWeightConfig.WeightFormat = "%.1f kg"

return WeaponWeightConfig
