--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local HoldConfig = require(shared:WaitForChild("Config"):WaitForChild("HoldConfig"))
local PlayerAttributes = require(shared:WaitForChild("Constants"):WaitForChild("PlayerAttributes"))
local RemoteNames = require(shared:WaitForChild("Network"):WaitForChild("RemoteNames"))
local WeaponModelFinder = require(shared:WaitForChild("Utils"):WaitForChild("WeaponModelFinder"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local WeaponModelPrep = require(script.Parent.Parent.Internal.WeaponModelPrep)
local RateLimiter = require(script.Parent.Parent.Security.RateLimiter)

local REMOTES_FOLDER_NAME = "Remotes"
local RATE_LIMIT_KEY = "Equip"
local MAX_WEAPON_ID_LENGTH = 64

type Held = {
	WeaponId: string,
	ShapeStage: number,
	Model: Model,
	Track: AnimationTrack?,
}

local HoldService = {}

local isInitialized = false
local notifyHoldResult: RemoteEvent? = nil
local heldByPlayer: { [Player]: Held } = {}

local function sendResult(player: Player, ok: boolean, reason: string?)
	if notifyHoldResult ~= nil then
		notifyHoldResult:FireClient(player, ok, reason)
	end
end

local function release(player: Player)
	local held = heldByPlayer[player]
	heldByPlayer[player] = nil
	if held then
		held.Model:Destroy()
		local track = held.Track
		if track then
			track:Stop(HoldConfig.HoldFadeTime)
			track:Destroy()
		end
	end
	player:SetAttribute(PlayerAttributes.HeldWeaponId, nil)
end

local function playHoldAnimation(character: Instance): AnimationTrack?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator == nil then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = HoldConfig.HoldAnimationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok then
		warn("[HoldService] Failed to load hold animation:", track)
		return nil
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(HoldConfig.HoldFadeTime)
	return track
end

local function getGripCFrame(hand: BasePart): CFrame
	local grip = hand:FindFirstChild(HoldConfig.GripAttachmentName)
	local base = if grip and grip:IsA("Attachment") then grip.WorldCFrame else hand.CFrame
	return base * HoldConfig.GripRotation
end

local function weldToHand(model: Model, hand: BasePart)
	local boxCFrame, size = model:GetBoundingBox()
	local gripOffset = Vector3.yAxis * (size.Y * (0.5 - HoldConfig.GripFraction))
	local target = getGripCFrame(hand) * CFrame.new(gripOffset)
	model:PivotTo(target * boxCFrame:ToObjectSpace(model:GetPivot()))
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hand
			weld.Part1 = descendant
			weld.Parent = descendant
			descendant.Anchored = false
		end
	end
end

local function getHand(player: Player): BasePart?
	local character = player.Character
	local hand = character and character:FindFirstChild(HoldConfig.HandPartName)
	return if hand and hand:IsA("BasePart") then hand else nil
end

local function attach(player: Player, weapon: any): (boolean, string?)
	local hand = getHand(player)
	if hand == nil then
		return false, "NoCharacter"
	end
	local shapeStage = weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
	local source = WeaponModelFinder.Find(weapon.WeaponType, shapeStage)
	if source == nil then
		return false, "NoModel"
	end
	release(player)
	local model = WeaponModelPrep.Prepare(source, HoldConfig.ModelName, HoldConfig.WeaponLength)
	weldToHand(model, hand)
	model.Parent = hand.Parent
	local track = playHoldAnimation(hand.Parent :: Instance)
	heldByPlayer[player] = {
		WeaponId = weapon.Id,
		ShapeStage = shapeStage,
		Model = model,
		Track = track,
	}
	player:SetAttribute(PlayerAttributes.HeldWeaponId, weapon.Id)
	return true, nil
end

local function toggleHold(player: Player, weaponId: string): (boolean, string?)
	local held = heldByPlayer[player]
	if held and held.WeaponId == weaponId then
		release(player)
		return true, nil
	end
	local weapon, reason = DataActions.GetWeapon(player, weaponId)
	if weapon == nil then
		return false, reason
	end
	if weapon.State == DataTemplate.WeaponStates.Broken then
		return false, "WeaponBroken"
	end
	return attach(player, weapon)
end

local function onRequestHold(player: Player, weaponId: any)
	if type(weaponId) ~= "string" or #weaponId > MAX_WEAPON_ID_LENGTH then
		sendResult(player, false, "InvalidRequest")
		return
	end
	if not DataService.IsLoaded(player) then
		sendResult(player, false, "NotLoaded")
		return
	end
	if not RateLimiter.Check(player, RATE_LIMIT_KEY) then
		sendResult(player, false, "RateLimited")
		return
	end
	local ok, reason = toggleHold(player, weaponId)
	sendResult(player, ok, reason)
end

local function refreshHeld(player: Player)
	local held = heldByPlayer[player]
	if held == nil then
		return
	end
	local weapon = DataActions.GetWeapon(player, held.WeaponId)
	if weapon == nil or weapon.State == DataTemplate.WeaponStates.Broken then
		release(player)
		return
	end
	local shapeStage = weapon.ShapeStage or DataTemplate.Limits.MinShapeStage
	if shapeStage ~= held.ShapeStage then
		attach(player, weapon)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterRemoving:Connect(function()
		release(player)
	end)
end

local function getRemotesFolder(): Instance
	local remotesFolder = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME)
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = REMOTES_FOLDER_NAME
		remotesFolder.Parent = ReplicatedStorage
	end
	return remotesFolder :: Instance
end

local function createRemote(name: string, parent: Instance): RemoteEvent
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function HoldService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotesFolder = getRemotesFolder()
	local requestHold = createRemote(RemoteNames.RequestHoldWeapon, remotesFolder)
	notifyHoldResult = createRemote(RemoteNames.NotifyHoldResult, remotesFolder)

	requestHold.OnServerEvent:Connect(onRequestHold)
	DataActions.OnDataChanged(refreshHeld)
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		heldByPlayer[player] = nil
	end)
end

return HoldService
