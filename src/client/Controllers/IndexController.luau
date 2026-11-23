--!strict

local IndexScreen = require(script.Parent.Parent.UI.Screens.IndexScreen)
local IndexMockData = require(script.Parent.IndexMockData)

local IndexController = {}

local isInitialized = false

local function selectTab(tabId: string)
	IndexScreen.RenderCollections(IndexMockData.GetCollections(tabId))
end

function IndexController.Init()
	if isInitialized then
		return
	end
	isInitialized = true

	local tabs = IndexMockData.GetTabs()
	local firstTab = tabs[1]
	IndexScreen.RenderTabs(tabs, firstTab and firstTab.Id, selectTab)
	IndexScreen.SetTotalProgress(IndexMockData.GetTotalProgress())
	if firstTab then
		selectTab(firstTab.Id)
	end
end

return IndexController
