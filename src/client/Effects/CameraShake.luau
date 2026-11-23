--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeFrenzyFxConfig = require(ReplicatedStorage.Shared.Config.ForgeFrenzyFxConfig)

local PHASE_X = 1.3
local PHASE_Y = 0.9
local PHASE_ROLL = 1.7

local CameraShake = {}

local sustain = 0
local kick = 0
local kickAt = 0

local function wave(time: number, factor: number): number
	return math.sin(time * ForgeFrenzyFxConfig.Shake.Frequency * factor)
end

function CameraShake.SetSustain(strength: number)
	sustain = math.max(strength, 0)
end

function CameraShake.Kick(strength: number)
	kick = math.max(strength, 0)
	kickAt = os.clock()
end

function CameraShake.GetOffset(): CFrame
	local config = ForgeFrenzyFxConfig.Shake
	local now = os.clock()
	local kickLevel = kick * math.exp(-config.KickDecay * (now - kickAt))
	local position = sustain * config.SustainPosition + kickLevel * config.KickPosition
	local rotation = math.rad(sustain * config.SustainRotation + kickLevel * config.KickRotation)
	if position <= 0 and rotation <= 0 then
		return CFrame.identity
	end
	local x, y, roll = wave(now, PHASE_X), wave(now, PHASE_Y), wave(now, PHASE_ROLL)
	return CFrame.new(x * position, y * position, 0) * CFrame.Angles(y * rotation, x * rotation, roll * rotation)
end

function CameraShake.Reset()
	sustain = 0
	kick = 0
end

return CameraShake
