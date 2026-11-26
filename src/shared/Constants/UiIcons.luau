--!strict

local AssetIds = require(script.Parent.AssetIds)

local UiIcons = {
	Locked = AssetIds.Icons.Locked,
	Unlocked = AssetIds.Icons.Unlocked,
	BackpackTabs = {
		Weapon = AssetIds.Icons.TabWeapon,
		Ore = AssetIds.Icons.TabOre,
		Buff = AssetIds.Icons.TabBuff,
	},
	ShopCategories = {
		Item = AssetIds.Icons.TabBuff,
	},
	Robux = AssetIds.Icons.Robux,
	Gift = AssetIds.Icons.Gift,
	PremiumShop = {
		Header = AssetIds.Icons.PremiumShop,
		Passes = {
			DoubleMoney = AssetIds.Icons.Coin,
			DoubleLuck = AssetIds.Icons.LuckPotion,
		} :: { [string]: string },
		CoinPacks = {
			Coins30K = AssetIds.Icons.Coin,
			Coins300K = AssetIds.Icons.Coin,
			Coins3M = AssetIds.Icons.Coin,
			Coins30M = AssetIds.Icons.Coin,
			Coins300M = AssetIds.Icons.Coin,
		} :: { [string]: string },
	},
	SpinWheel = {
		Header = AssetIds.Icons.SpinWheel,
		Coins = AssetIds.Icons.Coin,
		ExtraSpin = AssetIds.Icons.SpinWheel,
	},
}

return UiIcons
