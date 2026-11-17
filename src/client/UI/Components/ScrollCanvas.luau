--!strict

local ScrollCanvas = {}

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

return ScrollCanvas
