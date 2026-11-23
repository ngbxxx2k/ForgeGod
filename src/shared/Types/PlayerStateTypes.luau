--!strict

export type WeaponSummary = {
	Id: string,
	Rarity: string,
	WeaponType: string,
	State: string,
	Level: number,
	ForgePoints: number,
	ShapeStage: number?,
	Mutation: string?,
	Scale: number?,
	Value: number,
	IsLocked: boolean?,
}

export type PlayerState = {
	Coins: number,
	Items: { [string]: number },
	Weapons: { WeaponSummary },
	Equipped: { string },
	Capacity: number,
	LoadoutCapacity: number?,
	ActiveBuffs: { [string]: number }?,
	ArmedBuffs: { [string]: number }?,
}

return {}
