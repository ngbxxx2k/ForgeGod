--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)

local WELD_NAME = "HammerGripWeld"

local ForgeHammer = {}

local names = ForgeStrikeConfig.AttachmentNames

local function ensureAttachment(part: BasePart, name: string, offset: CFrame): Attachment
	local existing = part:FindFirstChild(name)
	if existing and existing:IsA("Attachment") then
		return existing
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = offset
	attachment.Parent = part
	return attachment
end

local function getHandle(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function prepareParts(root: Instance, handle: BasePart)
	local parts: { Instance } = if root:IsA("BasePart") then { root } else {}
	for _, descendant in root:GetDescendants() do
		table.insert(parts, descendant)
	end
	for _, item in parts do
		if item:IsA("BasePart") then
			item.Anchored = false
			item.CanCollide = false
			item.CanQuery = false
			item.CanTouch = false
			item.Massless = true
			if item ~= handle then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = item
				weld.Parent = item
			end
		end
	end
end

function ForgeHammer.Attach(character: Model, template: Instance): Instance?
	local hand = character:FindFirstChild(ForgeStrikeConfig.HandPartName)
	if hand == nil or not hand:IsA("BasePart") then
		warn("[ForgeHammer] Character has no", ForgeStrikeConfig.HandPartName)
		return nil
	end
	local hammer = template:Clone()
	local handle = getHandle(hammer)
	if handle == nil then
		warn("[ForgeHammer] Hammer has no BasePart")
		hammer:Destroy()
		return nil
	end
	prepareParts(hammer, handle)
	local handGrip = ensureAttachment(hand, names.HandGrip, ForgeStrikeConfig.HandGrip)
	local hammerGrip = ensureAttachment(handle, names.HammerGrip, ForgeStrikeConfig.HammerGrip)
	local weld = Instance.new("Weld")
	weld.Name = WELD_NAME
	weld.Part0 = hand
	weld.Part1 = handle
	weld.C0 = handGrip.CFrame
	weld.C1 = hammerGrip.CFrame
	weld.Parent = handle
	hammer.Parent = character
	return hammer
end

return ForgeHammer
