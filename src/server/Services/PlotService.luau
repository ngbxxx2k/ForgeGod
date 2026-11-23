--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

local PlotService = {}

local isInitialized = false
local plots: { Model } = {}
local ownerByPlot: { [Model]: Player } = {}
local plotByPlayer: { [Player]: Model } = {}
local assignedCallbacks: { (Player, Model) -> () } = {}
local releasedCallbacks: { (Player, Model) -> () } = {}

local function getPlotNumber(plot: Instance): number?
	local digits = string.match(plot.Name, "^" .. PlotConfig.PlotNamePrefix .. "(%d+)$")
	return if digits then tonumber(digits) else nil
end

local function collectPlots(): { Model }
	local folder = Workspace:FindFirstChild(PlotConfig.PlotsFolderName)
	if folder == nil then
		warn("[PlotService] Missing Workspace folder:", PlotConfig.PlotsFolderName)
		return {}
	end
	local found: { Model } = {}
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and getPlotNumber(child) ~= nil then
			table.insert(found, child)
		end
	end
	table.sort(found, function(a: Model, b: Model): boolean
		return (getPlotNumber(a) :: number) < (getPlotNumber(b) :: number)
	end)
	return found
end

local function fireCallbacks(callbacks: { (Player, Model) -> () }, player: Player, plot: Model)
	for _, callback in callbacks do
		task.spawn(callback, player, plot)
	end
end

local function findFreePlot(): Model?
	for _, plot in plots do
		if ownerByPlot[plot] == nil then
			return plot
		end
	end
	return nil
end

local function assign(player: Player)
	if plotByPlayer[player] ~= nil then
		return
	end
	local plot = findFreePlot()
	if plot == nil then
		warn("[PlotService] No free plot for", player.Name)
		return
	end
	ownerByPlot[plot] = player
	plotByPlayer[player] = plot
	plot:SetAttribute(PlotAttributes.OwnerUserId, player.UserId)
	fireCallbacks(assignedCallbacks, player, plot)
end

local function release(player: Player)
	local plot = plotByPlayer[player]
	if plot == nil then
		return
	end
	plotByPlayer[player] = nil
	ownerByPlot[plot] = nil
	plot:SetAttribute(PlotAttributes.OwnerUserId, nil)
	for _, callback in releasedCallbacks do
		local ok, err = pcall(callback, player, plot)
		if not ok then
			warn("[PlotService] Release callback failed:", err)
		end
	end
end

function PlotService.GetPlot(player: Player): Model?
	return plotByPlayer[player]
end

function PlotService.OnAssigned(callback: (Player, Model) -> ())
	table.insert(assignedCallbacks, callback)
end

function PlotService.OnReleased(callback: (Player, Model) -> ())
	table.insert(releasedCallbacks, callback)
end

function PlotService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	plots = collectPlots()
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(release)
	for _, player in Players:GetPlayers() do
		task.spawn(assign, player)
	end
end

return PlotService
