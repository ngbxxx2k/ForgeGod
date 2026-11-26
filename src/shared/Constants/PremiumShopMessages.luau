--!strict

local PremiumShopMessages = {}

PremiumShopMessages.PassesTitle = "-- PASSES --"
PremiumShopMessages.MoneyTitle = "-- MONEY --"
PremiumShopMessages.OresTitle = "-- ORES --"
PremiumShopMessages.OreAmountFormat = "x%d"
PremiumShopMessages.Owned = "OWNED"
PremiumShopMessages.PriceFormat = "%s"
PremiumShopMessages.CoinsFormat = "$%s"
PremiumShopMessages.PurchaseSuccess = "Purchase complete!"
PremiumShopMessages.PassOwnedNotice = "%s unlocked!"
PremiumShopMessages.UnknownError = "Something went wrong."

PremiumShopMessages.Passes = {
	DoubleMoney = {
		Title = "x2 Money",
		Description = 'Weapons earn <font color="#5CFF3C">x2</font> money!',
	},
	DoubleLuck = {
		Title = "x2 Luck",
		Description = 'Forge, smelt & dig with <font color="#5CFF3C">x2</font> luck!',
	},
}

PremiumShopMessages.Reasons = {
	InvalidRequest = "Invalid request.",
	NotAvailable = "This item is not available yet.",
	AlreadyOwned = "You already own this pass.",
	PromptFailed = "Could not open the purchase window.",
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "Slow down a little.",
}

return PremiumShopMessages
