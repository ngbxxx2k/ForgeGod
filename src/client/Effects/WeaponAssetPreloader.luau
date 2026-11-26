--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local WeaponCatalog = require(ReplicatedStorage.Shared.Constants.WeaponCatalog)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local WeaponModelFinder = require(ReplicatedStorage.Shared.Utils.WeaponModelFinder)

type WeaponSummary = PlayerStateTypes.WeaponSummary

local WeaponAssetPreloader = {}

local loadedTemplates: { [Model]: boolean } = {}
local waitingCallbacks: { [Model]: { () -> () } } = {}
local backgroundQueue: { Model } = {}
local queuedTemplates: { [Model]: boolean } = {}
local isQueueRunning = false

local function finish(template: Model)
	loadedTemplates[template] = true
	local callbacks = waitingCallbacks[template]
	waitingCallbacks[template] = nil
	for _, callback in callbacks or {} do
		task.spawn(callback)
	end
end

local function isKnown(template: Model): boolean
	return loadedTemplates[template] == true or waitingCallbacks[template] ~= nil
end

local function load(template: Model)
	waitingCallbacks[template] = waitingCallbacks[template] or {}
	local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, { template })
	if not ok then
		warn("[WeaponAssetPreloader] Preload failed:", template:GetFullName(), err)
	end
	finish(template)
end

local function runQueue()
	isQueueRunning = true
	while #backgroundQueue > 0 do
		local template = table.remove(backgroundQueue, 1) :: Model
		queuedTemplates[template] = nil
		if not isKnown(template) then
			load(template)
		end
	end
	isQueueRunning = false
end

local function enqueue(template: Model)
	if isKnown(template) or queuedTemplates[template] then
		return
	end
	queuedTemplates[template] = true
	table.insert(backgroundQueue, template)
	if not isQueueRunning then
		task.spawn(runQueue)
	end
end

local function getMaxStage(weaponType: string?): number
	local resolved = WeaponCatalog.Resolve(weaponType)
	return if resolved then resolved.MaxShapeStage else ForgeStrikeConfig.DefaultShapeStage
end

local function enqueueStage(weaponType: string?, stage: number)
	local template = WeaponModelFinder.Find(weaponType, stage)
	if template then
		enqueue(template)
	end
end

function WeaponAssetPreloader.Preload(template: Model)
	if isKnown(template) then
		return
	end
	waitingCallbacks[template] = {}
	task.spawn(load, template)
end

function WeaponAssetPreloader.PreloadWeaponType(weaponType: string?, firstStage: number?)
	local startStage = firstStage or ForgeStrikeConfig.DefaultShapeStage
	local template = WeaponModelFinder.Find(weaponType, startStage)
	if template then
		WeaponAssetPreloader.Preload(template)
	end
	for stage = startStage + 1, getMaxStage(weaponType) do
		enqueueStage(weaponType, stage)
	end
end

function WeaponAssetPreloader.QueueWeapons(weapons: { WeaponSummary })
	for _, weapon in weapons do
		enqueueStage(weapon.WeaponType, weapon.ShapeStage or ForgeStrikeConfig.DefaultShapeStage)
	end
	for _, weapon in weapons do
		local currentStage = weapon.ShapeStage or ForgeStrikeConfig.DefaultShapeStage
		for stage = currentStage + 1, getMaxStage(weapon.WeaponType) do
			enqueueStage(weapon.WeaponType, stage)
		end
	end
end

function WeaponAssetPreloader.WhenReady(template: Model, callback: () -> ())
	if loadedTemplates[template] then
		callback()
		return
	end
	local isDone = false
	local function runOnce()
		if not isDone then
			isDone = true
			callback()
		end
	end
	WeaponAssetPreloader.Preload(template)
	local callbacks = waitingCallbacks[template]
	if callbacks then
		table.insert(callbacks, runOnce)
	end
	task.delay(ForgeStrikeConfig.ModelPreloadTimeout, runOnce)
end

return WeaponAssetPreloader
