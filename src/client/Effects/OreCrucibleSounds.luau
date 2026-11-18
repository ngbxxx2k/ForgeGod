--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OreCrucibleConfig = require(ReplicatedStorage.Shared.Config.OreCrucibleConfig)
local OreCrucibleRig = require(script.Parent.OreCrucibleRig)

local SILENT = 0

type SoundState = {
	Spec: OreCrucibleConfig.SoundSpec,
	Sound: Sound,
	Volume: number,
}

export type SoundSet = {
	Loops: { SoundState },
	OneShots: { SoundState },
	State: string,
	IsAwake: boolean,
}

local OreCrucibleSounds = {}

local warnedMissingSounds = false

local function newSound(rig: OreCrucibleRig.Rig, spec: OreCrucibleConfig.SoundSpec): Sound
	local sound = Instance.new("Sound")
	sound.Name = spec.Key
	sound.Archivable = false
	sound.SoundId = spec.Id
	sound.Looped = spec.Looped
	sound.Volume = if spec.Looped then SILENT else spec.Volume
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = OreCrucibleConfig.SoundRollOff.Min
	sound.RollOffMaxDistance = OreCrucibleConfig.SoundRollOff.Max
	sound.Parent = rig.Anchors[spec.Anchor]
	return sound
end

function OreCrucibleSounds.Create(rig: OreCrucibleRig.Rig, state: string): SoundSet
	local set: SoundSet = { Loops = {}, OneShots = {}, State = state, IsAwake = false }
	for _, spec in OreCrucibleConfig.Sounds do
		if spec.Id == "" then
			if not warnedMissingSounds then
				warnedMissingSounds = true
				warn("[OreCrucibleSounds] Sound ids are empty in OreCrucibleConfig")
			end
			continue
		end
		local entry: SoundState = { Spec = spec, Sound = newSound(rig, spec), Volume = SILENT }
		table.insert(if spec.Looped then set.Loops else set.OneShots, entry)
	end
	return set
end

function OreCrucibleSounds.ApplyState(set: SoundSet, state: string, playOneShot: boolean)
	set.State = state
	if not (playOneShot and set.IsAwake) then
		return
	end
	for _, entry in set.OneShots do
		if entry.Spec.State == state then
			entry.Sound.TimePosition = 0
			entry.Sound:Play()
		end
	end
end

function OreCrucibleSounds.SetAwake(set: SoundSet, isAwake: boolean)
	set.IsAwake = isAwake
	for _, entry in set.Loops do
		if isAwake then
			entry.Volume = if entry.Spec.State == set.State then entry.Spec.Volume else SILENT
			entry.Sound.Volume = entry.Volume
			entry.Sound:Play()
		else
			entry.Sound:Stop()
		end
	end
	if not isAwake then
		for _, entry in set.OneShots do
			entry.Sound:Stop()
		end
	end
end

function OreCrucibleSounds.Update(set: SoundSet, dt: number)
	local alpha = math.clamp(dt * OreCrucibleConfig.BlendRate, 0, 1)
	for _, entry in set.Loops do
		local target = if entry.Spec.State == set.State then entry.Spec.Volume else SILENT
		entry.Volume += (target - entry.Volume) * alpha
		entry.Sound.Volume = entry.Volume
	end
end

function OreCrucibleSounds.Destroy(set: SoundSet)
	for _, list in { set.Loops, set.OneShots } do
		for _, entry in list do
			entry.Sound:Stop()
			entry.Sound:Destroy()
		end
		table.clear(list)
	end
end

return OreCrucibleSounds
