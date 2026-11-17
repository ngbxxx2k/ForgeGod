--!strict

local Players = game:GetService("Players")

local ScrollCanvas = require(script.Parent.Parent.Components.ScrollCanvas)
local OpenAnimation = require(script.Parent.Parent.Components.OpenAnimation)
local HudSlide = require(script.Parent.Parent.Components.HudSlide)
local ScreenRegistry = require(script.Parent.Parent.Components.ScreenRegistry)
local UiSound = require(script.Parent.Parent.Parent.Effects.UiSound)

local SHOP_GUI_NAME = "ShopGui"
local TEMPLATE_NAME = "OddsCellTemplate"
local CELL_NAME = "OddsCell"
local CHANCE_FORMAT = "%.2f%%"
local PERCENT_MULTIPLIER = 100

export type OddsEntry = {
	DisplayName: string,
	Chance: number,
	Image: string?,
	Color: Color3?,
}

local OddsScreen = {}

local isInitialized = false
local oddsList: ScrollingFrame? = nil
local cellTemplate: Frame? = nil
local titleLabel: TextLabel? = nil
local iconLabel: ImageLabel? = nil
local isReplacingShop = false

local function setText(parent: Instance, childName: string, text: string)
	local label = parent:FindFirstChild(childName)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function setImage(parent: Instance, image: string?, color: Color3?)
	local imageLabel = parent:FindFirstChild("ItemImage")
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		return
	end
	if image then
		imageLabel.Image = image
	end
	if color then
		imageLabel.BackgroundColor3 = color
		imageLabel.BackgroundTransparency = 0
	end
end

local function clearCells(list: ScrollingFrame)
	for _, child in list:GetChildren() do
		if child.Name == CELL_NAME then
			child:Destroy()
		end
	end
end

local function createCell(template: Frame, entry: OddsEntry, order: number): Frame
	local cell = template:Clone()
	cell.Name = CELL_NAME
	cell.LayoutOrder = order
	cell.Visible = true
	setText(cell, "ItemName", entry.DisplayName)
	setText(cell, "Chance", string.format(CHANCE_FORMAT, entry.Chance * PERCENT_MULTIPLIER))
	setImage(cell, entry.Image, entry.Color)
	return cell
end

local function bindButton(button: Instance, callback: () -> ())
	if button:IsA("GuiButton") then
		button.Activated:Connect(callback)
	end
end

local function bindPanelButtons(shopGui: Instance)
	local panel = shopGui:WaitForChild("OddsPanel")
	local main = shopGui:WaitForChild("Main")
	if not panel:IsA("GuiObject") or not main:IsA("GuiObject") then
		return
	end
	local oddsPanel = panel :: GuiObject
	local mainFrame = main :: GuiObject
	oddsPanel.Visible = false
	UiSound.WatchOpen(oddsPanel)
	OpenAnimation.Watch(oddsPanel)
	HudSlide.TrackScreen(oddsPanel)
	ScreenRegistry.Register(oddsPanel)
	bindButton(main:WaitForChild("Header"):WaitForChild("OddsButton"), function()
		isReplacingShop = true
		mainFrame.Visible = false
		oddsPanel.Visible = true
	end)
	bindButton(panel:WaitForChild("Header"):WaitForChild("CloseButton"), function()
		OpenAnimation.Close(oddsPanel, function()
			isReplacingShop = false
			mainFrame.Visible = true
		end)
	end)
	mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if mainFrame.Visible then
			isReplacingShop = false
			oddsPanel.Visible = false
		elseif not isReplacingShop then
			oddsPanel.Visible = false
		end
	end)
end

function OddsScreen.Render(entries: { OddsEntry })
	local list = oddsList
	local template = cellTemplate
	if not list or not template then
		warn("[OddsScreen] Render called before Init")
		return
	end
	clearCells(list)
	for index, entry in entries do
		createCell(template, entry, index).Parent = list
	end
end

function OddsScreen.SetTitle(text: string)
	if titleLabel then
		titleLabel.Text = text
	end
end

function OddsScreen.SetIcon(image: string)
	if iconLabel then
		iconLabel.Image = image
	end
end

function OddsScreen.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local shopGui = playerGui:WaitForChild(SHOP_GUI_NAME)
	local list = shopGui:WaitForChild("OddsPanel"):WaitForChild("OddsList")
	local template = list:WaitForChild(TEMPLATE_NAME)
	if not list:IsA("ScrollingFrame") or not template:IsA("Frame") then
		warn("[OddsScreen] OddsList or template has wrong class")
		return
	end
	local templateFrame = template :: Frame
	templateFrame.Visible = false
	oddsList = list :: ScrollingFrame
	cellTemplate = templateFrame
	if not ScrollCanvas.BindToLayout(list :: ScrollingFrame) then
		warn("[OddsScreen] OddsList missing layout")
	end
	local header = shopGui:WaitForChild("OddsPanel"):WaitForChild("Header")
	local title = header:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		titleLabel = title
	end
	local icon = header:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		iconLabel = icon
	end

	bindPanelButtons(shopGui)
end

return OddsScreen
