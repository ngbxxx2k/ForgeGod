--!strict

export type MutationDefinition = {
	Id: string,
	Multiplier: number,
	Rarity: string,
}

local MutationConfig = {}

MutationConfig.Mutations = {
	{ Id = "Molten", Multiplier = 2, Rarity = "Common" },
	{ Id = "Aqua", Multiplier = 1.5, Rarity = "Common" },
	{ Id = "Thunder", Multiplier = 3, Rarity = "Uncommon" },
	{ Id = "Aurora", Multiplier = 4, Rarity = "Uncommon" },
	{ Id = "Radioactive", Multiplier = 4, Rarity = "Rare" },
	{ Id = "Shadow", Multiplier = 5, Rarity = "Rare" },
	{ Id = "Plasma", Multiplier = 5, Rarity = "Rare" },
} :: { MutationDefinition }

MutationConfig.ById = {} :: { [string]: MutationDefinition }

for _, mutation in MutationConfig.Mutations do
	MutationConfig.ById[mutation.Id] = mutation
end

function MutationConfig.GetMultiplier(mutationId: string): number
	local mutation = MutationConfig.ById[mutationId]
	return if mutation then mutation.Multiplier else 1
end

return MutationConfig
