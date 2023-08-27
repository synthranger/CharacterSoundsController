return function(character: Model, humanoid: Humanoid)
	local rootPart: Part = character:WaitForChild("HumanoidRootPart")
	local verticalVelocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
	if verticalVelocity.Magnitude > 16 then
		return "Sprint"
	end
	return "Default"
end