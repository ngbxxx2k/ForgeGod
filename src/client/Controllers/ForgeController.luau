--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)
local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local ForgeScreen = require(script.Parent.Parent.UI.Screens.ForgeScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local ForgeStrikeFx = require(script.Parent.Parent.Effects.ForgeStrikeFx)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)

type ForgeResult = ForgeScreen.ForgeResult
type WeaponSummary = PlayerStateTypes.WeaponSummary

local REMOTES_FOLDER_NAME = "Remotes"
local BROKEN_STATE = "Broken"

local ForgeController = {}

local isInitialized = false
local isOpen = false
local isWeaponLost = false
local selectedWeaponId: string? = nil
local weaponLostHandler: (() -> ())? = nil
local isPreviewPending = false
local lastClickAt = 0
local requestForge: RemoteEvent? = nil
local requestPreview: RemoteEvent? = nil
local lastResult: ForgeResult? = nil
local chancesWeaponId: string? = nil
local chances: { [string]: number } = {}

local function getActiveWeapon(): WeaponSummary?
	local state = PlayerStateController.GetState()
	if state == nil then
		return nil
	end
	for _, weapon in state.Weapons do
		if weapon.Id == selectedWeaponId then
			return weapon
		end
	end
	return nil
end

local function requestChances()
	local remote = requestPreview
	if remote and not isPreviewPending then
		isPreviewPending = true
		remote:FireServer()
	end
end

local function renderEmpty()
	ForgeScreen.Render({
		WeaponName = ForgeMessages.NoWeaponName,
		Level = 0,
		Value = 0,
		ForgePoints = 0,
		MaxForgePoints = ForgeConfig.MaxForgePoints,
		Chances = {},
		LastResult = lastResult,
	})
	if lastResult == nil then
		ForgeScreen.ShowMessage(ForgeMessages.Reasons.NoWeaponEquipped)
	end
end

local function render()
	local weapon = getActiveWeapon()
	if weapon == nil then
		renderEmpty()
		return
	end
	local hasChances = chancesWeaponId == weapon.Id
	if not hasChances then
		requestChances()
	end
	ForgeScreen.Render({
		WeaponName = InventoryItems.GetWeaponName(weapon),
		Level = weapon.Level,
		Value = weapon.Value,
		ForgePoints = weapon.ForgePoints,
		MaxForgePoints = ForgeConfig.MaxForgePoints,
		Chances = if hasChances then chances else {},
		LastResult = lastResult,
	})
end

local function toScreenResult(result: any): ForgeResult
	return {
		OutcomeId = result.OutcomeId,
		PointDelta = result.PointDelta,
		ValueDelta = result.ValueDelta,
		Multiplier = result.Multiplier,
		FrenzyTimeLeft = result.FrenzyTimeLeft,
		IsShapeChanged = result.IsShapeChanged,
	}
end

local function handleWeaponBroken(weaponId: string)
	isWeaponLost = true
	Toast.Show(ForgeMessages.NotificationTitle, ForgeMessages.WeaponBrokeText)
	task.delay(ForgeConfig.BreakReturnDelay, function()
		local handler = weaponLostHandler
		if isOpen and isWeaponLost and selectedWeaponId == weaponId and handler then
			handler()
		end
	end)
end

local function onForgeResult(ok: any, reason: any, result: any)
	if ok ~= true or type(result) ~= "table" then
		if isOpen and not isWeaponLost then
			local message = type(reason) == "string" and ForgeMessages.Reasons[reason]
			ForgeScreen.ShowMessage(message or ForgeMessages.UnknownError)
		end
		return
	end
	if result.WeaponId ~= selectedWeaponId then
		return
	end
	lastResult = toScreenResult(result)
	chancesWeaponId = result.WeaponId
	chances = result.Chances
	if isOpen then
		render()
	end
	if result.IsProtected == true then
		Toast.Show(ForgeMessages.NotificationTitle, ForgeMessages.WeaponProtectedText)
	end
	if result.State == BROKEN_STATE and not isWeaponLost then
		handleWeaponBroken(result.WeaponId)
	end
end

local function onPreview(ok: any, _reason: any, preview: any)
	isPreviewPending = false
	if ok ~= true or type(preview) ~= "table" then
		return
	end
	chancesWeaponId = preview.WeaponId
	chances = preview.Chances
	if isOpen then
		render()
	end
end

local function startStrikeFx()
	local worldFolder = Workspace:FindFirstChild(StationConfig.WorldFolderName)
	local anvil = worldFolder and worldFolder:FindFirstChild(StationConfig.ForgeModelName)
	local hammer = worldFolder and worldFolder:FindFirstChild(ForgeStrikeConfig.HammerModelName)
	if anvil == nil or hammer == nil then
		warn("[ForgeController] Missing anvil or hammer in", StationConfig.WorldFolderName)
		return
	end
	ForgeStrikeFx.Start(anvil, hammer)
end

local function isClickInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if not isOpen or gameProcessed or not isClickInput(input) then
		return
	end
	local now = os.clock()
	if now - lastClickAt < ForgeConfig.ClickCooldown then
		return
	end
	local weapon = getActiveWeapon()
	local remote = requestForge
	if isWeaponLost or weapon == nil or weapon.State == BROKEN_STATE or remote == nil then
		return
	end
	lastClickAt = now
	remote:FireServer(weapon.Id)
	ForgeStrikeFx.Strike()
end

function ForgeController.Open(weaponId: string)
	isOpen = true
	isWeaponLost = false
	selectedWeaponId = weaponId
	lastResult = nil
	chancesWeaponId = nil
	render()
	ForgeScreen.SetVisible(true)
	startStrikeFx()
end

function ForgeController.Close()
	isOpen = false
	isWeaponLost = false
	selectedWeaponId = nil
	ForgeScreen.SetVisible(false)
	ForgeStrikeFx.Stop()
end

function ForgeController.SetWeaponLostHandler(handler: () -> ())
	weaponLostHandler = handler
end

function ForgeController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER_NAME)
	requestForge = remotes:WaitForChild(RemoteNames.RequestForge) :: RemoteEvent
	requestPreview = remotes:WaitForChild(RemoteNames.RequestForgePreview) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyForgeResult) :: RemoteEvent
	local previewRemote = remotes:WaitForChild(RemoteNames.NotifyForgePreview) :: RemoteEvent

	resultRemote.OnClientEvent:Connect(onForgeResult)
	previewRemote.OnClientEvent:Connect(onPreview)
	ForgeScreen.SetCloseHandler(ForgeController.Close)
	PlayerStateController.OnChanged(function()
		if isOpen then
			render()
		end
	end)
	UserInputService.InputBegan:Connect(onInputBegan)
end

return ForgeController
