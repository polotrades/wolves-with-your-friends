-- Talking mouths: each character has a Mouth part (Appearance.addGear). This wires an AudioAnalyzer to every
-- player's voice input and opens their mouth by how loud they're talking, so you can see who's speaking. Falls back
-- to a closed mouth where the Audio API or a voice input isn't available.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local TalkingMouths = {}

local analyzers: { [Player]: AudioAnalyzer } = {}

-- find a player's voice input (under the Player, or the local player's mic under SoundService)
local function voiceInput(p: Player): AudioDeviceInput?
	local input = p:FindFirstChildWhichIsA("AudioDeviceInput", true)
	if input then
		return input
	end
	if p == Players.LocalPlayer then
		return SoundService:FindFirstChildWhichIsA("AudioDeviceInput", true)
	end
	return nil
end

local function analyzerFor(p: Player): AudioAnalyzer?
	if analyzers[p] and analyzers[p].Parent then
		return analyzers[p]
	end
	local input = voiceInput(p)
	if not input then
		return nil
	end
	local ok, analyzer = pcall(function()
		local a = Instance.new("AudioAnalyzer")
		a.Parent = input
		local wire = Instance.new("Wire")
		wire.SourceInstance = input
		wire.TargetInstance = a
		wire.Parent = a
		return a
	end)
	if ok and analyzer then
		analyzers[p] = analyzer
		return analyzer
	end
	return nil
end

local function mouthOf(p: Player): BasePart?
	local char = p.Character
	local gear = char and char:FindFirstChild("Gear")
	return gear and gear:FindFirstChild("Mouth") :: BasePart?
end

function TalkingMouths.init()
	RunService.Heartbeat:Connect(function()
		for _, p in Players:GetPlayers() do
			local mouth = mouthOf(p)
			if mouth then
				local base = mouth:GetAttribute("BaseY") or mouth.Size.Y
				local analyzer = analyzerFor(p)
				local level = analyzer and math.clamp(analyzer.PeakLevel, 0, 1) or 0
				-- open the mouth downward by the voice level
				local openY = base + level * 0.5
				mouth.Size = Vector3.new(mouth.Size.X, openY, mouth.Size.Z)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		if analyzers[p] then
			analyzers[p]:Destroy()
			analyzers[p] = nil
		end
	end)
end

return TalkingMouths
