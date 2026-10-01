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
local GameLoop = require(script.Parent:WaitForChild("GameLoop"))

local office = OfficeBuilder.build()
local rooftop = RooftopBuilder.build(office)
NPCGuide.init(office)
Shop.init()
Casino.init()
Physics.init()
Interactions.init(Props)
RoofService.init(office, rooftop)
CallService.init(office)
GameLoop.run(office)

local joined: { [Player]: boolean } = {}

Net.Spawn.OnServerEvent:Connect(function(player)
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
