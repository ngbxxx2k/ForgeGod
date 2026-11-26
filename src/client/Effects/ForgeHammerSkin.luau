--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeAnimationConfig = require(ReplicatedStorage.Shared.Config.ForgeAnimationConfig)
local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeUpgradeConfig = require(ReplicatedStorage.Shared.Config.ForgeUpgradeConfig)
local PlayerAttributes = require(ReplicatedStorage.Shared.Constants.PlayerAttributes)
local ForgeToolSkin = require(ReplicatedStorage.Shared.Utils.ForgeToolSkin)

local ForgeHammerSkin = {}

local function findTemplate(): Instance?
	local assets = ReplicatedStorage:FindFirstChild(ForgeAnimationConfig.AssetsFolderName)
	local models = assets and assets:FindFirstChild(ForgeAnimationConfig.ModelsFolderName)
	return models and models:FindFirstChild(ForgeStrikeConfig.HammerModelName)
end

local function getSkinTier(player: Player): number
	local hammerId = ForgeUpgradeConfig.TrackIds.Hammer
	return ForgeUpgradeConfig.ClampTier(hammerId, player:GetAttribute(PlayerAttributes.HammerSkinTier))
end

function ForgeHammerSkin.CreateTemplate(player: Player): Instance?
	local template = findTemplate()
	if template == nil then
		return nil
	end
	local skinned = template:Clone()
	ForgeToolSkin.Apply(skinned, ForgeUpgradeConfig.TrackIds.Hammer, getSkinTier(player))
	return skinned
end

return ForgeHammerSkin
