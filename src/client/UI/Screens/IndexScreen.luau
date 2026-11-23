--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudButton = require(script.Parent.Parent.Components.HudButton)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local RarityGradient = require(script.Parent.Parent.Components.RarityGradient)
local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)
local IndexMessages = require(ReplicatedStorage.Shared.Constants.IndexMessages)
local MutationColors = require(ReplicatedStorage.Shared.Constants.MutationColors)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)

local INDEX_GUI_NAME = "IndexGui"
local INDEX_BUTTON_NAME = "IndexButton"
local COLLECTION_TEMPLATE_NAME = "CollectionTemplate"
local CELL_TEMPLATE_NAME = "WeaponCellTemplate"
local TAB_TEMPLATE_NAME = "TabButtonTemplate"
local COLLECTION_NAME = "Collection"
local CELL_NAME = "WeaponCell"
local TAB_NAME = "TabButton"
local TAB_ID_ATTRIBUTE = "TabId"
local LOCKED_IMAGE_COLOR = Color3.fromRGB(10, 10, 40)
local UNLOCKED_IMAGE_COLOR = Color3.new(1, 1, 1)
local SELECTED_STROKE_COLOR = Color3.new(1, 1, 1)
local DEFAULT_STROKE_COLOR = Color3.fromRGB(15, 15, 25)
local GRID_NAME = "WeaponGrid"
local STRETCHED_PART_NAMES = { "WeaponGrid", "Showcase" }
local SHIFTED_PART_NAMES = { "ProgressBar", "RewardIcon" }
local HOVER_ATTRIBUTE = "HasHoverEffect"
local REWARD_ICON_NAME = "RewardIcon"
local FOCUS_LINE_RATIO = 0.35
local SCROLL_END_TOLERANCE = 1

export type IndexEntry = {
	Id: string,
	DisplayName: string,
	Rarity: string,
	IsUnlocked: boolean,
	Image: string?,
}

export type RewardInfo = {
	DisplayName: string,
	Image: string?,
	IsClaimable: boolean,
	IsClaimed: boolean,
}

export type IndexCollection = {
	Id: string,
	Rarity: string,
	ChancePercent: string,
	Image: string?,
	Entries: { IndexEntry },
	Reward: RewardInfo?,
}

export type IndexTab = {
	Id: string,
	DisplayName: string,
}

local IndexScreen = {}

local isInitialized = false
local container: Frame? = nil
local main: Frame? = nil
local collectionList: ScrollingFrame? = nil
local tabList: ScrollingFrame? = nil
local collectionTemplate: Frame? = nil
local tabTemplate: TextButton? = nil
local collectionData: { [Frame]: IndexCollection } = {}
local focusedFrame: Frame? = nil

local function findChild(parent: Instance, path: { string }): Instance?
	local current: Instance? = parent
	for _, name in path do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function setText(parent: Instance, path: { string }, text: string)
	local label = findChild(parent, path)
	if label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
		label.Text = text
	end
end

local function setImage(parent: Instance, path: { string }, image: string?, color: Color3?)
	local imageLabel = findChild(parent, path)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		return
	end
	imageLabel.Image = image or ""
	imageLabel.ImageColor3 = color or UNLOCKED_IMAGE_COLOR
end

local function setFill(bar: Instance?, current: number, total: number)
	local fill = bar and bar:FindFirstChild("Fill")
	if fill and fill:IsA("Frame") then
		local ratio = if total > 0 then math.clamp(current / total, 0, 1) else 0
		fill.Size = UDim2.fromScale(ratio, 1)
	end
end

local function setStrokeColor(target: Instance, color: Color3)
	for _, child in target:GetChildren() do
		if child:IsA("UIStroke") and child.ApplyStrokeMode == Enum.ApplyStrokeMode.Border then
			child.Color = color
		end
	end
end

local function clearChildren(parent: Instance, childName: string)
	for _, child in parent:GetChildren() do
		if child.Name == childName then
			child:Destroy()
		end
	end
end

local function getEntryName(entry: IndexEntry): string
	return if entry.IsUnlocked then entry.DisplayName else IndexMessages.UnknownName
end

local function getEntryColor(entry: IndexEntry): Color3
	return if entry.IsUnlocked then UNLOCKED_IMAGE_COLOR else LOCKED_IMAGE_COLOR
end

local function showPreview(entry: IndexEntry)
	local preview = main and main:FindFirstChild("Preview")
	if not preview then
		return
	end
	setText(preview, { "NameLabel" }, getEntryName(entry))
	setText(preview, { "RarityLabel" }, string.upper(entry.Rarity))
	setImage(preview, { "Slot", "WeaponImage" }, entry.Image, getEntryColor(entry))
	local slot = preview:FindFirstChild("Slot")
	if slot and slot:IsA("GuiObject") then
		RarityGradient.Apply(slot, entry.Rarity)
	end
end

local function createCell(template: GuiButton, entry: IndexEntry, order: number): GuiButton
	local cell = template:Clone()
	cell.Name = CELL_NAME
	cell.LayoutOrder = order
	cell.Visible = true
	RarityGradient.Apply(cell, entry.Rarity)
	setText(cell, { "NameLabel" }, getEntryName(entry))
	setText(cell, { "RarityLabel" }, string.upper(entry.Rarity))
	setImage(cell, { "WeaponImage" }, entry.Image, getEntryColor(entry))
	cell.Activated:Connect(function()
		showPreview(entry)
	end)
	return cell
end

local function countUnlocked(entries: { IndexEntry }): number
	local count = 0
	for _, entry in entries do
		if entry.IsUnlocked then
			count += 1
		end
	end
	return count
end

local function fillShowcase(frame: Instance, data: IndexCollection)
	local showcase = frame:FindFirstChild("Showcase")
	if not showcase or not showcase:IsA("GuiObject") then
		return
	end
	RarityGradient.Apply(showcase, data.Rarity)
	setText(showcase, { "RarityLabel" }, string.upper(data.Rarity))
	setText(showcase, { "ChanceLabel" }, string.format(IndexMessages.ChanceFormat, data.ChancePercent))
	setImage(showcase, { "WeaponImage" }, data.Image)
end

local function fillProgress(frame: Instance, entries: { IndexEntry })
	local unlocked = countUnlocked(entries)
	local progressText = string.format(IndexMessages.ProgressFormat, unlocked, #entries)
	setText(frame, { "ProgressBar", "ProgressText" }, progressText)
	setFill(frame:FindFirstChild("ProgressBar"), unlocked, #entries)
end

local function fillGrid(frame: Instance, entries: { IndexEntry })
	local grid = frame:FindFirstChild(GRID_NAME)
	local template = grid and grid:FindFirstChild(CELL_TEMPLATE_NAME)
	if not grid or not template or not template:IsA("GuiButton") then
		warn("[IndexScreen] Collection template missing WeaponGrid or cell template")
		return
	end
	template.Visible = false
	for index, entry in entries do
		createCell(template, entry, index).Parent = grid
	end
end

local function getUiScaleFactor(instance: Instance): number
	local factor = 1
	local current: Instance? = instance
	while current do
		local scale = current:FindFirstChildOfClass("UIScale")
		if scale and scale.Scale > 0 then
			factor *= scale.Scale
		end
		current = current.Parent
	end
	return factor
end

local function getUnscaledContentHeight(grid: GuiObject, layout: UIGridLayout): number
	return layout.AbsoluteContentSize.Y / getUiScaleFactor(grid)
end

local function getGridNeededHeight(grid: GuiObject, layout: UIGridLayout): number
	local padding = grid:FindFirstChildOfClass("UIPadding")
	local paddingHeight = if padding then padding.PaddingTop.Offset + padding.PaddingBottom.Offset else 0
	return getUnscaledContentHeight(grid, layout) + paddingHeight
end

local function resizeParts(frame: Frame, baseHeight: number, extra: number, height: number)
	local template = collectionTemplate
	if not template then
		return
	end
	for _, name in STRETCHED_PART_NAMES do
		local part = frame:FindFirstChild(name)
		local original = template:FindFirstChild(name)
		if part and original and part:IsA("GuiObject") and original:IsA("GuiObject") then
			local scaleY = (original.Size.Y.Scale * baseHeight + extra) / height
			part.Size = UDim2.new(original.Size.X, UDim.new(scaleY, 0))
		end
	end
	for _, name in SHIFTED_PART_NAMES do
		local part = frame:FindFirstChild(name)
		local original = template:FindFirstChild(name)
		if part and original and part:IsA("GuiObject") and original:IsA("GuiObject") then
			local positionY = (original.Position.Y.Scale * baseHeight + extra) / height
			part.Position = UDim2.new(original.Position.X, UDim.new(positionY, 0))
			part.Size = UDim2.new(original.Size.X, UDim.new(original.Size.Y.Scale * baseHeight / height, 0))
		end
	end
end

local function getAvailableWidth(): number
	local list = collectionList
	if not list then
		return 0
	end
	local canvasWidth = list.AbsoluteCanvasSize.X / getUiScaleFactor(list)
	local padding = list:FindFirstChildOfClass("UIPadding")
	if not padding then
		return canvasWidth
	end
	local left, right = padding.PaddingLeft, padding.PaddingRight
	return canvasWidth * (1 - left.Scale - right.Scale) - left.Offset - right.Offset
end

local function fitCollectionHeight(frame: Frame, grid: GuiObject, layout: UIGridLayout)
	local template = collectionTemplate
	local templateGrid = template and template:FindFirstChild(GRID_NAME)
	local templateAspect = template and template:FindFirstChildOfClass("UIAspectRatioConstraint")
	local aspect = frame:FindFirstChildOfClass("UIAspectRatioConstraint")
	local width = getAvailableWidth()
	if not templateGrid or not templateGrid:IsA("GuiObject") or not templateAspect or not aspect or width <= 0 then
		return
	end
	local baseHeight = width / templateAspect.AspectRatio
	local extra = math.max(0, getGridNeededHeight(grid, layout) - templateGrid.Size.Y.Scale * baseHeight)
	local height = baseHeight + extra
	aspect.AspectRatio = width / height
	frame.Size = UDim2.new(1, 0, 0, math.ceil(height))
	resizeParts(frame, baseHeight, extra, height)
end

local function bindCollectionHeight(frame: Frame)
	local grid = frame:FindFirstChild(GRID_NAME)
	local layout = grid and grid:FindFirstChildOfClass("UIGridLayout")
	if not grid or not grid:IsA("ScrollingFrame") or not layout then
		return
	end
	grid.ScrollingEnabled = false
	grid.ScrollBarThickness = 0
	local lastWidth, lastContentHeight = -1, -1
	local function refit()
		local width, contentHeight = getAvailableWidth(), getUnscaledContentHeight(grid, layout)
		if width == lastWidth and contentHeight == lastContentHeight then
			return
		end
		lastWidth, lastContentHeight = width, contentHeight
		fitCollectionHeight(frame, grid, layout)
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refit)
	local list = collectionList
	if list then
		local canvasConnection = list:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(refit)
		frame.Destroying:Connect(function()
			canvasConnection:Disconnect()
		end)
	end
	refit()
end

local function createCollection(template: Frame, data: IndexCollection, order: number): Frame
	local frame = template:Clone()
	frame.Name = COLLECTION_NAME
	frame.LayoutOrder = order
	frame.Visible = true
	fillShowcase(frame, data)
	fillGrid(frame, data.Entries)
	fillProgress(frame, data.Entries)
	setImage(frame, { REWARD_ICON_NAME }, data.Reward and data.Reward.Image)
	bindCollectionHeight(frame)
	return frame
end

local function applyReward(reward: RewardInfo?)
	local rewardFrame = main and main:FindFirstChild("Reward")
	if not rewardFrame or not rewardFrame:IsA("GuiObject") then
		return
	end
	rewardFrame.Visible = reward ~= nil
	if not reward then
		return
	end
	setText(rewardFrame, { "OreName" }, string.upper(reward.DisplayName))
	setImage(rewardFrame, { "OreIcon" }, reward.Image)
	local buttonText = if reward.IsClaimed
		then IndexMessages.Claimed
		elseif reward.IsClaimable then IndexMessages.Claim
		else IndexMessages.Locked
	setText(rewardFrame, { "ClaimButton" }, buttonText)
end

local function getPreviewEntry(entries: { IndexEntry }): IndexEntry?
	for _, entry in entries do
		if entry.IsUnlocked then
			return entry
		end
	end
	return entries[1]
end

local function focusCollection(frame: Frame)
	local data = collectionData[frame]
	if frame == focusedFrame or not data then
		return
	end
	focusedFrame = frame
	applyReward(data.Reward)
	local entry = getPreviewEntry(data.Entries)
	if entry then
		showPreview(entry)
	end
end

local function isScrolledToEnd(list: ScrollingFrame): boolean
	local maxScroll = list.AbsoluteCanvasSize.Y - list.AbsoluteWindowSize.Y
	return maxScroll > 0 and list.CanvasPosition.Y >= maxScroll - SCROLL_END_TOLERANCE
end

local function isBetterFocus(top: number, best: Frame?, isAtEnd: boolean): boolean
	if not best then
		return true
	end
	local bestTop = best.AbsolutePosition.Y
	return if isAtEnd then top > bestTop else top < bestTop
end

local function findFocusedCollection(list: ScrollingFrame): Frame?
	local isAtEnd = isScrolledToEnd(list)
	local focusLine = list.AbsolutePosition.Y + list.AbsoluteSize.Y * FOCUS_LINE_RATIO
	local best: Frame? = nil
	for frame in collectionData do
		local top = frame.AbsolutePosition.Y
		local isCandidate = isAtEnd or top + frame.AbsoluteSize.Y >= focusLine
		if isCandidate and isBetterFocus(top, best, isAtEnd) then
			best = frame
		end
	end
	return best
end

local function refreshFocus()
	local list = collectionList
	local frame = list and findFocusedCollection(list)
	if frame then
		focusCollection(frame)
	end
end

local function applyTabColor(button: GuiObject, tabId: string)
	local mutationColor = MutationColors.Get(tabId)
	local gradient = button:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	gradient.Color = mutationColor.Gradient
	gradient.Rotation = mutationColor.Rotation
	button.BackgroundColor3 = Color3.new(1, 1, 1)
	gradient.Parent = button
end

local function highlightTab(selectedId: string)
	local list = tabList
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child.Name == TAB_NAME then
			local isSelected = child:GetAttribute(TAB_ID_ATTRIBUTE) == selectedId
			setStrokeColor(child, if isSelected then SELECTED_STROKE_COLOR else DEFAULT_STROKE_COLOR)
		end
	end
end

local function createTab(template: TextButton, tab: IndexTab, order: number, onSelected: (string) -> ())
	local button = template:Clone()
	button.Name = TAB_NAME
	button.LayoutOrder = order
	button.Visible = true
	button.Text = string.upper(tab.DisplayName)
	button:SetAttribute(TAB_ID_ATTRIBUTE, tab.Id)
	applyTabColor(button, tab.Id)
	button.Activated:Connect(function()
		highlightTab(tab.Id)
		onSelected(tab.Id)
	end)
	return button
end

local function bindCanvasToLayout(list: ScrollingFrame)
	if not ScrollCanvas.BindToLayout(list) then
		warn("[IndexScreen] CollectionList missing UIListLayout")
	end
end

local function setIndexVisible(isVisible: boolean)
	if container then
		container.Visible = isVisible
	end
end

local function bindCloseButton(mainFrame: Instance)
	local closeButton = mainFrame:WaitForChild("Header"):WaitForChild("CloseButton")
	if closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			if container then
				OpenAnimation.Close(container)
			end
		end)
	end
end

local function enableHoverEffects(mainFrame: Instance, collection: Instance, tab: Instance)
	local targets = {
		tab,
		collection:FindFirstChild(CELL_TEMPLATE_NAME, true),
		mainFrame:FindFirstChild("CloseButton", true),
		mainFrame:FindFirstChild("ClaimButton", true),
	}
	for _, target in targets do
		if target and target:IsA("GuiButton") then
			target:SetAttribute(HOVER_ATTRIBUTE, true)
		end
	end
end

function IndexScreen.RenderCollections(collections: { IndexCollection })
	local list = collectionList
	local template = collectionTemplate
	if not list or not template then
		warn("[IndexScreen] RenderCollections called before Init")
		return
	end
	clearChildren(list, COLLECTION_NAME)
	table.clear(collectionData)
	focusedFrame = nil
	local firstFrame: Frame? = nil
	for index, data in collections do
		local frame = createCollection(template, data, index)
		collectionData[frame] = data
		frame.Parent = list
		firstFrame = firstFrame or frame
	end
	list.CanvasPosition = Vector2.zero
	if firstFrame then
		focusCollection(firstFrame)
	else
		applyReward(nil)
	end
end

function IndexScreen.RenderTabs(tabs: { IndexTab }, selectedId: string?, onSelected: (string) -> ())
	local list = tabList
	local template = tabTemplate
	if not list or not template then
		warn("[IndexScreen] RenderTabs called before Init")
		return
	end
	clearChildren(list, TAB_NAME)
	for index, tab in tabs do
		createTab(template, tab, index, onSelected).Parent = list
	end
	if selectedId then
		highlightTab(selectedId)
	end
end

function IndexScreen.SetTotalProgress(unlocked: number, total: number)
	local bar = main and main:FindFirstChild("UnlockedBar")
	if not bar then
		return
	end
	setText(bar, { "UnlockedText" }, string.format(IndexMessages.UnlockedFormat, unlocked, total))
	setFill(bar, unlocked, total)
end

function IndexScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = playerGui:WaitForChild(INDEX_GUI_NAME):WaitForChild("Container")
	local mainFrame = root:WaitForChild("Main")
	local collections = mainFrame:WaitForChild("CollectionList")
	local tabs = root:WaitForChild("TabPanel"):WaitForChild("TabList")
	local collection = collections:WaitForChild(COLLECTION_TEMPLATE_NAME)
	local tab = tabs:WaitForChild(TAB_TEMPLATE_NAME)
	if not root:IsA("Frame") or not mainFrame:IsA("Frame") or not collections:IsA("ScrollingFrame") then
		warn("[IndexScreen] IndexGui has wrong structure")
		return
	end
	if not tabs:IsA("ScrollingFrame") or not collection:IsA("Frame") or not tab:IsA("TextButton") then
		warn("[IndexScreen] IndexGui templates have wrong structure")
		return
	end
	collection.Visible = false
	tab.Visible = false
	root.Visible = false
	container, main, collectionList, tabList = root, mainFrame, collections, tabs
	collectionTemplate, tabTemplate = collection, tab

	enableHoverEffects(mainFrame, collection, tab)
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	HudSlide.TrackScreen(root)
	ScreenRegistry.Register(root)
	bindCanvasToLayout(collections)
	collections:GetPropertyChangedSignal("CanvasPosition"):Connect(refreshFocus)
	bindCloseButton(mainFrame)
	HudButton.Bind(INDEX_BUTTON_NAME, function()
		setIndexVisible(not root.Visible)
	end)
end

return IndexScreen
