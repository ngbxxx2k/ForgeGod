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

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local FriendBoostService = require(script.Parent.FriendBoostService)
local MutationRoller = require(script.Parent.Parent.Internal.MutationRoller)
local WeatherSchedule = require(script.Parent.Parent.Internal.WeatherSchedule)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Parent.Security.StationRange)

local ForgeOutcomeTable =
	require(ServerStorage:WaitForChild("LootTables"):WaitForChild("ForgeOutcomeTable"))

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Forge"
local PREVIEW_RATE_LIMIT_KEY = "ForgePreview"
local FRENZY_OUTCOME_ID = "Frenzy"
local PROTECTED_OUTCOME_ID = "Keep"
local PERCENT_SCALE = 100
local MAX_WEAPON_ID_LENGTH = 64

local EffectIds = BuffConfig.EffectIds

type Outcome = {
	Id: string,
	Weight: number,
	PointDelta: number,
	Multipliers: { number },
}

type ForgeModifiers = {
	Luck: number,
	BreakMultiplier: number,
	SuccessMultiplier: number,
}

type ForgeSession = {
	WeaponId: string,
	FrenzyEndsAt: number,
	LockedUntil: number,
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
	IsShapeChanged: boolean,
	IsProtected: boolean,
	FrenzyTimeLeft: number,
	Chances: { [string]: number },
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

local function getBuffHolder(player: Player): BuffEffects.BuffHolder
	return DataService.GetData(player) or {}
end

local function getModifiers(player: Player): ForgeModifiers
	local holder = getBuffHolder(player)
	local now = os.time()
	return {
		Luck = FriendBoostService.GetLuck(player),
		BreakMultiplier = BuffEffects.GetMultiplier(holder, EffectIds.BreakChanceMultiplier, now),
		SuccessMultiplier = BuffEffects.GetMultiplier(
			holder,
			EffectIds.SuccessChanceMultiplier,
			now
		),
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

local function buildCandidates(forgePoints: number, modifiers: ForgeModifiers): { Outcome }
	local breakWeight = ForgeOutcomeTable.BreakBaseWeight
		+ ForgeOutcomeTable.BreakWeightPerPoint * forgePoints
	local candidates: { Outcome } = {
		{
			Id = ForgeOutcomeTable.BreakOutcomeId,
			Weight = breakWeight * modifiers.BreakMultiplier,
			PointDelta = 0,
			Multipliers = {},
		},
	}
	for _, outcome in ForgeOutcomeTable.Outcomes do
		local isBlockedDowngrade = outcome.PointDelta < 0 and forgePoints <= 0
		if not isBlockedDowngrade then
			table.insert(candidates, applySuccessModifiers(outcome, modifiers))
		end
	end
	return candidates
end

local function getTotalWeight(candidates: { Outcome }): number
	local totalWeight = 0
	for _, candidate in candidates do
		totalWeight += candidate.Weight
	end
	return totalWeight
end

local function buildChances(forgePoints: number, modifiers: ForgeModifiers): { [string]: number }
	local candidates = buildCandidates(forgePoints, modifiers)
	local totalWeight = getTotalWeight(candidates)
	local chances: { [string]: number } = {}
	for _, outcome in ForgeOutcomeTable.Outcomes do
		chances[outcome.Id] = 0
	end
	for _, candidate in candidates do
		chances[candidate.Id] = candidate.Weight / totalWeight * PERCENT_SCALE
	end
	return chances
end

local function rollOutcome(forgePoints: number, modifiers: ForgeModifiers): Outcome
	local candidates = buildCandidates(forgePoints, modifiers)
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

local function pickMultiplier(outcome: Outcome): number
	local count = #outcome.Multipliers
	if count == 0 then
		return 1
	end
	return outcome.Multipliers[rng:NextInteger(1, count)]
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

local function applyUpgrade(weapon: any, multiplier: number): boolean
	table.insert(weapon.ValueHistory, weapon.Value)
	weapon.Value = math.floor(weapon.Value * multiplier)
	weapon.Level += 1
	weapon.ForgePoints += 1
	if weapon.ForgePoints < DataTemplate.Limits.MaxForgePoints then
		return false
	end
	weapon.ForgePoints = 0
	weapon.ValueHistory = {}
	return true
end

local function buildResult(
	before: any,
	after: any,
	outcomeId: string,
	multiplier: number,
	isShapeChanged: boolean,
	frenzyTimeLeft: number,
	modifiers: ForgeModifiers
): ForgeResult
	return {
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
		Chances = buildChances(after.ForgePoints, modifiers),
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
	}
end

local function applyOutcome(weapon: any, outcome: Outcome): (number, boolean)
	if outcome.Id == ForgeOutcomeTable.BreakOutcomeId then
		applyBreak(weapon)
		return 1, false
	end
	weapon.State = DataTemplate.WeaponStates.Forged
	if outcome.PointDelta < 0 then
		applyDowngrade(weapon)
		return 1, false
	end
	if outcome.PointDelta > 0 then
		local multiplier = pickMultiplier(outcome)
		return multiplier, applyUpgrade(weapon, multiplier)
	end
	return 1, false
end

local function protectedOnce(
	player: Player,
	weapon: any,
	modifiers: ForgeModifiers
): (boolean, string?, ForgeResult?)
	DataActions.TryRecordForge(player, false)
	local result = buildResult(weapon, weapon, PROTECTED_OUTCOME_ID, 1, false, 0, modifiers)
	result.IsProtected = true
	return true, nil, result
end

local function forgeOnce(player: Player, weapon: any): (boolean, string?, ForgeResult?)
	local modifiers = getModifiers(player)
	local outcome = rollOutcome(weapon.ForgePoints, modifiers)
	local isBreak = outcome.Id == ForgeOutcomeTable.BreakOutcomeId
	if isBreak and tryConsumeBreakProtection(player) then
		return protectedOnce(player, weapon, modifiers)
	end
	local updated = cloneWeapon(weapon)
	local multiplier, isShapeChanged = applyOutcome(updated, outcome)
	tryApplyMutation(player, updated)
	local ok, reason = DataActions.TryUpdateWeapon(player, updated)
	if not ok then
		return false, reason, nil
	end
	DataActions.TryRecordForge(player, isBreak)
	local frenzyTimeLeft = 0
	if isShapeChanged then
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
		modifiers
	)
	return true, nil, result
end

local function frenzyOnce(
	player: Player,
	weapon: any,
	session: ForgeSession
): (boolean, string?, ForgeResult?)
	local updated = cloneWeapon(weapon)
	local multiplier = ForgeOutcomeTable.FrenzyMultiplier
	updated.Value = math.floor(updated.Value * multiplier)
	local ok, reason = DataActions.TryUpdateWeapon(player, updated)
	if not ok then
		return false, reason, nil
	end
	local frenzyTimeLeft = session.FrenzyEndsAt - os.clock()
	local modifiers = getModifiers(player)
	local result =
		buildResult(weapon, updated, FRENZY_OUTCOME_ID, multiplier, false, frenzyTimeLeft, modifiers)
	return true, nil, result
end

local function getActiveWeapon(player: Player): (any?, string?)
	local data = DataService.GetData(player)
	if data == nil then
		return nil, "NotLoaded"
	end
	local weaponId = data.Equipped[#data.Equipped]
	if weaponId == nil then
		return nil, "NoWeaponEquipped"
	end
	return DataActions.GetWeapon(player, weaponId)
end

function ForgeService.GetPreview(player: Player): (boolean, string?, ForgePreview?)
	local weapon, reason = getActiveWeapon(player)
	if weapon == nil then
		return false, reason, nil
	end
	local chances = buildChances(weapon.ForgePoints, getModifiers(player))
	return true, nil, { WeaponId = weapon.Id, Chances = chances }
end

function ForgeService.Forge(player: Player, weaponId: string): (boolean, string?, ForgeResult?)
	local weapon, reason = getActiveWeapon(player)
	if weapon == nil then
		return false, reason, nil
	end
	if weapon.Id ~= weaponId then
		return false, "WeaponChanged", nil
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
	if weapon.Level >= DataTemplate.Limits.MaxWeaponLevel then
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
	if not StationRange.IsNear(player, StationConfig.ForgeModelName) then
		sendResult(player, false, "TooFar", nil)
		return
	end
	local ok, reason, result = ForgeService.Forge(player, weaponId)
	sendResult(player, ok, reason, result)
end

local function sendPreview(player: Player, ok: boolean, reason: string?, preview: ForgePreview?)
	if notifyForgePreview ~= nil then
		notifyForgePreview:FireClient(player, ok, reason, preview)
	end
end

local function onRequestPreview(player: Player)
	if not DataService.IsLoaded(player) then
		sendPreview(player, false, "NotLoaded", nil)
		return
	end
	if not RateLimiter.Check(player, PREVIEW_RATE_LIMIT_KEY) then
		sendPreview(player, false, "RateLimited", nil)
		return
	end
	local ok, reason, preview = ForgeService.GetPreview(player)
	sendPreview(player, ok, reason, preview)
end

local function handlePlayerRemoving(player: Player)
	sessions[player] = nil
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
