--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)
local DigZoneConfig = require(ReplicatedStorage.Shared.Config.DigZoneConfig)

local DigSiteBadgeController = {}

local isInitialized = false

local function createAnchor(): Attachment
	local anchor = Instance.new("Attachment")
	anchor.Name = DigZoneConfig.BadgeAnchorName
	anchor.Parent = Workspace.Terrain
	anchor.WorldPosition = DigZoneConfig.Center + Vector3.yAxis * DigZoneConfig.BadgeHeight
	return anchor
end

local function createIcon(): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(1, 1)
	icon.BackgroundTransparency = 1
	icon.Image = AssetIds.Icons.DigSite
	icon.ScaleType = Enum.ScaleType.Fit
	return icon
end

local function build()
	local anchor = createAnchor()
	local size = DigZoneConfig.BadgeIconSize
	local gui = Instance.new("BillboardGui")
	gui.Name = DigZoneConfig.BadgeName
	gui.Adornee = anchor
	gui.Size = UDim2.fromOffset(size, size)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	createIcon().Parent = gui
	gui.Parent = anchor
end

function DigSiteBadgeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	build()
end

return DigSiteBadgeController
