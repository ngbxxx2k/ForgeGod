--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local BuffConfig = require(shared:WaitForChild("Config"):WaitForChild("BuffConfig"))
local DigToolConfig = require(shared:WaitForChild("Config"):WaitForChild("DigToolConfig"))
local BuffEffects = require(shared:WaitForChild("Utils"):WaitForChild("BuffEffects"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local FriendBoostService = require(script.Parent.FriendBoostService)
local GamePassService = require(script.Parent.GamePassService)

local DEFAULT_DETECTOR_LUCK = 1

local DigLuckService = {}

local isInitialized = false

local function getDetectorLuck(player: Player): number
	local detectorId = DigToolConfig.ToolIds.Detector
	local tierIndex = DataActions.GetDigToolTier(player, detectorId) or DigToolConfig.MinTier
	local tier = DigToolConfig.GetTier(detectorId, tierIndex)
	return if tier and tier.Luck then tier.Luck else DEFAULT_DETECTOR_LUCK
end

local function getPotionBonus(player: Player): number
	local data = DataService.GetData(player)
	if data == nil then
		return 0
	end
	return BuffEffects.GetBonus(data, BuffConfig.EffectIds.DigLuckBonus, os.time())
end

function DigLuckService.GetLuck(player: Player): number
	local bonus = 1 + FriendBoostService.GetLuck(player) + getPotionBonus(player)
	return getDetectorLuck(player) * bonus * GamePassService.GetLuckMultiplier(player)
end

function DigLuckService.Init()
	if isInitialized then
		return
	end
	isInitialized = true
end

return DigLuckService
