--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GiftMessages = require(ReplicatedStorage.Shared.Constants.GiftMessages)
local UiIcons = require(ReplicatedStorage.Shared.Constants.UiIcons)
local GuiPath = require(script.Parent.Parent.Components.GuiPath)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local GIFT_GUI_NAME = "GiftGui"
local LIST_PATH = { "Main", "PlayerList" }
local CLOSE_BUTTON_PATH = { "Main", "Header", "CloseButton" }
local HEADER_ICON_PATH = { "Main", "Header", "Icon" }
local HEADER_EMOJI_PATH = { "Main", "Header", "IconFallback" }
local EMPTY_LABEL_PATH = { "Main", "EmptyLabel" }
local TEMPLATE_NAME = "PlayerRowTemplate"
local ROW_NAME = "PlayerRow"
local HOVER_ATTRIBUTE = "HasHoverEffect"
local THUMBNAIL_TYPE = Enum.ThumbnailType.HeadShot
local THUMBNAIL_SIZE = Enum.ThumbnailSize.Size150x150

export type SelectHandler = (userId: number) -> ()

local GiftScreen = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer
local container: GuiObject? = nil
local playerList: Instance? = nil
local rowTemplate: GuiObject? = nil
local selectHandler: SelectHandler? = nil
local thumbnails: { [number]: string } = {}

local function close()
	local root = container
	selectHandler = nil
	if root then
		OpenAnimation.Close(root)
	end
end

local function loadThumbnail(userId: number, avatar: Instance)
	local cached = thumbnails[userId]
	if cached then
		if avatar:IsA("ImageLabel") then
			avatar.Image = cached
		end
		return
	end
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(userId, THUMBNAIL_TYPE, THUMBNAIL_SIZE)
		end)
		if not ok then
			warn("[GiftScreen] Thumbnail failed:", userId, image)
			return
		end
		thumbnails[userId] = image
		if avatar.Parent ~= nil and avatar:IsA("ImageLabel") then
			avatar.Image = image
		end
	end)
end

local function onSelect(userId: number)
	local handler = selectHandler
	close()
	if handler then
		handler(userId)
	end
end

local function createRow(template: GuiObject, player: Player, order: number): GuiObject
	local row = template:Clone()
	row.Name = ROW_NAME
	row.Visible = true
	row.LayoutOrder = order
	GuiPath.SetText(row, { "DisplayName" }, player.DisplayName)
	GuiPath.SetText(row, { "Username" }, string.format(GiftMessages.UsernameFormat, player.Name))
	GuiPath.SetText(row, { "SelectButton", "Label" }, GiftMessages.SelectButton)
	local avatar = row:FindFirstChild("Avatar")
	if avatar then
		loadThumbnail(player.UserId, avatar)
	end
	local button = row:FindFirstChild("SelectButton")
	if button and button:IsA("GuiButton") then
		button:SetAttribute(HOVER_ATTRIBUTE, true)
		local userId = player.UserId
		button.Activated:Connect(function()
			onSelect(userId)
		end)
	end
	return row
end

local function getOtherPlayers(): { Player }
	local others = {}
	for _, player in Players:GetPlayers() do
		if player ~= localPlayer then
			table.insert(others, player)
		end
	end
	table.sort(others, function(a: Player, b: Player): boolean
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	return others
end

local function refresh()
	local list = playerList
	local template = rowTemplate
	local root = container
	if list == nil or template == nil or root == nil then
		return
	end
	GuiPath.ClearChildren(list, ROW_NAME)
	local others = getOtherPlayers()
	for index, player in others do
		createRow(template, player, index).Parent = list
	end
	GuiPath.SetVisible(root, EMPTY_LABEL_PATH, #others == 0)
end

local function refreshIfOpen()
	local root = container
	if root and root.Visible then
		task.defer(refresh)
	end
end

function GiftScreen.Open(handler: SelectHandler)
	local root = container
	if root == nil then
		warn("[GiftScreen] Open called before Init")
		return
	end
	selectHandler = handler
	refresh()
	OpenAnimation.Open(root)
end

function GiftScreen.Close()
	close()
end

local function applyStaticContent(root: Instance)
	GuiPath.SetText(root, { "Main", "Header", "Title" }, GiftMessages.Title)
	GuiPath.SetText(root, EMPTY_LABEL_PATH, GiftMessages.EmptyList)
	local hasIcon = UiIcons.Gift ~= ""
	GuiPath.SetImage(root, HEADER_ICON_PATH, UiIcons.Gift)
	GuiPath.SetVisible(root, HEADER_ICON_PATH, hasIcon)
	GuiPath.SetVisible(root, HEADER_EMOJI_PATH, not hasIcon)
end

function GiftScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild(GIFT_GUI_NAME)
	local root = gui:WaitForChild("Container")
	local list = GuiPath.Find(root, LIST_PATH)
	local template = list and list:FindFirstChild(TEMPLATE_NAME)
	if not root:IsA("GuiObject") or list == nil or not template or not template:IsA("GuiObject") then
		warn("[GiftScreen] GiftGui has wrong structure")
		return
	end
	template.Visible = false
	root.Visible = false
	if gui:IsA("ScreenGui") then
		gui.Enabled = true
	end
	container, playerList, rowTemplate = root, list, template
	if list:IsA("ScrollingFrame") and not ScrollCanvas.BindToLayout(list) then
		warn("[GiftScreen] PlayerList has no layout")
	end
	UiSound.WatchOpen(root)
	OpenAnimation.Watch(root)
	ScreenRegistry.Register(root, close)
	applyStaticContent(root)
	local closeButton = GuiPath.Find(root, CLOSE_BUTTON_PATH)
	if closeButton and closeButton:IsA("GuiButton") then
		closeButton:SetAttribute(HOVER_ATTRIBUTE, true)
		closeButton.Activated:Connect(close)
	end
	Players.PlayerAdded:Connect(refreshIfOpen)
	Players.PlayerRemoving:Connect(refreshIfOpen)
end

return GiftScreen
