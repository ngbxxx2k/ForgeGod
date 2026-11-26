--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)
local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeWheelConfig = require(ReplicatedStorage.Shared.Config.ForgeWheelConfig)
local StationConfig = require(ReplicatedStorage.Shared.Config.StationConfig)
local ForgeMessages = require(ReplicatedStorage.Shared.Constants.ForgeMessages)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local RemoteNames = require(ReplicatedStorage.Shared.Network.RemoteNames)
local WeaponIncome = require(ReplicatedStorage.Shared.Utils.WeaponIncome)
local WeaponMaxLevel = require(ReplicatedStorage.Shared.Utils.WeaponMaxLevel)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local ForgeScreen = require(script.Parent.Parent.UI.Screens.ForgeScreen)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local ForgeBreakFx = require(script.Parent.Parent.Effects.ForgeBreakFx)
local ForgeFrenzyFx = require(script.Parent.Parent.Effects.ForgeFrenzyFx)
local ForgeHammerSkin = require(script.Parent.Parent.Effects.ForgeHammerSkin)
local ForgeMutationFx = require(script.Parent.Parent.Effects.ForgeMutationFx)
local ForgeStrikeFx = require(script.Parent.Parent.Effects.ForgeStrikeFx)
local ForgeStation = require(script.Parent.Parent.Effects.ForgeStation)
local WeaponAssetPreloader = require(script.Parent.Parent.Effects.WeaponAssetPreloader)
local WeaponModels = require(script.Parent.Parent.Effects.WeaponModels)
local ForgePlayback = require(script.Parent.ForgePlayback)
local ForgeStance = require(script.Parent.ForgeStance)
local InventoryItems = require(script.Parent.InventoryItems)
local PlayerStateController = require(script.Parent.PlayerStateController)
local TutorialState = require(script.Parent.TutorialState)

type WeaponSummary = PlayerStateTypes.WeaponSummary

type Beat = {
	Id: number,
	EndsAt: number,
	IsResolved: boolean,
	FrenzyEndsAt: number?,
	HitAt: number,
}

local REMOTES_FOLDER_NAME = "Remotes"
local BROKEN_STATE = "Broken"

local ForgeController = {}

local isInitialized = false
local isOpen = false
local isWeaponLost = false
local selectedWeaponId: string? = nil
local weaponLostHandler: (() -> ())? = nil
local isPreviewPending = false
local requestForge: RemoteEvent? = nil
local requestPreview: RemoteEvent? = nil
local requestStance: RemoteEvent? = nil
local chancesWeaponId: string? = nil
local latestChances: { [string]: number } = {}
local currentBeat: Beat? = nil
local placedTemplate: Model? = nil
local modelToken = 0
local beatCounter = 0
local staleResponses = 0
local frenzyEndsAt = 0
local lockedUntil = 0
local cooldownToken = 0

local function isCoolingDown(): boolean
	local now = os.clock()
	return now >= frenzyEndsAt and now < lockedUntil
end

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

local function resolveName(result: any): (string, number)
	local weapon = getActiveWeapon()
	if weapon == nil then
		return ForgeMessages.NoWeaponName, WeaponMaxLevel.Get(nil)
	end
	local summary = table.clone(weapon)
	summary.State = if type(result.State) == "string" then result.State else weapon.State
	if type(result.ShapeStage) == "number" then
		summary.ShapeStage = result.ShapeStage
	end
	return InventoryItems.GetWeaponName(summary), WeaponMaxLevel.Get(weapon.Rarity)
end

local function isAtMaxLevel(weapon: WeaponSummary): boolean
	return WeaponMaxLevel.IsReached(weapon.Rarity, weapon.Level) and os.clock() >= frenzyEndsAt
end

local function requestChances()
	local remote, weaponId = requestPreview, selectedWeaponId
	if remote and weaponId and not isPreviewPending then
		isPreviewPending = true
		remote:FireServer(weaponId)
	end
end

local function render(isAnimated: boolean)
	local weapon = getActiveWeapon()
	if weapon == nil then
		ForgeScreen.Render({
			WeaponName = ForgeMessages.NoWeaponName,
			Level = 0,
			MaxLevel = WeaponMaxLevel.Get(nil),
			Value = 0,
			ForgePoints = 0,
			MaxForgePoints = ForgeConfig.MaxForgePoints,
		}, false)
		return
	end
	if chancesWeaponId ~= weapon.Id then
		requestChances()
	end
	ForgeScreen.Render({
		WeaponName = InventoryItems.GetWeaponName(weapon),
		Mutation = weapon.Mutation,
		Level = weapon.Level,
		MaxLevel = WeaponMaxLevel.Get(weapon.Rarity),
		Value = WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, false),
		ForgePoints = weapon.ForgePoints,
		MaxForgePoints = ForgeConfig.MaxForgePoints,
	}, isAnimated)
	if currentBeat == nil and isAtMaxLevel(weapon) then
		ForgeScreen.ShowMessage(ForgeMessages.MaxLevelText, ForgeMessages.MaxLevelDetailText)
	end
end

local function showNextChances(beatId: number)
	task.delay(ForgeWheelConfig.NextChancesDelay, function()
		local isSameRest = currentBeat == nil and beatCounter == beatId
		if not isOpen or not isSameRest or chancesWeaponId ~= selectedWeaponId then
			return
		end
		if next(latestChances) ~= nil then
			ForgeScreen.SetChances(latestChances, true)
			ForgePlayback.SettleNeedle()
		end
	end)
end

local function finishBeat(beat: Beat)
	if currentBeat ~= beat then
		return
	end
	currentBeat = nil
	if not isOpen then
		return
	end
	render(true)
	showNextChances(beat.Id)
	if isCoolingDown() then
		ForgeScreen.ShowMessage(ForgeMessages.CooldownText)
	end
end

local function scheduleCooldown(endsAt: number)
	frenzyEndsAt = endsAt
	lockedUntil = endsAt + ForgeConfig.FrenzyLockDuration
	cooldownToken += 1
	local token = cooldownToken
	local now = os.clock()
	task.delay(endsAt - now, function()
		if token == cooldownToken and isOpen and currentBeat == nil then
			ForgeScreen.ShowMessage(ForgeMessages.CooldownText)
		end
	end)
	task.delay(lockedUntil - now, function()
		if token == cooldownToken and isOpen and currentBeat == nil then
			ForgeScreen.ResetResult()
		end
	end)
end

local function handleWeaponBroken(weaponId: string)
	isWeaponLost = true
	ForgeBreakFx.Shatter(ForgeStrikeFx.GetWeapon())
	placedTemplate = nil
	ForgeStrikeFx.SetForgeWeapon(nil)
	Toast.Error(ForgeMessages.WeaponBrokeText)
	task.delay(ForgeConfig.BreakReturnDelay, function()
		local handler = weaponLostHandler
		if isOpen and isWeaponLost and selectedWeaponId == weaponId and handler then
			handler()
		end
	end)
end

local function showWeaponModel(template: Model?, isAnnounced: boolean)
	ForgeStrikeFx.SetForgeWeapon(template)
	if isAnnounced then
		ForgeStrikeFx.Hit()
	end
end

local function updateWeaponModel(shapeStage: number, isAnnounced: boolean)
	local template = WeaponModels.Find(getActiveWeapon(), shapeStage)
	if template == placedTemplate then
		return
	end
	placedTemplate = template
	modelToken += 1
	if template == nil or not isAnnounced then
		showWeaponModel(template, isAnnounced)
		return
	end
	local token = modelToken
	WeaponAssetPreloader.WhenReady(template, function()
		if isOpen and token == modelToken and not isWeaponLost then
			showWeaponModel(template, isAnnounced)
		end
	end)
end

local function onLanded(beat: Beat, result: any)
	if currentBeat ~= beat or not isOpen then
		return
	end
	if type(result.ShapeStage) == "number" and result.State ~= BROKEN_STATE then
		updateWeaponModel(result.ShapeStage, true)
	end
	if result.IsNewMutation == true and type(result.Mutation) == "string" then
		ForgeMutationFx.Strike(ForgeStrikeFx.GetAnvilPart(), result.Mutation)
	end
	local frenzyEndsAt = beat.FrenzyEndsAt
	if frenzyEndsAt then
		ForgeFrenzyFx.Start(frenzyEndsAt)
	end
	if result.IsProtected == true then
		Toast.Success(ForgeMessages.WeaponProtectedText)
	end
	if result.State == BROKEN_STATE and not isWeaponLost then
		handleWeaponBroken(result.WeaponId)
	end
	task.delay(math.max(beat.EndsAt - os.clock(), 0), finishBeat, beat)
end

local function getLandingTime(beat: Beat): number
	return math.max(beat.HitAt - os.clock(), ForgeWheelConfig.MinLandingTime)
end

local function resolveSuccess(beat: Beat, result: any)
	ForgePlayback.Land(result, getLandingTime(beat), function()
		onLanded(beat, result)
	end)
end

local function resolveFailure(beat: Beat, reason: any)
	local message = type(reason) == "string" and ForgeMessages.Reasons[reason]
	ForgePlayback.Halt(ForgeWheelConfig.HaltTime, function()
		if currentBeat ~= beat or not isOpen then
			return
		end
		if not isWeaponLost then
			ForgePlayback.ShowMessage(message or ForgeMessages.UnknownError)
		end
		task.delay(math.max(beat.EndsAt - os.clock(), 0), finishBeat, beat)
	end)
end

local function onForgeResult(ok: any, reason: any, result: any)
	if staleResponses > 0 then
		staleResponses -= 1
		return
	end
	local beat = currentBeat
	if beat == nil or beat.IsResolved or not isOpen then
		return
	end
	beat.IsResolved = true
	local isValid = ok == true and type(result) == "table" and result.WeaponId == selectedWeaponId
	if not isValid then
		resolveFailure(beat, reason)
		return
	end
	chancesWeaponId = result.WeaponId
	latestChances = result.Chances
	local frenzyTimeLeft = result.FrenzyTimeLeft
	if type(frenzyTimeLeft) == "number" and frenzyTimeLeft > 0 then
		beat.FrenzyEndsAt = os.clock() + frenzyTimeLeft
		scheduleCooldown(os.clock() + frenzyTimeLeft)
	end
	resolveSuccess(beat, result)
end

local function watchTimeout(beat: Beat)
	task.delay(ForgeWheelConfig.ResultTimeout, function()
		if currentBeat == beat and not beat.IsResolved then
			beat.IsResolved = true
			staleResponses += 1
			resolveFailure(beat, nil)
		end
	end)
end

local function onPreview(ok: any, _reason: any, preview: any)
	isPreviewPending = false
	if ok ~= true or type(preview) ~= "table" or preview.WeaponId ~= selectedWeaponId then
		return
	end
	chancesWeaponId = preview.WeaponId
	latestChances = preview.Chances
	if isOpen and currentBeat == nil then
		ForgeScreen.SetChances(latestChances, true)
	end
end

local function onUseItemResult(ok: any)
	if ok == true and isOpen and currentBeat == nil then
		requestChances()
	end
end

local function enterStation()
	local userId = Players.LocalPlayer.UserId
	local anvil = PlotStations.FindOwnedStation(userId, StationConfig.ForgeModelName)
	local hammer = ForgeHammerSkin.CreateTemplate(Players.LocalPlayer)
	local anvilPart = anvil and ForgeStation.GetAnvilPart(anvil)
	if anvil == nil or hammer == nil or anvilPart == nil then
		warn("[ForgeController] Missing anvil in own plot or hammer in Assets")
		return
	end
	ForgeStrikeFx.Start(anvil, hammer)
	hammer:Destroy()
	local weapon = getActiveWeapon()
	local shapeStage = weapon and weapon.ShapeStage or ForgeStrikeConfig.DefaultShapeStage
	WeaponAssetPreloader.PreloadWeaponType(if weapon then weapon.WeaponType else nil, shapeStage)
	updateWeaponModel(shapeStage, false)
	ForgeScreen.SetAdornee(ForgeStance.Enter(anvilPart))
end

local function canForge(weapon: WeaponSummary?): boolean
	if not isOpen or isWeaponLost or currentBeat ~= nil or isCoolingDown() then
		return false
	end
	return weapon ~= nil and weapon.State ~= BROKEN_STATE and not isAtMaxLevel(weapon)
end

local function startBeat(weaponId: string, remote: RemoteEvent)
	local duration = ForgeConfig.StrikeDuration
	beatCounter += 1
	local hitDelay = duration * ForgeStrikeConfig.HitTime / ForgeStrikeConfig.AnimationLength
	local now = os.clock()
	local beat: Beat = {
		Id = beatCounter,
		EndsAt = now + duration,
		IsResolved = false,
		HitAt = now + hitDelay,
	}
	currentBeat = beat
	remote:FireServer(weaponId)
	ForgeStrikeFx.Strike(duration)
	ForgePlayback.BeginSpin(hitDelay)
	watchTimeout(beat)
end

local function tryForge()
	local weapon = getActiveWeapon()
	local remote = requestForge
	if not canForge(weapon) or remote == nil or weapon == nil then
		return
	end
	if TutorialState.IsStrikeBlocked() then
		Toast.Error(ForgeMessages.Reasons.TutorialLocked)
		return
	end
	startBeat(weapon.Id, remote)
end

local function isClickInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function onInputBegan(input: InputObject, gameProcessed: boolean)
	if not isOpen or gameProcessed or not isClickInput(input) then
		return
	end
	local position = Vector2.new(input.Position.X, input.Position.Y)
	if ForgeScreen.IsOverExitButton(position) then
		ForgeController.Close()
		return
	end
	tryForge()
end

local function resetSession()
	local beat = currentBeat
	if beat and not beat.IsResolved then
		staleResponses += 1
	end
	currentBeat = nil
	placedTemplate = nil
	modelToken += 1
	ForgeFrenzyFx.Stop()
	ForgePlayback.Reset()
	isWeaponLost = false
	frenzyEndsAt = 0
	lockedUntil = 0
	cooldownToken += 1
	chancesWeaponId = nil
	latestChances = {}
end

function ForgeController.Open(weaponId: string)
	resetSession()
	isOpen = true
	selectedWeaponId = weaponId
	ForgeScreen.SetChances({}, false)
	ForgeScreen.ResetResult()
	render(false)
	enterStation()
	ForgeScreen.SetVisible(true)
	if requestStance then
		requestStance:FireServer(weaponId)
	end
end

function ForgeController.Close()
	if isOpen and requestStance then
		requestStance:FireServer(nil)
	end
	isOpen = false
	resetSession()
	selectedWeaponId = nil
	ForgeScreen.SetVisible(false)
	ForgeScreen.SetAdornee(nil)
	ForgeStance.Exit()
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
	requestStance = remotes:WaitForChild(RemoteNames.RequestForgeStance) :: RemoteEvent
	local resultRemote = remotes:WaitForChild(RemoteNames.NotifyForgeResult) :: RemoteEvent
	local previewRemote = remotes:WaitForChild(RemoteNames.NotifyForgePreview) :: RemoteEvent

	ForgePlayback.SetNameResolver(resolveName)
	resultRemote.OnClientEvent:Connect(onForgeResult)
	previewRemote.OnClientEvent:Connect(onPreview)
	local useResultRemote = remotes:WaitForChild(RemoteNames.NotifyUseItemResult) :: RemoteEvent
	useResultRemote.OnClientEvent:Connect(onUseItemResult)
	ForgeScreen.SetCloseHandler(ForgeController.Close)
	PlayerStateController.OnChanged(function(state)
		WeaponAssetPreloader.QueueWeapons(state.Weapons)
		if isOpen and currentBeat == nil then
			render(true)
		end
	end)
	UserInputService.InputBegan:Connect(onInputBegan)
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		if isOpen then
			ForgeController.Close()
		end
	end)
end

return ForgeController
