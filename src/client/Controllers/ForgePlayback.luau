--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)
local ForgeWheelConfig = require(ReplicatedStorage.Shared.Config.ForgeWheelConfig)
local ForgeOutcomes = require(ReplicatedStorage.Shared.Constants.ForgeOutcomes)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local WheelMath = require(ReplicatedStorage.Shared.Utils.WheelMath)
local WeaponIncome = require(ReplicatedStorage.Shared.Utils.WeaponIncome)
local ForgeScreen = require(script.Parent.Parent.UI.Screens.ForgeScreen)
local ForgeWheel = require(script.Parent.Parent.UI.Components.ForgeWheel)
local WheelNeedle = require(script.Parent.Parent.UI.Components.WheelNeedle)
local ForgeResultFx = require(script.Parent.Parent.Effects.ForgeResultFx)
local ForgeOutcomePopup = require(script.Parent.Parent.Effects.ForgeOutcomePopup)
local ForgeStrikeFx = require(script.Parent.Parent.Effects.ForgeStrikeFx)

local BREAK_OUTCOME_ID = "Break"
local PROTECTED_STYLE_ID = "Protected"
local FRENZY_COLOR = Color3.fromRGB(255, 200, 60)
local PROTECTED_COLOR = Color3.fromRGB(120, 180, 255)
local ANGLE_TOLERANCE = 1e-3
local FULL_TURN = 360
local MONOTONIC_DIVISOR = 3

export type NameResolver = (result: any) -> string

local ForgePlayback = {}

local isInitialized = false
local rng = Random.new()
local nameResolver: NameResolver? = nil
local landedOutcomeId: string? = nil
local spinStartRotation = 0
local lastTickSegment: string? = nil

local function findOutcome(outcomeId: string): ForgeOutcomes.ForgeOutcome?
	for _, outcome in ForgeOutcomes do
		if outcome.Id == outcomeId then
			return outcome
		end
	end
	return nil
end

local function getTargetId(result: any): string
	return if result.IsProtected == true then BREAK_OUTCOME_ID else result.OutcomeId
end

local function getMutation(result: any): string?
	return if type(result.Mutation) == "string" then result.Mutation else nil
end

local function getIncome(value: number, mutation: string?): number
	return WeaponIncome.PerSecond(value, mutation, false)
end

local function formatValueDetail(result: any): string?
	local valueDelta = result.ValueDelta
	if type(valueDelta) ~= "number" or valueDelta == 0 or type(result.Value) ~= "number" then
		return nil
	end
	local mutation = getMutation(result)
	local delta = getIncome(result.Value, mutation) - getIncome(result.Value - valueDelta, mutation)
	if delta == 0 then
		return nil
	end
	local sign = if delta < 0 then ForgeMessages.NegativeSign else ForgeMessages.PositiveSign
	local amount = NumberFormat.Compact(math.abs(delta))
	return string.format(ForgeMessages.ValueDetailFormat, sign, amount, tostring(result.Multiplier))
end

local function formatChance(result: any): string
	local chances = result.RollChances
	local chance = if type(chances) == "table" then chances[getTargetId(result)] else nil
	if type(chance) ~= "number" then
		return ""
	end
	return string.format(ForgeMessages.ChanceFormat, ForgeWheel.FormatPercent(chance))
end

local function buildStyle(styleId: string): any
	local style = ForgeResultFx.GetStyle(styleId)
	if style == nil then
		return { StartScale = 1, Duration = 0.2, EasingStyle = Enum.EasingStyle.Quad, Wobble = 0 }
	end
	return {
		StartScale = style.TextStartScale,
		Duration = style.TextDuration,
		EasingStyle = style.TextEasing,
		Wobble = style.TextWobble,
	}
end

local function getEventText(result: any): string?
	local isShapeChanged = result.IsShapeChanged == true
	local isFrenzyStarted = result.IsFrenzyStarted == true
	if isShapeChanged and isFrenzyStarted then
		return ForgeMessages.ShapeAndFrenzyText
	end
	if isShapeChanged then
		return ForgeMessages.ShapeChangedText
	end
	if isFrenzyStarted then
		return ForgeMessages.FrenzyStartedText
	end
	return nil
end

local function buildView(result: any): (ForgeScreen.ResultView, string)
	if result.IsProtected == true then
		return {
			Text = ForgeMessages.ProtectedDisplayName,
			Detail = ForgeMessages.ProtectedDetailText,
			Color = PROTECTED_COLOR,
			HighlightId = BREAK_OUTCOME_ID,
			ValueDetail = nil,
			SwapStyle = buildStyle(PROTECTED_STYLE_ID),
		}, PROTECTED_STYLE_ID
	end
	local outcome = findOutcome(result.OutcomeId)
	local delta = string.format(ForgeMessages.PointDeltaFormat, result.PointDelta or 0)
	local name = if outcome then outcome.DisplayName else ForgeMessages.FrenzyDisplayName
	local text = if (result.PointDelta or 0) ~= 0
		then string.format(ForgeMessages.ResultFormat, name, delta)
		else name
	local detail = getEventText(result) or formatChance(result)
	return {
		Text = text,
		Detail = detail,
		Color = if outcome then outcome.TextColor else FRENZY_COLOR,
		HighlightId = if outcome then outcome.Id else nil,
		ValueDetail = formatValueDetail(result),
		SwapStyle = buildStyle(result.OutcomeId),
	}, result.OutcomeId
end

local function getPopupLabel(result: any): (string, Color3)
	if result.IsProtected == true then
		return ForgeMessages.ProtectedDisplayName, PROTECTED_COLOR
	end
	local outcome = findOutcome(result.OutcomeId)
	if outcome == nil then
		return ForgeMessages.FrenzyDisplayName, FRENZY_COLOR
	end
	return outcome.DisplayName, outcome.TextColor
end

local function present(result: any)
	local view, styleId = buildView(result)
	ForgeScreen.ShowResult(view)
	ForgeResultFx.Play(styleId)
	local popupText, popupColor = getPopupLabel(result)
	ForgeOutcomePopup.Show(ForgeStrikeFx.GetImpactPoint(), popupText, popupColor)
	local resolver = nameResolver
	ForgeScreen.Render({
		WeaponName = if resolver then resolver(result) else "",
		Mutation = getMutation(result),
		Level = result.Level,
		Value = getIncome(result.Value, getMutation(result)),
		ForgePoints = result.ForgePoints,
		MaxForgePoints = ForgeConfig.MaxForgePoints,
	}, true)
end

local function verifyLanding(segments: { WheelMath.Segment }, targetId: string, strikeId: any)
	local angle = WheelMath.NeedleAngle(WheelNeedle.GetRotation(), ForgeWheelConfig.NeedleRestAngle)
	local landed = WheelMath.SegmentAt(segments, angle + ANGLE_TOLERANCE)
	if landed == nil or landed.Id ~= targetId then
		warn("[ForgePlayback] Needle landed outside target", strikeId, targetId, angle)
	end
end

local function onNeedleTick(rotation: number)
	local angle = WheelMath.NeedleAngle(rotation, ForgeWheelConfig.NeedleRestAngle)
	local segment = WheelMath.SegmentAt(ForgeWheel.GetSegments(), angle)
	local id = if segment then segment.Id else nil
	if id ~= lastTickSegment then
		lastTickSegment = id
		ForgeResultFx.PlayTick(ForgeWheelConfig.TickSoundName, ForgeWheelConfig.TickMinInterval)
	end
end

function ForgePlayback.BeginSpin(beatDuration: number)
	WheelNeedle.Normalize()
	spinStartRotation = WheelNeedle.GetRotation()
	local turns = ForgeWheelConfig.FreeSpinTurnsPerBeat
	WheelNeedle.StartSpin(turns * FULL_TURN / math.max(beatDuration, 1e-3))
	ForgeScreen.Highlight(nil)
end

function ForgePlayback.Halt(duration: number, onDone: () -> ())
	local rotation = WheelNeedle.GetRotation()
	local travel = math.max(WheelNeedle.GetVelocity(), 0) * duration / 2
	WheelNeedle.LandAt(rotation + travel, duration, function()
		WheelNeedle.Normalize()
		onDone()
	end)
end

local function planTarget(result: any): (number?, string)
	local targetId = getTargetId(result)
	local segment = WheelMath.FindSegment(ForgeWheel.GetSegments(), targetId)
	if segment == nil then
		warn("[ForgePlayback] No wheel segment for", targetId)
		return nil, targetId
	end
	local margin = ForgeWheelConfig.TargetEdgeMargin
	return WheelMath.PickTargetAngle(segment, rng:NextNumber(), margin), targetId
end

function ForgePlayback.Land(result: any, duration: number, onDone: () -> ())
	local rollChances = result.RollChances
	if type(rollChances) ~= "table" then
		ForgePlayback.Halt(duration, function()
			present(result)
			onDone()
		end)
		return
	end
	ForgeScreen.SetChances(rollChances, true)
	local angle, targetId = planTarget(result)
	if angle == nil then
		ForgePlayback.Halt(duration, function()
			present(result)
			onDone()
		end)
		return
	end
	local rotation = WheelNeedle.GetRotation()
	local minTravel = math.max(WheelNeedle.GetVelocity(), 0) * duration / MONOTONIC_DIVISOR
	local final = WheelMath.PlanLanding(
		rotation,
		spinStartRotation,
		angle,
		ForgeWheelConfig.NeedleRestAngle,
		ForgeWheelConfig.MinFullTurns,
		minTravel
	)
	WheelNeedle.LandAt(final, duration, function()
		verifyLanding(ForgeWheel.GetSegments(), targetId, result.StrikeId)
		WheelNeedle.Normalize()
		landedOutcomeId = targetId
		present(result)
		onDone()
	end)
end

function ForgePlayback.ShowMessage(text: string)
	ForgeScreen.ShowMessage(text)
end

function ForgePlayback.SettleNeedle()
	local targetId = landedOutcomeId
	local segment = targetId and WheelMath.FindSegment(ForgeWheel.GetSegments(), targetId)
	if segment == nil or WheelNeedle.IsMoving() then
		return
	end
	local rest = ForgeWheelConfig.NeedleRestAngle
	local rotation = WheelNeedle.GetRotation()
	local angle = WheelMath.NeedleAngle(rotation, rest)
	local inside = WheelMath.ClampInside(segment, angle, ForgeWheelConfig.TargetEdgeMargin)
	local delta = WheelMath.ShortestDelta(angle, inside)
	if math.abs(delta) < ANGLE_TOLERANCE then
		return
	end
	WheelNeedle.LandAt(rotation + delta, ForgeWheelConfig.SettleTime, WheelNeedle.Normalize)
end

function ForgePlayback.Reset()
	local idleRotation = ForgeWheelConfig.NeedleIdleAngle - ForgeWheelConfig.NeedleRestAngle
	landedOutcomeId = nil
	spinStartRotation = idleRotation
	lastTickSegment = nil
	WheelNeedle.Reset(idleRotation)
	ForgeResultFx.StopAll()
	ForgeOutcomePopup.Stop()
end

function ForgePlayback.SetNameResolver(resolver: NameResolver)
	nameResolver = resolver
end

function ForgePlayback.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	WheelNeedle.SetTickHandler(onNeedleTick)
end

return ForgePlayback
