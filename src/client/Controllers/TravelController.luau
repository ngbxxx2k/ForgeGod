--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HudMessages = require(ReplicatedStorage.Shared.Constants.HudMessages)
local PlotStations = require(ReplicatedStorage.Shared.Utils.PlotStations)
local ShopZoneConfig = require(ReplicatedStorage.Shared.Config.ShopZoneConfig)
local TravelConfig = require(ReplicatedStorage.Shared.Config.TravelConfig)
local HudButton = require(script.Parent.Parent.UI.Components.HudButton)
local Toast = require(script.Parent.Parent.UI.Components.Toast)
local ShopScreen = require(script.Parent.Parent.UI.Screens.ShopScreen)
local ShopZoneController = require(script.Parent.ShopZoneController)
local CrucibleStance = require(script.Parent.CrucibleStance)
local ForgeStance = require(script.Parent.ForgeStance)

type ShopCategory = ShopScreen.ShopCategory

local HOME_BUTTON_NAME = "HomeButton"
local ORE_SHOP_BUTTON_NAME = "OreShopButton"
local ITEM_SHOP_BUTTON_NAME = "ItemShopButton"
local ROOT_PART_NAME = "HumanoidRootPart"

local TravelController = {}

local isInitialized = false
local localPlayer = Players.LocalPlayer

local function moveCameraBehind(stand: CFrame)
	local camera = Workspace.CurrentCamera
	if camera == nil or camera.CameraType ~= Enum.CameraType.Custom then
		return
	end
	local back = -stand.LookVector * TravelConfig.CameraBackDistance
	local eye = stand.Position + back + Vector3.yAxis * TravelConfig.CameraHeight
	camera.CFrame = CFrame.lookAt(eye, stand.Position)
end

local function teleportTo(ground: CFrame)
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild(ROOT_PART_NAME)
	if not character or not humanoid or not root or not root:IsA("BasePart") then
		return
	end
	if CrucibleStance.IsActive() or ForgeStance.IsActive() or humanoid.Health <= 0 then
		return
	end
	local lift = humanoid.HipHeight + root.Size.Y / 2
	local stand = ground + Vector3.yAxis * lift
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(stand)
	moveCameraBehind(stand)
end

local function goHome()
	local plot = PlotStations.FindOwnedPlot(localPlayer.UserId)
	if plot == nil then
		Toast.Show(HudMessages.TravelTitle, HudMessages.NoPlot)
		return
	end
	local stand = plot:GetPivot() * TravelConfig.HomeStandOffset
	teleportTo(CFrame.lookAt(stand.Position, stand.Position + plot:GetPivot().LookVector))
end

local function goToShop(category: ShopCategory)
	local center = ShopZoneController.GetZoneCenter(category)
	if center == nil then
		return
	end
	local distance = ShopZoneConfig.Radius + TravelConfig.ShopStandGap
	local stand = center * CFrame.new(0, 0, -distance)
	teleportTo(CFrame.lookAt(stand.Position, Vector3.new(center.X, stand.Y, center.Z)))
end

function TravelController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	HudButton.Bind(HOME_BUTTON_NAME, goHome)
	HudButton.Bind(ORE_SHOP_BUTTON_NAME, function()
		goToShop("Ore")
	end)
	HudButton.Bind(ITEM_SHOP_BUTTON_NAME, function()
		goToShop("Item")
	end)
end

return TravelController
