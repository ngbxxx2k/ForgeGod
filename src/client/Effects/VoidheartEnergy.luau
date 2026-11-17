--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)

local VoidheartEnergy = {}

local cycleLength = 0
for _, segment in VoidheartFxConfig.Cycle do
	cycleLength += segment.Duration
end

function VoidheartEnergy.Smoothstep(value: number): number
	local clamped = math.clamp(value, 0, 1)
	return clamped * clamped * (3 - 2 * clamped)
end

function VoidheartEnergy.Sample(time: number): number
	local cycle = VoidheartFxConfig.Cycle
	local remaining = time % cycleLength
	for _, segment in cycle do
		if remaining <= segment.Duration then
			local alpha = VoidheartEnergy.Smoothstep(remaining / segment.Duration)
			return segment.From + (segment.To - segment.From) * alpha
		end
		remaining -= segment.Duration
	end
	return cycle[#cycle].To
end

function VoidheartEnergy.Surge(energy: number): number
	local span = VoidheartFxConfig.SurgeFull - VoidheartFxConfig.SurgeStart
	return VoidheartEnergy.Smoothstep((energy - VoidheartFxConfig.SurgeStart) / span)
end

return VoidheartEnergy
