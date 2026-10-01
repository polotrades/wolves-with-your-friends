-- Tuning numbers for the whole game. Change these while playtesting.
local Config = {}

Config.MAX_PLAYERS = 10
Config.INTERMISSION = 10 -- seconds before the first day starts
Config.DAY_LENGTH = 600 -- one workday = 10 minutes
Config.MEETING_VOTE_TIME = 15
Config.MEETING_VERDICT_TIME = 8
Config.FIRED_TIME = 20

-- Daily target curve (day 1, day 2, ...). Past the end of the list it grows 30% a day.
Config.QUOTAS = { 600, 1400, 1750, 2600, 3400, 4400, 5600, 7000 }
function Config.quotaFor(day: number): number
	if day <= #Config.QUOTAS then
		return Config.QUOTAS[day]
	end
	return math.floor(Config.QUOTAS[#Config.QUOTAS] * 1.3 ^ (day - #Config.QUOTAS))
end

-- Calls
Config.RING_TIMEOUT = 15 -- seconds a desk rings before the call jumps to another desk
Config.RING_MAX_JUMPS = 3 -- after this many jumps the client gives up
Config.RING_GAP_MIN = 5 -- seconds between new calls
Config.RING_GAP_MAX = 12
Config.START_TRUST = 25
Config.REVEAL_TRUST = 60 -- clients are told to share details above this interest level

-- AI
Config.AI_MAX_TOKENS = 160
Config.AI_TEMPERATURE = 0.85
Config.TTS_MAX_CHARS = 300 -- Roblox text-to-speech limit per request

-- Money
Config.VOTE_BONUS = 500 -- funniest-moment winner
Config.TARGET_BONUS = 100 -- every player, when the target is met

-- Art: the office is built from blender/office_scene.py's layout (OfficeLayout.lua) in Blender meters.
Config.STUDS_PER_METER = 3.0 -- a Roblox character is ~5.3 studs, a person ~1.8 m
-- Imported prop models (ServerStorage.PropModels) are scaled and turned automatically. If every prop ends up
-- facing backwards after an import, set this to 180.
Config.PROP_TURN_DEGREES = 0

-- Optional sound asset ids (Creator Store). Leave "" to skip.
-- All sounds use Roblox's BUILT-IN library (rbxasset://sounds/...), which ships with every Roblox install - so there
-- is audio out of the box with nothing to upload and no moderation. To upgrade any one, drop a Creator Store id
-- ("rbxassetid://...") in its place. If one comes out silent, it's a wrong built-in path - just swap that line.
Config.RING_SOUND_ID = "rbxasset://sounds/electronicpingshort.wav"
Config.CHEER_SOUND_ID = "rbxasset://sounds/victory.wav"
Config.DJ_MUSIC_ID = "" -- a music loop needs a real upload; leave "" for a silent stage (set an rbxassetid to add one)
Config.ELEVATOR_DING_ID = "rbxasset://sounds/electronicpingshort.wav"

-- Spatial sound effects played in the world (server/Audio.lua). Built-in by default; swap any for an rbxassetid.
Config.SOUNDS = {
	ring = "rbxasset://sounds/electronicpingshort.wav",
	impactSoft = "rbxasset://sounds/bass.wav",
	impactHard = "rbxasset://sounds/collide.wav",
	glassBreak = "rbxasset://sounds/snap.wav",
	elevatorDing = "rbxasset://sounds/electronicpingshort.wav",
	elevatorDoors = "rbxasset://sounds/swoosh.wav",
	splash = "rbxasset://sounds/impact_water.mp3",
	pour = "rbxasset://sounds/impact_water.mp3",
	printPage = "rbxasset://sounds/clickfast.wav",
	coin = "rbxasset://sounds/snap.wav",
	gong = "rbxasset://sounds/bass.wav",
}
-- The piano pitches ONE built-in tone across the octave (see PianoService), so it's playable with no upload.
Config.PIANO_BASE = "rbxasset://sounds/electronicpingshort.wav"

return Config
