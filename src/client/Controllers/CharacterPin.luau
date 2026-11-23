--!strict

local ROOT_PART_NAME = "HumanoidRootPart"
local ATTACHMENT_NAME = "PinAttachment"
local ALIGN_POSITION_NAME = "PinPosition"
local ALIGN_ORIENTATION_NAME = "PinOrientation"

export type Pin = {
	Root: BasePart,
	Instances: { Instance },
}

local CharacterPin = {}

local function createAligns(root: BasePart, target: CFrame): { Instance }
	local attachment = Instance.new("Attachment")
	attachment.Name = ATTACHMENT_NAME
	attachment.Parent = root
	local alignPosition = Instance.new("AlignPosition")
	alignPosition.Name = ALIGN_POSITION_NAME
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.Attachment0 = attachment
	alignPosition.RigidityEnabled = true
	alignPosition.Position = target.Position
	alignPosition.Parent = root
	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = ALIGN_ORIENTATION_NAME
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.RigidityEnabled = true
	alignOrientation.CFrame = target.Rotation
	alignOrientation.Parent = root
	return { alignPosition, alignOrientation, attachment }
end

function CharacterPin.Pin(character: Model?, target: CFrame): Pin?
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	if character == nil or root == nil or not root:IsA("BasePart") then
		return nil
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(target)
	return { Root = root, Instances = createAligns(root, target) }
end

function CharacterPin.Unpin(pin: Pin?)
	if pin == nil then
		return
	end
	for _, instance in pin.Instances do
		instance:Destroy()
	end
	if pin.Root.Parent then
		pin.Root.AssemblyLinearVelocity = Vector3.zero
	end
end

return CharacterPin
