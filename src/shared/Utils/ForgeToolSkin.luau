--!strict

local AssetIds = require(script.Parent.Parent.Constants.AssetIds)
local ForgeUpgradeConfig = require(script.Parent.Parent.Config.ForgeUpgradeConfig)

local ForgeToolSkin = {}

function ForgeToolSkin.GetTexture(trackId: string, tierIndex: number): string?
	local textures = AssetIds.ForgeUpgradeTextures[trackId]
	local tier = ForgeUpgradeConfig.GetTier(trackId, tierIndex)
	if textures == nil or tier == nil then
		return nil
	end
	return textures[tier.Material]
end

function ForgeToolSkin.IsTrackTexture(trackId: string, textureId: string): boolean
	local textures = AssetIds.ForgeUpgradeTextures[trackId]
	if textures == nil then
		return false
	end
	for _, texture in textures do
		if texture == textureId then
			return true
		end
	end
	return false
end

function ForgeToolSkin.Apply(model: Instance, trackId: string, tierIndex: number)
	local texture = ForgeToolSkin.GetTexture(trackId, tierIndex)
	if texture == nil then
		return
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("MeshPart") and ForgeToolSkin.IsTrackTexture(trackId, descendant.TextureID) then
			descendant.TextureID = texture
		end
	end
end

return ForgeToolSkin
