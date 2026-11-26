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

export type SpinState = {
	Tokens: number,
	NextFreeAt: number,
}

export type TutorialState = {
	StepId: string,
	DigCount: number,
	IsComplete: boolean,
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
	DigTools: { [string]: number }?,
	OwnedDigTiers: { [string]: { number } }?,
	OwnedForgeTiers: { [string]: { number } }?,
	ForgeSkins: { [string]: number }?,
	Index: { [string]: boolean }?,
	IndexRewards: { [string]: boolean }?,
	Spin: SpinState?,
	Tutorial: TutorialState?,
}

return {}
