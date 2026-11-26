--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local BuffConfig = require(shared:WaitForChild("Config"):WaitForChild("BuffConfig"))
local BuffEffects = require(shared:WaitForChild("Utils"):WaitForChild("BuffEffects"))
local ForgeConfig = require(shared:WaitForChild("Config"):WaitForChild("ForgeConfig"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local StationConfig = require(shared:WaitForChild("Config"):WaitForChild("StationConfig"))
local TutorialConfig = require(shared:WaitForChild("Config"):WaitForChild("TutorialConfig"))
local WeaponCatalog = require(shared:WaitForChild("Constants"):WaitForChild("WeaponCatalog"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local ForgeActivityService = require(script.Parent.ForgeActivityService)
local FriendBoostService = require(script.Parent.FriendBoostService)
local ForgeUpgradeService = require(script.Parent.ForgeUpgradeService)
local GamePassService = require(script.Parent.GamePassService)
local TutorialService = require(script.Parent.TutorialService)
local ForgeEventRoller = require(script.Parent.Parent.Internal.ForgeEventRoller)
local ForgeDifficulty = require(script.Parent.Parent.Internal.ForgeDifficulty)
local MutationRoller = require(script.Parent.Parent.Internal.MutationRoller)
local WeatherSchedule = require(script.Parent.Parent.Internal.WeatherSchedule)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Parent.Security.StationRange)

local ForgeOutcomeTable =
	require(ServerStorage:WaitForChild("LootTables"):WaitForChild("ForgeOutcomeTable"))

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Forge"
local PREVIEW_RATE_LIMIT_KEY = "ForgePreview"
local PROTECTED_OUTCOME_ID = "Keep"
local PERCENT_SCALE = 100
local MAX_WEAPON_ID_LENGTH = 64
local MIN_STRIKE_INTERVAL = ForgeConfig.StrikeDuration - ForgeConfig.StrikeServerTolerance

local EffectIds = BuffConfig.EffectIds

type Outcome = {
	Id: string,
	Weight: number,
	PointDelta: number,
	Multiplier: number,
}

type DowngradeRule = {
	ExtraWeight: number,
	Scale: number,
}

local FRENZY_DOWNGRADE_RULE: DowngradeRule = { ExtraWeight = 0, Scale = 1 }

type ForgeModifiers = {
	Luck: number,
	BreakMultiplier: number,
	SuccessMultiplier: number,
}

type ForgeSession = {
	WeaponId: string,
	FrenzyEndsAt: number,
	LockedUntil: number,
	ValueHistory: { number },
}

export type ForgeResult = {
	WeaponId: string,
	OutcomeId: string,
	PointDelta: number,
	ValueDelta: number,
	Multiplier: number,
	Level: number,
	ForgePoints: number,
	Value: number,
	State: string,
	ShapeStage: number,
	IsShapeChanged: boolean,
	IsFrenzyStarted: boolean,
	IsProtected: boolean,
	FrenzyTimeLeft: number,
	Chances: { [string]: number },
	RollChances: { [string]: number }?,
	StrikeId: number,
	Mutation: string?,
	IsNewMutation: boolean,
}

export type ForgePreview = {
	WeaponId: string,
	Chances: { [string]: number },
}

local ForgeService = {}

local isInitialized = false
local rng = Random.new()
local notifyForgeResult: RemoteEvent? = nil
local notifyForgePreview: RemoteEvent? = nil
local sessions: { [Player]: ForgeSession } = {}
local strikeCounters: { [Player]: number } = {}

local function getBuffHolder(player: Player): BuffEffects.BuffHolder
	return DataService.GetData(player) or {}
end

local function getModifiers(player: Player): ForgeModifiers
	local holder = getBuffHolder(player)
	local now = os.time()
	return {
		Luck = FriendBoostService.GetLuck(player) + ForgeUpgradeService.GetLuck(player),
		BreakMultiplier = BuffEffects.GetMultiplier(holder, EffectIds.BreakChanceMultiplier, now),
		SuccessMultiplier = BuffEffects.GetMultiplier(holder, EffectIds.SuccessChanceMultiplier, now)
			* GamePassService.GetLuckMultiplier(player),
	}
end

local function getMutationMultipliers(player: Player): MutationRoller.ChanceMultipliers
	local holder = getBuffHolder(player)
	local now = os.time()
	return {
		Base = BuffEffects.GetMultiplier(holder, EffectIds.MutationChanceMultiplier, now),
		Weather = BuffEffects.GetMultiplier(holder, EffectIds.WeatherMutationChanceMultiplier, now),
	}
end

local function applySuccessModifiers(outcome: Outcome, modifiers: ForgeModifiers): Outcome
	if outcome.PointDelta <= 0 then
		return outcome
	end
	local boosted = table.clone(outcome)
	boosted.Weight = outcome.Weight * (1 + modifiers.Luck) * modifiers.SuccessMultiplier
	return boosted
end

local function buildDowngrade(outcome: Outcome, rule: DowngradeRule): Outcome
	local candidate = table.clone(outcome)
	candidate.Weight = (outcome.Weight + rule.ExtraWeight) * rule.Scale
	return candidate
end

local function appendOutcomes(
	candidates: { Outcome },
	downgradeRule: DowngradeRule?,
	modifiers: ForgeModifiers
)
	for _, outcome in ForgeOutcomeTable.Outcomes do
		if outcome.PointDelta >= 0 then
			table.insert(candidates, applySuccessModifiers(outcome, modifiers))
		elseif downgradeRule ~= nil then
			table.insert(candidates, buildDowngrade(outcome, downgradeRule))
		end
	end
end

local function buildCandidates(weapon: any, modifiers: ForgeModifiers): { Outcome }
	local candidates: { Outcome } = {}
	local forgePoints = weapon.ForgePoints
	if forgePoints <= 0 then
		appendOutcomes(candidates, nil, modifiers)
		return candidates
	end
	local difficulty = ForgeDifficulty.GetMultiplier(weapon.Level)
	local riskWeight = ForgeOutcomeTable.RiskWeightPerPoint * forgePoints
	local breakWeight = ForgeOutcomeTable.BreakBaseWeight + riskWeight
	table.insert(candidates, {
		Id = ForgeOutcomeTable.BreakOutcomeId,
		Weight = breakWeight * difficulty * modifiers.BreakMultiplier,
		PointDelta = 0,
		Multiplier = 1,
	})
	appendOutcomes(candidates, { ExtraWeight = riskWeight, Scale = difficulty }, modifiers)
	return candidates
end

local function buildFrenzyCandidates(session: ForgeSession, modifiers: ForgeModifiers): { Outcome }
	local candidates: { Outcome } = {}
	local downgradeRule = if #session.ValueHistory > 0 then FRENZY_DOWNGRADE_RULE else nil
	appendOutcomes(candidates, downgradeRule, modifiers)
	return candidates
end

local function getActiveFrenzy(player: Player, weaponId: string): ForgeSession?
	local session = sessions[player]
	if session and session.WeaponId == weaponId and os.clock() < session.FrenzyEndsAt then
		return session
	end
	return nil
end

local function getCandidates(player: Player, weapon: any, modifiers: ForgeModifiers): { Outcome }
	local session = getActiveFrenzy(player, weapon.Id)
	if session then
		return buildFrenzyCandidates(session, modifiers)
	end
	return buildCandidates(weapon, modifiers)
end

local function getTotalWeight(candidates: { Outcome }): number
	local totalWeight = 0
	for _, candidate in candidates do
		totalWeight += candidate.Weight
	end
	return totalWeight
end

local function buildChances(candidates: { Outcome }): { [string]: number }
	local totalWeight = getTotalWeight(candidates)
	local chances: { [string]: number } = {}
	chances[ForgeOutcomeTable.BreakOutcomeId] = 0
	for _, outcome in ForgeOutcomeTable.Outcomes do
		chances[outcome.Id] = 0
	end
	for _, candidate in candidates do
		chances[candidate.Id] = candidate.Weight / totalWeight * PERCENT_SCALE
	end
	return chances
end

local function rollOutcome(candidates: { Outcome }): Outcome
	local totalWeight = getTotalWeight(candidates)
	local roll = rng:NextNumber(0, totalWeight)
	local cumulative = 0
	for _, candidate in candidates do
		cumulative += candidate.Weight
		if roll < cumulative then
			return candidate
		end
	end
	return candidates[#candidates]
end

local function cloneWeapon(weapon: any): any
	local copy = table.clone(weapon)
	copy.Recipe = table.clone(weapon.Recipe)
	copy.ValueHistory = table.clone(weapon.ValueHistory or {})
	return copy
end

local function applyBreak(weapon: any)
	weapon.State = DataTemplate.WeaponStates.Broken
	weapon.Value = math.floor(weapon.BaseValue * ForgeConfig.BrokenValueRatio)
	weapon.ValueHistory = {}
end

local function applyDowngrade(weapon: any)
	weapon.Level -= 1
	weapon.ForgePoints -= 1
	local previousValue = table.remove(weapon.ValueHistory)
	if previousValue ~= nil then
		weapon.Value = previousValue
	end
end

local function applyUpgrade(weapon: any, multiplier: number)
	local maxPoints = DataTemplate.Limits.MaxForgePoints
	table.insert(weapon.ValueHistory, weapon.Value)
	if #weapon.ValueHistory > maxPoints then
		table.remove(weapon.ValueHistory, 1)
	end
	weapon.Value = math.floor(weapon.Value * multiplier)
	weapon.Level += 1
	local nextPoints = weapon.ForgePoints + 1
	if nextPoints > maxPoints then
		weapon.ForgePoints = 0
		weapon.ValueHistory = {}
		return
	end
	weapon.ForgePoints = nextPoints
end

local function getShapeStage(weapon: any): number
	return weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
end

local function getMaxShapeStage(weapon: any): number
	local weaponType = WeaponCatalog.Resolve(weapon.WeaponType)
	local limit = DataTemplate.Limits.MaxShapeStage
	return if weaponType then math.min(weaponType.MaxShapeStage, limit) else limit
end

local function rollShapeChange(weapon: any): boolean
	local stage = getShapeStage(weapon)
	if stage >= getMaxShapeStage(weapon) then
		return false
	end
	local strikes = (weapon.ShapeStrikes or 0) + 1
	if not ForgeEventRoller.Roll(strikes) then
		weapon.ShapeStrikes = strikes
		return false
	end
	weapon.ShapeStrikes = 0
	weapon.ShapeStage = stage + 1
	return true
end

local function rollFrenzy(weapon: any): boolean
	local strikes = (weapon.FrenzyStrikes or 0) + 1
	local isTriggered = ForgeEventRoller.Roll(strikes)
	weapon.FrenzyStrikes = if isTriggered then 0 else strikes
	return isTriggered
end

local function buildResult(
	before: any,
	after: any,
	outcomeId: string,
	multiplier: number,
	isShapeChanged: boolean,
	frenzyTimeLeft: number,
	nextChances: { [string]: number }
): ForgeResult
	return {
		ShapeStage = getShapeStage(after),
		IsFrenzyStarted = false,
		WeaponId = after.Id,
		OutcomeId = outcomeId,
		PointDelta = after.Level - before.Level,
		ValueDelta = after.Value - before.Value,
		Multiplier = multiplier,
		Level = after.Level,
		ForgePoints = after.ForgePoints,
		Value = after.Value,
		State = after.State,
		IsShapeChanged = isShapeChanged,
		IsProtected = false,
		FrenzyTimeLeft = math.max(frenzyTimeLeft, 0),
		Chances = nextChances,
		RollChances = nil,
		StrikeId = 0,
		Mutation = after.Mutation,
		IsNewMutation = before.Mutation == nil and after.Mutation ~= nil,
	}
end

local function tryApplyMutation(player: Player, weapon: any)
	if weapon.Mutation ~= nil or weapon.State == DataTemplate.WeaponStates.Broken then
		return
	end
	local weatherId = WeatherSchedule.GetCurrent(os.time())
	weapon.Mutation = MutationRoller.Roll(weatherId, getMutationMultipliers(player))
end

local function tryConsumeBreakProtection(player: Player): boolean
	local buffId = BuffEffects.FindArmedBuff(getBuffHolder(player), EffectIds.BreakProtection)
	if buffId == nil then
		return false
	end
	local ok = DataActions.TryConsumeArmedBuff(player, buffId)
	return ok
end

local function startFrenzy(player: Player, weaponId: string)
	local now = os.clock()
	local frenzyEndsAt = now + ForgeConfig.FrenzyDuration
	sessions[player] = {
		WeaponId = weaponId,
		FrenzyEndsAt = frenzyEndsAt,
		LockedUntil = frenzyEndsAt + ForgeConfig.FrenzyLockDuration,
		ValueHistory = {},
	}
end

local function applyOutcome(weapon: any, outcome: Outcome): number
	if outcome.Id == ForgeOutcomeTable.BreakOutcomeId then
		applyBreak(weapon)
		return 1
	end
	weapon.State = DataTemplate.WeaponStates.Forged
	if outcome.PointDelta < 0 then
		applyDowngrade(weapon)
		return 1
	end
	if outcome.PointDelta > 0 then
		local multiplier = outcome.Multiplier
		applyUpgrade(weapon, multiplier)
		return multiplier
	end
	return 1
end

local function rollEvents(weapon: any, isBreak: boolean): (boolean, boolean)
	if isBreak then
		return false, false
	end
	return rollShapeChange(weapon), rollFrenzy(weapon)
end

local function protectedOnce(
	player: Player,
	weapon: any,
	modifiers: ForgeModifiers,
	rollChances: { [string]: number }
): (boolean, string?, ForgeResult?)
	DataActions.TryRecordForge(player, false)
	local nextChances = buildChances(getCandidates(player, weapon, modifiers))
	local result = buildResult(weapon, weapon, PROTECTED_OUTCOME_ID, 1, false, 0, nextChances)
	result.IsProtected = true
	result.RollChances = rollChances
	return true, nil, result
end

local function forgeOnce(player: Player, weapon: any): (boolean, string?, ForgeResult?)
	local modifiers = getModifiers(player)
	local candidates = buildCandidates(weapon, modifiers)
	local rollChances = buildChances(candidates)
	local outcome = rollOutcome(candidates)
	local isBreak = outcome.Id == ForgeOutcomeTable.BreakOutcomeId
	if isBreak and tryConsumeBreakProtection(player) then
		return protectedOnce(player, weapon, modifiers, rollChances)
	end
	local updated = cloneWeapon(weapon)
	local multiplier = applyOutcome(updated, outcome)
	local isShapeChanged, isFrenzyStarted = rollEvents(updated, isBreak)
	tryApplyMutation(player, updated)
	local ok, reason = DataActions.TryUpdateWeapon(player, updated)
	if not ok then
		return false, reason, nil
	end
	DataActions.TryRecordForge(player, isBreak)
	local frenzyTimeLeft = 0
	if isFrenzyStarted then
		startFrenzy(player, updated.Id)
		frenzyTimeLeft = ForgeConfig.FrenzyDuration
	end
	local result = buildResult(
		weapon,
		updated,
		outcome.Id,
		multiplier,
		isShapeChanged,
		frenzyTimeLeft,
		buildChances(getCandidates(player, updated, modifiers))
	)
	result.IsFrenzyStarted = isFrenzyStarted
	result.RollChances = rollChances
	return true, nil, result
end

local function applyFrenzyOutcome(weapon: any, outcome: Outcome, history: { number }): number
	if outcome.PointDelta < 0 then
		local previousValue = table.remove(history)
		if previousValue ~= nil then
			weapon.Value = previousValue
		end
		return 1
	end
	if outcome.PointDelta > 0 then
		local multiplier = outcome.Multiplier
		table.insert(history, weapon.Value)
		weapon.Value = math.floor(weapon.Value * multiplier)
		return multiplier
	end
	return 1
end

local function frenzyOnce(
	player: Player,
	weapon: any,
	session: ForgeSession
): (boolean, string?, ForgeResult?)
	local modifiers = getModifiers(player)
	local candidates = buildFrenzyCandidates(session, modifiers)
	local rollChances = buildChances(candidates)
	local outcome = rollOutcome(candidates)
	local updated = cloneWeapon(weapon)
	local history = table.clone(session.ValueHistory)
	local multiplier = applyFrenzyOutcome(updated, outcome, history)
	local isShapeChanged = rollShapeChange(updated)
	local ok, reason = DataActions.TryUpdateWeapon(player, updated)
	if not ok then
		return false, reason, nil
	end
	session.ValueHistory = history
	local frenzyTimeLeft = session.FrenzyEndsAt - os.clock()
	local nextChances = buildChances(getCandidates(player, updated, modifiers))
	local result = buildResult(
		weapon,
		updated,
		outcome.Id,
		multiplier,
		isShapeChanged,
		frenzyTimeLeft,
		nextChances
	)
	result.RollChances = rollChances
	return true, nil, result
end

local function getForgeWeapon(player: Player, weaponId: string): (any?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	local weapon, reason = DataActions.GetWeapon(player, weaponId)
	if weapon == nil then
		return nil, reason
	end
	if table.find(data.Equipped, weaponId) ~= nil then
		return nil, "WeaponEquipped"
	end
	return weapon, nil
end

local function isValidWeaponId(weaponId: any): boolean
	return type(weaponId) == "string" and #weaponId <= MAX_WEAPON_ID_LENGTH
end

local function getMaxLevel(weapon: any): number
	local rarityMax = ForgeConfig.MaxLevelByRarity[weapon.Rarity]
	local absoluteMax = DataTemplate.Limits.MaxWeaponLevel
	return if rarityMax then math.min(rarityMax, absoluteMax) else absoluteMax
end

function ForgeService.GetPreview(player: Player, weaponId: string): (boolean, string?, ForgePreview?)
	local weapon, reason = getForgeWeapon(player, weaponId)
	if weapon == nil then
		return false, reason, nil
	end
	local chances = buildChances(getCandidates(player, weapon, getModifiers(player)))
	return true, nil, { WeaponId = weapon.Id, Chances = chances }
end

function ForgeService.Forge(player: Player, weaponId: string): (boolean, string?, ForgeResult?)
	local weapon, reason = getForgeWeapon(player, weaponId)
	if weapon == nil then
		return false, reason, nil
	end
	if weapon.IsLocked == true then
		return false, "WeaponLocked", nil
	end
	if weapon.State == DataTemplate.WeaponStates.Broken then
		return false, "WeaponBroken", nil
	end
	local now = os.clock()
	local session = sessions[player]
	if session and now < session.FrenzyEndsAt then
		if session.WeaponId ~= weapon.Id then
			return false, "FrenzyActive", nil
		end
		return frenzyOnce(player, weapon, session)
	end
	if session and now < session.LockedUntil then
		return false, "ForgeLocked", nil
	end
	sessions[player] = nil
	if weapon.Level >= getMaxLevel(weapon) then
		return false, "MaxLevelReached", nil
	end
	return forgeOnce(player, weapon)
end

local function sendResult(player: Player, ok: boolean, reason: string?, result: ForgeResult?)
	if notifyForgeResult ~= nil then
		notifyForgeResult:FireClient(player, ok, reason, result)
	end
end

local function onRequestForge(player: Player, weaponId: any)
	if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
		sendResult(player, false, "InvalidRequest", nil)
		return
	end
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if not RateLimiter.CheckInterval(player, RATE_LIMIT_KEY, MIN_STRIKE_INTERVAL) then
		sendResult(player, false, "RateLimited", nil)
		return
	end
	if not StationRange.IsNear(player, StationConfig.ForgeModelName) then
		sendResult(player, false, "TooFar", nil)
		return
	end
	if TutorialService.IsStrikeBlocked(player) then
		sendResult(player, false, "TutorialLocked", nil)
		return
	end
	local ok, reason, result = ForgeService.Forge(player, weaponId)
	if ok and result then
		local strikeId = (strikeCounters[player] or 0) + 1
		strikeCounters[player] = strikeId
		result.StrikeId = strikeId
	end
	sendResult(player, ok, reason, result)
	if ok and result then
		ForgeActivityService.BroadcastStrike(player, result)
		TutorialService.Report(player, TutorialConfig.Events.Forged)
	end
end

local function sendPreview(player: Player, ok: boolean, reason: string?, preview: ForgePreview?)
	if notifyForgePreview ~= nil then
		notifyForgePreview:FireClient(player, ok, reason, preview)
	end
end

local function onRequestPreview(player: Player, weaponId: any)
	if not isValidWeaponId(weaponId) then
		sendPreview(player, false, "InvalidRequest", nil)
		return
	end
	if not DataService.IsLoaded(player) then
		sendPreview(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, PREVIEW_RATE_LIMIT_KEY) then
		sendPreview(player, false, "RateLimited", nil)
		return
	end
	local ok, reason, preview = ForgeService.GetPreview(player, weaponId)
	sendPreview(player, ok, reason, preview)
end

local function handlePlayerRemoving(player: Player)
	sessions[player] = nil
	strikeCounters[player] = nil
end

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

function ForgeService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()

	local requestForge = Instance.new("RemoteEvent")
	requestForge.Name = RemoteNames.RequestForge
	requestForge.Parent = remotesFolder

	local notifyRemote = Instance.new("RemoteEvent")
	notifyRemote.Name = RemoteNames.NotifyForgeResult
	notifyRemote.Parent = remotesFolder
	notifyForgeResult = notifyRemote

	local requestPreview = Instance.new("RemoteEvent")
	requestPreview.Name = RemoteNames.RequestForgePreview
	requestPreview.Parent = remotesFolder

	local previewRemote = Instance.new("RemoteEvent")
	previewRemote.Name = RemoteNames.NotifyForgePreview
	previewRemote.Parent = remotesFolder
	notifyForgePreview = previewRemote

	requestForge.OnServerEvent:Connect(onRequestForge)
	requestPreview.OnServerEvent:Connect(onRequestPreview)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)
end

return ForgeService
