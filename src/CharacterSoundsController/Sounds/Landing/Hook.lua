return function(character: Model, humanoid: Humanoid, fallPosition: Vector3, landVelocity: Vector3)
	--[[
	if landVelocity.Magnitude > 50 then
		return "BoneBreak"
	end
	]]
	return "Default"
end