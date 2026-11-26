--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local DigFxConfig = require(ReplicatedStorage.Shared.Config.DigFxConfig)

local SOUND_NAME = "DetectorSignalSound"

local DetectorSignalSound = {}

local sound: Sound? = nil

local function lerp(range: NumberRange, alpha: number): number
	return range.Min + (range.Max - range.Min) * alpha
end

local function getSound(): Sound?
	local existing = sound
	if existing then
		return existing
	end
	local config = DigFxConfig.DetectorSound
	if config.SoundId == "" then
		return nil
	end
	local created = Instance.new("Sound")
	created.Name = SOUND_NAME
	created.SoundId = config.SoundId
	created.Looped = true
	created.Parent = SoundService
	sound = created
	return created
end

function DetectorSignalSound.Update(isActive: boolean, strength: number)
	if not isActive or strength <= 0 then
		local current = sound
		if current and current.IsPlaying then
			current:Pause()
		end
		return
	end
	local current = getSound()
	if current == nil then
		return
	end
	local config = DigFxConfig.DetectorSound
	local alpha = math.clamp(strength, 0, 1)
	current.Volume = lerp(config.Volume, alpha)
	current.PlaybackSpeed = lerp(config.PlaybackSpeed, alpha)
	if not current.IsPlaying then
		current:Resume()
	end
end

return DetectorSignalSound
