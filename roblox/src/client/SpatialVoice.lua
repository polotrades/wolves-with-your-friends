-- Bystanders hear the calls: when a caller speaks, the server broadcasts the line (CallSpeak). Everyone except the
-- operator (who hears it on their own headset) plays it as positional speech from an AudioEmitter at that desk, so
-- walking past a busy desk you catch snippets of the call. Needs the Audio API (VoiceChatService.UseAudioApi).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local SpatialVoice = {}
local player = Players.LocalPlayer
local emitters: { [number]: { tts: AudioTextToSpeech, token: number } } = {}
local HEAR_RANGE = 60

local function wire(a: Instance, b: Instance)
	local w = Instance.new("Wire")
	w.SourceInstance = a
	w.TargetInstance = b
	w.Parent = b
end

-- an AudioTextToSpeech -> AudioEmitter attached to the desk monitor, built once per desk
local function emitterFor(deskId: number, monitor: BasePart?)
	if emitters[deskId] then
		return emitters[deskId]
	end
	local ok, built = pcall(function()
		local tts = Instance.new("AudioTextToSpeech")
		tts.Parent = monitor or Workspace.Terrain
		local emitter = Instance.new("AudioEmitter")
		emitter.Parent = monitor or Workspace.Terrain
		wire(tts, emitter)
		return { tts = tts, token = 0 }
	end)
	if ok and built then
		emitters[deskId] = built
		return built
	end
	return nil
end

function SpatialVoice.init()
	Net.CallSpeak.OnClientEvent:Connect(function(deskId, position, text, voice, pitch, speed, operator)
		if operator == player then
			return -- the operator hears it on their own headset (Voice)
		end
		if typeof(position) ~= "Vector3" then
			return
		end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or (hrp.Position - position).Magnitude > HEAR_RANGE then
			return
		end
		local floor = Workspace:FindFirstChild("Floor100")
		local desk = floor and floor:FindFirstChild("Desk" .. deskId)
		local monitor = desk and desk:FindFirstChild("Monitor") :: BasePart?
		local e = emitterFor(deskId, monitor)
		if not e then
			return
		end
		e.token += 1
		local mine = e.token
		local tts = e.tts
		tts:Pause()
		tts.Text = tostring(text):sub(1, 200)
		tts.VoiceId = tostring(voice)
		tts.Pitch = tonumber(pitch) or 1
		tts.Speed = tonumber(speed) or 1
		task.spawn(function()
			local status = tts:LoadAsync()
			if mine == e.token and status == Enum.AssetFetchStatus.Success then
				tts:Play()
			end
		end)
	end)
end

return SpatialVoice
