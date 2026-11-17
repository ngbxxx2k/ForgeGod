--!strict
--[[
	WeaponCatalog
	Trách nhiệm: danh mục 25 loại vũ khí (F3.5): 5 họ vũ khí x 5 độ hiếm.
	-- PLACEHOLDER: doc chưa đặt tên 25 loại, tên hiển thị dưới đây là tạm.
]]

type WeaponType = {
	Id: string, -- mã loại vũ khí, ví dụ "CommonSword"
	Family: string, -- họ vũ khí: Sword/Axe/Spear/Dagger/Hammer
	DisplayName: string, -- tên hiển thị cho client
}

local RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic" }
local FAMILIES = { "Sword", "Axe", "Spear", "Dagger", "Hammer" }

-- PLACEHOLDER: tiền tố tên hiển thị theo độ hiếm.
local NAME_PREFIX = {
	Common = "Copper",
	Rare = "Silver",
	Epic = "Golden",
	Legendary = "Platinum",
	Mythic = "Godly",
}

local WeaponCatalog = {}

WeaponCatalog.Families = FAMILIES

-- Types[rarity] = danh sách 5 loại vũ khí của độ hiếm đó.
WeaponCatalog.Types = {} :: { [string]: { WeaponType } }

for _, rarity in RARITY_ORDER do
	local list = {}
	for _, family in FAMILIES do
		table.insert(list, {
			Id = rarity .. family,
			Family = family,
			DisplayName = NAME_PREFIX[rarity] .. " " .. family,
		})
	end
	WeaponCatalog.Types[rarity] = list
end

return WeaponCatalog
