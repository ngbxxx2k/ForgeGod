--!strict

local ScreenRegistry = {}

local closeHandlers: { [GuiObject]: () -> () } = {}

function ScreenRegistry.Register(frame: GuiObject, close: (() -> ())?)
	closeHandlers[frame] = close or function()
		frame.Visible = false
	end
	frame.Destroying:Connect(function()
		closeHandlers[frame] = nil
	end)
end

function ScreenRegistry.CloseAllExcept(keep: GuiObject)
	for frame, close in closeHandlers do
		if frame ~= keep and frame.Visible then
			close()
		end
	end
end

return ScreenRegistry
