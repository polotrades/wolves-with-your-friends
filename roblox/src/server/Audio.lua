-- Spatial sound helper. Plays a one-shot sound at a position or on a part (server-made sounds replicate and play
-- positionally for everyone nearby). All ids come from Config.SOUNDS; an empty id is a no-op, so the game stays
-- quiet until the owner drops in Creator Store audio.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Audio = {}

-- play a one-shot sound (by Config.SOUNDS key, or a raw id) at a world position
function Audio.at(key: string, position: Vector3, volume: number?, pitch: number?)
	local id = (Config.SOUNDS :: any)[key] or key
	if type(id) ~= "string" or id == "" then
		return
	end
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	holder.Parent = workspace
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMaxDistance = 120
	sound.RollOffMinDistance = 8
	sound.Parent = holder
	sound:Play()
	sound.Ended:Connect(function()
		holder:Destroy()
	end)
	Debris:AddItem(holder, 10)
end

-- play on an existing part (follows it)
function Audio.on(key: string, part: BasePart, volume: number?, pitch: number?)
	local id = (Config.SOUNDS :: any)[key] or key
	if type(id) ~= "string" or id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Volume = volume or 1
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMaxDistance = 120
	sound.Parent = part
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	Debris:AddItem(sound, 10)
end

-- a raw asset id (used for piano notes), at a position
function Audio.note(id: string, position: Vector3, volume: number?)
	if type(id) ~= "string" or id == "" then
		return
	end
	Audio.at(id, position, volume)
end

return Audio
