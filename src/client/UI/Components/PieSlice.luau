--!strict

local HALF_TURN = 180
local CENTER = 0.5
local MASK_EDGE = 0.4999
local SEAM_OVERLAP = 1

export type Slice = {
	Right: Frame,
	Left: Frame,
	RightGradient: UIGradient,
	LeftGradient: UIGradient,
}

local PieSlice = {}

local function createMaskGradient(): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(MASK_EDGE, 0),
		NumberSequenceKeypoint.new(CENTER, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	return gradient
end

local function createHalf(name: string, color: Color3, isRight: boolean): (Frame, UIGradient)
	local clip = Instance.new("Frame")
	clip.Name = name
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	local overlap = if isRight then SEAM_OVERLAP else 0
	clip.Size = UDim2.new(CENTER, overlap, 1, 0)
	clip.Position = UDim2.new(if isRight then CENTER else 0, -overlap, 0, 0)
	local disc = Instance.new("Frame")
	disc.Name = "Disc"
	disc.BorderSizePixel = 0
	disc.BackgroundColor3 = color
	disc.Size = UDim2.new(2, -2 * overlap, 1, 0)
	disc.Position = UDim2.new(if isRight then -1 else 0, 2 * overlap, 0, 0)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(CENTER, 0)
	corner.Parent = disc
	local gradient = createMaskGradient()
	gradient.Parent = disc
	disc.Parent = clip
	return clip, gradient
end

function PieSlice.Create(parent: Instance, name: string, color: Color3, zIndex: number): Slice
	local right, rightGradient = createHalf("Right" .. name, color, true)
	local left, leftGradient = createHalf("Left" .. name, color, false)
	right.ZIndex, left.ZIndex = zIndex, zIndex
	right.Parent, left.Parent = parent, parent
	return {
		Right = right,
		Left = left,
		RightGradient = rightGradient,
		LeftGradient = leftGradient,
	}
end

function PieSlice.SetStart(slice: Slice, start: number)
	slice.Right.Visible = start < HALF_TURN
	slice.Left.Visible = true
	slice.RightGradient.Rotation = start + HALF_TURN
	slice.LeftGradient.Rotation = math.max(start, HALF_TURN) + HALF_TURN
end

function PieSlice.SetZIndex(slice: Slice, zIndex: number)
	slice.Right.ZIndex = zIndex
	slice.Left.ZIndex = zIndex
end

function PieSlice.Hide(slice: Slice)
	slice.Right.Visible = false
	slice.Left.Visible = false
end

return PieSlice
