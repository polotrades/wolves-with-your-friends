-- Server entry point. Max players (10) is set in Game Settings > Places.
-- Characters don't load automatically: players spawn when they leave the main menu.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local OfficeBuilder = require(script.Parent:WaitForChild("OfficeBuilder"))
local NPCGuide = require(script.Parent:WaitForChild("NPCGuide"))
local CallService = require(script.Parent:WaitForChild("CallService"))
local Shop = require(script.Parent:WaitForChild("Shop"))
local Casino = require(script.Parent:WaitForChild("Casino"))
local Props = require(script.Parent:WaitForChild("Props"))
local Physics = require(script.Parent:WaitForChild("Physics"))
local Interactions = require(script.Parent:WaitForChild("Interactions"))
local RooftopBuilder = require(script.Parent:WaitForChild("RooftopBuilder"))
local RoofService = require(script.Parent:WaitForChild("RoofService"))
local RaidService = require(script.Parent:WaitForChild("RaidService"))
local PianoService = require(script.Parent:WaitForChild("PianoService"))
local GameLoop = require(script.Parent:WaitForChild("GameLoop"))
local CharacterService = require(script.Parent:WaitForChild("CharacterService"))

-- Build the office first (we need its clear spawn point), then wire up SPAWNING before anything else, so a crash in
-- any later builder can never stop players from getting a character. Each remaining init is guarded for the same
-- reason: one broken system must not take down the whole server and leave you unable to spawn, move or look.
local office: any
do
	local ok, result = pcall(OfficeBuilder.build)
	if ok then
		office = result
	else
		warn("[init] OfficeBuilder.build failed:", result)
		office = { folder = nil, desks = {}, elevators = {} }
	end
end

local function safeInit(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn("[init] " .. name .. " failed:", err)
	end
end

local joined: { [Player]: boolean } = {}

Net.Gesture.OnServerEvent:Connect(function(player, name)
	if type(name) == "string" and #name <= 16 then
		Net.Gesture:FireAllClients(player, name)
	end
end)

Net.Spawn.OnServerEvent:Connect(function(player, look)
	CharacterService.setLook(player, look)
	if joined[player] then
		return
	end
	joined[player] = true
	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		-- no usernames or health bars over anyone's head
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.NameDisplayDistance = 0
		hum.HealthDisplayDistance = 0
		-- Put the player on the clear lobby spot ourselves. Don't trust the SpawnLocation: with Teams or an odd
		-- spawn the engine can drop you at the world origin, which is the middle of the desk-packed trading floor,
		-- so you end up stuck inside furniture and can't move.
		local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
		if office.lobby then
			char:PivotTo(office.lobby)
			-- a couple more times as the character settles, so nothing yanks it back
			task.spawn(function()
				for _ = 1, 3 do
					task.wait(0.1)
					if hrp and hrp.Parent and office.lobby then
						char:PivotTo(office.lobby)
					end
				end
			end)
		end
		hum.WalkSpeed = 16
		hum.JumpPower = 50
		CharacterService.dress(player, char)
		hum.Died:Connect(function()
			task.wait(4)
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	joined[player] = nil
end)

-- everything else, guarded so a failure in one system can't stop spawning/movement
local rooftop
safeInit("RooftopBuilder.build", function()
	rooftop = RooftopBuilder.build(office)
end)
safeInit("NPCGuide.init", function()
	NPCGuide.init(office)
end)
safeInit("Shop.init", Shop.init)
safeInit("Casino.init", Casino.init)
safeInit("Physics.init", Physics.init)
safeInit("Interactions.init", function()
	Interactions.init(Props)
end)
safeInit("RoofService.init", function()
	RoofService.init(office, rooftop)
end)
safeInit("RaidService.init", function()
	RaidService.init(office, rooftop)
end)
safeInit("PianoService.init", PianoService.init)
safeInit("CallService.init", function()
	CallService.init(office)
end)
safeInit("CharacterService.init", CharacterService.init)
safeInit("GameLoop.run", function()
	GameLoop.run(office)
end)
