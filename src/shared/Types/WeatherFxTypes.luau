--!strict

local LightningTypes = require(script.Parent.LightningTypes)

export type LightingProfile = {
	Brightness: number,
	ClockTime: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	ExposureCompensation: number,
}

export type AtmosphereProfile = {
	Density: number,
	Offset: number,
	Color: Color3,
	Decay: Color3,
	Glare: number,
	Haze: number,
}

export type ColorCorrectionProfile = {
	Brightness: number,
	Contrast: number,
	Saturation: number,
	TintColor: Color3,
}

export type BloomProfile = {
	Intensity: number,
	Size: number,
	Threshold: number,
}

export type DepthOfFieldProfile = {
	FarIntensity: number,
	FocusDistance: number,
	InFocusRadius: number,
	NearIntensity: number,
}

export type SkyProfile = {
	MoonTextureId: string?,
	MoonAngularSize: number?,
	StarCount: number?,
}

export type ParticleAnchor = "Camera" | "Ground"

export type ParticleLayer = {
	Texture: string,
	Rate: number,
	Speed: NumberRange,
	Lifetime: NumberRange,
	Size: NumberSequence,
	Transparency: NumberSequence,
	Color: ColorSequence,
	Squash: number?,
	LightEmission: number?,
	LightInfluence: number?,
	Brightness: number?,
	Orientation: Enum.ParticleOrientation?,
	EmissionDirection: Enum.NormalId?,
	SpreadAngle: Vector2?,
	Acceleration: Vector3?,
	Drag: number?,
	Rotation: NumberRange?,
	RotSpeed: NumberRange?,
	AreaSize: Vector3,
	Offset: Vector3,
	Anchor: ParticleAnchor,
}

export type BoltProfile = {
	Chance: number,
	Distance: NumberRange,
	RaycastDepth: number,
	Style: LightningTypes.BoltStyle,
}

export type LightningProfile = {
	Interval: NumberRange,
	Bolt: BoltProfile?,
	FlashBrightness: number,
	FlashTint: Color3,
	FlashFadeTime: number,
	DoubleFlashChance: number,
	DoubleFlashGap: number,
	ThunderDelay: NumberRange,
	ThunderSoundIds: { string },
	ThunderVolume: number,
}

export type AmbientSoundProfile = {
	SoundId: string,
	Volume: number,
}

export type VignetteProfile = {
	Texture: string,
	Color: Color3,
	Transparency: number,
}

export type AuroraProfile = {
	Texture: string,
	Colors: ColorSequence,
	Count: number,
	Height: number,
	Distance: NumberRange,
	Length: number,
	Width: number,
	Transparency: number,
	Brightness: number,
	TextureSpeed: number,
	CurveSize: number,
	SwayAmount: number,
	SwaySpeed: number,
}

export type WeatherFxProfile = {
	Lighting: LightingProfile,
	Atmosphere: AtmosphereProfile,
	ColorCorrection: ColorCorrectionProfile,
	Bloom: BloomProfile?,
	DepthOfField: DepthOfFieldProfile?,
	Sky: SkyProfile?,
	Particles: { ParticleLayer }?,
	Lightning: LightningProfile?,
	AmbientSounds: { AmbientSoundProfile }?,
	Vignette: VignetteProfile?,
	Aurora: AuroraProfile?,
}

return {}
