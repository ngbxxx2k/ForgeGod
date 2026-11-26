--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)

local FOLDER_NAME = "TutorialArrow"
local ROOT_PART_NAME = "HumanoidRootPart"
local UPDATE_INTERVAL = 0.1

type Segment = {
	Beam: Beam,
	Near: Attachment,
	Far: Attachment,
}

local TutorialArrow = {}

local localPlayer = Players.LocalPlayer
local folder: Folder? = nil
local segments: { Segment } = {}
local target: Vector3? = nil
local connection: RBXScriptConnection? = nil
local elapsed = 0
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function getFolder(): Folder
	local current = folder
	if current and current.Parent then
		return current
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace.Terrain
	folder = created
	return created
end

local function createSegment(): Segment
	local config = TutorialConfig.Arrow
	local parent = getFolder()
	local near = Instance.new("Attachment")
	local far = Instance.new("Attachment")
	local beam = Instance.new("Beam")
	beam.Texture = config.Texture
	beam.TextureMode = Enum.TextureMode.Static
	beam.TextureLength = config.TextureLength
	beam.TextureSpeed = config.TextureSpeed
	beam.Width0 = config.Width
	beam.Width1 = config.Width
	beam.FaceCamera = false
	beam.Segments = 1
	beam.LightEmission = config.LightEmission
	beam.Transparency = NumberSequence.new(config.Transparency)
	beam.Attachment0 = far
	beam.Attachment1 = near
	near.Parent = Workspace.Terrain
	far.Parent = Workspace.Terrain
	beam.Parent = parent
	return { Beam = beam, Near = near, Far = far }
end

local function setSegmentCount(count: number)
	while #segments < count do
		table.insert(segments, createSegment())
	end
	for index, segment in segments do
		segment.Beam.Enabled = index <= count
	end
end

local function groundAt(point: Vector3): Vector3
	local config = TutorialConfig.Arrow
	local origin = point + Vector3.yAxis * config.RaycastHeight
	local result = Workspace:Raycast(origin, -Vector3.yAxis * config.RaycastDepth, raycastParams)
	local y = if result then result.Position.Y else point.Y
	return Vector3.new(point.X, y + config.GroundOffset, point.Z)
end

local function placeSegment(segment: Segment, from: Vector3, to: Vector3)
	local direction = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if direction.Magnitude < 1e-3 then
		return
	end
	direction = direction.Unit
	local side = direction:Cross(Vector3.yAxis).Unit
	segment.Near.WorldCFrame = CFrame.fromMatrix(from, direction, side)
	segment.Far.WorldCFrame = CFrame.fromMatrix(to, direction, side)
end

local function getFeet(): (Vector3?, Model?)
	local character = localPlayer.Character
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	if character == nil or root == nil or not root:IsA("BasePart") then
		return nil, nil
	end
	return root.Position, character
end

local function rebuild()
	local goal = target
	local feet, character = getFeet()
	if goal == nil or feet == nil then
		setSegmentCount(0)
		return
	end
	local config = TutorialConfig.Arrow
	local flat = Vector3.new(goal.X - feet.X, 0, goal.Z - feet.Z)
	local length = flat.Magnitude - config.StopDistance - config.StartGap
	if length <= 0 then
		setSegmentCount(0)
		return
	end
	raycastParams.FilterDescendantsInstances = { character :: Model, getFolder() }
	local direction = flat.Unit
	local start = feet + direction * config.StartGap
	local count = math.clamp(math.ceil(length / config.SegmentLength), 1, config.MaxSegments)
	setSegmentCount(count)
	local previous = groundAt(start)
	for index = 1, count do
		local alpha = index / count
		local point = start + direction * length * alpha + Vector3.yAxis * (goal.Y - feet.Y) * alpha
		local current = groundAt(point)
		placeSegment(segments[index], previous, current)
		previous = current
	end
end

local function onHeartbeat(dt: number)
	elapsed += dt
	if elapsed < UPDATE_INTERVAL then
		return
	end
	elapsed = 0
	rebuild()
end

function TutorialArrow.SetTarget(position: Vector3?)
	if target == position then
		return
	end
	target = position
	if position == nil then
		setSegmentCount(0)
		return
	end
	if connection == nil then
		connection = RunService.Heartbeat:Connect(onHeartbeat)
	end
	rebuild()
end

return TutorialArrow
