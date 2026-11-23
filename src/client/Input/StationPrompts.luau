--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local StationMessages = require(ReplicatedStorage.Shared.Constants.StationMessages)
local FurnaceController = require(script.Parent.Parent.Controllers.FurnaceController)
local WeaponPickerController = require(script.Parent.Parent.Controllers.WeaponPickerController)

local PROMPT_NAME = "StationPrompt"
local OWNED_PLOT_POLL_INTERVAL = 0.5

type Station = {
	ModelName: string,
	ObjectText: string,
	ActionText: string,
	Open: () -> (),
	Close: () -> (),
	ClosesOnHide: boolean,
}

local STATIONS: { Station } = {
	{
		ModelName = StationConfig.FurnaceModelName,
		ObjectText = StationMessages.FurnaceObjectText,
		ActionText = StationMessages.FurnaceActionText,
		Open = FurnaceController.Open,
		Close = FurnaceController.Close,
		ClosesOnHide = false,
	},
	{
		ModelName = StationConfig.ForgeModelName,
		ObjectText = StationMessages.ForgeObjectText,
		ActionText = StationMessages.ForgeActionText,
		Open = WeaponPickerController.Open,
		Close = WeaponPickerController.ClosePicker,
		ClosesOnHide = true,
	},
}

local StationPrompts = {}

local isInitialized = false

local function waitForBasePart(model: Instance): BasePart
	local part = model:FindFirstChildWhichIsA("BasePart", true)
	while part == nil do
		model.DescendantAdded:Wait()
		part = model:FindFirstChildWhichIsA("BasePart", true)
	end
	return part :: BasePart
end

local function createPrompt(station: Station): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ObjectText = station.ObjectText
	prompt.ActionText = station.ActionText
	prompt.KeyboardKeyCode = StationConfig.PromptKeyCode
	prompt.MaxActivationDistance = StationConfig.MaxActivationDistance
	prompt.HoldDuration = StationConfig.HoldDuration
	prompt.RequiresLineOfSight = false
	return prompt
end

local function waitForOwnedPlot(): Model
	local userId = Players.LocalPlayer.UserId
	local plot = PlotStations.FindOwnedPlot(userId)
	while plot == nil do
		task.wait(OWNED_PLOT_POLL_INTERVAL)
		plot = PlotStations.FindOwnedPlot(userId)
	end
	return plot
end

local function setupStation(stationsFolder: Instance, station: Station)
	local model = stationsFolder:WaitForChild(station.ModelName)
	local part = waitForBasePart(model)
	local prompt = createPrompt(station)
	prompt.Triggered:Connect(function()
		station.Open()
	end)
	prompt.PromptHidden:Connect(function()
		if station.ClosesOnHide then
			station.Close()
		end
	end)
	prompt.Parent = part
end

function StationPrompts.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	task.spawn(function()
		local plot = waitForOwnedPlot()
		local stationsFolder = plot:WaitForChild(PlotConfig.StationsFolderName)
		for _, station in STATIONS do
			task.spawn(setupStation, stationsFolder, station)
		end
	end)
end

return StationPrompts
