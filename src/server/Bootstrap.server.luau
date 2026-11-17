--!strict
--[[
	Bootstrap.server
	Trách nhiệm: script duy nhất khởi động server. Chỉ require và Init
	theo thứ tự: Data -> Security -> Services -> Systems. Không logic khác.
]]

local DataService = require(script.Parent.Data.DataService)
local DataActions = require(script.Parent.Data.DataActions)
local LeaderboardService = require(script.Parent.Data.LeaderboardService)
local RateLimiter = require(script.Parent.Security.RateLimiter)
local StationRange = require(script.Parent.Security.StationRange)
local PlayerStateService = require(script.Parent.Services.PlayerStateService)
local FriendBoostService = require(script.Parent.Services.FriendBoostService)
local ShopService = require(script.Parent.Services.ShopService)
local FurnaceService = require(script.Parent.Services.FurnaceService)
local ForgeService = require(script.Parent.Services.ForgeService)
local EquipService = require(script.Parent.Services.EquipService)
local SellService = require(script.Parent.Services.SellService)
local WeaponLockService = require(script.Parent.Services.WeaponLockService)
local BuffService = require(script.Parent.Services.BuffService)
local ShopRestockSystem = require(script.Parent.Systems.ShopRestockSystem)
local WeatherSystem = require(script.Parent.Systems.WeatherSystem)

DataService.Init()
LeaderboardService.Init()
DataActions.Init()
RateLimiter.Init()
StationRange.Init()
PlayerStateService.Init()
FriendBoostService.Init()
ShopService.Init()
FurnaceService.Init()
ForgeService.Init()
EquipService.Init()
SellService.Init()
WeaponLockService.Init()
BuffService.Init()
ShopRestockSystem.Init()
WeatherSystem.Init()


