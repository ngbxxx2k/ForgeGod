--!strict
--[[
	DataService
	Trách nhiệm: vòng đời phiên dữ liệu người chơi (tải, lưu, khóa phiên
	chống ghi đè khi đổi server) dựa trên ProfileStore. Không chứa logic gameplay.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local ForgeConfig = require(sharedFolder:WaitForChild("Config"):WaitForChild("ForgeConfig"))
local ForgeUpgradeConfig = require(sharedFolder:WaitForChild("Config"):WaitForChild("ForgeUpgradeConfig"))
local DigToolConfig = require(sharedFolder:WaitForChild("Config"):WaitForChild("DigToolConfig"))
local IndexKey = require(sharedFolder:WaitForChild("Utils"):WaitForChild("IndexKey"))

local DataTemplate = require(script.Parent.DataTemplate)
local ProfileStore = require(script.Parent.ProfileStore)
local LeaderboardService = require(script.Parent.LeaderboardService)

local STORE_NAME = "forgeGod_PlayerData_v5"

-- Trong Studio dùng store giả để không ghi vào dữ liệu thật của người chơi.
-- Đang đặt false để TEST lưu thật (đã bật Studio Access to API Services).
-- CẢNH BÁO: đổi về true trước khi commit (quy tắc file 05-data).
local USE_MOCK_IN_STUDIO = false

-- Thời gian tối đa đợi chiếm khóa phiên (giây). Quá thời hạn thì kick
-- để tránh người chơi treo máy chờ vô hạn.
local SESSION_ACQUIRE_TIMEOUT = 30
local PURCHASE_SAVE_RETRY_SECONDS = 10

-- Thông báo hiển thị khi kick người chơi (tiếng Anh).
local KICK_MESSAGE_LOAD_FAILED = "Could not load your data. Please rejoin."
local KICK_MESSAGE_SESSION_ENDED = "Your data session ended. Please rejoin."

local DataService = {}

local isInitialized = false
local store: any = nil
local profiles: { [Player]: any } = {}
local loadedCallbacks: { (Player) -> () } = {}
local sessionEndingCallbacks: { (Player) -> () } = {}

local function migrateArmedBuffsToCounts(data: any)
	local armedCounts: { [string]: number } = {}
	if type(data.ArmedBuffs) == "table" then
		for itemId, isArmed in data.ArmedBuffs do
			if isArmed == true then
				armedCounts[itemId] = 1
			end
		end
	end
	data.ArmedBuffs = armedCounts
end

local LEGACY_BUFF_IDS = { "LuckPotion", "BlacksmithPotion", "CoinPotion", "MutationPotion" }
local RETIRED_BUFF_IDS_V5 = { "MerchantPotion" }
local BUFF_STORAGE_FIELDS = { "Items", "ActiveBuffs", "PausedBuffs", "ArmedBuffs" }

local function removeBuffIds(data: any, itemIds: { string })
	for _, field in BUFF_STORAGE_FIELDS do
		local storage = data[field]
		if type(storage) == "table" then
			for _, itemId in itemIds do
				storage[itemId] = nil
			end
		end
	end
end

local LEGACY_MUTATION_RENAMES = {
	Lightning = "Thunder",
	BlackMoon = "Shadow",
	Plasma = "Plasma",
} :: { [string]: string }

local function renameLegacyMutations(data: any)
	if type(data.Weapons) ~= "table" then
		return
	end
	for _, weapon in data.Weapons do
		if type(weapon) == "table" and weapon.Mutation ~= nil then
			weapon.Mutation = LEGACY_MUTATION_RENAMES[weapon.Mutation]
		end
	end
end

local function clampWeaponLevel(weapon: any)
	local maxLevel = ForgeConfig.MaxLevelByRarity[weapon.Rarity]
	if type(maxLevel) ~= "number" or type(weapon.Level) ~= "number" or weapon.Level <= maxLevel then
		return
	end
	weapon.Level = maxLevel
	weapon.ValueHistory = nil
end

local function backfillIndex(data: any, weapon: any)
	if type(weapon.WeaponType) ~= "string" then
		return
	end
	if type(data.Index) ~= "table" then
		data.Index = {}
	end
	data.Index[IndexKey.Build(weapon.Mutation, weapon.WeaponType, weapon.ShapeStage)] = true
end

local function migrateLevelCapAndIndex(data: any)
	if type(data.Weapons) ~= "table" then
		return
	end
	for _, weapon in data.Weapons do
		if type(weapon) == "table" then
			clampWeaponLevel(weapon)
			backfillIndex(data, weapon)
		end
	end
end

local function buildOwnedTiers(trackId: string, highestTier: any): { number }
	local highest = ForgeUpgradeConfig.ClampTier(trackId, highestTier)
	local owned = {}
	for tierIndex = ForgeUpgradeConfig.MinTier, highest do
		table.insert(owned, tierIndex)
	end
	return owned
end

local function migrateForgeToolsToOwnedTiers(data: any)
	local highestTiers = if type(data.ForgeTools) == "table" then data.ForgeTools else {}
	local ownedTiers = {}
	for trackId in ForgeUpgradeConfig.Tracks do
		ownedTiers[trackId] = buildOwnedTiers(trackId, highestTiers[trackId])
	end
	data.OwnedForgeTiers = ownedTiers
	data.ForgeTools = nil
end

local function migrateDigToolsToOwnedTiers(data: any)
	local highestTiers = if type(data.DigTools) == "table" then data.DigTools else {}
	local ownedTiers = {}
	for toolId in DigToolConfig.Tracks do
		local highest = DigToolConfig.ClampTier(toolId, highestTiers[toolId])
		local owned = {}
		for tierIndex = DigToolConfig.MinTier, highest do
			table.insert(owned, tierIndex)
		end
		ownedTiers[toolId] = owned
	end
	data.OwnedDigTiers = ownedTiers
end

-- Áp dụng các bước nâng cấp cấu trúc dữ liệu cũ lên phiên bản hiện tại.
local function migrate(data: any)
	if data.SchemaVersion == nil then
		-- Dữ liệu tiền lịch sử: để Reconcile tự bổ sung trường còn thiếu.
		data.SchemaVersion = 1
	end
	if data.SchemaVersion == 1 then
		migrateArmedBuffsToCounts(data)
		data.SchemaVersion = 2
	end
	if data.SchemaVersion == 2 then
		removeBuffIds(data, LEGACY_BUFF_IDS)
		data.SchemaVersion = 3
	end
	if data.SchemaVersion == 3 then
		renameLegacyMutations(data)
		data.SchemaVersion = 4
	end
	if data.SchemaVersion == 4 then
		removeBuffIds(data, RETIRED_BUFF_IDS_V5)
		data.SchemaVersion = 5
	end
	if data.SchemaVersion == 5 then
		migrateLevelCapAndIndex(data)
		data.SchemaVersion = 6
	end
	if data.SchemaVersion == 6 then
		migrateForgeToolsToOwnedTiers(data)
		data.SchemaVersion = 7
	end
	if data.SchemaVersion == 7 then
		migrateDigToolsToOwnedTiers(data)
		data.SchemaVersion = 8
	end
	return data
end

-- Lấy store thật hoặc store giả tuỳ môi trường chạy (tạo một lần duy nhất).
local function getStore(): any
	if store == nil then
		local template = DataTemplate.Default
		if USE_MOCK_IN_STUDIO and RunService:IsStudio() then
			-- Dùng hậu tố riêng để dữ liệu Studio không lẫn production.
			store = ProfileStore.New(STORE_NAME .. "_Mock", template).Mock
		else
			store = ProfileStore.New(STORE_NAME, template)
		end
	end
	return store
end

-- Tải (hoặc tạo mới) dữ liệu cho một người chơi, kèm khóa phiên.
-- Trả về profile hoặc nil nếu không chiếm được phiên.
local function loadProfile(player: Player): any?
	local playerStore = getStore()
	local startedAt = os.clock()

	-- Cancel: dừng đợi khóa phiên khi người chơi đã rời, server đang tắt,
	-- hoặc đợi quá lâu (khóa có thể bị server khác treo).
	local profile = playerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player:IsDescendantOf(Players) == false
				or ProfileStore.IsClosing
				or os.clock() - startedAt > SESSION_ACQUIRE_TIMEOUT
		end,
	})

	if profile == nil then
		return nil
	end

	-- Gắn UserId vào profile để hỗ trợ xoá dữ liệu theo yêu cầu người dùng (RTBF).
	profile:AddUserId(player.UserId)
	migrate(profile.Data)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		-- Session kết thúc bất thường (bị server khác giành quyền) mà người
		-- chơi còn ở lại thì kick, tránh chơi tiếp trên dữ liệu không còn hợp lệ.
		if player:IsDescendantOf(Players) then
			player:Kick(KICK_MESSAGE_SESSION_ENDED)
		end
	end)

	return profile
end

local function handlePlayerAdded(player: Player)
	local profile = loadProfile(player)
	if profile == nil then
		warn("[DataService] Không mở được phiên dữ liệu:", player.Name)
		player:Kick(KICK_MESSAGE_LOAD_FAILED)
		return
	end
	if not player:IsDescendantOf(Players) then
		profile:EndSession()
		return
	end
	profiles[player] = profile
	-- Hiển thị coin trong danh sách người chơi ngay khi tải xong.
	LeaderboardService.AttachStats(player, profile.Data.Coins)
	print(`[DataService] Loaded profile for {player.Name}`)
	for _, callback in loadedCallbacks do
		task.spawn(callback, player)
	end
end

local function handlePlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		for _, callback in sessionEndingCallbacks do
			local ok, err = pcall(callback, player)
			if not ok then
				warn("[DataService] Session ending callback failed:", err)
			end
		end
	end
	profiles[player] = nil
	if profile ~= nil then
		-- EndSession sẽ lưu lần cuối rồi nhả khóa phiên.
		profile:EndSession()
	end
end

-- Lấy dữ liệu người chơi. nil nếu chưa tải xong hoặc đã thoát.
-- LUÔN kiểm tra nil trước khi dùng.
function DataService.GetData(player: Player): any?
	local profile = profiles[player]
	if profile == nil then
		return nil
	end
	return profile.Data
end

-- Dữ liệu đã tải xong và session còn hiệu lực?
function DataService.IsLoaded(player: Player): boolean
	local profile = profiles[player]
	return profile ~= nil and profile:IsActive() == true
end

function DataService.OnProfileLoaded(callback: (Player) -> ())
	table.insert(loadedCallbacks, callback)
end

function DataService.OnSessionEnding(callback: (Player) -> ())
	table.insert(sessionEndingCallbacks, callback)
end

-- Yêu cầu lưu ngay (ngoài auto-save định kỳ của ProfileStore).
function DataService.Save(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:Save()
	end
end

local function isPurchaseSaved(profile: any, purchaseId: string): boolean
	local savedData = profile.LastSavedData
	local saved = if type(savedData) == "table" then savedData.ProcessedPurchases else nil
	return type(saved) == "table" and table.find(saved, purchaseId) ~= nil
end

function DataService.WaitForPurchaseSaved(player: Player, purchaseId: string): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end
	if isPurchaseSaved(profile, purchaseId) then
		return true
	end
	while profile:IsActive() do
		local lastSavedData = profile.LastSavedData
		profile:Save()
		if profile.LastSavedData == lastSavedData then
			profile.OnAfterSave:Wait()
		end
		if isPurchaseSaved(profile, purchaseId) then
			return true
		end
		if not profile:IsActive() then
			break
		end
		task.wait(PURCHASE_SAVE_RETRY_SECONDS)
	end
	return false
end

function DataService.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	-- Khởi tạo store sớm để kịp kiểm tra quyền truy cập DataStore.
	getStore()

	Players.PlayerAdded:Connect(handlePlayerAdded)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)

	-- Người chơi đã có mặt trước khi Init chạy (ví dụ khi chạy trong Studio).
	for _, player in Players:GetPlayers() do
		task.spawn(handlePlayerAdded, player)
	end
end

return DataService
