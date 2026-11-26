--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)

export type Step = {
	Id: string,
	ServerEvent: string?,
	ResumeStepId: string?,
	Icon: string,
}

local TutorialConfig = {}

TutorialConfig.Events = {
	OreDug = "OreDug",
	Smelted = "Smelted",
	ForgeEntered = "ForgeEntered",
	Forged = "Forged",
	ForgeLeft = "ForgeLeft",
	WeaponEquipped = "WeaponEquipped",
}

local Events = TutorialConfig.Events
local Icons = AssetIds.Icons

TutorialConfig.Steps = {
	{ Id = "GoToDigSite", Icon = Icons.DigSite },
	{ Id = "DigOres", ServerEvent = Events.OreDug, Icon = Icons.DigSite },
	{ Id = "OpenCrucible", Icon = Icons.OreCrucible },
	{ Id = "SmeltOres", ServerEvent = Events.Smelted, ResumeStepId = "OpenCrucible", Icon = Icons.OreCrucible },
	{ Id = "CloseFurnace", ResumeStepId = "SelectWeapon", Icon = Icons.OreCrucible },
	{ Id = "SelectWeapon", ServerEvent = Events.ForgeEntered, Icon = Icons.TabWeapon },
	{ Id = "StrikeOnce", ServerEvent = Events.Forged, ResumeStepId = "SelectWeapon", Icon = Icons.TabWeapon },
	{ Id = "ExitForge", ServerEvent = Events.ForgeLeft, ResumeStepId = "OpenLoadout", Icon = Icons.TabWeapon },
	{ Id = "OpenLoadout", Icon = Icons.TabWeapon },
	{ Id = "EquipWeapon", ServerEvent = Events.WeaponEquipped, ResumeStepId = "OpenLoadout", Icon = Icons.TabWeapon },
	{ Id = "CloseLoadout", ResumeStepId = "ViewUpgrades", Icon = Icons.TabWeapon },
	{ Id = "ViewUpgrades", Icon = Icons.UpgradeShop },
} :: { Step }

TutorialConfig.FirstStepId = TutorialConfig.Steps[1].Id
TutorialConfig.CompleteIcon = AssetIds.Tutorial.Check

TutorialConfig.DigTarget = 5
TutorialConfig.UpgradeTabIds = { "Anvil", "Hammer", "Shovel", "Detector" }
TutorialConfig.UpgradeTabSuffix = "Tab"
TutorialConfig.StrikeBlockedStepId = "ExitForge"
TutorialConfig.EquipBestBlockedStepIds = { "OpenLoadout", "EquipWeapon" }

TutorialConfig.CompleteDisplaySeconds = 6
TutorialConfig.ClientReportRetrySeconds = 1
TutorialConfig.TargetRefreshSeconds = 0.2

TutorialConfig.Panel = {
	RightAnchor = Vector2.new(1, 0),
	RightPosition = UDim2.fromScale(0.99, 0.115),
	LeftAnchor = Vector2.new(0, 0),
	LeftPosition = UDim2.fromScale(0.01, 0.115),
	BottomAnchor = Vector2.new(0.5, 1),
	BottomPosition = UDim2.fromScale(0.5, 0.985),
	BadgeColor = Color3.fromRGB(52, 132, 255),
	CompleteBadgeColor = Color3.fromRGB(70, 190, 60),
	IconColor = Color3.fromRGB(52, 132, 255),
	CompleteIconColor = Color3.fromRGB(70, 190, 60),
	BadgeNumberColor = "#FFD84A",
	FillTweenSeconds = 0.35,
}

TutorialConfig.Arrow = {
	Texture = AssetIds.Tutorial.Chevron,
	Width = 3,
	TextureLength = 3,
	TextureSpeed = 1.2,
	LightEmission = 0.4,
	Transparency = 0.05,
	SegmentLength = 6,
	MaxSegments = 80,
	GroundOffset = 0.25,
	RaycastHeight = 4,
	RaycastDepth = 30,
	StartGap = 2,
	StopDistance = 5,
}

TutorialConfig.Pointer = {
	Image = AssetIds.Tutorial.Hand,
	SizePixels = 72,
	BobPixels = 12,
	BobSpeed = 6,
	StrikeScreenPoint = Vector2.new(0.5, 0.62),
}

return TutorialConfig
