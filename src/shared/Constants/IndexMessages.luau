--!strict

local IndexMessages = {
	UnknownName = "???",
	Locked = "LOCKED",
	Claim = "CLAIM",
	Claimed = "CLAIMED",
	ProgressFormat = "%d/%d",
	UnlockedFormat = "UNLOCKED: %d/%d",
	ChanceFormat = "(%s%%)",
	RewardFormat = "%dx %s",
	ClaimedToastFormat = "Claimed %s!",
	UnknownError = "Could not claim reward",
	Reasons = {
		AlreadyClaimed = "Reward already claimed",
		CollectionIncomplete = "Collect every weapon in this set first",
		RateLimited = "Slow down!",
		NotLoaded = "Your data is still loading",
		InvalidRequest = "Could not claim reward",
	} :: { [string]: string },
}

return IndexMessages
