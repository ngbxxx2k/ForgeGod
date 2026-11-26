--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ForgeConfig = require(ReplicatedStorage.Shared.Config.ForgeConfig)
local ForgeStrikeConfig = require(ReplicatedStorage.Shared.Config.ForgeStrikeConfig)
local WeaponModelFinder = require(ReplicatedStorage.Shared.Utils.WeaponModelFinder)
local ForgeBreakFx = require(script.Parent.ForgeBreakFx)
local ForgeFrenzyFx = require(script.Parent.ForgeFrenzyFx)
local ForgeHammer = require(script.Parent.ForgeHammer)
local ForgeImpactSound = require(script.Parent.ForgeImpactSound)
local ForgeMutationFx = require(script.Parent.ForgeMutationFx)
local ForgeSparks = require(script.Parent.ForgeSparks)
local ForgeStation = require(script.Parent.ForgeStation)
local ForgeWeaponImpact = require(script.Parent.ForgeWeaponImpact)
local RainbowWeapon = require(script.Parent.RainbowWeapon)
local WeaponAssetPreloader = require(script.Parent.WeaponAssetPreloader)

local BROKEN_STATE = "Broken"

export type StrikeInfo = {
	WeaponType: string,
	ShapeStage: number,
	State: string,
	Mutation: string?,
	IsNewMutation: boolean,
	FrenzyTimeLeft: number,
}

export type Session = {
	Character: Model,
	AnvilPart: BasePart,
	ForgePoint: Attachment,
	ImpactPoint: Attachment,
	Hammer: Instance?,
	Sparks: ForgeSparks.SparkSet?,
	Sounds: ForgeImpactSound.SoundSet,
	WeaponType: string,
	ShapeStage: number,
	Weapon: Model?,
	WeaponPivot: CFrame?,
	Impact: ForgeWeaponImpact.Impact?,
	Rainbow: RainbowWeapon.Target?,
	FrenzyEndsAt: number,
	FrenzyConnection: RBXScriptConnection?,
	PlaceToken: number,
	IsActive: boolean,
}

local ForgeSpectatorSession = {}

local runtimeFolder: Folder? = nil

local function getRuntimeFolder(): Folder
	local folder = runtimeFolder
	if folder and folder.Parent then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = ForgeStrikeConfig.SpectatorFolderName
	created.Parent = Workspace
	runtimeFolder = created
	return created
end

local function releaseRainbow(session: Session)
	local rainbow = session.Rainbow
	session.Rainbow = nil
	if rainbow then
		RainbowWeapon.Release(rainbow)
	end
end

local function stopImpact(session: Session)
	local impact = session.Impact
	session.Impact = nil
	if impact then
		ForgeWeaponImpact.Cancel(impact)
	end
end

local function clearWeapon(session: Session)
	stopImpact(session)
	releaseRainbow(session)
	if session.Weapon then
		session.Weapon:Destroy()
	end
	session.Weapon = nil
	session.WeaponPivot = nil
end

local function applyContact(session: Session)
	local height = ForgeStation.FitUnderHammer(session.AnvilPart, session.Weapon)
	session.ImpactPoint.CFrame = CFrame.new(ForgeStrikeConfig.ImpactPointOffset + Vector3.yAxis * height)
end

local function swapWeapon(session: Session, template: Model?)
	clearWeapon(session)
	if template then
		session.Weapon = ForgeStation.PlaceWeapon(session.ForgePoint, template, getRuntimeFolder())
	end
	applyContact(session)
	local weapon = session.Weapon
	session.WeaponPivot = if weapon then weapon:GetPivot() else nil
end

local function hit(session: Session)
	if not session.IsActive then
		return
	end
	if session.Sparks then
		ForgeSparks.Burst(session.Sparks)
	end
	local weapon, pivot = session.Weapon, session.WeaponPivot
	if weapon and pivot then
		stopImpact(session)
		session.Impact = ForgeWeaponImpact.Start(weapon, pivot)
	end
	ForgeImpactSound.Play(session.Sounds)
end

local function placeWeapon(session: Session, shapeStage: number, isAnnounced: boolean)
	session.ShapeStage = shapeStage
	session.PlaceToken += 1
	local token = session.PlaceToken
	local template = WeaponModelFinder.Find(session.WeaponType, shapeStage)
	if template == nil or not isAnnounced then
		swapWeapon(session, template)
		return
	end
	WeaponAssetPreloader.WhenReady(template, function()
		if not session.IsActive or session.PlaceToken ~= token then
			return
		end
		swapWeapon(session, template)
		if isAnnounced then
			hit(session)
		end
	end)
end

local function stopFrenzy(session: Session)
	local connection = session.FrenzyConnection
	session.FrenzyConnection = nil
	if connection then
		connection:Disconnect()
	end
	releaseRainbow(session)
	if session.Sparks then
		ForgeSparks.SetRainbow(session.Sparks, false)
	end
end

local function renderFrenzy(session: Session)
	local now = os.clock()
	local weapon = session.Weapon
	if now >= session.FrenzyEndsAt or not session.IsActive then
		stopFrenzy(session)
		return
	end
	if weapon and (session.Rainbow == nil or session.Rainbow.Model ~= weapon) then
		releaseRainbow(session)
		session.Rainbow = RainbowWeapon.Capture(weapon)
	end
	local rainbow = session.Rainbow
	if rainbow then
		RainbowWeapon.Paint(rainbow, now, ForgeFrenzyFx.IsLitAt(session.FrenzyEndsAt, now))
	end
end

local function startFrenzy(session: Session, timeLeft: number)
	session.FrenzyEndsAt = os.clock() + timeLeft
	if session.FrenzyConnection then
		return
	end
	if session.Sparks then
		ForgeSparks.SetRainbow(session.Sparks, true)
	end
	session.FrenzyConnection = RunService.RenderStepped:Connect(function()
		renderFrenzy(session)
	end)
end

local function land(session: Session, info: StrikeInfo)
	if not session.IsActive then
		return
	end
	if info.State == BROKEN_STATE then
		ForgeBreakFx.Shatter(session.Weapon)
		session.PlaceToken += 1
		clearWeapon(session)
		return
	end
	if info.ShapeStage ~= session.ShapeStage then
		placeWeapon(session, info.ShapeStage, true)
	end
	if info.IsNewMutation and info.Mutation then
		ForgeMutationFx.StrikeWorld(session.AnvilPart, info.Mutation, session.Character)
	end
	if info.FrenzyTimeLeft > 0 then
		startFrenzy(session, info.FrenzyTimeLeft)
	end
end

function ForgeSpectatorSession.Strike(session: Session, info: StrikeInfo)
	local duration = ForgeConfig.StrikeDuration
	local hitDelay = duration * ForgeStrikeConfig.HitTime / ForgeStrikeConfig.AnimationLength
	task.delay(hitDelay, hit, session)
	task.delay(duration, land, session, info)
end

function ForgeSpectatorSession.Start(
	character: Model,
	anvilPart: BasePart,
	hammerTemplate: Instance,
	weaponType: string,
	shapeStage: number
): Session
	local forgePoint, impactPoint = ForgeStation.EnsurePoints(anvilPart)
	local session: Session = {
		Character = character,
		AnvilPart = anvilPart,
		ForgePoint = forgePoint,
		ImpactPoint = impactPoint,
		Hammer = ForgeHammer.Attach(character, hammerTemplate),
		Sparks = ForgeSparks.Create(impactPoint),
		Sounds = ForgeImpactSound.Create(impactPoint),
		WeaponType = weaponType,
		ShapeStage = shapeStage,
		FrenzyEndsAt = 0,
		PlaceToken = 0,
		IsActive = true,
	}
	WeaponAssetPreloader.PreloadWeaponType(weaponType, shapeStage)
	placeWeapon(session, shapeStage, false)
	return session
end

function ForgeSpectatorSession.Stop(session: Session)
	if not session.IsActive then
		return
	end
	session.IsActive = false
	stopFrenzy(session)
	clearWeapon(session)
	if session.Hammer then
		session.Hammer:Destroy()
	end
	if session.Sparks then
		ForgeSparks.Destroy(session.Sparks)
	end
	ForgeImpactSound.Destroy(session.Sounds)
	session.ImpactPoint.CFrame = CFrame.new(ForgeStrikeConfig.ImpactPointOffset)
end

return ForgeSpectatorSession
