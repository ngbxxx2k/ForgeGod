--!strict

local ForgeMessages = {
	LevelFormat = "+%d",
	MoneyFormat = "$%s",
	PercentFormat = "%.1f%%",
	PointsFormat = "%d / %d",
	PointDeltaFormat = "%+d",
	ResultFormat = "%s %s",
	ResultDetailFormat = "%s$%s · %sx",
	FrenzyDetailFormat = "%s$%s · %.1fs left",
	PositiveSign = "+",
	NegativeSign = "-",
	FrenzyDisplayName = "FRENZY",
	ShapeChangedText = "SHAPE UP! Click fast!",
	NoWeaponName = "No weapon equipped",
	WeaponBrokeText = "Your weapon broke! Pick another one.",
	WeaponProtectedText = "Your Guardian Talisman saved your weapon from breaking!",
	NotificationTitle = "Forge",
	UnknownError = "Something went wrong.",
}

ForgeMessages.Reasons = {
	NoWeaponEquipped = "Equip a weapon in your backpack first.",
	WeaponBroken = "This weapon is broken.",
	ForgeLocked = "Cooling down...",
	FrenzyActive = "Finish the frenzy first.",
	MaxLevelReached = "This weapon is at max level.",
	TooFar = "Move closer to the anvil.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	WeaponNotFound = "Weapon not found.",
	WeaponChanged = "Select a weapon to forge first.",
	WeaponLocked = "This weapon is locked.",
	InvalidRequest = "Invalid request.",
}

return ForgeMessages
