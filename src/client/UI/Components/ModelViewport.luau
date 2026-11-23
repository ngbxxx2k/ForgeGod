--!strict

local CAMERA_NAME = "PreviewCamera"
local MODEL_NAME = "PreviewModel"
local VIEW_DIRECTION = Vector3.new(1, 0.6, 1).Unit
local DISTANCE_PER_SIZE = 1.15
local FIELD_OF_VIEW = 40

local ModelViewport = {}

local function prepareClone(source: Model): Model
	local clone = source:Clone()
	clone.Name = MODEL_NAME
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BaseScript") or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	return clone
end

local function getOrCreateCamera(viewport: ViewportFrame): Camera
	local existing = viewport:FindFirstChild(CAMERA_NAME)
	if existing and existing:IsA("Camera") then
		return existing
	end
	local camera = Instance.new("Camera")
	camera.Name = CAMERA_NAME
	camera.FieldOfView = FIELD_OF_VIEW
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return camera
end

function ModelViewport.Clear(viewport: ViewportFrame)
	local existing = viewport:FindFirstChild(MODEL_NAME)
	if existing then
		existing:Destroy()
	end
end

function ModelViewport.Show(viewport: ViewportFrame, source: Model?)
	ModelViewport.Clear(viewport)
	if source == nil then
		return
	end
	local clone = prepareClone(source)
	clone:PivotTo(CFrame.identity)
	local boxCFrame, boxSize = clone:GetBoundingBox()
	local camera = getOrCreateCamera(viewport)
	local distance = boxSize.Magnitude * DISTANCE_PER_SIZE
	local focus = boxCFrame.Position
	camera.CFrame = CFrame.lookAt(focus + VIEW_DIRECTION * distance, focus)
	clone.Parent = viewport
end

return ModelViewport
