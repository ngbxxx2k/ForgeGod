--!strict

export type SavedMovement = {
	Humanoid: Humanoid,
	WalkSpeed: number,
	JumpPower: number,
	JumpHeight: number,
	AutoRotate: boolean,
}

local MovementLock = {}

function MovementLock.Lock(character: Model?): SavedMovement?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil then
		return nil
	end
	local saved: SavedMovement = {
		Humanoid = humanoid,
		WalkSpeed = humanoid.WalkSpeed,
		JumpPower = humanoid.JumpPower,
		JumpHeight = humanoid.JumpHeight,
		AutoRotate = humanoid.AutoRotate,
	}
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	humanoid:Move(Vector3.zero)
	return saved
end

function MovementLock.Unlock(saved: SavedMovement?)
	if saved == nil or saved.Humanoid.Parent == nil then
		return
	end
	local humanoid = saved.Humanoid
	humanoid.WalkSpeed = saved.WalkSpeed
	humanoid.JumpPower = saved.JumpPower
	humanoid.JumpHeight = saved.JumpHeight
	humanoid.AutoRotate = saved.AutoRotate
end

return MovementLock
