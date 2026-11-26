--!strict

local SpinMessages = {}

SpinMessages.Title = "SPIN THE LUCKY WHEEL"
SpinMessages.HudLabel = "Spin"
SpinMessages.TokensFormat = "Spins left: %d"
SpinMessages.FreeReady = "Free spin ready!"
SpinMessages.FreeCountdownFormat = "Free spin in %02d:%02d:%02d"
SpinMessages.SpinButton = "SPIN"
SpinMessages.FreeSpinButton = "FREE SPIN"
SpinMessages.SpinningButton = "..."
SpinMessages.HideButton = "Hide"
SpinMessages.BuyButton = "Buy x1"
SpinMessages.RewardWonFormat = "You won %s!"
SpinMessages.PurchaseSuccess = "+1 spin!"
SpinMessages.UnknownError = "Something went wrong."

SpinMessages.CoinsFormat = "$%s"
SpinMessages.AmountFormat = "%s x%d"
SpinMessages.ExtraSpinLabel = "+1 Spin"

SpinMessages.Reasons = {
	NoSpins = "No spins left. Wait for the free spin or buy one.",
	Spinning = "The wheel is still spinning.",
	NotAvailable = "This item is not available yet.",
	PromptFailed = "Could not open the purchase window.",
	NotLoaded = "Your data is still loading, please wait.",
	RateLimited = "Slow down a little.",
	MaxTokens = "You have too many spins saved.",
}

return SpinMessages
