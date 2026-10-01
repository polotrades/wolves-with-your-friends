-- The playable grand piano: a "Play Piano" prompt opens a keyboard on the client; pressed keys come back here and
-- play the matching note (Config.PIANO_NOTES) at the piano so everyone nearby hears it.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local PianoService = {}
local pianos: { [BasePart]: boolean } = {}

local function mainPart(model: Instance): BasePart?
	if model:IsA("BasePart") then
		return model
	end
	return (model :: Model).PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function watch(model: Instance)
	local part = mainPart(model)
	if not part or model:FindFirstChild("PianoPrompt") then
		return
	end
	pianos[part] = true
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PianoPrompt"
	prompt.ActionText = "Play Piano"
	prompt.ObjectText = "Grand Piano"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		Net.Piano:FireClient(player, part)
	end)
end

function PianoService.init()
	for _, m in CollectionService:GetTagged("Piano") do
		watch(m)
	end
	CollectionService:GetInstanceAddedSignal("Piano"):Connect(watch)
	Net.Piano.OnServerEvent:Connect(function(_player, noteIndex, position)
		if type(noteIndex) ~= "number" or typeof(position) ~= "Vector3" then
			return
		end
		noteIndex = math.floor(noteIndex)
		local id = Config.PIANO_NOTES[noteIndex]
		if id and id ~= "" then
			Audio.note(id, position, 0.8)
		end
	end)
end

return PianoService
