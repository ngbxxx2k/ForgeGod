--!strict

export type Entry = {
	UserId: number,
	Name: string,
	Score: number,
}

export type Payload = {
	Cycle: number,
	Boards: { [string]: { Entry } },
}

return {}
