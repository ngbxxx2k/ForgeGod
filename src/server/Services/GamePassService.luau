--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local PremiumShopConfig = require(shared:WaitForChild("Config"):WaitForChild("PremiumShopConfig"))
local PlayerAttributes = require(shared:WaitForChild("Constants"):WaitForChild("PlayerAttributes"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)

local NO_MULTIPLIER = 1

local GamePassService = {}

local isInitialized = false
local ownedPasses: { [Player]: { [string]: boolean } } = {}
local purchasedCallbacks: { (Player, string) -> () } = {}

local function findPassByGamePassId(gamePassId: number): PremiumShopConfig.PassDefinition?
	for _, pass in PremiumShopConfig.Passes do
		if pass.GamePassId == gamePassId then
			return pass
		end
	end
	return nil
end

local function markOwned(player: Player, passId: string)
	if player.Parent == nil then
		return
	end
	local owned = ownedPasses[player] or {}
	ownedPasses[player] = owned
	if owned[passId] then
		return
	end
	owned[passId] = true
	player:SetAttribute(PlayerAttributes.OwnedPassPrefix .. passId, true)
end

local function ownsPassAsync(player: Player, pass: PremiumShopConfig.PassDefinition): boolean
	if pass.GamePassId <= 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.GamePassId)
	end)
	if not ok then
		warn("[GamePassService] Ownership check failed:", pass.Id, result)
		return false
	end
	return result == true
end

local function checkOwnership(player: Player, pass: PremiumShopConfig.PassDefinition)
	if ownsPassAsync(player, pass) and player.Parent ~= nil then
		markOwned(player, pass.Id)
	end
end

local function syncGiftedPasses(player: Player)
	local data = DataService.GetData(player)
	local gifted = data and data.GiftedPasses
	if type(gifted) ~= "table" then
		return
	end
	for passId, isGifted in gifted do
		if isGifted == true and PremiumShopConfig.PassById[passId] ~= nil then
			markOwned(player, passId)
		end
	end
end

local function onPlayerAdded(player: Player)
	ownedPasses[player] = ownedPasses[player] or {}
	for _, pass in PremiumShopConfig.Passes do
		task.spawn(checkOwnership, player, pass)
	end
end

local function onPlayerRemoving(player: Player)
	ownedPasses[player] = nil
end

local function onPromptFinished(player: Player, gamePassId: number, wasPurchased: boolean)
	if not wasPurchased then
		return
	end
	local pass = findPassByGamePassId(gamePassId)
	if pass == nil then
		return
	end
	if GamePassService.HasPass(player, pass.Id) then
		return
	end
	if not ownsPassAsync(player, pass) then
		warn("[GamePassService] Purchase signal without ownership:", player.Name, pass.Id)
		return
	end
	if player.Parent == nil or GamePassService.HasPass(player, pass.Id) then
		return
	end
	markOwned(player, pass.Id)
	DataActions.TryAddRobuxSpent(player, pass.RobuxPrice)
	for _, callback in purchasedCallbacks do
		task.spawn(callback, player, pass.Id)
	end
end

function GamePassService.HasPass(player: Player, passId: string): boolean
	local owned = ownedPasses[player]
	return owned ~= nil and owned[passId] == true
end

function GamePassService.GetMoneyMultiplier(player: Player): number
	if GamePassService.HasPass(player, PremiumShopConfig.PassIds.DoubleMoney) then
		return PremiumShopConfig.DoubleMoneyMultiplier
	end
	return NO_MULTIPLIER
end

function GamePassService.GetLuckMultiplier(player: Player): number
	if GamePassService.HasPass(player, PremiumShopConfig.PassIds.DoubleLuck) then
		return PremiumShopConfig.DoubleLuckMultiplier
	end
	return NO_MULTIPLIER
end

function GamePassService.Prompt(player: Player, passId: string): (boolean, string?)
	local pass = PremiumShopConfig.PassById[passId]
	if pass == nil then
		return false, "InvalidRequest"
	end
	if pass.GamePassId <= 0 then
		return false, "NotAvailable"
	end
	if GamePassService.HasPass(player, passId) then
		return false, "AlreadyOwned"
	end
	local ok, err = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, pass.GamePassId)
	end)
	if not ok then
		warn("[GamePassService] Prompt failed:", err)
		return false, "PromptFailed"
	end
	return true
end

function GamePassService.SyncGiftedPasses(player: Player)
	syncGiftedPasses(player)
end

function GamePassService.OnPassPurchased(callback: (Player, string) -> ())
	table.insert(purchasedCallbacks, callback)
end

function GamePassService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPromptFinished)
	DataService.OnProfileLoaded(syncGiftedPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
		syncGiftedPasses(player)
	end
end

return GamePassService
