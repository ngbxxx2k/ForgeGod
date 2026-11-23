--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SOUNDS_FOLDER_NAME = "Sounds"
local CLICK_SOUND_NAME = "UiClick"
local HOVER_SOUND_NAME = "UiHover"
local OPEN_SOUND_NAME = "UiOpen"
local SELL_SOUND_NAME = "UiSell"
local NO_SOUND_ATTRIBUTE = "NoUiSound"
local NO_HOVER_SOUND_ATTRIBUTE = "NoHoverSound"
local OPEN_SOUND_DURATION = 1

local UiSound = {}

local isInitialized = false
local clickSound: Sound? = nil
local hoverSound: Sound? = nil
local openSound: Sound? = nil
local sellSound: Sound? = nil
local attachedButtons: { [GuiButton]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local watchedFrames: { [GuiObject]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function play(sound: Sound?)
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

local function findSound(folder: Instance, name: string): Sound?
	local sound = folder:WaitForChild(name)
	if not sound:IsA("Sound") then
		warn("[UiSound] Not a Sound:", name)
		return nil
	end
	return sound
end

local function fitOpenSoundSpeed(sound: Sound)
	if not sound.IsLoaded then
		sound.Loaded:Wait()
	end
	if sound.TimeLength > OPEN_SOUND_DURATION then
		sound.PlaybackSpeed = sound.TimeLength / OPEN_SOUND_DURATION
	end
end

local function attachButton(button: GuiButton)
	if attachedButtons[button] or button:GetAttribute(NO_SOUND_ATTRIBUTE) == true then
		return
	end
	attachedButtons[button] = true
	button.MouseEnter:Connect(function()
		if button:GetAttribute(NO_HOVER_SOUND_ATTRIBUTE) ~= true then
			play(hoverSound)
		end
	end)
	button.Activated:Connect(function()
		play(clickSound)
	end)
end

local function tryAttach(instance: Instance)
	if instance:IsA("GuiButton") then
		attachButton(instance)
	end
end

function UiSound.AttachButton(button: GuiButton)
	attachButton(button)
end

function UiSound.PlayOpen()
	play(openSound)
end

function UiSound.PlaySell()
	play(sellSound)
end

function UiSound.WatchOpen(frame: GuiObject)
	if watchedFrames[frame] then
		return
	end
	watchedFrames[frame] = true
	frame:GetPropertyChangedSignal("Visible"):Connect(function()
		if frame.Visible then
			UiSound.PlayOpen()
		end
	end)
end

function UiSound.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	local folder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild(SOUNDS_FOLDER_NAME)
	clickSound = findSound(folder, CLICK_SOUND_NAME)
	hoverSound = findSound(folder, HOVER_SOUND_NAME)
	openSound = findSound(folder, OPEN_SOUND_NAME)
	sellSound = findSound(folder, SELL_SOUND_NAME)
	local sound = openSound
	if sound then
		task.spawn(fitOpenSoundSpeed, sound)
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, descendant in playerGui:GetDescendants() do
		tryAttach(descendant)
	end
	playerGui.DescendantAdded:Connect(tryAttach)
end

return UiSound
