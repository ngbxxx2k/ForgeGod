--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

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

local function prepareClone(model: Model): Model
	local clone = model:Clone()
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	return clone
end

local function lowestOffset(model: Model, up: Vector3): number
	local lowest = math.huge
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local rotation = descendant.CFrame
			local half = descendant.Size / 2
			local reach = math.abs(rotation.RightVector:Dot(up)) * half.X
				+ math.abs(rotation.UpVector:Dot(up)) * half.Y
				+ math.abs(rotation.LookVector:Dot(up)) * half.Z
			lowest = math.min(lowest, descendant.Position:Dot(up) - reach)
		end
	end
	return lowest
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

function ForgeStation.PlaceWeapon(forgePoint: Attachment, model: Model, parent: Instance): Model
	local clone = prepareClone(model)
	clone.Parent = parent
	alignToForgePoint(clone, forgePoint)
	return clone
end

return ForgeStation
