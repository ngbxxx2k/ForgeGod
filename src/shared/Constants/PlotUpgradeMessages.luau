--!strict

local PlotUpgradeMessages = {
	NotificationTitle = "Upgrade Plot",
	Title = "Upgrade Plot",
	LevelFormat = "Level %d > Level %d",
	CurrentLevelFormat = "Level %d",
	MaxLevelText = "Max Level",
	CoinPriceFormat = "$%s",
	RobuxPriceFormat = "\u{E002} %s",
	RobuxUnknownPrice = "\u{E002} ?",
	ConfirmTitle = "Upgrade Plot",
	ConfirmFormat = "Spend $%s to unlock pedestal %d?",
	ConfirmButton = "UPGRADE",
	SuccessText = "Plot upgraded!",
	UnknownError = "Something went wrong.",
}

PlotUpgradeMessages.Reasons = {
	NotEnoughCoins = "Not enough coins.",
	MaxLevel = "Your plot is already max level.",
	NotAvailable = "Robux upgrade is not available yet.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	InvalidRequest = "Invalid request.",
	PromptFailed = "Could not open the purchase window.",
}

return PlotUpgradeMessages
