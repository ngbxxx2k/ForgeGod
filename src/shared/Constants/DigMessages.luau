--!strict

local DigMessages = {
	NotificationTitle = "Digging",
	UpgradeTitle = "Upgrades",
	PromptObjectText = "Buried Ore",
	PromptActionText = "Dig",
	UnknownError = "Something went wrong.",
	FoundFormat = "You dug up %s!",
	OwnedText = "OWNED",
	EquippedText = "EQUIPPED",
	EquipText = "EQUIP",
	EquippedFormat = "Now using %s.",
	LockedText = "LOCKED",
	BoughtFormat = "%s unlocked!",
	RadiusFormat = '<font color="#82FF3C">%s</font> Radius  <font color="#82FF3C">x%s</font> Luck',
	SpeedFormat = '<font color="#82FF3C">x%s</font> %s',
	DetectorTabLabel = "DETECTOR",
	ShovelTabLabel = "SHOVEL",
	RobuxComingSoon = "Robux purchases are coming soon!",
}

DigMessages.Reasons = {
	NotInZone = "Go to the dig site in the middle of the map.",
	NoSpot = "Nothing buried here. Follow the green signal!",
	AlreadyDigging = "You are already digging.",
	Interrupted = "Digging was interrupted.",
	NoCharacter = "Your character is not ready.",
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "Slow down!",
	InvalidRequest = "Invalid request.",
	NotEnoughCoins = "Not enough coins.",
	AlreadyOwned = "You already own this.",
	NotOwned = "Unlock this tier first.",
	BuyPreviousFirst = "Unlock the previous tier first.",
	NotAvailable = "Robux purchases are coming soon!",
	PromptFailed = "Could not open the purchase window.",
}

return DigMessages
