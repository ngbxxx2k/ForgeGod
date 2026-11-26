--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotAttributes = require(ReplicatedStorage.Shared.Constants.PlotAttributes)
local HoldConfig = require(ReplicatedStorage.Shared.Config.HoldConfig)
local PlotConfig = require(ReplicatedStorage.Shared.Config.PlotConfig)
local PlotUpgradeConfig = require(ReplicatedStorage.Shared.Config.PlotUpgradeConfig)
local WeaponModelFinder = require(ReplicatedStorage.Shared.Utils.WeaponModelFinder)
local WeaponSize = require(ReplicatedStorage.Shared.Utils.WeaponSize)

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local PedestalLabel = require(script.Parent.Parent.Internal.PedestalLabel)
local WeaponModelPrep = require(script.Parent.Parent.Internal.WeaponModelPrep)
local PlotService = require(script.Parent.PlotService)

type Display = {
	Key: string,
	Model: Model?,
}

type PartLook = {
	Transparency: number,
	CanCollide: boolean,
	CanQuery: boolean,
}

local PedestalDisplayService = {}

local isInitialized = false
local displaysByPlayer: { [Player]: { [number]: Display } } = {}
local originalLooks: { [BasePart]: PartLook } = {}

local function getPedestal(plot: Model, slot: number): Instance?
	local folder = plot:FindFirstChild(PlotConfig.PedestalsFolderName)
	return folder and folder:FindFirstChild(PlotConfig.PedestalNamePrefix .. slot)
end

local function getAnchor(pedestal: Instance): Attachment?
	local anchor = pedestal:FindFirstChild(PlotConfig.AnchorName, true)
	return if anchor and anchor:IsA("Attachment") then anchor else nil
end

local function setPartVisible(part: BasePart, isVisible: boolean)
	local look = originalLooks[part]
	if look == nil then
		look = {
			Transparency = part.Transparency,
			CanCollide = part.CanCollide,
			CanQuery = part.CanQuery,
		}
		originalLooks[part] = look
	end
	local original = look :: PartLook
	part.Transparency = if isVisible then original.Transparency else 1
	part.CanCollide = isVisible and original.CanCollide
	part.CanQuery = isVisible and original.CanQuery
end

local function setPedestalVisible(pedestal: Instance, isVisible: boolean)
	for _, descendant in pedestal:GetDescendants() do
		local isPedestalPart = descendant:IsA("BasePart")
			and descendant:FindFirstAncestor(PlotConfig.DisplayModelName) == nil
		if isPedestalPart then
			setPartVisible(descendant :: BasePart, isVisible)
		end
	end
end

local function updatePedestalVisibility(plot: Model, slots: number)
	for slot = 1, PlotUpgradeConfig.MaxSlots do
		local pedestal = getPedestal(plot, slot)
		if pedestal then
			setPedestalVisible(pedestal, slot <= slots)
		end
	end
end

local function getSlotWeapon(data: any, slot: number): any?
	local weaponId = data.Equipped[slot]
	return if weaponId then data.Weapons[weaponId] else nil
end

local function getDisplayKey(weapon: any?): string
	if weapon == nil then
		return ""
	end
	local shapeStage = weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
	return table.concat({
		tostring(weapon.Id),
		tostring(weapon.WeaponType),
		tostring(weapon.Rarity),
		tostring(weapon.State),
		tostring(shapeStage),
		tostring(weapon.Scale),
		tostring(weapon.Value),
		tostring(weapon.Mutation),
	}, "|")
end

local function getShaftOffset(model: Model, boxCFrame: CFrame): Vector3
	local gripPoint = model:FindFirstChild(HoldConfig.WeaponGripPointName, true)
	if not gripPoint or not gripPoint:IsA("Attachment") then
		return Vector3.zero
	end
	local shaft = boxCFrame:PointToObjectSpace(gripPoint.WorldPosition)
	return Vector3.new(shaft.X, 0, shaft.Z)
end

local function placeOnAnchor(model: Model, anchor: Attachment): number
	local boxCFrame, size = model:GetBoundingBox()
	local bottomToCenter = CFrame.new(Vector3.new(0, size.Y / 2, 0) - getShaftOffset(model, boxCFrame))
	model:PivotTo(anchor.WorldCFrame * bottomToCenter * boxCFrame:ToObjectSpace(model:GetPivot()))
	return size.Y
end

local function buildModel(weapon: any, anchor: Attachment, slot: number): Model?
	local shapeStage = weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
	local source = WeaponModelFinder.Find(weapon.WeaponType, shapeStage)
	if source == nil then
		return nil
	end
	local length = WeaponSize.GetLength(weapon.WeaponType, weapon.Scale)
	local model = WeaponModelPrep.Prepare(source, PlotConfig.DisplayModelName, length)
	local height = placeOnAnchor(model, anchor)
	PedestalLabel.Build(weapon, anchor, height).Parent = model
	model:SetAttribute(PlotAttributes.SlotIndex, slot)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

local function clearDisplay(display: Display?)
	if display and display.Model then
		display.Model:Destroy()
	end
end

local function refreshSlot(displays: { [number]: Display }, plot: Model, data: any, slot: number)
	local pedestal = getPedestal(plot, slot)
	local anchor = pedestal and getAnchor(pedestal)
	if pedestal == nil or anchor == nil then
		return
	end
	local weapon = getSlotWeapon(data, slot)
	local key = getDisplayKey(weapon)
	local current = displays[slot]
	if current and current.Key == key then
		return
	end
	clearDisplay(current)
	local model = if weapon then buildModel(weapon, anchor, slot) else nil
	if model then
		model.Parent = pedestal
	end
	displays[slot] = { Key = key, Model = model }
end

local function refresh(player: Player)
	local plot = PlotService.GetPlot(player)
	if plot == nil or player.Parent == nil then
		return
	end
	local data = DataService.GetData(player)
	if data == nil then
		updatePedestalVisibility(plot, DataTemplate.Limits.DefaultLoadoutSlots)
		return
	end
	local displays = displaysByPlayer[player]
	if displays == nil then
		displays = {}
		displaysByPlayer[player] = displays
	end
	local slots = data.Capacity and data.Capacity.Loadout or DataTemplate.Default.Capacity.Loadout
	updatePedestalVisibility(plot, slots)
	for slot = 1, slots do
		refreshSlot(displays :: { [number]: Display }, plot, data, slot)
	end
end

local function clear(player: Player)
	local displays = displaysByPlayer[player]
	displaysByPlayer[player] = nil
	if displays == nil then
		return
	end
	for _, display in displays do
		clearDisplay(display)
	end
end

function PedestalDisplayService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	PlotService.OnAssigned(refresh)
	PlotService.OnReleased(clear)
	DataService.OnProfileLoaded(refresh)
	DataActions.OnDataChanged(refresh)
	for _, player in Players:GetPlayers() do
		task.spawn(refresh, player)
	end
end

return PedestalDisplayService
