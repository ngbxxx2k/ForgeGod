--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)

local MusicConfig = {
	Tracks = AssetIds.Music,
	Volume = 0.1,
	FadeInTime = 3,
	GapBetweenTracks = 2,
	SoundGroupName = "BackgroundMusic",
}

return MusicConfig
