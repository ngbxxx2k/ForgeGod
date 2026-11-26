--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DigZoneConfig = require(ReplicatedStorage.Shared.Config.DigZoneConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local DigZone = require(ReplicatedStorage.Shared.Utils.DigZone)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local GuiPath = require(script.Parent.Parent.UI.Components.GuiPath)
local ForgeUpgradeZoneController = require(script.Parent.ForgeUpgradeZoneController)

local ROOT_PART_NAME = "HumanoidRootPart"

local TutorialTargets = {}

TutorialTargets.Paths = {
	FurnaceMain = { "FurnaceGui", "Main" },
	FurnaceBagList = { "FurnaceGui", "Main", "RightPanel", "BagPanel", "Body", "BagList" },
	FurnaceStart = { "FurnaceGui", "Main", "StartButton" },
	FurnaceClose = { "FurnaceGui", "Main", "RightPanel", "SelectedPanel", "Header", "CloseButton" },
	PickerMain = { "WeaponPickerGui", "Main" },
	PickerAction = { "WeaponPickerGui", "Main", "DetailPanel", "ActionButton" },
	LoadoutButton = { "HudGui", "InventoryButtonHolder", "LoadoutButton" },
	LoadoutClose = { "LoadoutGui", "Container", "Main", "Header", "CloseButton" },
	UpgradeTabBar = { "ForgeUpgradeGui", "Main", "TabBar" },
}

TutorialTargets.BagItemName = "BagItem"

local localPlayer = Players.LocalPlayer

function TutorialTargets.GetRoot(): BasePart?
	local character = localPlayer.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	return if root and root:IsA("BasePart") then root else nil
end

function TutorialTargets.IsInDigZone(): boolean
	local root = TutorialTargets.GetRoot()
	return root ~= nil and DigZone.IsInside(root.Position)
end

function TutorialTargets.DigSite(): Vector3
	return DigZoneConfig.Center
end

local function stationPosition(modelName: string): Vector3?
	local station = PlotStations.FindOwnedStation(localPlayer.UserId, modelName)
	return if station then station:GetPivot().Position else nil
end

function TutorialTargets.Crucible(): Vector3?
	return stationPosition(StationConfig.FurnaceModelName)
end

function TutorialTargets.Anvil(): Vector3?
	return stationPosition(StationConfig.ForgeModelName)
end

function TutorialTargets.UpgradeShop(): Vector3?
	local center = ForgeUpgradeZoneController.GetZoneCenter()
	return if center then center.Position else nil
end

function TutorialTargets.Gui(path: { string }): GuiObject?
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	local found = playerGui and GuiPath.Find(playerGui, path)
	return if found and found:IsA("GuiObject") then found else nil
end

function TutorialTargets.IsGuiVisible(path: { string }): boolean
	local found = TutorialTargets.Gui(path)
	return found ~= nil and found.Visible
end

function TutorialTargets.FirstVisibleChild(path: { string }, childName: string): GuiObject?
	local parent = TutorialTargets.Gui(path)
	if parent == nil then
		return nil
	end
	local best: GuiObject? = nil
	for _, child in parent:GetChildren() do
		if child.Name == childName and child:IsA("GuiObject") and child.Visible then
			if best == nil or child.LayoutOrder < best.LayoutOrder then
				best = child
			end
		end
	end
	return best
end

return TutorialTargets
