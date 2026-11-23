--!strict

local LeaderboardMessages = {
	Boards = {
		Money = {
			Icon = "💰",
			Title = "TOP MONEY",
			Subtitle = "Total money earned",
			ValueFormat = "$%s",
		},
		Level = {
			Icon = "🔨",
			Title = "TOP LEVEL",
			Subtitle = "Highest weapon level",
			ValueFormat = "Lv. %s",
		},
		WeaponIncome = {
			Icon = "⚔️",
			Title = "TOP WEAPON $/S",
			Subtitle = "Best weapon income",
			ValueFormat = "$%s/s",
		},
		Donated = {
			Icon = "💎",
			Title = "TOP DONATED",
			Subtitle = "Total Robux spent",
			ValueFormat = "R$ %s",
		},
	},
	UpdateFormat = "Updates in %d:%02d",
	Updating = "Updating...",
	Empty = "No players yet",
	UnknownName = "Player",
	AvatarFormat = "rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60",
}

return LeaderboardMessages
