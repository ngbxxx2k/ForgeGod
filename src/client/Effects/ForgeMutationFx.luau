--!strict

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local ForgeMutationFxConfig = require(ReplicatedStorage.Shared.Config.ForgeMutationFxConfig)
local MutationConfig = require(ReplicatedStorage.Shared.Config.MutationConfig)
local LightningTypes = require(ReplicatedStorage.Shared.Types.LightningTypes)
local CameraShake = require(script.Parent.CameraShake)
local LightningBolt = require(script.Parent.LightningBolt)

local BURST_PART_NAME = "ForgeMutationBurst"
local SOUND_HOLDER_NAME = "ForgeMutationSound"
local BURST_PART_SIZE = Vector3.new(0.2, 0.2, 0.2)
local HIDDEN = 1
local WHITE = Color3.new(1, 1, 1)

local ForgeMutationFx = {}

local random = Random.new()
local flashEffect: ColorCorrectionEffect? = nil

local function getTierColor(mutationId: string): ForgeMutationFxConfig.TierColor
	local mutation = MutationConfig.ById[mutationId]
	local tiers = ForgeMutationFxConfig.TierColors
	local tier = if mutation then tiers[mutation.Rarity] else nil
	return tier or tiers[ForgeMutationFxConfig.DefaultTier]
end

local function buildStyle(color: ForgeMutationFxConfig.TierColor): LightningTypes.BoltStyle
	local style = table.clone(ForgeMutationFxConfig.BoltStyle)
	style.CoreColor = color.Core
	style.GlowColor = color.Glow
	return style
end

local function getStrikePoint(anvilPart: BasePart, ignore: Model?): Vector3
	local center = anvilPart.Position
	local probe = Vector3.yAxis * ForgeMutationFxConfig.ProbeHeight
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if ignore then { ignore } else {}
	local result = Workspace:Raycast(center + probe, -probe * 2, params)
	return if result then result.Position else center + Vector3.yAxis * anvilPart.Size.Y / 2
end

local function getFlashEffect(): ColorCorrectionEffect
	local existing = flashEffect
	if existing and existing.Parent then
		return existing
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = ForgeMutationFxConfig.FlashEffectName
	effect.Archivable = false
	effect.Parent = Lighting
	flashEffect = effect
	return effect
end

local function flash(color: Color3)
	local effect = getFlashEffect()
	effect.Brightness = ForgeMutationFxConfig.FlashBrightness
	effect.TintColor = WHITE:Lerp(color, ForgeMutationFxConfig.FlashTintStrength)
	local info = TweenInfo.new(ForgeMutationFxConfig.FlashFadeTime, Enum.EasingStyle.Quad)
	TweenService:Create(effect, info, { Brightness = 0, TintColor = WHITE }):Play()
end

local function createBurstPart(position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = BURST_PART_NAME
	part.Size = BURST_PART_SIZE
	part.Transparency = HIDDEN
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Archivable = false
	part.CFrame = CFrame.new(position)
	return part
end

local function burst(position: Vector3, color: Color3)
	local config = ForgeMutationFxConfig
	local part = createBurstPart(position)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = config.BurstTexture
	emitter.Color = ColorSequence.new(color)
	emitter.Size = config.BurstSize
	emitter.Speed = config.BurstSpeed
	emitter.Lifetime = config.BurstLifetime
	emitter.Brightness = config.BurstBrightness
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = part
	part.Parent = Workspace
	emitter:Emit(config.BurstCount)
	task.delay(config.CleanupDelay, part.Destroy, part)
end

local function playSound(soundIds: { string }, volume: number, parent: Instance, cleanup: Instance)
	if #soundIds == 0 then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundIds[random:NextInteger(1, #soundIds)]
	sound.Volume = volume
	sound.Parent = parent
	sound.Ended:Once(function()
		cleanup:Destroy()
	end)
	sound:Play()
end

local function playGlobalSound(soundIds: { string }, volume: number)
	if #soundIds == 0 then
		return
	end
	local holder = Instance.new("Folder")
	holder.Name = SOUND_HOLDER_NAME
	holder.Parent = SoundService
	playSound(soundIds, volume, holder, holder)
end

local function playSoundAt(soundIds: { string }, volume: number, position: Vector3)
	if #soundIds == 0 then
		return
	end
	local part = createBurstPart(position)
	part.Name = SOUND_HOLDER_NAME
	part.Parent = Workspace
	playSound(soundIds, volume, part, part)
end

local function drawBolts(style: LightningTypes.BoltStyle, target: Vector3, onFollowUp: (() -> ())?)
	local config = ForgeMutationFxConfig
	LightningBolt.Draw(style, target)
	for index = 2, config.StrikeCount do
		task.delay((index - 1) * config.StrikeGap, function()
			LightningBolt.Draw(style, target)
			if onFollowUp then
				onFollowUp()
			end
		end)
	end
end

function ForgeMutationFx.Strike(anvilPart: BasePart?, mutationId: string)
	if anvilPart == nil or anvilPart.Parent == nil then
		return
	end
	local config = ForgeMutationFxConfig
	local color = getTierColor(mutationId)
	local target = getStrikePoint(anvilPart, Players.LocalPlayer.Character)
	drawBolts(buildStyle(color), target, function()
		CameraShake.Kick(config.FollowUpShakeStrength)
	end)
	CameraShake.Kick(config.ShakeStrength)
	flash(color.Glow)
	burst(target, color.Glow)
	playGlobalSound(config.CrackSoundIds, config.CrackVolume)
	playGlobalSound(config.ThunderSoundIds, config.ThunderVolume)
end

function ForgeMutationFx.StrikeWorld(anvilPart: BasePart?, mutationId: string, ignore: Model?)
	if anvilPart == nil or anvilPart.Parent == nil then
		return
	end
	local config = ForgeMutationFxConfig
	local color = getTierColor(mutationId)
	local target = getStrikePoint(anvilPart, ignore)
	drawBolts(buildStyle(color), target, nil)
	burst(target, color.Glow)
	playSoundAt(config.CrackSoundIds, config.CrackVolume, target)
	playSoundAt(config.ThunderSoundIds, config.ThunderVolume, target)
end

return ForgeMutationFx
