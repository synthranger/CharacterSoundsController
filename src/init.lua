local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Character = require(script:WaitForChild("Character"))

local CSC_TAG = "csc_wrap"

local CharacterSoundsController = {}
local CharacterRegistry: {[Model]: Character.Class} = {}

local function characterAdded(char: Model)
    if CharacterRegistry[char] then
        return CharacterRegistry[char]
    end

    CharacterRegistry[char] = Character.new(char)
    char.Destroying:Connect(function()
        CharacterRegistry[char] = nil
    end)

    return CharacterRegistry[char]
end

local function playerAdded(player: Player)
    player.CharacterAdded:Connect(characterAdded)
    if player.Character then characterAdded(player.Character) end
end

function CharacterSoundsController:WrapCharacter(char: Model): Character.Class
    return characterAdded(char)
end

function CharacterSoundsController:Commence(auto_wrap_players: boolean)
    -- wrap players
    if auto_wrap_players then
        Players.PlayerAdded:Connect(playerAdded)
        for _, player in Players:GetPlayers() do
            playerAdded(player)
        end
    end

    -- wrap tagged instances
    CollectionService:GetInstanceAddedSignal(CSC_TAG):Connect(characterAdded)
    for _, char in CollectionService:GetTagged(CSC_TAG) do
        characterAdded(char)
    end
end

return CharacterSoundsController