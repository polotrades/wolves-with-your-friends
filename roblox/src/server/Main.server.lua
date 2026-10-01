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
local GameLoop = require(script.Parent:WaitForChild("GameLoop"))
local CharacterService = require(script.Parent:WaitForChild("CharacterService"))

local office = OfficeBuilder.build()
local rooftop = RooftopBuilder.build(office)
NPCGuide.init(office)
Shop.init()
Casino.init()
Physics.init()
Interactions.init(Props)
RoofService.init(office, rooftop)
RaidService.init(office, rooftop)
CallService.init(office)
CharacterService.init()
GameLoop.run(office)

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
