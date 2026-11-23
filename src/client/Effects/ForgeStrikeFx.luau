--!strict

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local ForgeHammer = require(script.Parent.ForgeHammer)
local ForgeImpactSound = require(script.Parent.ForgeImpactSound)
local ForgeSparks = require(script.Parent.ForgeSparks)
local ForgeStation = require(script.Parent.ForgeStation)
local ForgeWeaponImpact = require(script.Parent.ForgeWeaponImpact)

local ASSETS_FOLDER_NAME = "Assets"
local ANIMATIONS_FOLDER_NAME = "Animations"

type Session = {
	Character: Model,
	AnvilPart: BasePart,
	ForgePoint: Attachment,
	ImpactPoint: Attachment,
	StrikeToken: number,
	Hammer: Instance?,
	Track: AnimationTrack?,
	HitConnection: RBXScriptConnection?,
	LastTimePosition: number,
	Sparks: ForgeSparks.SparkSet?,
	Sounds: ForgeImpactSound.SoundSet,
	Weapon: Model?,
	WeaponPivot: CFrame?,
}

local ForgeStrikeFx = {}

local isInitialized = false
local session: Session? = nil
local hitHandler: (() -> ())? = nil
local isRainbowSparks = false
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
	task.spawn(function()
		local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, { animation })
		if not ok then
			warn("[ForgeStrikeFx] Preload failed:", err)
		end
	end)
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	return track
end

local function destroyWeapon(current: Session)
	ForgeWeaponImpact.Stop()
	if current.Weapon then
		current.Weapon:Destroy()
		current.Weapon = nil
	end
	current.WeaponPivot = nil
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

local function holdReadyPose(current: Session, track: AnimationTrack)
	if not track.IsPlaying then
		track:Play(ForgeStrikeConfig.FadeTime, 1, 0)
	end
	track:AdjustSpeed(0)
	track.TimePosition = 0
	current.LastTimePosition = 0
end

function ForgeStrikeFx.Hit()
	local current = session
	if current == nil then
		return
	end
	if current.Sparks then
		ForgeSparks.Burst(current.Sparks)
	end
	if current.Weapon and current.WeaponPivot then
		ForgeWeaponImpact.Play(current.Weapon, current.WeaponPivot)
	end
	ForgeImpactSound.Play(current.Sounds)
	local handler = hitHandler
	if handler then
		handler()
	end
end

function ForgeStrikeFx.SetHitHandler(handler: (() -> ())?)
	hitHandler = handler
end

function ForgeStrikeFx.GetWeapon(): Model?
	local current = session
	return if current then current.Weapon else nil
end

function ForgeStrikeFx.GetAnvilPart(): BasePart?
	local current = session
	return if current then current.AnvilPart else nil
end

function ForgeStrikeFx.GetImpactPoint(): Attachment?
	local current = session
	return if current then current.ImpactPoint else nil
end

function ForgeStrikeFx.SetRainbowSparks(isRainbow: boolean)
	isRainbowSparks = isRainbow
	local current = session
	if current and current.Sparks then
		ForgeSparks.SetRainbow(current.Sparks, isRainbow)
	end
end

function ForgeStrikeFx.Strike(duration: number)
	local current = session
	if current == nil then
		return
	end
	local track = current.Track
	if track == nil then
		local hitDelay = duration * ForgeStrikeConfig.HitTime / ForgeStrikeConfig.AnimationLength
		task.delay(hitDelay, ForgeStrikeFx.Hit)
		return
	end
	local speed = ForgeStrikeConfig.AnimationLength / math.max(duration, 1e-3)
	current.StrikeToken += 1
	local token = current.StrikeToken
	current.LastTimePosition = 0
	if not track.IsPlaying then
		track:Play(ForgeStrikeConfig.FadeTime, 1, speed)
	end
	track.TimePosition = 0
	track:AdjustSpeed(speed)
	task.delay(duration, function()
		if session == current and current.StrikeToken == token then
			holdReadyPose(current, track)
		end
	end)
end

local function applyStrikeContact(current: Session)
	local contactHeight = ForgeStation.FitUnderHammer(current.AnvilPart, current.Weapon)
	local impact = ForgeStrikeConfig.ImpactPointOffset + Vector3.yAxis * contactHeight
	current.ImpactPoint.CFrame = CFrame.new(impact)
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
	applyStrikeContact(current)
	local weapon = current.Weapon
	current.WeaponPivot = if weapon then weapon:GetPivot() else nil
end

function ForgeStrikeFx.Stop()
	local current = session
	if current == nil then
		return
	end
	session = nil
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
	current.ImpactPoint.CFrame = CFrame.new(ForgeStrikeConfig.ImpactPointOffset)
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
	local current: Session = {
		Character = character,
		AnvilPart = anvilPart,
		ForgePoint = forgePoint,
		ImpactPoint = impactPoint,
		Hammer = ForgeHammer.Attach(character, hammerTemplate),
		Sparks = ForgeSparks.Create(impactPoint),
		Sounds = ForgeImpactSound.Create(impactPoint),
		LastTimePosition = 0,
		StrikeToken = 0,
	}
	session = current
	if current.Sparks then
		ForgeSparks.SetRainbow(current.Sparks, isRainbowSparks)
	end
	applyStrikeContact(current)
	local track = loadTrack(character)
	current.Track = track
	if track then
		holdReadyPose(current, track)
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
