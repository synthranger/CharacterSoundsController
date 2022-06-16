local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer

local Sounds = script:WaitForChild("Sounds")
local Config = script:WaitForChild("Config")

local FootstepsConfig = require(Config.Footsteps)
local LandingConfig = require(Config.Landing)
local JumpingConfig = require(Config.Jumping)

local CanPlayFootstepSound = true

local CharacterSoundsController = {}

local function clonePlay(sound: Sound, parent: Instance): Sound
	local clone = sound:Clone()
	clone.Parent = parent
	clone:Play()
	task.delay(clone.TimeLength + 5, function()
		clone:Destroy()
	end)
	return clone
end

local function chooseRandom<T>(array: {[number]: T}): T
	if #array <= 0 then return end
	return array[math.random(1, #array)]
end

local function checkMovement(humanoid: Humanoid): boolean
	local velocity = humanoid.RootPart.AssemblyLinearVelocity.Magnitude
	if humanoid.WalkSpeed > 0 and velocity > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
		return true
	end
	return false
end

local function GetSoundGroup(categoryName: string, ...: any): Folder
	local Category: Folder? = Sounds:FindFirstChild(categoryName)
	if Category then
		local Hook = Category:FindFirstChild("Hook") and require(Category.Hook)
		local SoundGroupName = "Default"
		if Hook then
			SoundGroupName = Hook(...)
		end
		return Category:FindFirstChild(SoundGroupName)
	end
end

local function PlaySound(character: Model, rootPart: Part, template: Sound, localMultiplier: number, multiplier: number)
	local sound = template:Clone()
	sound.Parent = rootPart
	if character == LocalPlayer.Character then
		sound.Volume = template.Volume 
			* localMultiplier
	else
		sound.Volume = template.Volume 
			* multiplier
	end
	sound:Play()
	task.delay(sound.TimeLength + 5, function()
		sound:Destroy()
	end)
end

function CharacterSoundsController:WrapCharacter(character: Model)
	local humanoid: Humanoid = character:WaitForChild("Humanoid")
	local rootPart: Part = character:WaitForChild("HumanoidRootPart")
	
	rootPart:WaitForChild("Running").SoundId = ""
	rootPart:WaitForChild("Jumping").SoundId = ""
	rootPart:WaitForChild("Landing").SoundId = ""
	
	local fallPosition = Vector3.new()
	humanoid.StateChanged:Connect(function(oldState, newState)
		-- JUMPING
		if newState == Enum.HumanoidStateType.Jumping then
			local soundGroup = GetSoundGroup("Jumping", character, humanoid)
			if soundGroup then
				local materialSoundGroup = soundGroup:FindFirstChild(humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild("Default")
				local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
				if template then
					if template:IsA("Sound") then
						PlaySound(
							character, 
							rootPart, 
							template, 
							JumpingConfig.LOCALPLAYER_VOLUME_MULTIPLIER,
							JumpingConfig.VOLUME_MULTIPLIER
						)
					elseif template:IsA("Folder") then
						for _, templateSound in pairs(template:GetChildren()) do
							PlaySound(
								character, 
								rootPart, 
								templateSound, 
								JumpingConfig.LOCALPLAYER_VOLUME_MULTIPLIER,
								JumpingConfig.VOLUME_MULTIPLIER
							)
						end
					end
				end
			end
		end
		
		-- LANDING
		if newState == Enum.HumanoidStateType.Freefall then
			fallPosition = rootPart.Position
		end
		if newState == Enum.HumanoidStateType.Landed then
			local landVelocity = rootPart.AssemblyLinearVelocity
			local finalLandVelocity = math.clamp(landVelocity.Magnitude / 100, 1, math.huge)
			
			local soundGroup = GetSoundGroup("Landing", character, humanoid, fallPosition, landVelocity)
			if soundGroup then
				local materialSoundGroup = soundGroup:FindFirstChild(humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild("Default")
				local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
				if template then
					if template:IsA("Sound") then
						PlaySound(
							character,
							rootPart,
							template,
							LandingConfig.LOCALPLAYER_VOLUME_MULTIPLIER * finalLandVelocity,
							LandingConfig.VOLUME_MULTIPLIER * finalLandVelocity
						)
					elseif template:IsA("Folder") then
						for _, templateSound in pairs(template:GetChildren()) do
							PlaySound(
								character,
								rootPart,
								templateSound,
								LandingConfig.LOCALPLAYER_VOLUME_MULTIPLIER * finalLandVelocity,
								LandingConfig.VOLUME_MULTIPLIER * finalLandVelocity
							)
						end
					end
					CanPlayFootstepSound = false
					task.delay(0.1, function()
						CanPlayFootstepSound = true
					end)
				end
			end
		end
	end)
	
	-- FOOTSTEPS
	task.spawn(function()
		while humanoid.Health > 0 do
			local rawVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
			local velocity = ((Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude) / 25)
			local finalVelocity = (rawVelocity / StarterPlayer.CharacterWalkSpeed)
			
			if checkMovement(humanoid) and velocity > 0.2 and CanPlayFootstepSound then
				local soundGroup = GetSoundGroup("Footsteps", character, humanoid)
				if soundGroup then
					local materialSoundGroup = soundGroup:FindFirstChild(humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild("Default")
					local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
					
					if template then
						if template:IsA("Sound") then
							PlaySound(
								character,
								rootPart,
								template,
								FootstepsConfig.LOCALPLAYER_VOLUME_MULTIPLIER * finalVelocity,
								FootstepsConfig.VOLUME_MULTIPLIER * finalVelocity
							)
						elseif template:IsA("Folder") then
							for _, templateSound in pairs(template:GetChildren()) do
								PlaySound(
									character,
									rootPart,
									templateSound,
									FootstepsConfig.LOCALPLAYER_VOLUME_MULTIPLIER * finalVelocity,
									FootstepsConfig.VOLUME_MULTIPLIER * finalVelocity
								)
							end
						end
					end
				end
				task.wait(0.2 / velocity)
			else
				task.wait()
			end
		end
	end)
end

local function wrapCharacter(character)
	return CharacterSoundsController:WrapCharacter(character)
end

function CharacterSoundsController:Commence(autoWrapPlayers: boolean): typeof(CharacterSoundsController)
	if autoWrapPlayers then
		for _, player: Player in pairs(Players:GetPlayers()) do
			player.CharacterAdded:Connect(wrapCharacter)
			if player.Character then
				wrapCharacter(player.Character)
			end
		end
		Players.PlayerAdded:Connect(function(Player)
			Player.CharacterAdded:Connect(wrapCharacter)
		end)
	end
	return CharacterSoundsController
end

return CharacterSoundsController