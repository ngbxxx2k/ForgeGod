--!strict

local ForgeUpgradeMessages = {
	NotificationTitle = "Upgrades",
	ZoneLabel = "UPGRADE",
	EquippedText = "EQUIPPED",
	EquipText = "EQUIP",
	LuckStatFormat = '<font color="#82FF3C">+%d%%</font> %s',
	CoinPriceFormat = "$%s",
	RobuxPriceFormat = "\u{E002} %s",
	BoughtFormat = "%s unlocked!",
	SkinChangedFormat = "Now using %s look.",
	UnknownError = "Something went wrong.",
}

ForgeUpgradeMessages.Reasons = {
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "Slow down!",
	InvalidRequest = "Invalid request.",
	NotEnoughCoins = "Not enough coins.",
	AlreadyOwned = "You already own this.",
	NotOwned = "Unlock this tier first.",
	NotAvailable = "Robux purchases are coming soon!",
	PromptFailed = "Could not open the purchase window.",
}

return ForgeUpgradeMessages
