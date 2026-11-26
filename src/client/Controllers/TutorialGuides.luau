--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FurnaceConfig = require(ReplicatedStorage.Shared.Config.FurnaceConfig)
local TutorialConfig = require(ReplicatedStorage.Shared.Config.TutorialConfig)
local TutorialMessages = require(ReplicatedStorage.Shared.Constants.TutorialMessages)
local PlayerStateTypes = require(ReplicatedStorage.Shared.Types.PlayerStateTypes)
local TutorialPointer = require(script.Parent.Parent.UI.Components.TutorialPointer)
local ForgeScreen = require(script.Parent.Parent.UI.Screens.ForgeScreen)
local ForgeUpgradeScreen = require(script.Parent.Parent.UI.Screens.ForgeUpgradeScreen)
local LoadoutScreen = require(script.Parent.Parent.UI.Screens.LoadoutScreen)
local TutorialScreen = require(script.Parent.Parent.UI.Screens.TutorialScreen)
local CrucibleStance = require(script.Parent.CrucibleStance)
local ForgeRevealController = require(script.Parent.ForgeRevealController)
local ForgeStance = require(script.Parent.ForgeStance)
local FurnaceController = require(script.Parent.FurnaceController)
local PlayerStateController = require(script.Parent.PlayerStateController)
local TutorialTargets = require(script.Parent.TutorialTargets)

type PlayerState = PlayerStateTypes.PlayerState
type TutorialState = PlayerStateTypes.TutorialState
type StepText = TutorialMessages.StepText
type PointResolver = TutorialPointer.PointResolver

export type ReportKind = "Advance" | "LeaveForge"

export type Guide = {
	World: Vector3?,
	Pointer: PointResolver?,
	Side: TutorialScreen.PanelSide,
	Text: StepText?,
	Progress: number,
	Report: ReportKind?,
}

local FORGED_STATE = "Forged"
local BROKEN_STATE = "Broken"

local Paths = TutorialTargets.Paths

local TutorialGuides = {}

local upgradeTabIndex = 1
local boundTabs: { [GuiButton]: boolean } = {}

local function newGuide(): Guide
	return { Side = "Right", Progress = 0 }
end

local function pointAtGui(path: { string }): PointResolver
	return function(): Vector2?
		return TutorialPointer.GuiCenter(TutorialTargets.Gui(path))
	end
end

local function pointAtObject(target: GuiObject?): PointResolver?
	if target == nil then
		return nil
	end
	return function(): Vector2?
		return TutorialPointer.GuiCenter(target)
	end
end

local function pointAtStrike(): Vector2?
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return nil
	end
	return TutorialPointer.FromViewport(camera.ViewportSize * TutorialConfig.Pointer.StrikeScreenPoint)
end

local function pointAtForgeExit(): Vector2?
	local point = ForgeScreen.GetExitButtonViewportPoint()
	return if point then TutorialPointer.FromViewport(point) else nil
end

local function goToDigSite(_: TutorialState, guide: Guide)
	if TutorialTargets.IsInDigZone() then
		guide.Report = "Advance"
		return
	end
	guide.World = TutorialTargets.DigSite()
end

local function digOres(tutorial: TutorialState, guide: Guide)
	local target = TutorialConfig.DigTarget
	local base = TutorialMessages.Steps.DigOres
	guide.Text = {
		Title = base.Title,
		Description = string.format(TutorialMessages.DigProgressFormat, tutorial.DigCount, target),
	}
	guide.Progress = tutorial.DigCount / target
	if not TutorialTargets.IsInDigZone() then
		guide.World = TutorialTargets.DigSite()
	end
end

local function openCrucible(_: TutorialState, guide: Guide)
	if CrucibleStance.IsActive() then
		guide.Report = "Advance"
		return
	end
	guide.World = TutorialTargets.Crucible()
end

local function smeltOres(_: TutorialState, guide: Guide)
	if not CrucibleStance.IsActive() then
		guide.World = TutorialTargets.Crucible()
		return
	end
	guide.Side = "Left"
	if not TutorialTargets.IsGuiVisible(Paths.FurnaceMain) then
		return
	end
	if FurnaceController.GetSelectedCount() >= FurnaceConfig.RecipeSize then
		guide.Pointer = pointAtGui(Paths.FurnaceStart)
		return
	end
	guide.Pointer = pointAtObject(TutorialTargets.FirstVisibleChild(Paths.FurnaceBagList, TutorialTargets.BagItemName))
end

local function closeFurnace(_: TutorialState, guide: Guide)
	if ForgeRevealController.IsPlaying() then
		guide.Side = "Left"
		return
	end
	if not CrucibleStance.IsActive() then
		guide.Report = "Advance"
		return
	end
	guide.Side = "Left"
	guide.Pointer = pointAtGui(Paths.FurnaceClose)
end

local function approachAnvil(guide: Guide)
	guide.Text = TutorialMessages.Steps.SelectWeapon
	if TutorialTargets.IsGuiVisible(Paths.PickerMain) then
		guide.Side = "Bottom"
		guide.Pointer = pointAtGui(Paths.PickerAction)
		return
	end
	guide.World = TutorialTargets.Anvil()
end

local function selectWeapon(_: TutorialState, guide: Guide)
	if not ForgeStance.IsActive() then
		approachAnvil(guide)
	end
end

local function strikeOnce(_: TutorialState, guide: Guide)
	if not ForgeStance.IsActive() then
		approachAnvil(guide)
		return
	end
	guide.Side = "Bottom"
	guide.Pointer = pointAtStrike
end

local function exitForge(_: TutorialState, guide: Guide)
	if not ForgeStance.IsActive() then
		guide.Report = "LeaveForge"
		return
	end
	guide.Side = "Bottom"
	guide.Pointer = pointAtForgeExit
end

local function openLoadout(_: TutorialState, guide: Guide)
	if LoadoutScreen.IsVisible() then
		guide.Report = "Advance"
		return
	end
	guide.Pointer = pointAtGui(Paths.LoadoutButton)
end

local function findTutorialWeapon(state: PlayerState): string?
	local fallback: string? = nil
	for _, weapon in state.Weapons do
		local isFree = weapon.State ~= BROKEN_STATE and table.find(state.Equipped, weapon.Id) == nil
		if isFree and weapon.State == FORGED_STATE then
			return weapon.Id
		end
		if isFree and fallback == nil then
			fallback = weapon.Id
		end
	end
	return fallback
end

local function equipWeapon(_: TutorialState, guide: Guide)
	if not LoadoutScreen.IsVisible() then
		guide.Pointer = pointAtGui(Paths.LoadoutButton)
		return
	end
	guide.Side = "Left"
	local state = PlayerStateController.GetState()
	local weaponId = state and findTutorialWeapon(state)
	if weaponId then
		guide.Pointer = pointAtObject(LoadoutScreen.FindEquipButton(weaponId))
	end
end

local function closeLoadout(_: TutorialState, guide: Guide)
	if not LoadoutScreen.IsVisible() then
		guide.Report = "Advance"
		return
	end
	guide.Side = "Left"
	guide.Pointer = pointAtGui(Paths.LoadoutClose)
end

local function getTabName(index: number): string?
	local tabId = TutorialConfig.UpgradeTabIds[index]
	return if tabId then tabId .. TutorialConfig.UpgradeTabSuffix else nil
end

local function onTabActivated(button: GuiButton)
	if button.Name == getTabName(upgradeTabIndex) then
		upgradeTabIndex += 1
	end
end

local function bindTabs()
	local tabBar = TutorialTargets.Gui(Paths.UpgradeTabBar)
	if tabBar == nil then
		return
	end
	for _, child in tabBar:GetChildren() do
		if child:IsA("GuiButton") and not boundTabs[child] then
			boundTabs[child] = true
			child.Activated:Connect(function()
				onTabActivated(child)
			end)
		end
	end
end

local function viewUpgrades(_: TutorialState, guide: Guide)
	if not ForgeUpgradeScreen.IsOpen() then
		guide.World = TutorialTargets.UpgradeShop()
		return
	end
	guide.Side = "Bottom"
	bindTabs()
	local tabCount = #TutorialConfig.UpgradeTabIds
	local tabName = getTabName(upgradeTabIndex)
	if tabName == nil then
		guide.Report = "Advance"
		guide.Progress = 1
		return
	end
	local tabId = TutorialConfig.UpgradeTabIds[upgradeTabIndex]
	guide.Text = {
		Title = TutorialMessages.UpgradeTabsTitle,
		Description = string.format(
			TutorialMessages.UpgradeTabFormat,
			TutorialMessages.UpgradeTabNames[tabId] or tabId,
			upgradeTabIndex,
			tabCount
		),
	}
	guide.Progress = (upgradeTabIndex - 1) / tabCount
	local tabPath = table.clone(Paths.UpgradeTabBar)
	table.insert(tabPath, tabName)
	guide.Pointer = pointAtGui(tabPath)
end

local BUILDERS: { [string]: (TutorialState, Guide) -> () } = {
	GoToDigSite = goToDigSite,
	DigOres = digOres,
	OpenCrucible = openCrucible,
	SmeltOres = smeltOres,
	CloseFurnace = closeFurnace,
	SelectWeapon = selectWeapon,
	StrikeOnce = strikeOnce,
	ExitForge = exitForge,
	OpenLoadout = openLoadout,
	EquipWeapon = equipWeapon,
	CloseLoadout = closeLoadout,
	ViewUpgrades = viewUpgrades,
}

function TutorialGuides.Build(tutorial: TutorialState): Guide
	local guide = newGuide()
	local builder = BUILDERS[tutorial.StepId]
	if builder then
		builder(tutorial, guide)
	end
	return guide
end

function TutorialGuides.ResetUpgradeTabs()
	upgradeTabIndex = 1
end

return TutorialGuides
