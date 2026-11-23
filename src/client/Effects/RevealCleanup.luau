--!strict

export type CleanupTask = Instance | RBXScriptConnection | () -> ()

export type Cleanup = {
	Tasks: { CleanupTask },
	IsCleaned: boolean,
}

local RevealCleanup = {}

local function runTask(item: CleanupTask)
	if typeof(item) == "Instance" then
		item:Destroy()
	elseif typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	else
		item()
	end
end

function RevealCleanup.New(): Cleanup
	return { Tasks = {}, IsCleaned = false }
end

function RevealCleanup.Add(cleanup: Cleanup, item: CleanupTask)
	if cleanup.IsCleaned then
		runTask(item)
		return
	end
	table.insert(cleanup.Tasks, item)
end

function RevealCleanup.Clean(cleanup: Cleanup)
	if cleanup.IsCleaned then
		return
	end
	cleanup.IsCleaned = true
	for index = #cleanup.Tasks, 1, -1 do
		local ok, err = pcall(runTask, cleanup.Tasks[index])
		if not ok then
			warn("[RevealCleanup] Cleanup task failed:", err)
		end
	end
	table.clear(cleanup.Tasks)
end

return RevealCleanup
