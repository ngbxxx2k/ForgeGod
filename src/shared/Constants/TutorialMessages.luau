--!strict

export type StepText = {
	Title: string,
	Description: string,
}

local TutorialMessages = {
	BadgeFormat = 'TUTORIAL <font color="%s">%d/%d</font>',
	CompleteTitle = "TUTORIAL COMPLETE!",
	CompleteDescription = "Keep forging weapons and upgrade your tools",
	DigProgressFormat = "Follow the detector signal and dig up ores (%d/%d)",
	UpgradeTabFormat = "Tap the %s tab (%d/%d)",
	UpgradeTabsTitle = "CHECK THE UPGRADES",
}

TutorialMessages.Steps = {
	GoToDigSite = {
		Title = "GO TO THE DIG SITE",
		Description = "Follow the arrows to the dig site",
	},
	DigOres = {
		Title = "FIND 5 ORES",
		Description = "Follow the detector signal and dig up ores",
	},
	OpenCrucible = {
		Title = "GO TO YOUR CRUCIBLE",
		Description = "Follow the arrows and press E at the crucible",
	},
	SmeltOres = {
		Title = "SMELT YOUR ORES",
		Description = "Pick 5 ores, then press Start",
	},
	CloseFurnace = {
		Title = "CLOSE THE CRUCIBLE",
		Description = "Press the X button to close it",
	},
	SelectWeapon = {
		Title = "GO TO YOUR ANVIL",
		Description = "Press E at the anvil and choose your new weapon",
	},
	StrikeOnce = {
		Title = "FORGE YOUR WEAPON",
		Description = "Click to strike the weapon once",
	},
	ExitForge = {
		Title = "LEAVE THE ANVIL",
		Description = "Press Exit to leave the anvil",
	},
	OpenLoadout = {
		Title = "OPEN YOUR LOADOUT",
		Description = "Press the Loadout button",
	},
	EquipWeapon = {
		Title = "EQUIP YOUR WEAPON",
		Description = "Press EQUIP on the weapon you forged",
	},
	CloseLoadout = {
		Title = "CLOSE THE LOADOUT",
		Description = "Equipped weapons earn money every second",
	},
	ViewUpgrades = {
		Title = "VISIT THE UPGRADE SHOP",
		Description = "Follow the arrows to the upgrade shop",
	},
} :: { [string]: StepText }

TutorialMessages.UpgradeTabNames = {
	Anvil = "Anvil",
	Hammer = "Hammer",
	Shovel = "Shovel",
	Detector = "Detector",
} :: { [string]: string }

return TutorialMessages
