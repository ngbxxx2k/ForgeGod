--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardConfig = require(ReplicatedStorage.Shared.Config.LeaderboardConfig)
local LeaderboardMessages = require(ReplicatedStorage.Shared.Constants.LeaderboardMessages)
local LeaderboardTypes = require(ReplicatedStorage.Shared.Types.LeaderboardTypes)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local LeaderboardRow = require(script.Parent.LeaderboardRow)

local CARD_CORNER = UDim.new(0, 36)
local CARD_STROKE = 8
local RIM_INSET = 16
local INNER_CORNER = UDim.new(0, 26)
local INNER_STROKE = 4
local HEADER_HEIGHT = 150
local ICON_SIZE = 96
local ICON_PADDING = 14
local TITLE_X = 116
local TITLE_HEIGHT = 74
local SUBTITLE_Y = 88
local SUBTITLE_HEIGHT = 40
local LIST_PADDING = 12
local LIST_GAP = 8
local FOOTER_HEIGHT = 44
local FOOTER_BOTTOM = 12
local SCROLLBAR_THICKNESS = 10
local TITLE_STROKE = 5
local TEXT_STROKE = 3
local RIM_GRADIENT_ROTATION = 90

export type Board = {
	Id: string,
	Gui: SurfaceGui,
	List: ScrollingFrame,
	EmptyLabel: TextLabel,
	Footer: TextLabel,
	Rows: { LeaderboardRow.Row },
	ValueFormat: string,
	ValueColor: Color3,
}

local LeaderboardBoard = {}

local Colors = LeaderboardConfig.Colors

local function addCorner(target: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = target
end

local function addStroke(target: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Outline
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode
	stroke.Parent = target
end

local function createText(name: string, text: string, strokeThickness: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = LeaderboardConfig.Font
	label.TextScaled = true
	label.TextColor3 = Colors.Text
	label.Text = text
	addStroke(label, strokeThickness, Enum.ApplyStrokeMode.Contextual)
	return label
end

local function createGui(boardId: string): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Leaderboard" .. boardId
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = LeaderboardConfig.PixelsPerStud
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.LightInfluence = 0
	gui.MaxDistance = LeaderboardConfig.MaxViewDistance
	gui.ResetOnSpawn = false
	return gui
end

local function createCard(gui: SurfaceGui): Frame
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Colors.Rim
	addCorner(card, CARD_CORNER)
	addStroke(card, CARD_STROKE, Enum.ApplyStrokeMode.Border)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Colors.Rim, Colors.RimDark)
	gradient.Rotation = RIM_GRADIENT_ROTATION
	gradient.Parent = card
	card.Parent = gui
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.Position = UDim2.fromOffset(RIM_INSET, RIM_INSET)
	inner.Size = UDim2.new(1, -RIM_INSET * 2, 1, -RIM_INSET * 2)
	inner.BackgroundColor3 = Colors.Inner
	addCorner(inner, INNER_CORNER)
	addStroke(inner, INNER_STROKE, Enum.ApplyStrokeMode.Border)
	inner.Parent = card
	return inner
end

local function createHeader(inner: Frame, boardId: string)
	local messages = LeaderboardMessages.Boards[boardId]
	local icon = createText("Icon", messages.Icon, 0)
	icon.Position = UDim2.fromOffset(ICON_PADDING, ICON_PADDING)
	icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
	icon.Parent = inner
	local title = createText("Title", messages.Title, TITLE_STROKE)
	title.Position = UDim2.fromOffset(TITLE_X, ICON_PADDING)
	title.Size = UDim2.new(1, -TITLE_X - ICON_PADDING, 0, TITLE_HEIGHT)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = inner
	local subtitle = createText("Subtitle", messages.Subtitle, TEXT_STROKE)
	subtitle.Position = UDim2.fromOffset(TITLE_X, SUBTITLE_Y)
	subtitle.Size = UDim2.new(1, -TITLE_X - ICON_PADDING, 0, SUBTITLE_HEIGHT)
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = inner
end

local function createList(inner: Frame): ScrollingFrame
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(LIST_PADDING, HEADER_HEIGHT)
	list.Size = UDim2.new(1, -LIST_PADDING * 2, 1, -HEADER_HEIGHT - FOOTER_HEIGHT - FOOTER_BOTTOM * 2)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.ScrollBarThickness = SCROLLBAR_THICKNESS
	list.ScrollBarImageColor3 = Colors.ScrollBar
	list.ElasticBehavior = Enum.ElasticBehavior.Always
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, LIST_GAP)
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, LIST_GAP)
	padding.PaddingBottom = UDim.new(0, LIST_GAP)
	padding.PaddingLeft = UDim.new(0, LIST_GAP / 2)
	padding.Parent = list
	list.Parent = inner
	return list
end

local function createFooter(inner: Frame): TextLabel
	local footer = createText("Footer", LeaderboardMessages.Updating, TEXT_STROKE)
	footer.AnchorPoint = Vector2.new(0.5, 1)
	footer.Position = UDim2.new(0.5, 0, 1, -FOOTER_BOTTOM)
	footer.Size = UDim2.new(1, -LIST_PADDING * 2, 0, FOOTER_HEIGHT)
	footer.Parent = inner
	return footer
end

local function createEmptyLabel(list: ScrollingFrame): TextLabel
	local label = createText("Empty", LeaderboardMessages.Empty, TEXT_STROKE)
	label.Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT)
	label.Parent = list
	return label
end

local function getRow(board: Board, index: number): LeaderboardRow.Row
	local row = board.Rows[index]
	if row == nil then
		row = LeaderboardRow.Create()
		row.Frame.Parent = board.List
		board.Rows[index] = row
	end
	return row
end

function LeaderboardBoard.Build(definition: LeaderboardConfig.BoardDefinition): Board
	local gui = createGui(definition.Id)
	local inner = createCard(gui)
	createHeader(inner, definition.Id)
	local list = createList(inner)
	return {
		Id = definition.Id,
		Gui = gui,
		List = list,
		EmptyLabel = createEmptyLabel(list),
		Footer = createFooter(inner),
		Rows = {},
		ValueFormat = LeaderboardMessages.Boards[definition.Id].ValueFormat,
		ValueColor = definition.ValueColor,
	}
end

function LeaderboardBoard.Mount(board: Board, panel: BasePart, playerGui: Instance)
	board.Gui.Adornee = panel
	board.Gui.Parent = playerGui
end

function LeaderboardBoard.Render(board: Board, entries: { LeaderboardTypes.Entry })
	for index, entry in entries do
		local valueText = string.format(board.ValueFormat, NumberFormat.Abbreviate(entry.Score))
		local row = getRow(board, index)
		LeaderboardRow.Render(row, index, entry.UserId, entry.Name, valueText, board.ValueColor)
	end
	for index = #entries + 1, #board.Rows do
		board.Rows[index].Frame.Visible = false
	end
	board.EmptyLabel.Visible = #entries == 0
end

function LeaderboardBoard.SetFooter(board: Board, text: string)
	if board.Footer.Text ~= text then
		board.Footer.Text = text
	end
end

function LeaderboardBoard.Destroy(board: Board)
	board.Gui:Destroy()
end

return LeaderboardBoard
