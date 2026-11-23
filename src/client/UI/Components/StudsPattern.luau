--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(ReplicatedStorage.Shared.Constants.AssetIds)

local STUDS_IMAGE = AssetIds.Textures.Studs
local STUDS_NAME = "StudsTexture"
local STUDS_TRANSPARENCY = 0.1
local TILES_PER_SHORT_SIDE = 1
local SKIP_ATTRIBUTE = "NoStudsPattern"
local TARGET_GUI_NAME = "HudGui"

local StudsPattern = {}

local isInitialized = false
local attachedButtons: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function getLowestChildZIndex(button: GuiButton): number
	local lowest = math.huge
	for _, child in button:GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= STUDS_NAME then
			lowest = math.min(lowest, child.ZIndex)
		end
	end
	return if lowest == math.huge then button.ZIndex else lowest - 1
end

local function getOrCreateStuds(button: GuiButton): ImageLabel
	local existing = button:FindFirstChild(STUDS_NAME)
	if existing and existing:IsA("ImageLabel") then
		return existing
	end
	local studs = Instance.new("ImageLabel")
	studs.Name = STUDS_NAME
	studs.Size = UDim2.fromScale(1, 1)
	studs.BackgroundTransparency = 1
	studs.Image = STUDS_IMAGE
	studs.ImageTransparency = STUDS_TRANSPARENCY
	studs.ScaleType = Enum.ScaleType.Tile
	studs.ZIndex = getLowestChildZIndex(button)
	local buttonCorner = button:FindFirstChildOfClass("UICorner")
	if buttonCorner then
		buttonCorner:Clone().Parent = studs
	end
	studs.Parent = button
	return studs
end

local function updateTileSize(button: GuiButton, studs: ImageLabel)
	local size = button.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		return
	end
	local tileSide = math.min(size.X, size.Y) / TILES_PER_SHORT_SIDE
	studs.TileSize = UDim2.fromScale(tileSide / size.X, tileSide / size.Y)
end

local function canAttach(instance: Instance): boolean
	if not instance:IsA("GuiButton") then
		return false
	end
	if instance:GetAttribute(SKIP_ATTRIBUTE) == true then
		return false
	end
	local screenGui = instance:FindFirstAncestorOfClass("ScreenGui")
	if not screenGui or screenGui.Name ~= TARGET_GUI_NAME then
		return false
	end
	return instance.BackgroundTransparency < 1
end

local function tryAttach(instance: Instance)
	if not canAttach(instance) then
		return
	end
	StudsPattern.Attach(instance :: GuiButton)
end

function StudsPattern.Attach(button: GuiButton)
	if attachedButtons[button] then
		return
	end
	attachedButtons[button] = true
	local studs = getOrCreateStuds(button)
	updateTileSize(button, studs)
	button:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateTileSize(button, studs)
	end)
end

function StudsPattern.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, descendant in playerGui:GetDescendants() do
		tryAttach(descendant)
	end
	playerGui.DescendantAdded:Connect(tryAttach)
end

return StudsPattern
