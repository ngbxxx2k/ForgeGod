--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local CutsceneGuiHider = {}

type SavedState = {
	ScreenGuis: { [ScreenGui]: boolean },
	CoreGuis: { [Enum.CoreGuiType]: boolean },
}

local function hideScreenGuis(saved: SavedState)
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui == nil then
		return
	end
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Enabled then
			saved.ScreenGuis[child] = true
			child.Enabled = false
		end
	end
end

local function hideCoreGuis(saved: SavedState)
	for _, coreType in Enum.CoreGuiType:GetEnumItems() do
		if coreType ~= Enum.CoreGuiType.All and StarterGui:GetCoreGuiEnabled(coreType) then
			saved.CoreGuis[coreType] = true
		end
	end
	local ok, err = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, false)
	if not ok then
		warn("[CutsceneGuiHider] Hide core gui failed:", err)
	end
end

local function restore(saved: SavedState)
	for gui in saved.ScreenGuis do
		if gui.Parent ~= nil then
			gui.Enabled = true
		end
	end
	for coreType in saved.CoreGuis do
		local ok, err = pcall(StarterGui.SetCoreGuiEnabled, StarterGui, coreType, true)
		if not ok then
			warn("[CutsceneGuiHider] Restore core gui failed:", err)
		end
	end
end

function CutsceneGuiHider.Hide(): () -> ()
	local saved: SavedState = { ScreenGuis = {}, CoreGuis = {} }
	hideScreenGuis(saved)
	hideCoreGuis(saved)
	local isRestored = false
	return function()
		if isRestored then
			return
		end
		isRestored = true
		restore(saved)
	end
end

return CutsceneGuiHider
