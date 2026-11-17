--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BackpackMessages = require(ReplicatedStorage.Shared.Constants.BackpackMessages)
local MutationConfig = require(ReplicatedStorage.Shared.Config.MutationConfig)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local StatusEffectMessages = require(ReplicatedStorage.Shared.Constants.StatusEffectMessages)
local WeatherConfig = require(ReplicatedStorage.Shared.Config.WeatherConfig)
local WeatherMessages = require(ReplicatedStorage.Shared.Constants.WeatherMessages)
local WorldAttributes = require(ReplicatedStorage.Shared.Constants.WorldAttributes)
local PlayerStateController = require(script.Parent.PlayerStateController)
local StatusEffectsScreen = require(script.Parent.Parent.UI.Screens.StatusEffectsScreen)

type PlayerState = PlayerStateTypes.PlayerState
type StatusEffect = StatusEffectsScreen.StatusEffect

local StatusEffectController = {}

local isInitialized = false

local function getWeatherDescription(weatherId: string): string
	local weather = WeatherConfig.ById[weatherId]
	if not weather then
		return ""
	end
	local mutationName = WeatherMessages.MutationNames[weather.MutationId] or weather.MutationId
	local multiplier = tostring(MutationConfig.GetMultiplier(weather.MutationId))
	return string.format(StatusEffectMessages.WeatherDescriptionFormat, mutationName, multiplier)
end

local function getBuffTitle(itemId: string): string
	return BackpackMessages.ItemNames[itemId] or itemId
end

local function getBuffDescription(itemId: string, count: number?): string
	local description = BackpackMessages.ItemDescriptions[itemId] or ""
	if count == nil then
		return description
	end
	return string.format(StatusEffectMessages.UsesLeftFormat, description, count)
end

local function collectWeather(effects: { StatusEffect })
	local weatherId = ReplicatedStorage:GetAttribute(WorldAttributes.WeatherId)
	local endsAt = ReplicatedStorage:GetAttribute(WorldAttributes.WeatherEndsAt)
	if type(weatherId) ~= "string" or weatherId == "" or type(endsAt) ~= "number" then
		return
	end
	local weatherName = WeatherMessages.WeatherNames[weatherId] or weatherId
	table.insert(effects, {
		Id = weatherId,
		Kind = "Weather",
		ExpiresAt = endsAt,
		Title = string.format(StatusEffectMessages.WeatherTitleFormat, weatherName),
		Description = getWeatherDescription(weatherId),
	})
end

local function collectBuffs(effects: { StatusEffect }, state: PlayerState?)
	local activeBuffs = if state then state.ActiveBuffs else nil
	if not activeBuffs then
		return
	end
	local buffs: { StatusEffect } = {}
	for itemId, expiresAt in activeBuffs do
		table.insert(buffs, {
			Id = itemId,
			Kind = "Buff",
			ExpiresAt = expiresAt,
			Title = getBuffTitle(itemId),
			Description = getBuffDescription(itemId, nil),
		})
	end
	table.sort(buffs, function(a: StatusEffect, b: StatusEffect): boolean
		return a.ExpiresAt < b.ExpiresAt
	end)
	table.move(buffs, 1, #buffs, #effects + 1, effects)
end

local function collectArmedBuffs(effects: { StatusEffect }, state: PlayerState?)
	local armedBuffs = if state then state.ArmedBuffs else nil
	if not armedBuffs then
		return
	end
	local itemIds: { string } = {}
	for itemId, count in armedBuffs do
		if count > 0 then
			table.insert(itemIds, itemId)
		end
	end
	table.sort(itemIds)
	for _, itemId in itemIds do
		local count = armedBuffs[itemId]
		table.insert(effects, {
			Id = itemId,
			Kind = "Buff",
			ExpiresAt = math.huge,
			Count = count,
			Title = getBuffTitle(itemId),
			Description = getBuffDescription(itemId, count),
		})
	end
end

local function render()
	local effects: { StatusEffect } = {}
	local state = PlayerStateController.GetState()
	collectWeather(effects)
	collectBuffs(effects, state)
	collectArmedBuffs(effects, state)
	StatusEffectsScreen.SetEffects(effects)
end

function StatusEffectController.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	PlayerStateController.OnChanged(function()
		render()
	end)
	ReplicatedStorage:GetAttributeChangedSignal(WorldAttributes.WeatherId):Connect(render)
	ReplicatedStorage:GetAttributeChangedSignal(WorldAttributes.WeatherEndsAt):Connect(render)
	render()
end

return StatusEffectController
