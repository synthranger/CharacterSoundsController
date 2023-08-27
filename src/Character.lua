local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer

local EPSILON = 0.01

local Sounds = script.Parent:WaitForChild("Sounds")
local Config = script.Parent:WaitForChild("Config")

local FOOTSTEPS_CONFIG = require(Config.Footsteps)
local LANDING_CONFIG = require(Config.Landing)
local JUMPING_CONFIG = require(Config.Jumping)

export type Class = {
    Instance: Model;
    Humanoid: Humanoid;
    Player: Player;
    SoundGroup: string;

    _started: boolean;
    _stateChanged: RBXScriptConnection?;
    _canFootstep: boolean;
    _fallPos: Vector3;

    _checkMovement: (self: Class) -> boolean;
    _getDelay: (self: Class) -> number;
    _getSoundGroup: (self: Class, categoryName: string, ...any) -> (Folder?, number?);
    _playSound: (self: Class, template: Sound, localMultiplier: number, multiplier: number) -> ();

    Footstep: (self: Class) -> number;
    Jumped: (self: Class) -> ();
    Landed: (self: Class) -> ();

    Start: (self: Class) -> ();
    Stop: (self: Class) -> ();
}

local Character: Class = {}
Character.__index = Character

local function chooseRandom<T>(array: {[number]: T}): T
	if #array <= 0 then return end
	return array[math.random(1, #array)]
end

local function GetSoundGroup(categoryName: string, ...: any): (Folder, number)
	local category: Folder? = Sounds:FindFirstChild(categoryName)
	if category then
		local hook = category:FindFirstChild("Hook") and require(category.Hook)
		local soundGroupName, delayTime = "Default", 0.2
		if hook then soundGroupName, delayTime = hook(...) end
		return category:FindFirstChild(soundGroupName), delayTime
	end
end

function Character:_checkMovement(): boolean
    local rootPart: Part = self.Humanoid.RootPart
    if not rootPart then return false end
    local velocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
    return self.Humanoid.WalkSpeed > 0 and velocity > EPSILON and self.Humanoid.FloorMaterial ~= Enum.Material.Air
end

function Character:_getDelay(): number
    local rootPart: Part = self.Humanoid.RootPart
    if not rootPart then return 0 end
    local velocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
    return 0.2 / (velocity / 25)
end

function Character:_getSoundGroup(categoryName: string, ...: any): (Folder?, number?)
	local category: Folder? = Sounds:FindFirstChild(categoryName)
	if category then
		local hook = category:FindFirstChild("Hook") and require(category.Hook)
		local soundGroupName, delayTime = nil, nil
		if hook then soundGroupName, delayTime = hook(...) end
		return category:FindFirstChild(soundGroupName), (delayTime or self:_getDelay())
	end
end

function Character:_playSound(template: Sound | Folder, localMultiplier: number, multiplier: number)
    local rootPart: Part = self.Humanoid.RootPart
    if not rootPart then return end

    local function play(sound: Sound)
        local clone = sound:Clone()
        clone.Parent = rootPart
        clone.Volume = sound.Volume * (self.Instance == LocalPlayer.Character and localMultiplier or multiplier)
        clone:Play()
        task.delay(clone.TimeLength + 5, function()
            clone:Destroy()
        end)
    end

    if template:IsA("Sound") then
        play(template)
    elseif template:IsA("Folder") then
        for _, sound in template:GetChildren() do
            play(sound)
        end
    else
        error("invalid class")
    end
end

function Character:Footstep(): number
	local rootPart: Part = self.Humanoid.RootPart
    if not rootPart then return end
    if not self:_checkMovement() then return end
    if not self._canFootstep then return end

    local velocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z).Magnitude
    local finalVelocity = (velocity / StarterPlayer.CharacterWalkSpeed)

    local soundGroup, delayTime = self:_getSoundGroup("Footsteps", self.Instance, self.Humanoid)
    if soundGroup then
        local materialSoundGroup = soundGroup:FindFirstChild(self.Humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild(self.SoundGroup)
        local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
        self:_playSound(template, FOOTSTEPS_CONFIG.LOCALPLAYER_VOLUME_MULTIPLIER * finalVelocity, FOOTSTEPS_CONFIG.VOLUME_MULTIPLIER * finalVelocity)
    end

    return delayTime
end

function Character:Jumped()
    local soundGroup = self:_getSoundGroup("Jumping", self.Instance, self.Humanoid)
    if soundGroup then
        local materialSoundGroup = soundGroup:FindFirstChild(self.Humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild(self.SoundGroup)
        local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
        self:_playSound(template, JUMPING_CONFIG.LOCALPLAYER_VOLUME_MULTIPLIER, JUMPING_CONFIG.VOLUME_MULTIPLIER)
    end
end

function Character:Landed()
    local rootPart: Part = self.Humanoid.RootPart
    if not rootPart then return end

    local landVelocity = rootPart.AssemblyLinearVelocity
    local finalLandVelocity = math.clamp(landVelocity.Magnitude / 100, 1, math.huge)

    local soundGroup = GetSoundGroup("Landing", self.Instance, self.Humanoid, self._fallPos, landVelocity)
    if soundGroup then
        local materialSoundGroup = soundGroup:FindFirstChild(self.Humanoid.FloorMaterial.Name) or soundGroup:FindFirstChild(self.SoundGroup)
        local template: Sound | Folder = chooseRandom(materialSoundGroup:GetChildren())
        self:_playSound(template, LANDING_CONFIG.LOCALPLAYER_VOLUME_MULTIPLIER, LANDING_CONFIG.VOLUME_MULTIPLIER)
    end

    self._canFootstep = false
    task.delay(0.1, function()
        if not getmetatable(self) then return warn("some") end -- was destroyed
        self._canFootstep = true
    end)
end

function Character:Start()
    if self._started then return end
    self._started = true
    self._stateChanged = self.Humanoid.StateChanged:Connect(function(oldState, newState)
        local rootPart = self.Humanoid.RootPart
        if not rootPart then return end
        if newState == Enum.HumanoidStateType.Jumping then
            self:Jumped()
        elseif newState == Enum.HumanoidStateType.Freefall then
            self._fallPos = rootPart.Position
        elseif newState == Enum.HumanoidStateType.Landed then
            self:Landed()
        end
    end)

    task.spawn(function()
        while self._started and (self.Instance and self.Instance.Parent) and (self.Humanoid and self.Humanoid.Health > 0) do
            local delayTime = self:Footstep()
            task.wait(delayTime)
        end
    end)
end

function Character:Stop()
    if not self._started then return end
    self._started = false
    self._stateChanged:Disconnect()
    self._stateChanged = nil
end

function Character.new(model: Model): Class
    local self: Class = setmetatable({}, Character)

    self.Instance = model
    self.Humanoid = model:FindFirstChild("Humanoid")
    self.Player = Players:GetPlayerFromCharacter(model)
    self.SoundGroup = self.Instance:GetAttribute("csc_soundgroup") or "Default"

    self._canFootstep = true
    self._fallPos = Vector3.new()

    local function onHumanoid(humanoid: Humanoid)
        if not humanoid:IsA("Humanoid") then return end
        self.Humanoid = humanoid
        self.Humanoid.Destroying:Connect(function()
            self.Humanoid = nil
            self:Stop()
        end)
        self:Start()
    end

    self.Instance.ChildAdded:Connect(onHumanoid)
    if self.Humanoid then onHumanoid(self.Humanoid) end

    self.Instance.Destroying:Connect(function()
        setmetatable(self, nil)
        table.clear(self)
    end)

    return self
end

return Character