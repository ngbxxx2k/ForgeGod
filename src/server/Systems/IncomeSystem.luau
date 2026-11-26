--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local LoadoutConfig = require(shared:WaitForChild("Config"):WaitForChild("LoadoutConfig"))
local WeaponIncome = require(shared:WaitForChild("Utils"):WaitForChild("WeaponIncome"))

local DataActions = require(script.Parent.Parent.Data.DataActions)
local DataService = require(script.Parent.Parent.Data.DataService)
local DataTemplate = require(script.Parent.Parent.Data.DataTemplate)
local LeaderboardService = require(script.Parent.Parent.Data.LeaderboardService)
local GamePassService = require(script.Parent.Parent.Services.GamePassService)

local IncomeSystem = {}

local isInitialized = false

local function getLoadoutIncome(data: any): number
	local total = 0
	for _, weaponId in data.Equipped do
		local weapon = data.Weapons[weaponId]
		if weapon then
			local isBroken = weapon.State == DataTemplate.WeaponStates.Broken
			total += WeaponIncome.PerSecond(weapon.Value, weapon.Mutation, isBroken)
		end
	end
	return total
end

local function payPlayer(player: Player, elapsed: number)
	local data = DataService.GetData(player)
	if data == nil then
		return
	end
	local perSecond = getLoadoutIncome(data) * GamePassService.GetMoneyMultiplier(player)
	LeaderboardService.SetIncome(player, perSecond)
	local amount = math.floor(perSecond * elapsed)
	if amount > 0 then
		DataActions.TryAddCoins(player, amount)
	end
end

local function payAll(elapsed: number)
	for _, player in Players:GetPlayers() do
		payPlayer(player, elapsed)
	end
end

function IncomeSystem.Init()
	if isInitialized then
		return
	end
	isInitialized = true
	task.spawn(function()
		while isInitialized do
			task.wait(LoadoutConfig.TickInterval)
			payAll(LoadoutConfig.TickInterval)
		end
	end)
end

return IncomeSystem
