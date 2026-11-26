--!strict

local EDGE_ALLOWANCE = 8

local ScrollCanvas = {}

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

local function getHorizontalPadding(list: ScrollingFrame): number
	local padding = list:FindFirstChildOfClass("UIPadding")
	if not padding then
		return 0
	end
	return padding.PaddingLeft.Offset + padding.PaddingRight.Offset
end

local function getVerticalPadding(list: ScrollingFrame): number
	local padding = list:FindFirstChildOfClass("UIPadding")
	if not padding then
		return 0
	end
	local height = list.AbsoluteSize.Y
	local top = padding.PaddingTop.Offset + padding.PaddingTop.Scale * height
	local bottom = padding.PaddingBottom.Offset + padding.PaddingBottom.Scale * height
	return top + bottom
end

function ScrollCanvas.BindToLayout(list: ScrollingFrame): boolean
	local layout = list:FindFirstChildWhichIsA("UIGridStyleLayout")
	if not layout then
		return false
	end
	list.AutomaticCanvasSize = Enum.AutomaticSize.None
	local function updateCanvas()
		local height = layout.AbsoluteContentSize.Y + getVerticalPadding(list)
		list.CanvasSize = UDim2.fromOffset(0, math.ceil(height))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
	updateCanvas()
	return true
end

function ScrollCanvas.BindHorizontalToLayout(list: ScrollingFrame): boolean
	local layout = list:FindFirstChildWhichIsA("UIGridStyleLayout")
	if not layout then
		return false
	end
	list.AutomaticCanvasSize = Enum.AutomaticSize.None
	local function updateCanvas()
		local contentWidth = layout.AbsoluteContentSize.X / getUiScaleFactor(list)
		local width = contentWidth + getHorizontalPadding(list) + EDGE_ALLOWANCE
		list.CanvasSize = UDim2.fromOffset(math.ceil(width), 0)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
	list:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvas)
	updateCanvas()
	return true
end

return ScrollCanvas
