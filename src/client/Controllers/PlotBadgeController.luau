--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotBadge = require(script.Parent.Parent.UI.Components.PlotBadge)

local PlotBadgeController = {}

local isInitialized = false
local badgeByPlot: { [Model]: BillboardGui } = {}
local watchedPlots: { [Model]: boolean } = {}

local function clearBadge(plot: Model)
	local badge = badgeByPlot[plot]
	if badge then
		badge:Destroy()
		badgeByPlot[plot] = nil
	end
end

local function getDisplayName(userId: number): string?
	local owner = Players:GetPlayerByUserId(userId)
	return if owner then owner.DisplayName else nil
end

local function getAnchor(floor: BasePart): Attachment
	local existing = floor:FindFirstChild(PlotConfig.BadgeAnchorName)
	local anchor: Attachment
	if existing and existing:IsA("Attachment") then
		anchor = existing
	else
		anchor = Instance.new("Attachment")
		anchor.Name = PlotConfig.BadgeAnchorName
		anchor.Parent = floor
	end
	anchor.WorldPosition = floor.Position + Vector3.yAxis * PlotConfig.BadgeHeight
	return anchor
end

local function refresh(plot: Model)
	clearBadge(plot)
	local userId = plot:GetAttribute(PlotAttributes.OwnerUserId)
	local floor = plot.PrimaryPart
	if type(userId) ~= "number" or floor == nil then
		return
	end
	local displayName = getDisplayName(userId)
	if displayName == nil then
		return
	end
	local isHome = userId == Players.LocalPlayer.UserId
	local anchor = getAnchor(floor)
	local badge = PlotBadge.Build(anchor, userId, displayName, isHome)
	badge.Parent = anchor
	badgeByPlot[plot] = badge
end

local function watchPlot(child: Instance)
	if not child:IsA("Model") or watchedPlots[child] then
		return
	end
	local plot = child
	watchedPlots[plot] = true
	plot:GetAttributeChangedSignal(PlotAttributes.OwnerUserId):Connect(function()
		refresh(plot)
	end)
	plot:GetPropertyChangedSignal("PrimaryPart"):Connect(function()
		refresh(plot)
	end)
	plot.Destroying:Connect(function()
		clearBadge(plot)
		watchedPlots[plot] = nil
	end)
	refresh(plot)
end

local function refreshAll()
	for plot in watchedPlots do
		refresh(plot)
	end
end

function PlotBadgeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(function()
		local folder = Workspace:WaitForChild(PlotConfig.PlotsFolderName)
		folder.ChildAdded:Connect(watchPlot)
		for _, child in folder:GetChildren() do
			watchPlot(child)
		end
	end)
	Players.PlayerAdded:Connect(refreshAll)
end

return PlotBadgeController
