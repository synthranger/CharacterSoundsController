# CharacterSoundsController
A module for quick and easy character sounds including:
- Footsteps
- Jumping
- Landing

[Roblox Model](https://www.roblox.com/library/9925561505/CharacterSoundsController)

---
## Setting up
Put  anywhere the client can access it.
Preferrably somewhere in ReplicatedStorage.
And then put a LocalScript in StarterPlayerScripts and do the following:
```lua
require(game.ReplicatedStorage.CharacterSoundsController):Commence(true)
```
---
## Documentation
### Functions <br>
#### CharacterSoundsController:Commence
Starts the Controller. Set the first argument to true for auto player character wrapping.
```lua
function CharacterSoundsController:Commence(autoWrapPlayers: boolean): CharacterSoundsController
```

<br>

#### CharacterSoundsController:WrapCharacter
Wraps a character and gives it character sounds.
```lua
function CharacterSoundsController:WrapCharacter(character: Model): void
```
---
## Tutorials

### Making a new sound group
Firstly duplicate a copy of a SoundGroupTemplates inside the templates folder.
![image](assets/SoundGroupTemplate.PNG) <br>
Now let's rename it into Sprint. Note that we will be using this SoundGroup in a later tutorial.
![image](assets/SprintFolderCreated.PNG) <br>
Now you can freely put sounds and [stacked sounds](https://github.com/Synthranger/CharacterSoundsController#) inside the individual folders of this SoundGroup.

<br>

### Making stacked sounds
Just add a folder inside the material folder that you want stacked sounds to be. <br>

Possible use cases are:
- Having sounds of breaking bones alongside a normal landing sound
- Having sound of burning with the normal landing sound when landing on cracked lava material.

It should look like this: <br>
![image](assets/StackedSounds.PNG)