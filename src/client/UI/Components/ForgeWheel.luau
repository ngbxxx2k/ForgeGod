--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ForgeWheelConfig = require(ReplicatedStorage.Shared.Config.ForgeWheelConfig)
local ForgeOutcomes = require(ReplicatedStorage.Shared.Constants.ForgeOutcomes)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local WheelMath = require(ReplicatedStorage.Shared.Utils.WheelMath)

local HALF_TURN = 180
local CENTER = 0.5
local PERCENT_TEMPLATE_NAME = "PercentTemplate"
local MASK_EDGE = 0.4999
local WHOLE_TOLERANCE = 0.05
local SEAM_OVERLAP = 1

type Slice = {
	Right: Frame,
	Left: Frame,
	RightGradient: UIGradient,
	LeftGradient: UIGradient,
	Divider: Frame,
	Label: TextLabel,
}

local ForgeWheel = {}

local order: { string } = {}
local slices: { [string]: Slice } = {}
local segments: { WheelMath.Segment } = {}
local shownChances: { [string]: number } = {}
local morphDriver: NumberValue? = nil
local morphTween: Tween? = nil
local morphConnection: RBXScriptConnection? = nil

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

local function createDivider(parent: Instance): Frame
	local pivot = Instance.new("Frame")
	pivot.Name = "Divider"
	pivot.BackgroundTransparency = 1
	pivot.Size = UDim2.fromScale(1, 1)
	local line = Instance.new("Frame")
	line.Name = "Line"
	line.BorderSizePixel = 0
	line.BackgroundColor3 = ForgeWheelConfig.DividerColor
	line.AnchorPoint = Vector2.new(CENTER, CENTER)
	line.Position = UDim2.fromScale(CENTER, CENTER - ForgeWheelConfig.DividerRadius)
	line.Size = UDim2.new(0, ForgeWheelConfig.DividerThickness, ForgeWheelConfig.DividerLength, 0)
	line.Parent = pivot
	pivot.Parent = parent
	return pivot
end

local function createSlice(
	segmentsFrame: Instance,
	dividers: Instance,
	labelTemplate: TextLabel,
	outcome: ForgeOutcomes.ForgeOutcome,
	index: number
): Slice
	local right, rightGradient = createHalf("Right" .. outcome.Id, outcome.Color, true)
	local left, leftGradient = createHalf("Left" .. outcome.Id, outcome.Color, false)
	right.ZIndex, left.ZIndex = index, index
	right.Parent, left.Parent = segmentsFrame, segmentsFrame
	local label = labelTemplate:Clone()
	label.Name = "Percent" .. outcome.Id
	label.Parent = labelTemplate.Parent
	return {
		Right = right,
		Left = left,
		RightGradient = rightGradient,
		LeftGradient = leftGradient,
		Divider = createDivider(dividers),
		Label = label,
	}
end

function ForgeWheel.FormatPercent(percent: number): string
	local rounded = math.round(percent)
	if math.abs(percent - rounded) < WHOLE_TOLERANCE then
		return string.format(ForgeMessages.WholePercentFormat, rounded)
	end
	return string.format(ForgeMessages.PercentFormat, percent)
end

local function placeLabel(label: TextLabel, segment: WheelMath.Segment)
	local width = segment.Finish - segment.Start
	label.Visible = width > 0 and segment.Percent >= ForgeWheelConfig.MinLabelChance
	local middle = math.rad(segment.Start + width / 2)
	local radius = ForgeWheelConfig.LabelRadius
	label.Position = UDim2.fromScale(CENTER + radius * math.sin(middle), CENTER - radius * math.cos(middle))
	label.Text = ForgeWheel.FormatPercent(segment.Percent)
end

local function applySlice(slice: Slice, segment: WheelMath.Segment, isDividerShown: boolean)
	local start = segment.Start
	slice.Right.Visible = start < HALF_TURN
	slice.Left.Visible = true
	slice.RightGradient.Rotation = start + HALF_TURN
	slice.LeftGradient.Rotation = math.max(start, HALF_TURN) + HALF_TURN
	slice.Divider.Rotation = start
	slice.Divider.Visible = isDividerShown
	placeLabel(slice.Label, segment)
end

local function countVisible(drawn: { WheelMath.Segment }): number
	local count = 0
	for _, segment in drawn do
		if segment.Finish > segment.Start then
			count += 1
		end
	end
	return count
end

local function draw(chances: { [string]: number })
	local drawn = WheelMath.BuildSegments(order, chances)
	local isDividerShown = countVisible(drawn) > 1
	for _, id in order do
		local slice = slices[id]
		slice.Right.Visible, slice.Left.Visible = false, false
		slice.Divider.Visible, slice.Label.Visible = false, false
	end
	for _, segment in drawn do
		local slice = slices[segment.Id]
		if slice then
			applySlice(slice, segment, isDividerShown and segment.Finish > segment.Start)
		end
	end
end

local function stopMorph()
	if morphTween then
		morphTween:Cancel()
		morphTween = nil
	end
	if morphConnection then
		morphConnection:Disconnect()
		morphConnection = nil
	end
end

local function lerpChances(from: { [string]: number }, to: { [string]: number }, alpha: number)
	local mixed: { [string]: number } = {}
	for _, id in order do
		local a, b = from[id] or 0, to[id] or 0
		mixed[id] = a + (b - a) * alpha
	end
	return mixed
end

local function hasAny(chances: { [string]: number }): boolean
	for _, id in order do
		if (chances[id] or 0) > 0 then
			return true
		end
	end
	return false
end

local function morphTo(from: { [string]: number }, target: { [string]: number }, duration: number)
	local driver = morphDriver
	if driver == nil then
		draw(target)
		return
	end
	driver.Value = 0
	morphConnection = driver.Changed:Connect(function(alpha: number)
		draw(lerpChances(from, target, alpha))
	end)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(driver, info, { Value = 1 })
	morphTween = tween
	tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
		if playbackState == Enum.PlaybackState.Completed and morphTween == tween then
			stopMorph()
			draw(target)
		end
	end)
	tween:Play()
end

function ForgeWheel.SetChances(chances: { [string]: number }, isAnimated: boolean)
	stopMorph()
	local target = table.clone(chances)
	local from = shownChances
	segments = WheelMath.BuildSegments(order, target)
	shownChances = target
	if isAnimated and hasAny(from) and hasAny(target) then
		morphTo(from, target, ForgeWheelConfig.ChanceMorphTime)
		return
	end
	draw(target)
end

function ForgeWheel.GetSegments(): { WheelMath.Segment }
	return segments
end

function ForgeWheel.GetChances(): { [string]: number }
	return shownChances
end

function ForgeWheel.Bind(wheel: Frame)
	local segmentsFrame = wheel:WaitForChild("Segments")
	local dividers = wheel:WaitForChild("Dividers")
	local labels = wheel:WaitForChild("Labels")
	local template = labels:WaitForChild(PERCENT_TEMPLATE_NAME)
	if not template:IsA("TextLabel") then
		warn("[ForgeWheel] PercentTemplate is not a TextLabel")
		return
	end
	template.Visible = false
	morphDriver = Instance.new("NumberValue")
	for index, outcome in ForgeOutcomes do
		table.insert(order, outcome.Id)
		slices[outcome.Id] = createSlice(segmentsFrame, dividers, template, outcome, index)
	end
	draw({})
end

return ForgeWheel
