--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeRevealTypes = require(ReplicatedStorage.Shared.Types.ForgeRevealTypes)

type SoundSpec = ForgeRevealTypes.SoundSpec

local RevealSound = {}

local random = Random.new()

function RevealSound.Play(spec: SoundSpec, parent: Instance, speedMultiplier: number?): Sound?
	if spec.SoundId == "" then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.SoundId = spec.SoundId
	sound.Volume = spec.Volume
	sound.PlaybackSpeed = spec.PlaybackSpeed * (speedMultiplier or 1)
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound.Parent = parent
	sound:Play()
	return sound
end

function RevealSound.PlayRandom(soundIds: { string }, volume: number, parent: Instance, speed: number?): Sound?
	if #soundIds == 0 then
		return nil
	end
	local spec: SoundSpec = {
		SoundId = soundIds[random:NextInteger(1, #soundIds)],
		Volume = volume,
		PlaybackSpeed = speed or 1,
	}
	return RevealSound.Play(spec, parent)
end

return RevealSound
