--!strict

export type SmeltResult = {
	Id: string,
	Rarity: string,
	WeaponType: string,
	WeaponTypeId: string,
	Scale: number,
	Value: number,
}

export type WeaponVisual = {
	ModelName: string,
	WeaponTypeId: string?,
	Length: number,
	Rotation: CFrame?,
}

export type SoundSpec = {
	SoundId: string,
	Volume: number,
	PlaybackSpeed: number,
}

return {}
