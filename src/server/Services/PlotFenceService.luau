--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotUpgradeConfig = require(ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local PlotLevel = require(ReplicatedStorage.Shared.Utils.PlotLevel)

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local PlotService = require(script.Parent.PlotService)

local PlotFenceService = {}

local isInitialized = false
local originalColors: { [BasePart]: Color3 } = {}
local paintedLevels: { [Model]: number } = {}

local function findFence(plot: Model): Instance?
	local current: Instance? = Workspace
	for _, name in PlotConfig.FencePath do
		current = if current then current:FindFirstChild(name) else nil
	end
	return if current then current:FindFirstChild(plot.Name .. PlotConfig.FenceSuffix) else nil
end

local function paintPart(part: BasePart, color: Color3)
	if originalColors[part] == nil then
		originalColors[part] = part.Color
	end
	part.Color = color
	for _, child in part:GetChildren() do
		if child:IsA("Texture") then
			child.Color3 = color
		end
	end
end

local function getPartColor(part: BasePart, colors: PlotUpgradeConfig.FenceColors?): Color3?
	if colors == nil then
		return originalColors[part]
	end
	if table.find(PlotConfig.FencePostNames, part.Name) then
		return colors.Post
	end
	if table.find(PlotConfig.FenceRailNames, part.Name) then
		return colors.Rail
	end
	return nil
end

local function paintFence(plot: Model, colors: PlotUpgradeConfig.FenceColors?)
	local fence = findFence(plot)
	if fence == nil then
		warn("[PlotFenceService] Missing fence for", plot.Name)
		return
	end
	for _, child in fence:GetChildren() do
		if child:IsA("BasePart") then
			local color = getPartColor(child, colors)
			if color then
				paintPart(child, color)
			end
		end
	end
end

local function refresh(player: Player)
	local plot = PlotService.GetPlot(player)
	if plot == nil or player.Parent == nil then
		return
	end
	local data = DataService.GetData(player)
	local slots = if data then data.Capacity.Loadout else DataTemplate.Limits.DefaultLoadoutSlots
	local level = PlotLevel.FromSlots(slots or DataTemplate.Limits.DefaultLoadoutSlots)
	if paintedLevels[plot] == level then
		return
	end
	paintedLevels[plot] = level
	paintFence(plot, PlotUpgradeConfig.FenceColors[level])
end

local function reset(_player: Player, plot: Model)
	paintedLevels[plot] = nil
	paintFence(plot, nil)
end

function PlotFenceService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	PlotService.OnAssigned(refresh)
	PlotService.OnReleased(reset)
	DataService.OnProfileLoaded(refresh)
	DataActions.OnDataChanged(refresh)
	for _, player in Players:GetPlayers() do
		task.spawn(refresh, player)
	end
end

return PlotFenceService
