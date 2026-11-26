--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local MusicConfig = require(ReplicatedStorage.Shared.Config.MusicConfig)

local SILENT = 0

local BackgroundMusic = {}

local isInitialized = false
local random = Random.new()

local function shuffledOrder(count: number): { number }
	local order = {}
	for index = 1, count do
		order[index] = index
	end
	for index = count, 2, -1 do
		local swapIndex = random:NextInteger(1, index)
		order[index], order[swapIndex] = order[swapIndex], order[index]
	end
	return order
end

local function createSound(group: SoundGroup): Sound
	local sound = Instance.new("Sound")
	sound.Name = "Track"
	sound.Looped = false
	sound.Volume = SILENT
	sound.SoundGroup = group
	sound.Parent = group
	return sound
end

local function playTrack(sound: Sound, soundId: string)
	sound.SoundId = soundId
	sound.Volume = SILENT
	sound:Play()
	local info = TweenInfo.new(MusicConfig.FadeInTime, Enum.EasingStyle.Sine)
	TweenService:Create(sound, info, { Volume = MusicConfig.Volume }):Play()
end

local function runPlaylist(sound: Sound)
	local tracks = MusicConfig.Tracks
	while #tracks > 0 do
		for _, trackIndex in shuffledOrder(#tracks) do
			playTrack(sound, tracks[trackIndex])
			sound.Ended:Wait()
			task.wait(MusicConfig.GapBetweenTracks)
		end
	end
end

function BackgroundMusic.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	if #MusicConfig.Tracks == 0 then
		warn("[BackgroundMusic] No music tracks configured")
		return
	end
	local group = Instance.new("SoundGroup")
	group.Name = MusicConfig.SoundGroupName
	group.Archivable = false
	group.Parent = SoundService
	task.spawn(runPlaylist, createSound(group))
end

return BackgroundMusic
