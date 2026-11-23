--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)

local PlotService = require(script.Parent.PlotService)

local TEMPLATES_FOLDER_NAME = "Templates"
local STASH_FOLDER_NAME = "PlotContents"

type Templates = {
	Crucible: Model,
	Anvil: Model,
}

type PlotState = {
	Pivot: CFrame,
	Floor: BasePart?,
	Stash: Folder,
}

local PlotContentService = {}

local isInitialized = false
local templates: Templates? = nil
local stateByPlot: { [Model]: PlotState } = {}

local function getTemplate(name: string): Model?
	local folder = ServerStorage:FindFirstChild(TEMPLATES_FOLDER_NAME)
	local template = folder and folder:FindFirstChild(name)
	if template and template:IsA("Model") then
		return template
	end
	warn("[PlotContentService] Missing template:", name)
	return nil
end

local function loadTemplates(): Templates?
	local crucible = getTemplate(StationConfig.FurnaceModelName)
	local anvil = getTemplate(StationConfig.ForgeModelName)
	if crucible == nil or anvil == nil then
		return nil
	end
	return { Crucible = crucible, Anvil = anvil }
end

local function placeClone(template: Model, target: CFrame, parent: Instance)
	local clone = template:Clone()
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	clone.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	clone:PivotTo(target)
	clone.Parent = parent
end

local function buildStations(plot: Model, origin: CFrame)
	local loaded = templates
	if loaded == nil then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = PlotConfig.StationsFolderName
	placeClone(loaded.Crucible, origin * PlotConfig.CrucibleOffset, folder)
	placeClone(loaded.Anvil, origin * PlotConfig.AnvilOffset, folder)
	folder.Parent = plot
end

local function destroyStations(plot: Model)
	local existing = plot:FindFirstChild(PlotConfig.StationsFolderName)
	if existing then
		existing:Destroy()
	end
end

local function hide(plot: Model)
	local state = stateByPlot[plot]
	if state == nil then
		return
	end
	destroyStations(plot)
	for _, child in plot:GetChildren() do
		child.Parent = state.Stash
	end
	plot.WorldPivot = state.Pivot
end

local function show(plot: Model)
	local state = stateByPlot[plot]
	if state == nil then
		return
	end
	for _, child in state.Stash:GetChildren() do
		child.Parent = plot
	end
	plot.PrimaryPart = state.Floor
	destroyStations(plot)
	buildStations(plot, state.Pivot)
end

local function register(plot: Model, stashRoot: Folder)
	local stash = Instance.new("Folder")
	stash.Name = plot.Name
	stash.Parent = stashRoot
	stateByPlot[plot] = {
		Pivot = plot:GetPivot(),
		Floor = plot.PrimaryPart,
		Stash = stash,
	}
	if plot:GetAttribute(PlotAttributes.OwnerUserId) == nil then
		hide(plot)
	else
		show(plot)
	end
end

function PlotContentService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	templates = loadTemplates()
	local plotsFolder = Workspace:FindFirstChild(PlotConfig.PlotsFolderName)
	if plotsFolder == nil then
		warn("[PlotContentService] Missing Workspace folder:", PlotConfig.PlotsFolderName)
		return
	end
	local stashRoot = Instance.new("Folder")
	stashRoot.Name = STASH_FOLDER_NAME
	stashRoot.Parent = ServerStorage
	for _, plot in plotsFolder:GetChildren() do
		if plot:IsA("Model") then
			register(plot, stashRoot)
		end
	end
	PlotService.OnAssigned(function(_player: Player, plot: Model)
		show(plot)
	end)
	PlotService.OnReleased(function(_player: Player, plot: Model)
		hide(plot)
	end)
end

return PlotContentService
