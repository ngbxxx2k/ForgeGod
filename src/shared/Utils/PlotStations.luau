--!strict

local Workspace = game:GetService("Workspace")

local PlotConfig = require(script.Parent.Parent.Config.PlotConfig)
local PlotAttributes = require(script.Parent.Parent.Constants.PlotAttributes)

local PlotStations = {}

function PlotStations.FindOwnedPlot(userId: number): Model?
	local folder = Workspace:FindFirstChild(PlotConfig.PlotsFolderName)
	if folder == nil then
		return nil
	end
	for _, plot in folder:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute(PlotAttributes.OwnerUserId) == userId then
			return plot
		end
	end
	return nil
end

function PlotStations.FindStation(plot: Model, modelName: string): Model?
	local folder = plot:FindFirstChild(PlotConfig.StationsFolderName)
	local station = folder and folder:FindFirstChild(modelName)
	if station and station:IsA("Model") then
		return station
	end
	return nil
end

function PlotStations.FindOwnedStation(userId: number, modelName: string): Model?
	local plot = PlotStations.FindOwnedPlot(userId)
	return if plot then PlotStations.FindStation(plot, modelName) else nil
end

return PlotStations
