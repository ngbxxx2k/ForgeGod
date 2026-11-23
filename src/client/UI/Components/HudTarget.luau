--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local HudTarget = {}

local function findButton(guiName: string, buttonName: string): GuiObject?
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	local gui = playerGui and playerGui:FindFirstChild(guiName)
	local button = gui and gui:FindFirstChild(buttonName, true)
	if button and button:IsA("GuiObject") and button.AbsoluteSize.Magnitude > 0 then
		return button
	end
	return nil
end

local function ignoresInset(button: GuiObject): boolean
	local screenGui = button:FindFirstAncestorOfClass("ScreenGui")
	return screenGui ~= nil and screenGui.IgnoreGuiInset
end

local function getScreenCenter(): Vector2
	return Workspace.CurrentCamera.ViewportSize / 2
end

function HudTarget.GetWorldPoint(guiName: string, buttonName: string, depth: number): Vector3
	local camera = Workspace.CurrentCamera
	local button = findButton(guiName, buttonName)
	if button == nil then
		local center = getScreenCenter()
		local ray = camera:ViewportPointToRay(center.X, camera.ViewportSize.Y)
		return ray.Origin + ray.Direction * depth
	end
	local point = button.AbsolutePosition + button.AbsoluteSize / 2
	local ray = if ignoresInset(button)
		then camera:ViewportPointToRay(point.X, point.Y)
		else camera:ScreenPointToRay(point.X, point.Y)
	return ray.Origin + ray.Direction * depth
end

return HudTarget
