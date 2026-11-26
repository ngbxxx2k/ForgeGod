--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)

local PlotService = require(script.Parent.PlotService)

local ROOT_PART_NAME = "HumanoidRootPart"

local PlotSpawnService = {}

local isInitialized = false
local connectionByPlayer: { [Player]: RBXScriptConnection } = {}

local function moveToPlot(player: Player, character: Model)
	local root = character:WaitForChild(ROOT_PART_NAME, PlotConfig.SpawnRootWaitTime)
	if root == nil or character.Parent == nil or player.Character ~= character then
		return
	end
	local plot = PlotService.GetPlot(player)
	if plot == nil then
		return
	end
	character:PivotTo(plot:GetPivot() * PlotConfig.SpawnOffset)
end

local function onPlayerAdded(player: Player)
	connectionByPlayer[player] = player.CharacterAdded:Connect(function(character: Model)
		moveToPlot(player, character)
	end)
	local character = player.Character
	if character then
		task.spawn(moveToPlot, player, character)
	end
end

local function onPlayerRemoving(player: Player)
	local connection = connectionByPlayer[player]
	if connection then
		connection:Disconnect()
		connectionByPlayer[player] = nil
	end
end

function PlotSpawnService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlotSpawnService
