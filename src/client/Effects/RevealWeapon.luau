--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local HoldConfig = require(ReplicatedStorage.Shared.Config.HoldConfig)
local ForgeRevealTypes = require(ReplicatedStorage.Shared.Types.ForgeRevealTypes)
local WeaponModelFinder = require(ReplicatedStorage.Shared.Utils.WeaponModelFinder)
local RevealCleanup = require(script.Parent.RevealCleanup)

type WeaponVisual = ForgeRevealTypes.WeaponVisual

export type Weapon = {
	Model: Model,
	Length: number,
	Rotation: CFrame,
	CenterToPivot: CFrame,
	StrippedTags: { [Instance]: { string } },
	LavaPosition: Vector3,
	SpinAngle: number,
	RiseStart: number?,
	FrozenUntil: number,
	ShakeStart: number,
	ShakeStrength: number,
	Fly: Flight?,
}

type Flight = {
	StartTime: number,
	Duration: number,
	From: Vector3,
	BaseScale: number,
	BaseOffset: CFrame,
	GetTarget: () -> Vector3,
}

type BuiltModel = {
	Model: Model,
	CenterToPivot: CFrame,
	StrippedTags: { [Instance]: { string } },
}

local FULL_TURN = math.pi * 2
local SCALE_PASSES = 4
local SCALE_TOLERANCE = 0.01
local SHAKE_CUTOFF = 0.01
local NOISE_SCALE = 2

local RevealWeapon = {}

local function findInFolder(folder: Instance?, name: string): Model?
	local found = folder and folder:FindFirstChild(name)
	if found and found:IsA("Model") then
		return found
	end
	return nil
end

local function findSourceModel(name: string): Model?
	local assets = ReplicatedStorage:FindFirstChild(ForgeAnimationConfig.AssetsFolderName)
	local models = assets and assets:FindFirstChild(ForgeAnimationConfig.ModelsFolderName)
	return findInFolder(models, name)
end

local function stripTags(instance: Instance, stripped: { [Instance]: { string } })
	local tags = instance:GetTags()
	if #tags == 0 then
		return
	end
	stripped[instance] = tags
	for _, tag in tags do
		CollectionService:RemoveTag(instance, tag)
	end
end

local function prepareClone(clone: Model): { [Instance]: { string } }
	local stripped = {}
	stripTags(clone, stripped)
	for _, descendant in clone:GetDescendants() do
		stripTags(descendant, stripped)
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	return stripped
end

local function getLongestSide(model: Model): number
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Y, size.Z)
end

local function scaleToLength(clone: Model, length: number)
	for _ = 1, SCALE_PASSES do
		local longest = getLongestSide(clone)
		if longest <= 0 or math.abs(longest - length) <= SCALE_TOLERANCE then
			return
		end
		clone:ScaleTo(clone:GetScale() * (length / longest))
	end
end

local function getSpinCenter(model: Model): CFrame
	local boxCFrame = model:GetBoundingBox()
	local gripPoint = model:FindFirstChild(HoldConfig.WeaponGripPointName, true)
	if not gripPoint or not gripPoint:IsA("Attachment") then
		return boxCFrame
	end
	local shaft = boxCFrame:PointToObjectSpace(gripPoint.WorldPosition)
	return boxCFrame * CFrame.new(shaft.X, 0, shaft.Z)
end

local function buildModel(visual: WeaponVisual, length: number): BuiltModel?
	local fromLibrary = if visual.WeaponTypeId then WeaponModelFinder.Find(visual.WeaponTypeId, 1) else nil
	local source = fromLibrary or findSourceModel(visual.ModelName)
	if source == nil then
		warn("[RevealWeapon] Missing weapon model:", visual.ModelName)
		return nil
	end
	local clone = source:Clone()
	clone.Name = ForgeAnimationConfig.WeaponInstanceName
	local stripped = prepareClone(clone)
	scaleToLength(clone, length)
	return {
		Model = clone,
		CenterToPivot = getSpinCenter(clone):ToObjectSpace(clone:GetPivot()),
		StrippedTags = stripped,
	}
end

local function getCenterHeight(weapon: Weapon, height: number): Vector3
	return weapon.LavaPosition + Vector3.yAxis * height
end

local function noiseAt(phase: number, seed: number): number
	return math.noise(phase, seed) * NOISE_SCALE
end

local function getShakeOffset(weapon: Weapon): CFrame
	local config = ForgeAnimationConfig.WeaponShake
	local elapsed = os.clock() - weapon.ShakeStart
	local amount = weapon.ShakeStrength * math.exp(-config.Decay * elapsed)
	if amount <= SHAKE_CUTOFF then
		return CFrame.identity
	end
	local phase = elapsed * config.Frequency
	local offset = Vector3.new(noiseAt(phase, 0.17), noiseAt(phase, 1.31), noiseAt(phase, 2.73))
	local tilt = math.rad(config.Rotation) * amount
	local rotation = CFrame.Angles(noiseAt(phase, 3.91) * tilt, 0, noiseAt(phase, 5.13) * tilt)
	return CFrame.new(offset * config.Position * amount) * rotation
end

local function place(weapon: Weapon, center: Vector3)
	local spin = CFrame.Angles(0, weapon.SpinAngle, 0)
	local shake = getShakeOffset(weapon)
	weapon.Model:PivotTo(CFrame.new(center) * shake * spin * weapon.Rotation * weapon.CenterToPivot)
end

local function getHoverHeight(weapon: Weapon): number
	return ForgeAnimationConfig.Rise.HoverGap + weapon.Length / 2
end

local function getHeight(weapon: Weapon, elapsed: number, eased: number): number
	local config = ForgeAnimationConfig.Rise
	local startHeight = -weapon.Length / 2
	local height = startHeight + (getHoverHeight(weapon) - startHeight) * eased
	if elapsed >= config.Duration then
		local bobTime = elapsed - config.Duration
		height += math.sin(bobTime * config.BobFrequency * FULL_TURN) * config.BobAmplitude
	end
	return height
end

local function stepFlight(weapon: Weapon, flight: Flight, dt: number)
	local config = ForgeAnimationConfig.Outro
	local alpha = math.clamp((os.clock() - flight.StartTime) / flight.Duration, 0, 1)
	local eased = TweenService:GetValue(alpha, config.FlyEasingStyle, Enum.EasingDirection.In)
	local factor = 1 + (config.FlyEndScale - 1) * eased
	weapon.Model:ScaleTo(flight.BaseScale * factor)
	local offset = flight.BaseOffset
	weapon.CenterToPivot = offset - offset.Position + offset.Position * factor
	weapon.SpinAngle = (weapon.SpinAngle + ForgeAnimationConfig.Rise.SpinSpeedHover * dt) % FULL_TURN
	place(weapon, flight.From:Lerp(flight.GetTarget(), eased))
end

local function step(weapon: Weapon, dt: number)
	local config = ForgeAnimationConfig.Rise
	local riseStart = weapon.RiseStart
	local flight = weapon.Fly
	if flight then
		stepFlight(weapon, flight, dt)
		return
	end
	if riseStart == nil or os.clock() < weapon.FrozenUntil then
		return
	end
	local elapsed = os.clock() - riseStart
	local alpha = math.clamp(elapsed / config.Duration, 0, 1)
	local eased = TweenService:GetValue(alpha, config.EasingStyle, Enum.EasingDirection.Out)
	local spinSpeed = config.SpinSpeedStart + (config.SpinSpeedHover - config.SpinSpeedStart) * eased
	weapon.SpinAngle = (weapon.SpinAngle + spinSpeed * dt) % FULL_TURN
	place(weapon, getCenterHeight(weapon, getHeight(weapon, elapsed, eased)))
end

local function getCurrentHeight(weapon: Weapon): number
	local riseStart = weapon.RiseStart
	if riseStart == nil then
		return -weapon.Length / 2
	end
	return getHoverHeight(weapon)
end

function RevealWeapon.Create(
	visual: WeaponVisual,
	length: number,
	lavaPosition: Vector3,
	cleanup: RevealCleanup.Cleanup
): Weapon?
	local built = buildModel(visual, length)
	if built == nil then
		return nil
	end
	local weapon: Weapon = {
		Model = built.Model,
		Length = length,
		Rotation = visual.Rotation or CFrame.identity,
		CenterToPivot = built.CenterToPivot,
		StrippedTags = built.StrippedTags,
		LavaPosition = lavaPosition,
		SpinAngle = 0,
		RiseStart = nil,
		FrozenUntil = 0,
		ShakeStart = 0,
		ShakeStrength = 0,
		Fly = nil,
	}
	place(weapon, getCenterHeight(weapon, -length / 2))
	built.Model.Parent = Workspace
	RevealCleanup.Add(cleanup, built.Model)
	RevealCleanup.Add(cleanup, RunService.RenderStepped:Connect(function(dt: number)
		step(weapon, dt)
	end))
	return weapon
end

function RevealWeapon.Swap(weapon: Weapon, visual: WeaponVisual, length: number, cleanup: RevealCleanup.Cleanup): boolean
	local built = buildModel(visual, length)
	if built == nil then
		return false
	end
	weapon.Model:Destroy()
	weapon.Model = built.Model
	weapon.Length = length
	weapon.Rotation = visual.Rotation or CFrame.identity
	weapon.CenterToPivot = built.CenterToPivot
	weapon.StrippedTags = built.StrippedTags
	place(weapon, getCenterHeight(weapon, getCurrentHeight(weapon)))
	built.Model.Parent = Workspace
	RevealCleanup.Add(cleanup, built.Model)
	return true
end

function RevealWeapon.Rise(weapon: Weapon)
	weapon.RiseStart = os.clock()
end

function RevealWeapon.Freeze(weapon: Weapon, duration: number)
	weapon.FrozenUntil = os.clock() + duration
end

function RevealWeapon.Shake(weapon: Weapon, strength: number)
	weapon.ShakeStart = os.clock()
	weapon.ShakeStrength = strength
end

function RevealWeapon.RestoreTags(weapon: Weapon)
	for instance, tags in weapon.StrippedTags do
		if instance.Parent ~= nil or instance == weapon.Model then
			for _, tag in tags do
				CollectionService:AddTag(instance, tag)
			end
		end
	end
	table.clear(weapon.StrippedTags)
end

function RevealWeapon.StripTags(weapon: Weapon)
	stripTags(weapon.Model, weapon.StrippedTags)
	for _, descendant in weapon.Model:GetDescendants() do
		stripTags(descendant, weapon.StrippedTags)
	end
end

function RevealWeapon.FlyTo(weapon: Weapon, getTarget: () -> Vector3, duration: number)
	RevealWeapon.StripTags(weapon)
	weapon.Fly = {
		StartTime = os.clock(),
		Duration = math.max(duration, 1e-3),
		From = RevealWeapon.GetCenter(weapon),
		BaseScale = weapon.Model:GetScale(),
		BaseOffset = weapon.CenterToPivot,
		GetTarget = getTarget,
	}
end

function RevealWeapon.GetVisual(weaponTypeId: string): WeaponVisual
	return ForgeAnimationConfig.WeaponVisuals[weaponTypeId] or ForgeAnimationConfig.DefaultVisual
end

function RevealWeapon.FindLargestPart(model: Model): BasePart?
	local largest: BasePart? = nil
	local largestVolume = -1
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local size = descendant.Size
			local volume = size.X * size.Y * size.Z
			if volume > largestVolume then
				largest = descendant
				largestVolume = volume
			end
		end
	end
	return largest
end

function RevealWeapon.GetHoverCenter(weapon: Weapon): Vector3
	return getCenterHeight(weapon, getHoverHeight(weapon))
end

function RevealWeapon.GetCenter(weapon: Weapon): Vector3
	return getSpinCenter(weapon.Model).Position
end

function RevealWeapon.GetTip(weapon: Weapon): Vector3
	return RevealWeapon.GetCenter(weapon) + Vector3.yAxis * (weapon.Length / 2)
end

return RevealWeapon
