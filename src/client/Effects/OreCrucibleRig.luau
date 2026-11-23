--!strict

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local OreCrucibleConfig = require(ReplicatedStorage.Shared.Config.OreCrucibleConfig)

local RUNTIME_FOLDER_NAME = "OreCrucibleRuntime"
local LAVA_VOLUME_NAME = "OreCrucibleLavaVolume"
local CONTROLLER_NAME = "OreCrucibleAnimator"

export type Rig = {
	Model: Model,
	Body: BasePart,
	Glows: { [string]: BasePart },
	Bones: { [string]: Bone },
	Folder: Folder,
	LavaVolume: Part,
	Anchors: { [string]: Attachment },
	Tracks: { [string]: AnimationTrack },
	CreatedController: AnimationController?,
	CurrentTrack: AnimationTrack?,
}

local OreCrucibleRig = {}

local warnedMissingAnimations = false

local function findPart(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

local function findBone(model: Model, name: string): Bone?
	local found = model:FindFirstChild(name, true)
	if found and found:IsA("Bone") then
		return found
	end
	return nil
end

local function findBones(model: Model, shouldWarn: boolean): { [string]: Bone }?
	local bones = {}
	for key, name in OreCrucibleConfig.BoneNames do
		local bone = findBone(model, name)
		if not bone then
			if shouldWarn then
				warn("[OreCrucibleRig] Missing bone", name, "in", model:GetFullName())
			end
			return nil
		end
		bones[key] = bone
	end
	return bones
end

local function getAnimator(model: Model): (Animator, AnimationController?)
	local controller = model:FindFirstChildWhichIsA("AnimationController", true)
	local created: AnimationController? = nil
	if not controller then
		local newController = Instance.new("AnimationController")
		newController.Name = CONTROLLER_NAME
		newController.Archivable = false
		newController.Parent = model
		controller = newController
		created = newController
	end
	local animationController = controller :: AnimationController
	local animator = animationController:FindFirstChildWhichIsA("Animator")
	if not animator then
		local newAnimator = Instance.new("Animator")
		newAnimator.Parent = animationController
		animator = newAnimator
	end
	return animator :: Animator, created
end

local function getStudioPreviewId(state: string): string
	if not RunService:IsStudio() then
		return ""
	end
	local folder = ReplicatedStorage:FindFirstChild(OreCrucibleConfig.StudioKeyframesFolder)
	local sequence = folder and folder:FindFirstChild(state)
	if not sequence or not sequence:IsA("KeyframeSequence") then
		return ""
	end
	local ok, id = pcall(function()
		return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
	end)
	if not ok then
		warn("[OreCrucibleRig] Studio preview animation failed:", id)
		return ""
	end
	return id
end

local function loadTracks(animator: Animator): { [string]: AnimationTrack }
	local tracks = {}
	for state, configId in OreCrucibleConfig.AnimationIds do
		local id = if configId ~= "" then configId else getStudioPreviewId(state)
		if id == "" then
			if not warnedMissingAnimations then
				warnedMissingAnimations = true
				warn("[OreCrucibleRig] AnimationIds are empty in OreCrucibleConfig")
			end
			continue
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track.Priority = Enum.AnimationPriority.Core
		tracks[state] = track
	end
	return tracks
end

local function newAnchor(rig: Rig, parent: BasePart, name: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Archivable = false
	attachment.Parent = parent
	attachment.WorldCFrame = CFrame.new(position)
	rig.Anchors[name] = attachment
	return attachment
end

local function newLavaVolume(folder: Folder): Part
	local part = Instance.new("Part")
	part.Name = LAVA_VOLUME_NAME
	part.Size = OreCrucibleConfig.LavaVolume.Size
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Archivable = false
	part.Parent = folder
	return part
end

local function findGlows(model: Model): { [string]: BasePart }
	local glows = {}
	for _, key in { "Lava", "Rune", "Vent" } do
		local part = findPart(model, (OreCrucibleConfig.PartNames :: any)[key])
		if part then
			glows[key] = part
		end
	end
	return glows
end

function OreCrucibleRig.Build(model: Model, shouldWarn: boolean): Rig?
	local body = findPart(model, OreCrucibleConfig.PartNames.Body)
	local bones = findBones(model, shouldWarn)
	if not body or not bones then
		if shouldWarn then
			warn("[OreCrucibleRig] Model is not set up:", model:GetFullName())
		end
		return nil
	end
	local folder = Instance.new("Folder")
	folder.Name = RUNTIME_FOLDER_NAME
	folder.Archivable = false
	folder.Parent = model
	local animator, created = getAnimator(model)
	local rig: Rig = {
		Model = model,
		Body = body,
		Glows = findGlows(model),
		Bones = bones,
		Folder = folder,
		LavaVolume = newLavaVolume(folder),
		Anchors = {},
		Tracks = loadTracks(animator),
		CreatedController = created,
		CurrentTrack = nil,
	}
	OreCrucibleRig.UpdateLava(rig)
	newAnchor(rig, rig.LavaVolume, "LavaCenter", rig.LavaVolume.Position)
	for _, key in { "Top", "Grate", "BackVent", "Base" } do
		newAnchor(rig, body, key, bones[key].WorldPosition)
	end
	return rig
end

function OreCrucibleRig.FindLavaPosition(model: Model): Vector3
	local bone = findBone(model, OreCrucibleConfig.BoneNames.Lava)
	if bone then
		return bone.TransformedWorldCFrame.Position
	end
	return model:GetBoundingBox().Position
end

function OreCrucibleRig.FindGroundY(model: Model): number
	local bone = findBone(model, OreCrucibleConfig.BoneNames.Base)
	if bone then
		return bone.WorldPosition.Y
	end
	return model:GetPivot().Position.Y
end

function OreCrucibleRig.FindFrontDirection(model: Model): Vector3
	local center = model:GetPivot().Position
	local bone = findBone(model, OreCrucibleConfig.BoneNames.Grate)
	local offset = if bone then bone.WorldPosition - center else model:GetPivot().LookVector
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude == 0 then
		return Vector3.zAxis
	end
	return flat.Unit
end

function OreCrucibleRig.UpdateLava(rig: Rig)
	local position = rig.Bones.Lava.TransformedWorldCFrame.Position
	rig.LavaVolume.CFrame = CFrame.new(position + Vector3.yAxis * OreCrucibleConfig.LavaVolume.Lift)
end

function OreCrucibleRig.PlayState(rig: Rig, state: string, fadeTime: number)
	local track = rig.Tracks[state]
	if rig.CurrentTrack == track then
		return
	end
	if rig.CurrentTrack then
		rig.CurrentTrack:Stop(fadeTime)
	end
	rig.CurrentTrack = track
	if track then
		track:Play(fadeTime)
	end
end

function OreCrucibleRig.StopAll(rig: Rig)
	for _, track in rig.Tracks do
		track:Stop(0)
	end
	rig.CurrentTrack = nil
end

function OreCrucibleRig.Destroy(rig: Rig)
	OreCrucibleRig.StopAll(rig)
	for _, track in rig.Tracks do
		track:Destroy()
	end
	for _, attachment in rig.Anchors do
		attachment:Destroy()
	end
	rig.Folder:Destroy()
	if rig.CreatedController then
		rig.CreatedController:Destroy()
	end
end

return OreCrucibleRig
