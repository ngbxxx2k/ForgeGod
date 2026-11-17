--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

local ASSETS_FOLDER_NAME = "Assets"
local SOUNDS_FOLDER_NAME = "Sounds"

export type SoundSet = {
	Clang: Sound?,
	Sizzle: Sound?,
}

local ForgeImpactSound = {}

local random = Random.new()
local hasWarnedEmptyId = false

local function cloneSound(name: string, parent: Instance): Sound?
	local assets = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER_NAME)
	local folder = assets and assets:FindFirstChild(SOUNDS_FOLDER_NAME)
	local template = folder and folder:FindFirstChild(name)
	if template == nil or not template:IsA("Sound") then
		warn("[ForgeImpactSound] Missing sound:", name)
		return nil
	end
	local sound = template:Clone()
	sound.Parent = parent
	return sound
end

local function play(sound: Sound?, speed: NumberRange)
	if sound == nil then
		return
	end
	if sound.SoundId == "" then
		if not hasWarnedEmptyId then
			hasWarnedEmptyId = true
			warn("[ForgeImpactSound] SoundId is empty:", sound.Name)
		end
		return
	end
	sound.PlaybackSpeed = random:NextNumber(speed.Min, speed.Max)
	sound.TimePosition = 0
	sound:Play()
end

function ForgeImpactSound.Create(impact: Attachment): SoundSet
	local names = ForgeStrikeConfig.SoundNames
	return {
		Clang = cloneSound(names.Clang, impact),
		Sizzle = cloneSound(names.Sizzle, impact),
	}
end

function ForgeImpactSound.Play(set: SoundSet)
	play(set.Clang, ForgeStrikeConfig.ClangSpeed)
	play(set.Sizzle, ForgeStrikeConfig.SizzleSpeed)
end

function ForgeImpactSound.Destroy(set: SoundSet)
	if set.Clang then
		set.Clang:Destroy()
	end
	if set.Sizzle then
		set.Sizzle:Destroy()
	end
end

return ForgeImpactSound
