--!strict

local StarterGui = game:GetService("StarterGui")

local NOTIFICATION_DURATION = 2

local Toast = {}

function Toast.Show(title: string, text: string)
	local ok, err = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = NOTIFICATION_DURATION,
		})
	end)
	if not ok then
		warn("[Toast] Notification failed:", err)
	end
end

return Toast
