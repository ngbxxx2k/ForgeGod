--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeViewConfig = require(ReplicatedStorage.Shared.Config.ForgeViewConfig)
local ForgeHammerProfile = require(ReplicatedStorage.Shared.Config.ForgeHammerProfile)

local ForgeStation = {}

local names = ForgeStrikeConfig.AttachmentNames

local function ensureAttachment(part: BasePart, name: string, offset: Vector3): Attachment
	local existing = part:FindFirstChild(name)
	if existing and existing:IsA("Attachment") then
		return existing
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = CFrame.new(offset)
	attachment.Parent = part
	return attachment
end

local function checkSize(part: BasePart)
	local difference = (part.Size - ForgeStrikeConfig.AnvilSize).Magnitude
	if difference > ForgeStrikeConfig.AnvilSizeTolerance then
		warn("[ForgeStation] Anvil size", part.Size, "expected", ForgeStrikeConfig.AnvilSize)
	end
end

local function clearTags(instance: Instance)
	for _, tag in CollectionService:GetTags(instance) do
		CollectionService:RemoveTag(instance, tag)
	end
end

local function prepareClone(model: Model): Model
	local clone = model:Clone()
	local parts: { BasePart } = {}
	clearTags(clone)
	for _, descendant in clone:GetDescendants() do
		clearTags(descendant)
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			table.insert(parts, descendant)
		end
	end
	if clone.PrimaryPart == nil and #parts == 1 then
		parts[1].PivotOffset = CFrame.identity
		clone.PrimaryPart = parts[1]
	end
	return clone
end

local function getLongestSide(model: Model): number
	local _, size = model:GetBoundingBox()
	return math.max(size.X, size.Y, size.Z)
end

local function scaleToLength(model: Model, length: number)
	for _ = 1, ForgeStrikeConfig.WeaponScalePasses do
		local longest = getLongestSide(model)
		if longest <= 0 or math.abs(longest - length) <= ForgeStrikeConfig.WeaponScaleTolerance then
			return
		end
		model:ScaleTo(model:GetScale() * (length / longest))
	end
end

local function extremeOffset(model: Model, up: Vector3, sign: number): number
	local extreme = -math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local rotation = descendant.CFrame
			local half = descendant.Size / 2
			local reach = math.abs(rotation.RightVector:Dot(up)) * half.X
				+ math.abs(rotation.UpVector:Dot(up)) * half.Y
				+ math.abs(rotation.LookVector:Dot(up)) * half.Z
			extreme = math.max(extreme, sign * descendant.Position:Dot(up) + reach)
		end
	end
	return sign * extreme
end

local function lowestOffset(model: Model, up: Vector3): number
	return extremeOffset(model, up, -1)
end

local function setQueryable(model: Model, isQueryable: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanQuery = isQueryable
		end
	end
end

local function includeParams(instances: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = instances
	return params
end

local function gapAbove(
	anvilPart: BasePart,
	point: Vector3,
	anvilParams: RaycastParams,
	weaponParams: RaycastParams
): number?
	local up = anvilPart.CFrame.UpVector
	local probe = ForgeStrikeConfig.SurfaceProbeHeight
	local origin = anvilPart.CFrame:PointToWorldSpace(point + Vector3.yAxis * probe)
	local surface = Workspace:Raycast(origin, -up * (probe * 2 + anvilPart.Size.Y), anvilParams)
	if surface == nil then
		return nil
	end
	local depth = ForgeStrikeConfig.SettleProbeDepth
	local start = surface.Position - up * depth
	local underside = Workspace:Raycast(start, up * (probe * 2 + depth), weaponParams)
	if underside == nil then
		return nil
	end
	return (underside.Position - surface.Position):Dot(up)
end

local function settleOnAnvil(model: Model, anvilPart: BasePart)
	local anvilParams = includeParams({ anvilPart })
	local weaponParams = includeParams({ model })
	local half = anvilPart.Size / 2
	local step = ForgeStrikeConfig.SettleProbeStep
	local drop = math.huge
	setQueryable(model, true)
	for x = -half.X, half.X, step do
		for z = -half.Z, half.Z, step do
			local gap = gapAbove(anvilPart, Vector3.new(x, half.Y, z), anvilParams, weaponParams)
			drop = if gap then math.min(drop, gap) else drop
		end
	end
	setQueryable(model, false)
	if drop < math.huge then
		model:PivotTo(model:GetPivot() - anvilPart.CFrame.UpVector * drop)
	end
end

local function alignToForgePoint(model: Model, forgePoint: Attachment)
	local target = forgePoint.WorldCFrame
	local anchor = model:FindFirstChild(names.WeaponAnchor, true)
	if anchor and anchor:IsA("Attachment") then
		model:PivotTo(target * anchor.WorldCFrame:ToObjectSpace(model:GetPivot()))
		return
	end
	model:PivotTo(target * ForgeStrikeConfig.WeaponRotation)
	local center = model:GetBoundingBox().Position
	local up = target.UpVector
	local horizontal = (target.Position - center) - up * (target.Position - center):Dot(up)
	local lift = target.Position:Dot(up) - lowestOffset(model, up)
	model:PivotTo(model:GetPivot() + horizontal + up * lift)
	local anvilPart = forgePoint.Parent
	if anvilPart and anvilPart:IsA("BasePart") then
		settleOnAnvil(model, anvilPart)
	end
end

function ForgeStation.GetAnvilPart(anvil: Instance): BasePart?
	if anvil:IsA("BasePart") then
		return anvil
	end
	if anvil:IsA("Model") and anvil.PrimaryPart then
		return anvil.PrimaryPart
	end
	return anvil:FindFirstChildWhichIsA("BasePart", true)
end

function ForgeStation.EnsurePoints(anvilPart: BasePart): (Attachment, Attachment)
	checkSize(anvilPart)
	local forgePoint = ensureAttachment(anvilPart, names.ForgePoint, ForgeStrikeConfig.ForgePointOffset)
	local impactPoint = ensureAttachment(anvilPart, names.ImpactPoint, ForgeStrikeConfig.ImpactPointOffset)
	return forgePoint, impactPoint
end

function ForgeStation.GetStandCFrame(anvilPart: BasePart): CFrame
	return anvilPart.CFrame * ForgeStrikeConfig.StandOffset
end

function ForgeStation.GetEyeCFrame(anvilPart: BasePart): CFrame
	local stand = ForgeStation.GetStandCFrame(anvilPart)
	local pitch = CFrame.Angles(math.rad(ForgeViewConfig.CameraPitch), 0, 0)
	return CFrame.new(stand:PointToWorldSpace(ForgeViewConfig.EyeOffset)) * stand.Rotation * pitch
end

function ForgeStation.GetPanelCFrame(anvilPart: BasePart): CFrame
	local eye = ForgeStation.GetEyeCFrame(anvilPart)
	return eye * CFrame.new(ForgeViewConfig.PanelViewOffset) * CFrame.Angles(0, math.pi, 0)
end

local function probeHeight(anvilPart: BasePart, params: RaycastParams?, point: Vector3): number
	if params == nil then
		return 0
	end
	local probe = ForgeStrikeConfig.SurfaceProbeHeight
	local origin = anvilPart.CFrame:PointToWorldSpace(Vector3.new(point.X, probe, point.Z))
	local hit = Workspace:Raycast(origin, -anvilPart.CFrame.UpVector * probe * 2, params)
	if hit == nil then
		return 0
	end
	local height = anvilPart.CFrame:PointToObjectSpace(hit.Position).Y - anvilPart.Size.Y / 2
	return math.max(height, 0)
end

local function measureSurfaces(anvilPart: BasePart, weapon: Model): { number }
	local params = includeParams({ weapon })
	local heights: { number } = {}
	setQueryable(weapon, true)
	for index, point in ForgeHammerProfile do
		heights[index] = probeHeight(anvilPart, params, point)
	end
	setQueryable(weapon, false)
	return heights
end

local function getOverlap(heights: { number }): (number, number)
	local overlap, contactHeight = -math.huge, 0
	for index, point in ForgeHammerProfile do
		local needed = heights[index] + ForgeStrikeConfig.StrikeClearance - point.Y
		if needed > overlap then
			overlap, contactHeight = needed, heights[index]
		end
	end
	return overlap, contactHeight
end

local function getFlattenFactor(heights: { number }, base: number): number
	local factor = 1
	for index, point in ForgeHammerProfile do
		local height = heights[index]
		if height > base then
			local allowed = math.max(point.Y - ForgeStrikeConfig.StrikeClearance - base, 0)
			factor = math.min(factor, allowed / (height - base))
		end
	end
	return factor
end

local function axisScale(axis: Vector3, up: Vector3, factor: number): number
	local alignment = axis:Dot(up)
	return 1 - (1 - factor) * alignment * alignment
end

local function halfReach(frame: CFrame, size: Vector3, up: Vector3): number
	return math.abs(frame.RightVector:Dot(up)) * size.X / 2
		+ math.abs(frame.UpVector:Dot(up)) * size.Y / 2
		+ math.abs(frame.LookVector:Dot(up)) * size.Z / 2
end

local function flatten(model: Model, anvilPart: BasePart, base: number, factor: number)
	local up = anvilPart.CFrame.UpVector
	local plane = anvilPart.Position:Dot(up) + anvilPart.Size.Y / 2 + base
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local frame = descendant.CFrame
			local size = descendant.Size
			local bottom = frame.Position:Dot(up) - halfReach(frame, size, up) - plane
			local newSize = Vector3.new(
				size.X * axisScale(frame.RightVector, up, factor),
				size.Y * axisScale(frame.UpVector, up, factor),
				size.Z * axisScale(frame.LookVector, up, factor)
			)
			local newCenter = plane + bottom * factor + halfReach(frame, newSize, up)
			descendant.Size = newSize
			descendant.CFrame = frame + up * (newCenter - frame.Position:Dot(up))
		end
	end
end

local function raise(model: Model, anvilPart: BasePart, distance: number)
	model:PivotTo(model:GetPivot() + anvilPart.CFrame.UpVector * distance)
end

local function seatAboveAnvil(model: Model, anvilPart: BasePart)
	settleOnAnvil(model, anvilPart)
	raise(model, anvilPart, ForgeStrikeConfig.AnvilGap)
end

function ForgeStation.FitUnderHammer(anvilPart: BasePart, weapon: Model?): number
	if weapon == nil then
		return 0
	end
	local base = ForgeStrikeConfig.AnvilGap
	seatAboveAnvil(weapon, anvilPart)
	for _ = 1, ForgeStrikeConfig.FitIterations do
		local heights = measureSurfaces(anvilPart, weapon)
		if getOverlap(heights) <= ForgeStrikeConfig.FitTolerance then
			break
		end
		flatten(weapon, anvilPart, base, getFlattenFactor(heights, base))
		seatAboveAnvil(weapon, anvilPart)
	end
	local overlap, contactHeight = getOverlap(measureSurfaces(anvilPart, weapon))
	if overlap < 0 then
		raise(weapon, anvilPart, -overlap)
		return contactHeight - overlap
	end
	return contactHeight
end

function ForgeStation.PlaceWeapon(forgePoint: Attachment, model: Model, parent: Instance): Model
	local clone = prepareClone(model)
	scaleToLength(clone, ForgeStrikeConfig.WeaponLength)
	clone.Parent = parent
	alignToForgePoint(clone, forgePoint)
	return clone
end

return ForgeStation
