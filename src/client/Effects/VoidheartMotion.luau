--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)
local VoidheartRig = require(script.Parent.VoidheartRig)

export type MotionState = {
	RingAngles: { number },
	CoreAngles: Vector3,
	CorePhase: number,
	OrbAngle: number,
}

export type StepInput = {
	Time: number,
	Dt: number,
	Energy: number,
	Surge: number,
}

local VoidheartMotion = {}

local function aroundPivot(pivot: Vector3, rotation: CFrame): CFrame
	return CFrame.new(pivot) * rotation * CFrame.new(-pivot)
end

local function getRingRotation(state: MotionState, index: number, input: StepInput): CFrame
	local ring = VoidheartFxConfig.Rings[index]
	local boost = 1 + VoidheartFxConfig.RingEnergyBoost * input.Energy
	local variation = 1 + ring.Variation * math.sin(input.Time * ring.VariationRate)
	local angle = (state.RingAngles[index] or 0) + ring.Speed * variation * boost * input.Dt
	state.RingAngles[index] = angle
	local wobblePhase = input.Time * VoidheartFxConfig.RingWobbleRate + index
	local wobble = VoidheartFxConfig.RingWobbleAngle * math.sin(wobblePhase)
	return CFrame.fromAxisAngle(Vector3.xAxis, wobble) * CFrame.Angles(0, angle, 0)
end

local function stepRings(rig: VoidheartRig.Rig, state: MotionState, frame: CFrame, input: StepInput)
	for index, ring in VoidheartFxConfig.Rings do
		local mover = rig.Movers[ring.Name]
		local rotation = getRingRotation(state, index, input)
		VoidheartRig.Apply(mover, frame, aroundPivot(mover.Pivot, rotation))
	end
end

local function getPulseScale(state: MotionState, input: StepInput): number
	local idle = VoidheartFxConfig.CorePulsePeriodIdle
	local period = idle + (VoidheartFxConfig.CorePulsePeriodSurge - idle) * input.Energy
	state.CorePhase = (state.CorePhase + input.Dt / period) % 1
	local window = VoidheartFxConfig.CorePulseWindow
	if state.CorePhase >= window then
		return 1
	end
	return 1 - VoidheartFxConfig.CorePulseDepth * math.sin(state.CorePhase / window * math.pi)
end

local function stepCore(rig: VoidheartRig.Rig, state: MotionState, frame: CFrame, input: StepInput)
	local mover = rig.Movers.Core
	local boost = 1 + VoidheartFxConfig.CoreEnergyBoost * input.Energy
	state.CoreAngles += VoidheartFxConfig.CoreSpinRates * boost * input.Dt
	local angles = state.CoreAngles
	local rotation = CFrame.Angles(angles.X, angles.Y, angles.Z)
	VoidheartRig.Scale(mover, getPulseScale(state, input))
	VoidheartRig.Apply(mover, frame, aroundPivot(mover.Pivot, rotation))
end

local function stepOrb(rig: VoidheartRig.Rig, state: MotionState, frame: CFrame, input: StepInput)
	local mover = rig.Movers.Orb
	state.OrbAngle += VoidheartFxConfig.OrbSpinSpeed * input.Dt
	VoidheartRig.Apply(mover, frame, aroundPivot(mover.Pivot, CFrame.Angles(0, state.OrbAngle, 0)))
end

local function stepBlades(rig: VoidheartRig.Rig, frame: CFrame, input: StepInput)
	local distance = VoidheartFxConfig.BladeSlideFraction * rig.Length * input.Surge
	for _, blade in VoidheartFxConfig.Blades do
		local mover = rig.Movers[blade.Name]
		VoidheartRig.Apply(mover, frame, CFrame.new(mover.Radial * distance))
	end
end

local function stepClaws(rig: VoidheartRig.Rig, frame: CFrame, input: StepInput)
	for _, claw in VoidheartFxConfig.Claws do
		local mover = rig.Movers[claw.Name]
		if mover.Radial.Magnitude < 0.5 then
			continue
		end
		local hinge = mover.Pivot - mover.Radial * mover.Extent
		local axis = Vector3.yAxis:Cross(mover.Radial)
		local angle = claw.Direction * VoidheartFxConfig.ClawOpenAngle * input.Surge
		VoidheartRig.Apply(mover, frame, aroundPivot(hinge, CFrame.fromAxisAngle(axis, angle)))
	end
end

function VoidheartMotion.NewState(): MotionState
	return {
		RingAngles = {},
		CoreAngles = Vector3.zero,
		CorePhase = 0,
		OrbAngle = 0,
	}
end

function VoidheartMotion.Step(rig: VoidheartRig.Rig, state: MotionState, input: StepInput)
	local frame = VoidheartRig.GetFrame(rig)
	stepRings(rig, state, frame, input)
	stepCore(rig, state, frame, input)
	stepOrb(rig, state, frame, input)
	stepBlades(rig, frame, input)
	stepClaws(rig, frame, input)
end

return VoidheartMotion
