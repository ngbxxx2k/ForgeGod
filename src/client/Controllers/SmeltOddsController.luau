--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local SmeltOddsScreen = require(script.Parent.Parent.UI.Screens.SmeltOddsScreen)

type SmeltOdd = SmeltOddsScreen.SmeltOdd

local REMOTES_FOLDER_NAME = "Remotes"
local RECIPE_PART_FORMAT = "%s=%d"
local RECIPE_SEPARATOR = ","

local SmeltOddsController = {}

local isInitialized = false
local requestOdds: RemoteEvent? = nil
local latestRequestId = 0
local lastRecipeKey: string? = nil
local lastRecipe: { [string]: number }? = nil

local function getRecipeKey(recipe: { [string]: number }): string
	local parts = {}
	for oreId, amount in recipe do
		table.insert(parts, string.format(RECIPE_PART_FORMAT, oreId, amount))
	end
	table.sort(parts)
	return table.concat(parts, RECIPE_SEPARATOR)
end

local function parseOdds(odds: any): { SmeltOdd }?
	if type(odds) ~= "table" then
		return nil
	end
	local parsed: { SmeltOdd } = {}
	for _, odd in odds do
		if type(odd) ~= "table" or type(odd.Rarity) ~= "string" or type(odd.Percent) ~= "number" then
			return nil
		end
		table.insert(parsed, { Rarity = odd.Rarity, Percent = odd.Percent })
	end
	return parsed
end

local function onOdds(requestId: any, ok: any, _reason: any, odds: any)
	if requestId ~= latestRequestId or lastRecipeKey == nil then
		return
	end
	local parsed = if ok == true then parseOdds(odds) else nil
	if parsed then
		SmeltOddsScreen.Render(parsed)
		return
	end
	lastRecipeKey = nil
	SmeltOddsScreen.ShowHint()
end

function SmeltOddsController.Update(recipe: { [string]: number }, isComplete: boolean)
	if not isComplete then
		lastRecipeKey = nil
		lastRecipe = nil
		latestRequestId += 1
		SmeltOddsScreen.ShowHint()
		return
	end
	local key = getRecipeKey(recipe)
	local remote = requestOdds
	if key == lastRecipeKey or not remote then
		return
	end
	lastRecipeKey = key
	lastRecipe = recipe
	latestRequestId += 1
	remote:FireServer(latestRequestId, recipe)
end

function SmeltOddsController.Refresh()
	local recipe = lastRecipe
	if recipe == nil then
		return
	end
	lastRecipeKey = nil
	SmeltOddsController.Update(recipe, true)
end

local function connectRemotes()
	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestOdds = remotes:WaitForChild(RemoteNames.RequestSmeltOdds) :: RemoteEvent
	local oddsRemote = remotes:WaitForChild(RemoteNames.NotifySmeltOdds) :: RemoteEvent
	oddsRemote.OnClientEvent:Connect(onOdds)
	local useResultRemote = remotes:WaitForChild(RemoteNames.NotifyUseItemResult) :: RemoteEvent
	useResultRemote.OnClientEvent:Connect(function(ok: any)
		if ok == true then
			SmeltOddsController.Refresh()
		end
	end)
end

function SmeltOddsController.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	task.spawn(connectRemotes)
end

return SmeltOddsController
