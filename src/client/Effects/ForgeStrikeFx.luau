--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeHammer = require(script.Parent.ForgeHammer)
local ForgeImpactSound = require(script.Parent.ForgeImpactSound)
local ForgeSparks = require(script.Parent.ForgeSparks)
local ForgeStation = require(script.Parent.ForgeStation)

local ASSETS_FOLDER_NAME = "Assets"
local ANIMATIONS_FOLDER_NAME = "Animations"

type Session = {
	Character: Model,
	AnvilPart: BasePart,
	ForgePoint: Attachment,
	Hammer: Instance?,
	Track: AnimationTrack?,
	LoopConnection: RBXScriptConnection?,
	HitConnection: RBXScriptConnection?,
	LastTimePosition: number,
	Sparks: ForgeSparks.SparkSet?,
	Sounds: ForgeImpactSound.SoundSet,
	Weapon: Model?,
	LoopStartedAt: number,
	LastStrikeAt: number,
	StrikeInterval: number,
}

local ForgeStrikeFx = {}

local isInitialized = false
local session: Session? = nil
local runtimeFolder: Folder? = nil

local function getRuntimeFolder(): Folder
	local folder = runtimeFolder
	if folder and folder.Parent then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = ForgeStrikeConfig.RuntimeFolderName
	created.Parent = workspace
	runtimeFolder = created
	return created
end

local function findAnimation(): Animation?
	local assets = ReplicatedStorage:FindFirstChild(ASSETS_FOLDER_NAME)
	local folder = assets and assets:FindFirstChild(ANIMATIONS_FOLDER_NAME)
	local animation = folder and folder:FindFirstChild(ForgeStrikeConfig.AnimationName)
	if animation == nil or not animation:IsA("Animation") then
		warn("[ForgeStrikeFx] Missing animation:", ForgeStrikeConfig.AnimationName)
		return nil
	end
	if animation.AnimationId == "" then
		warn("[ForgeStrikeFx] AnimationId is empty:", animation.Name)
		return nil
	end
	return animation
end

local function loadTrack(character: Model): AnimationTrack?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local animation = findAnimation()
	if animator == nil or animation == nil then
		return nil
	end
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	return track
end

local function destroyWeapon(current: Session)
	if current.Weapon then
		current.Weapon:Destroy()
		current.Weapon = nil
	end
end

local function hasCrossedHit(previous: number, position: number): boolean
	local hitTime = ForgeStrikeConfig.HitTime
	if position >= previous then
		return previous < hitTime and position >= hitTime
	end
	return previous < hitTime or position >= hitTime
end

local function checkHit(current: Session, track: AnimationTrack)
	if not track.IsPlaying then
		current.LastTimePosition = 0
		return
	end
	local position = track.TimePosition
	if hasCrossedHit(current.LastTimePosition, position) then
		ForgeStrikeFx.Hit()
	end
	current.LastTimePosition = position
end

local function onLoop(current: Session, track: AnimationTrack)
	if current.LastStrikeAt <= current.LoopStartedAt then
		track:Stop(ForgeStrikeConfig.FadeTime)
		return
	end
	current.LoopStartedAt = os.clock()
end

local function updateSpeed(current: Session, track: AnimationTrack, now: number)
	local length = ForgeStrikeConfig.AnimationLength
	local interval = math.min(now - current.LastStrikeAt, length)
	local smoothing = ForgeStrikeConfig.StrikeSpeedSmoothing
	current.StrikeInterval += (interval - current.StrikeInterval) * smoothing
	local speed = math.clamp(length / current.StrikeInterval, 1, ForgeStrikeConfig.MaxStrikeSpeed)
	track:AdjustSpeed(speed)
end

function ForgeStrikeFx.Hit()
	local current = session
	if current == nil then
		return
	end
	if current.Sparks then
		ForgeSparks.Burst(current.Sparks)
	end
	ForgeImpactSound.Play(current.Sounds)
end

function ForgeStrikeFx.Strike()
	local current = session
	if current == nil then
		return
	end
	local now = os.clock()
	local track = current.Track
	if track == nil then
		current.LastStrikeAt = now
		ForgeStrikeFx.Hit()
		return
	end
	if track.IsPlaying then
		updateSpeed(current, track, now)
		current.LastStrikeAt = now
		return
	end
	current.LastStrikeAt = now
	current.LoopStartedAt = now
	current.StrikeInterval = ForgeStrikeConfig.AnimationLength
	current.LastTimePosition = 0
	track:Play(ForgeStrikeConfig.FadeTime, 1, 1)
end

function ForgeStrikeFx.SetForgeWeapon(model: Model?)
	local current = session
	if current == nil then
		return
	end
	destroyWeapon(current)
	if model then
		current.Weapon = ForgeStation.PlaceWeapon(current.ForgePoint, model, getRuntimeFolder())
	end
end

function ForgeStrikeFx.Stop()
	local current = session
	if current == nil then
		return
	end
	session = nil
	if current.LoopConnection then
		current.LoopConnection:Disconnect()
	end
	if current.HitConnection then
		current.HitConnection:Disconnect()
	end
	if current.Track then
		current.Track:Stop(ForgeStrikeConfig.FadeTime)
	end
	if current.Hammer then
		current.Hammer:Destroy()
	end
	if current.Sparks then
		ForgeSparks.Destroy(current.Sparks)
	end
	ForgeImpactSound.Destroy(current.Sounds)
	destroyWeapon(current)
end

function ForgeStrikeFx.Start(anvil: Instance, hammerTemplate: Instance): boolean
	ForgeStrikeFx.Stop()
	local character = Players.LocalPlayer.Character
	local anvilPart = ForgeStation.GetAnvilPart(anvil)
	if character == nil or anvilPart == nil then
		warn("[ForgeStrikeFx] Missing character or anvil part")
		return false
	end
	local forgePoint, impactPoint = ForgeStation.EnsurePoints(anvilPart)
	character:PivotTo(ForgeStation.GetStandCFrame(anvilPart))
	local current: Session = {
		Character = character,
		AnvilPart = anvilPart,
		ForgePoint = forgePoint,
		Hammer = ForgeHammer.Attach(character, hammerTemplate),
		Sparks = ForgeSparks.Create(impactPoint),
		Sounds = ForgeImpactSound.Create(impactPoint),
		LoopStartedAt = 0,
		LastStrikeAt = 0,
		StrikeInterval = ForgeStrikeConfig.AnimationLength,
		LastTimePosition = 0,
	}
	session = current
	local track = loadTrack(character)
	current.Track = track
	if track then
		current.LoopConnection = track.DidLoop:Connect(function()
			onLoop(current, track)
		end)
		current.HitConnection = RunService.Heartbeat:Connect(function()
			checkHit(current, track)
		end)
	end
	return track ~= nil
end

function ForgeStrikeFx.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		ForgeStrikeFx.Stop()
	end)
end

return ForgeStrikeFx
