--!strict
--[[
	ShopConfig
	Trách nhiệm: số liệu cân bằng shop mà client cũng cần biết (giá hiển thị,
	giới hạn mua mỗi lần, chu kỳ restock).
]]

local BuffConfig = require(script.Parent.BuffConfig)
local WeaponItemConfig = require(script.Parent.WeaponItemConfig)

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

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
} :: { [string]: number }

for _, buff in BuffConfig.Buffs do
	ShopConfig.ItemPrices[buff.Id] = buff.Price
end

for _, item in WeaponItemConfig.Items do
	ShopConfig.ItemPrices[item.Id] = item.Price
end

export type RobuxProduct = {
	ProductId: number,
	RobuxPrice: number,
	GiftProductId: number?,
}

ShopConfig.RobuxPurchaseKinds = {
	Item = "Item",
	Restock = "Restock",
}

-- GiftProductId = Developer Product riêng để tặng vật phẩm
ShopConfig.ItemRobuxProducts = {
	BlessingPotion = { ProductId = 3736223472, RobuxPrice = 19, GiftProductId = 3736224572 },
	LuckPotion = { ProductId = 3736223488, RobuxPrice = 29, GiftProductId = 3736224584 },
	MutationCatalyst = { ProductId = 3736223509, RobuxPrice = 49, GiftProductId = 3736224605 },
	AlloyFluxPotion = { ProductId = 3736223586, RobuxPrice = 79, GiftProductId = 3736224686 },
	StormPotion = { ProductId = 3736223595, RobuxPrice = 79, GiftProductId = 3736224699 },
	MutationEraser = { ProductId = 3736223607, RobuxPrice = 99, GiftProductId = 3736224715 },
	Talisman = { ProductId = 3736223657, RobuxPrice = 149, GiftProductId = 3736224790 },
	AngelHeart = { ProductId = 3736223674, RobuxPrice = 229, GiftProductId = 3736224810 },
} :: { [string]: RobuxProduct }

-- Developer Product restock Item Shop cho cả server
ShopConfig.RestockProduct = { ProductId = 3736223396, RobuxPrice = 29 } :: RobuxProduct

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

ShopConfig.BuffDisplayOrder = {
	"BlessingPotion",
	"LuckPotion",
	"AngelHeart",
	"MutationCatalyst",
	"AlloyFluxPotion",
	"StormPotion",
	"Talisman",
	"MutationEraser",
}

local function getItemRarity(itemId: string): string?
	local buff = BuffConfig.ById[itemId]
	if buff then
		return buff.Rarity
	end
	local weaponItem = WeaponItemConfig.ById[itemId]
	return if weaponItem then weaponItem.Rarity else nil
end

local function getRarityRank(itemId: string): number
	local rarity = getItemRarity(itemId)
	local rank = if rarity then table.find(RARITY_ORDER, rarity) else nil
	return rank or #RARITY_ORDER + 1
end

local function sortByRarity(itemIds: { string })
	local declaredIndex: { [string]: number } = {}
	for index, itemId in itemIds do
		declaredIndex[itemId] = index
	end
	table.sort(itemIds, function(a: string, b: string): boolean
		local rankA, rankB = getRarityRank(a), getRarityRank(b)
		if rankA ~= rankB then
			return rankA < rankB
		end
		return declaredIndex[a] < declaredIndex[b]
	end)
end

sortByRarity(ShopConfig.BuffDisplayOrder)

for _, itemId in ShopConfig.BuffDisplayOrder do
	if ShopConfig.ItemPrices[itemId] == nil then
		warn("[ShopConfig] Display item has no price:", itemId)
	end
end

return ShopConfig
