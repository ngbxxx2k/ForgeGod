--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VoidheartFxConfig = require(ReplicatedStorage.Shared.Config.VoidheartFxConfig)

export type Mover = {
	Parts: { BasePart },
	Rest: { CFrame },
	BaseSizes: { Vector3 },
	WasAnchored: { boolean },
	Pivot: Vector3,
	Radial: Vector3,
	Extent: number,
}

export type Rig = {
	Model: Model,
	Root: BasePart,
	RootToFrame: CFrame,
	Length: number,
	BottomHeight: number,
	TopHeight: number,
	Movers: { [string]: Mover },
}

local VoidheartRig = {}

local function findPart(model: Model, name: string): BasePart?
	local found = model:FindFirstChild(name, true)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

local function buildFrame(root: BasePart, top: BasePart, bottom: BasePart): CFrame
	local up = (top.Position - bottom.Position).Unit
	local reference = if math.abs(up.X) < 0.9 then Vector3.xAxis else Vector3.zAxis
	local right = (reference - up * up:Dot(reference)).Unit
	local back = right:Cross(up)
	return CFrame.fromMatrix(root.Position, right, up, back)
end

local function halfExtentAlong(part: BasePart, worldDirection: Vector3): number
	local localDirection = part.CFrame:VectorToObjectSpace(worldDirection)
	local size = part.Size
	return (math.abs(localDirection.X) * size.X + math.abs(localDirection.Y) * size.Y
		+ math.abs(localDirection.Z) * size.Z) / 2
end

local function createMover(frame: CFrame, parts: { BasePart }): Mover
	local main = parts[1]
	local pivot = frame:PointToObjectSpace(main.Position)
	local flat = Vector3.new(pivot.X, 0, pivot.Z)
	local radial = if flat.Magnitude > 1e-4 then flat.Unit else Vector3.zero
	local mover: Mover = {
		Parts = parts,
		Rest = {},
		BaseSizes = {},
		WasAnchored = {},
		Pivot = pivot,
		Radial = radial,
		Extent = halfExtentAlong(main, frame:VectorToWorldSpace(radial)),
	}
	for index, part in parts do
		mover.Rest[index] = frame:ToObjectSpace(part.CFrame)
		mover.BaseSizes[index] = part.Size
		mover.WasAnchored[index] = part.Anchored
		part.Anchored = true
	end
	return mover
end

local function collectParts(model: Model, names: { string }): { BasePart }?
	local parts = {}
	for _, name in names do
		local part = findPart(model, name)
		if not part then
			warn("[VoidheartRig] Missing part:", name)
			return nil
		end
		table.insert(parts, part)
	end
	return parts
end

local function getMoverDefinitions(): { [string]: { string } }
	local names = VoidheartFxConfig.PartNames
	local definitions: { [string]: { string } } = {
		Core = { names.Core },
		Orb = { names.Orb },
	}
	for _, ring in VoidheartFxConfig.Rings do
		definitions[ring.Name] = { ring.Name, ring.Glow }
	end
	for _, blade in VoidheartFxConfig.Blades do
		definitions[blade.Name] = { blade.Name, blade.Glow }
	end
	for _, claw in VoidheartFxConfig.Claws do
		definitions[claw.Name] = { claw.Name }
	end
	return definitions
end

function VoidheartRig.FindPart(model: Model, name: string): BasePart?
	return findPart(model, name)
end

function VoidheartRig.HalfExtentAlong(part: BasePart, worldDirection: Vector3): number
	return halfExtentAlong(part, worldDirection)
end

function VoidheartRig.Build(model: Model): Rig?
	local names = VoidheartFxConfig.PartNames
	local root = findPart(model, names.Root)
	local top = findPart(model, names.Top)
	local bottom = findPart(model, names.Bottom)
	if not (root and top and bottom) then
		warn("[VoidheartRig] Model is missing anchor parts:", model:GetFullName())
		return nil
	end
	local frame = buildFrame(root, top, bottom)
	local rig: Rig = {
		Model = model,
		Root = root,
		RootToFrame = root.CFrame:ToObjectSpace(frame),
		Length = (top.Position - bottom.Position).Magnitude,
		BottomHeight = frame:PointToObjectSpace(bottom.Position).Y,
		TopHeight = frame:PointToObjectSpace(top.Position).Y,
		Movers = {},
	}
	for key, partNames in getMoverDefinitions() do
		local parts = collectParts(model, partNames)
		if not parts then
			return nil
		end
		rig.Movers[key] = createMover(frame, parts)
	end
	return rig
end

function VoidheartRig.GetFrame(rig: Rig): CFrame
	return rig.Root.CFrame * rig.RootToFrame
end

function VoidheartRig.Apply(mover: Mover, frame: CFrame, transform: CFrame)
	for index, part in mover.Parts do
		part.CFrame = frame * transform * mover.Rest[index]
	end
end

function VoidheartRig.Scale(mover: Mover, factor: number)
	for index, part in mover.Parts do
		part.Size = mover.BaseSizes[index] * factor
	end
end

function VoidheartRig.Restore(rig: Rig)
	local frame = VoidheartRig.GetFrame(rig)
	for _, mover in rig.Movers do
		for index, part in mover.Parts do
			part.Size = mover.BaseSizes[index]
			part.CFrame = frame * mover.Rest[index]
			part.Anchored = mover.WasAnchored[index]
		end
	end
end

return VoidheartRig
