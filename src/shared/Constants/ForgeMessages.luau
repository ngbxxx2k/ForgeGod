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
	ShapeChangedText = "SHAPE UP!",
	FrenzyStartedText = "FRENZY! Click fast!",
	ShapeAndFrenzyText = "SHAPE UP! FRENZY! Click fast!",
	NoWeaponName = "No weapon selected",
	ForgeText = "FORGE",
	WeaponBrokeText = "Your weapon broke! Pick another one.",
	WeaponProtectedText = "Your Guardian Talisman saved your weapon from breaking!",
	NotificationTitle = "Forge",
	UnknownError = "Something went wrong.",
	CoinsFormat = "%s Coins/s",
	ValueDetailFormat = "%s%s Coins/s · %sx",
	ChanceFormat = "%s chance",
	WholePercentFormat = "%d%%",
	ProtectedDisplayName = "SAVED!",
	ProtectedDetailText = "Talisman protected it",
	ReadyText = "READY",
	CooldownText = "COOLDOWN",
	ReadyDetailText = "Click to forge",
}

ForgeMessages.Reasons = {
	WeaponEquipped = "Unequip this weapon from your Loadout to forge it.",
	WeaponBroken = "This weapon is broken.",
	ForgeLocked = "Cooling down...",
	FrenzyActive = "Finish the frenzy first.",
	MaxLevelReached = "This weapon is at max level.",
	TooFar = "Move closer to the anvil.",
	RateLimited = "Slow down!",
	NotLoaded = "Your data is still loading, please wait.",
	WeaponNotFound = "Weapon not found.",
	WeaponLocked = "This weapon is locked.",
	InvalidRequest = "Invalid request.",
}

return ForgeMessages
