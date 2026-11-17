--!strict

local Players = game:GetService("Players")

local HUD_GUI_NAME = "HudGui"

local HudButton = {}

local function connectButton(hud: Instance, buttonName: string, onActivated: () -> ())
	if hud.Name ~= HUD_GUI_NAME then
		return
	end
	local button = hud:FindFirstChild(buttonName, true)
	if not button or not button:IsA("GuiButton") then
		warn("[HudButton] Missing", buttonName)
		return
	end
	button.Activated:Connect(onActivated)
end

function HudButton.Bind(buttonName: string, onActivated: () -> ())
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, child in playerGui:GetChildren() do
		connectButton(child, buttonName, onActivated)
	end
	playerGui.ChildAdded:Connect(function(child: Instance)
		connectButton(child, buttonName, onActivated)
	end)
end

return HudButton
