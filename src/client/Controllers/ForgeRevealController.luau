--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local ForgeRevealTypes = require(ReplicatedStorage.Shared.Types.ForgeRevealTypes)
local ForgeRevealMessages = require(ReplicatedStorage.Shared.Constants.ForgeRevealMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local WeaponWeight = require(ReplicatedStorage.Shared.Utils.WeaponWeight)
local AuraEffect = require(script.Parent.Parent.Effects.AuraEffect)
local CameraDirector = require(script.Parent.Parent.Effects.CameraDirector)
local CrucibleFlare = require(script.Parent.Parent.Effects.CrucibleFlare)
local ImpactEffect = require(script.Parent.Parent.Effects.ImpactEffect)
local LightningEffect = require(script.Parent.Parent.Effects.LightningEffect)
local OreCrucibleRig = require(script.Parent.Parent.Effects.OreCrucibleRig)
local RarityLabel = require(script.Parent.Parent.Effects.RarityLabel)
local ResultLabel = require(script.Parent.Parent.Effects.ResultLabel)
local RevealBlackout = require(script.Parent.Parent.Effects.RevealBlackout)
local RevealCleanup = require(script.Parent.Parent.Effects.RevealCleanup)
local RevealSound = require(script.Parent.Parent.Effects.RevealSound)
local RevealWeapon = require(script.Parent.Parent.Effects.RevealWeapon)
local RollSchedule = require(script.Parent.Parent.Effects.RollSchedule)
local ScreenBurst = require(script.Parent.Parent.Effects.ScreenBurst)
local ScreenFlash = require(script.Parent.Parent.Effects.ScreenFlash)
local ShapeRollEffect = require(script.Parent.Parent.Effects.ShapeRollEffect)
local ShapeSparkles = require(script.Parent.Parent.Effects.ShapeSparkles)
local SilhouetteEffect = require(script.Parent.Parent.Effects.SilhouetteEffect)
local CutsceneGuiHider = require(script.Parent.Parent.UI.Components.CutsceneGuiHider)
local HudTarget = require(script.Parent.Parent.UI.Components.HudTarget)
local RevealBackButton = require(script.Parent.Parent.UI.Components.RevealBackButton)
local RevealInfoCard = require(script.Parent.Parent.UI.Components.RevealInfoCard)

type SmeltResult = ForgeRevealTypes.SmeltResult
type WeaponVisual = ForgeRevealTypes.WeaponVisual

type Stage = {
	LavaPosition: Vector3,
	Front: Vector3,
}

type Session = {
	Stage: Stage,
	Cleanup: RevealCleanup.Cleanup,
	OnFinished: () -> (),
	HasResult: boolean,
	RestoreGuis: () -> (),
}

type Scene = {
	Weapon: RevealWeapon.Weapon,
	Silhouette: SilhouetteEffect.Silhouette,
	Flash: ScreenFlash.Flash,
	Blackout: RevealBlackout.Blackout,
	Label: RarityLabel.Label,
	Aura: AuraEffect.Aura?,
}

local ForgeRevealController = {}

local isInitialized = false
local session: Session? = nil

local function isCurrent(current: Session): boolean
	return session == current
end

local function waitFor(current: Session, seconds: number): boolean
	task.wait(seconds)
	return isCurrent(current)
end

local function waitUntil(current: Session, deadline: number): boolean
	local remaining = deadline - os.clock()
	if remaining > 0 then
		return waitFor(current, remaining)
	end
	return isCurrent(current)
end

local function finish(current: Session)
	if not isCurrent(current) then
		return
	end
	session = nil
	RevealCleanup.Clean(current.Cleanup)
	local ok, err = pcall(current.OnFinished)
	if not ok then
		warn("[ForgeRevealController] OnFinished failed:", err)
	end
end

local function getRarityColor(rarity: string): Color3
	local info = ForgeAnimationConfig.Rarities[rarity] or ForgeAnimationConfig.Rarities.Common
	return info.Color
end

local function playIntro(current: Session)
	local config = ForgeAnimationConfig.Camera
	local stage = current.Stage
	local focus = stage.LavaPosition + Vector3.yAxis * config.IntroLookLift
	local shot = CameraDirector.BuildShot(focus, stage.Front, config.IntroDistance, config.IntroHeight)
	CameraDirector.MoveTo(shot, config.IntroFieldOfView, config.IntroDuration)
	CrucibleFlare.Play(stage.LavaPosition, current.Cleanup)
end

local function frameSpan(current: Session, focus: Vector3, span: number, duration: number, pullback: number)
	local config = ForgeAnimationConfig.Camera
	local distance = math.max(config.WeaponMinDistance, span * config.WeaponDistancePerStud) * pullback
	local shot = CameraDirector.BuildShot(focus, current.Stage.Front, distance, config.WeaponHeight)
	CameraDirector.MoveTo(shot, config.WeaponFieldOfView, duration)
end

local function frameWeapon(current: Session, weapon: RevealWeapon.Weapon, duration: number, pullback: number)
	frameSpan(current, RevealWeapon.GetHoverCenter(weapon), weapon.Length, duration, pullback)
end

local function getAboveTip(weapon: RevealWeapon.Weapon, gap: number): Vector3
	return RevealWeapon.GetHoverCenter(weapon) + Vector3.yAxis * (weapon.Length / 2 + gap)
end

local function getLabelPosition(weapon: RevealWeapon.Weapon): Vector3
	return getAboveTip(weapon, ForgeAnimationConfig.RarityLabel.Gap)
end

local function buildScene(current: Session): Scene?
	local visual = ForgeAnimationConfig.DefaultVisual
	local weapon = RevealWeapon.Create(visual, visual.Length, current.Stage.LavaPosition, current.Cleanup)
	if weapon == nil then
		return nil
	end
	return {
		Weapon = weapon,
		Silhouette = SilhouetteEffect.Apply(weapon.Model, weapon.Length),
		Flash = ScreenFlash.Create(current.Cleanup),
		Blackout = RevealBlackout.Create(current.Cleanup),
		Label =RarityLabel.Create(getLabelPosition(weapon), current.Cleanup),
		Aura = nil,
	}
end

local function playRise(current: Session): Scene?
	local config = ForgeAnimationConfig.Rise
	if not waitFor(current, config.StartDelay) then
		return nil
	end
	local scene = buildScene(current)
	if scene == nil then
		return nil
	end
	RevealWeapon.Rise(scene.Weapon)
	frameWeapon(current, scene.Weapon, config.Duration, 1)
	if not waitFor(current, config.Duration) then
		return nil
	end
	return scene
end

local function playStrikeSound(weapon: RevealWeapon.Weapon, strike: RollSchedule.Strike)
	local config = ForgeAnimationConfig.Lightning
	if strike.IsFinal then
		local speed = config.FinalPlaybackSpeed
		RevealSound.PlayRandom(config.ZapSoundIds, config.FinalZapVolume, weapon.Model, speed)
		RevealSound.PlayRandom(config.ThunderSoundIds, config.FinalThunderVolume, weapon.Model, speed)
		return
	end
	local pitch = config.PitchStart + (config.PitchEnd - config.PitchStart) * strike.Progress
	RevealSound.PlayRandom(config.ZapSoundIds, config.ZapVolume, weapon.Model, pitch)
	RevealSound.PlayRandom(config.ThunderSoundIds, config.ThunderVolume, weapon.Model, pitch)
end

local function playStrike(current: Session, scene: Scene, strike: RollSchedule.Strike)
	local info = ForgeAnimationConfig.Rarities[strike.Rarity]
	if info == nil then
		return
	end
	local cameraConfig = ForgeAnimationConfig.Camera
	local weapon = scene.Weapon
	local exitDepth = weapon.Length / 2 + ForgeAnimationConfig.Lightning.ExitDepth
	local exit = RevealWeapon.GetCenter(weapon) - Vector3.yAxis * exitDepth
	LightningEffect.Strike(RevealWeapon.GetTip(weapon), exit, info.Color, strike.IsFinal, current.Cleanup)
	ScreenFlash.Flash(scene.Flash, info.Color, strike.IsFinal)
	RarityLabel.Show(scene.Label, strike.Rarity, info.DisplayName, info.Color, strike.IsFinal)
	CameraDirector.Shake(if strike.IsFinal then cameraConfig.ShakeFinal else cameraConfig.ShakeStrike)
	local shakeConfig = ForgeAnimationConfig.WeaponShake
	RevealWeapon.Shake(weapon, if strike.IsFinal then shakeConfig.Final else shakeConfig.Strike)
	playStrikeSound(scene.Weapon, strike)
end

local function playRarityRoll(current: Session, scene: Scene, rarity: string): boolean
	local strikes, duration = RollSchedule.Build(rarity)
	ScreenFlash.Dim(scene.Flash)
	frameWeapon(current, scene.Weapon, duration, ForgeAnimationConfig.Camera.RollPullback)
	local startTime = os.clock()
	for _, strike in strikes do
		if not waitUntil(current, startTime + strike.Time) then
			return false
		end
		playStrike(current, scene, strike)
	end
	return waitUntil(current, startTime + duration)
end

local function swapShape(current: Session, scene: Scene, step: ShapeRollEffect.ShapeStep, isBlackFlicker: boolean)
	local config = ForgeAnimationConfig.ShapeRoll
	local visual = RevealWeapon.GetVisual(step.WeaponTypeId)
	if not RevealWeapon.Swap(scene.Weapon, visual, step.Length, current.Cleanup) then
		return
	end
	local weapon = scene.Weapon
	scene.Silhouette = SilhouetteEffect.Apply(weapon.Model, weapon.Length)
	if isBlackFlicker then
		RevealBlackout.Flicker(scene.Blackout)
	elseif not step.IsFinal then
		ScreenFlash.Flash(scene.Flash, config.FlashColor, false)
	end
	CameraDirector.Shake(config.Shake)
	frameWeapon(current, weapon, config.CameraMoveTime, ForgeAnimationConfig.Camera.RollPullback)
	local pitch = config.PitchStart + (config.PitchEnd - config.PitchStart) * step.Progress
	RevealSound.Play(config.Sound, weapon.Model, pitch)
end

local function playBlackout(current: Session, scene: Scene): boolean
	local config = ForgeAnimationConfig.Blackout
	RevealBlackout.FadeToBlack(scene.Blackout)
	return waitFor(current, config.FadeToBlackTime + config.BlackHoldTime)
end

local function playShapeRoll(current: Session, scene: Scene, result: SmeltResult): boolean
	RarityLabel.Hide(scene.Label)
	local steps = ShapeRollEffect.Build(result.Rarity, result.WeaponTypeId, result.Scale)
	local flickerFrom = #steps - ForgeAnimationConfig.ShapeRoll.BlackFlickerSteps
	local sparkles = ShapeSparkles.Start(function(): Vector3
		return RevealWeapon.GetCenter(scene.Weapon)
	end, scene.Weapon.Length, current.Cleanup)
	local startTime = os.clock()
	for index, step in steps do
		if not waitUntil(current, startTime + step.Time) then
			return false
		end
		if step.IsFinal then
			ShapeSparkles.Stop(sparkles)
			if not playBlackout(current, scene) then
				return false
			end
		end
		swapShape(current, scene, step, not step.IsFinal and index >= flickerFrom)
		if not step.IsFinal then
			ShapeSparkles.Burst(sparkles, scene.Weapon.Length)
		end
	end
	return true
end

local function playWhiteIn(current: Session, scene: Scene): boolean
	local config = ForgeAnimationConfig.Blackout
	RevealBlackout.ExpandWhite(scene.Blackout)
	return waitFor(current, config.WhiteExpandTime + config.WhiteHoldTime)
end

local function playLock(current: Session, scene: Scene, rarity: string): boolean
	if not playWhiteIn(current, scene) then
		return false
	end
	local config = ForgeAnimationConfig.Impact
	local color = getRarityColor(rarity)
	local magnitude = config.Magnitude[rarity] or 1
	local weapon = scene.Weapon
	ScreenFlash.Undim(scene.Flash, 0)
	SilhouetteEffect.Reveal(scene.Silhouette, weapon.Model, weapon.Length, current.Cleanup)
	RevealWeapon.RestoreTags(weapon)
	scene.Aura = AuraEffect.Apply(weapon.Model, color, weapon.Length)
	RevealBlackout.FadeOut(scene.Blackout)
	ScreenBurst.Play(color, current.Cleanup)
	ImpactEffect.Play(RevealWeapon.GetCenter(weapon), color, magnitude, weapon.Length, current.Cleanup)
	CameraDirector.PunchFov(config.FovPunch * magnitude)
	CameraDirector.Shake(config.Shake * magnitude)
	RevealSound.Play(config.Sound, weapon.Model)
	return waitFor(current, config.SettleTime)
end

local function buildResultLines(result: SmeltResult): ResultLabel.ResultLines
	local info = ForgeAnimationConfig.Rarities[result.Rarity] or ForgeAnimationConfig.Rarities.Common
	return {
		Rarity = result.Rarity,
		RarityText = info.DisplayName,
		NameText = result.WeaponType,
		WeightText = WeaponWeight.Format(WeaponWeight.Get(result.WeaponTypeId, result.Scale)),
		PriceText = string.format(ForgeRevealMessages.PriceFormat, NumberFormat.WithCommas(result.Value)),
	}
end

local function showResult(current: Session, scene: Scene, result: SmeltResult): ResultLabel.Label
	local config = ForgeAnimationConfig.ResultLabel
	local weapon = scene.Weapon
	local focus = RevealWeapon.GetHoverCenter(weapon) + Vector3.yAxis * (weapon.Length * config.FocusLift)
	frameSpan(current, focus, weapon.Length, config.CameraMoveTime, config.Pullback)
	local position = getAboveTip(weapon, config.Gap)
	return ResultLabel.Show(position, buildResultLines(result), current.Cleanup)
end

local function waitForContinue(current: Session): boolean
	local isPressed = false
	local backButton = RevealBackButton.Show(function()
		isPressed = true
	end)
	RevealCleanup.Add(current.Cleanup, backButton.Gui)
	local deadline = os.clock() + ForgeAnimationConfig.Outro.AutoCloseTime
	while not isPressed and os.clock() < deadline do
		if not waitFor(current, 0) then
			return false
		end
	end
	RevealBackButton.Hide(backButton)
	return isCurrent(current)
end

local function flyToInventory(current: Session, scene: Scene): boolean
	local config = ForgeAnimationConfig.Outro
	current.RestoreGuis()
	local aura = scene.Aura
	if aura then
		AuraEffect.Stop(aura)
	end
	RevealWeapon.FlyTo(scene.Weapon, function(): Vector3
		return HudTarget.GetWorldPoint(config.HudGuiName, config.InventoryButtonName, config.FlyDepth)
	end, config.FlyTime)
	RevealSound.Play(config.FlySound, scene.Weapon.Model)
	if not waitFor(current, config.FlyTime) then
		return false
	end
	scene.Weapon.Model:Destroy()
	return true
end

local function playInfoCard(current: Session, result: SmeltResult): boolean
	local config = ForgeAnimationConfig.InfoCard
	local card = RevealInfoCard.Show(buildResultLines(result), current.Cleanup)
	if not waitFor(current, config.PopTime + config.HoldTime) then
		return false
	end
	RevealInfoCard.Hide(card)
	return waitFor(current, config.HideTime)
end

local function playOutro(current: Session, scene: Scene, result: SmeltResult): boolean
	if not playInfoCard(current, result) then
		return false
	end
	local label = showResult(current, scene, result)
	if not waitForContinue(current) then
		return false
	end
	ResultLabel.Hide(label)
	if not flyToInventory(current, scene) then
		return false
	end
	local duration = ForgeAnimationConfig.Camera.ReturnDuration
	CameraDirector.ReturnToStart(duration)
	return waitFor(current, duration)
end

local function playSequence(current: Session, result: SmeltResult)
	local scene = playRise(current)
	if scene == nil then
		return
	end
	if not playRarityRoll(current, scene, result.Rarity) then
		return
	end
	if not playShapeRoll(current, scene, result) then
		return
	end
	if not playLock(current, scene, result.Rarity) then
		return
	end
	playOutro(current, scene, result)
end

local function runSequence(current: Session, result: SmeltResult)
	local ok, err = pcall(playSequence, current, result)
	if not ok then
		warn("[ForgeRevealController] Sequence failed:", err)
	end
	finish(current)
end

local function buildStage(crucible: Model): Stage
	return {
		LavaPosition = OreCrucibleRig.FindLavaPosition(crucible),
		Front = OreCrucibleRig.FindFrontDirection(crucible),
	}
end

function ForgeRevealController.Begin(crucible: Model, onFinished: () -> ()): boolean
	ForgeRevealController.Cancel()
	local current: Session = {
		Stage = buildStage(crucible),
		Cleanup = RevealCleanup.New(),
		OnFinished = onFinished,
		HasResult = false,
		RestoreGuis = function() end,
	}
	session = current
	local ok, err = pcall(function()
		current.RestoreGuis = CutsceneGuiHider.Hide()
		RevealCleanup.Add(current.Cleanup, current.RestoreGuis)
		CameraDirector.Start(current.Cleanup)
		playIntro(current)
	end)
	if not ok then
		warn("[ForgeRevealController] Begin failed:", err)
		finish(current)
		return false
	end
	task.delay(ForgeAnimationConfig.ResultTimeout, function()
		if isCurrent(current) and not current.HasResult then
			warn("[ForgeRevealController] Smelt result timed out")
			finish(current)
		end
	end)
	return true
end

function ForgeRevealController.IsWaitingForResult(): boolean
	local current = session
	return current ~= nil and not current.HasResult
end

function ForgeRevealController.ShowResult(result: SmeltResult)
	local current = session
	if current == nil or current.HasResult then
		return
	end
	current.HasResult = true
	task.spawn(runSequence, current, result)
end

function ForgeRevealController.Cancel()
	local current = session
	if current then
		finish(current)
	end
end

function ForgeRevealController.IsPlaying(): boolean
	return session ~= nil
end

function ForgeRevealController.Init()
	if isInitialized then
		return
	end
	isInitialized = true
end

return ForgeRevealController
