-- No NPCs in the tower: only players. Ringing desks are announced to every player's HUD
-- (a screen-edge arrow points at the phone), and The Chairman speaks through a banner on everyone's screen.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local NPCGuide = {}

function NPCGuide.init(_office) end

-- desk started (on = true) or stopped (on = false) ringing
function NPCGuide.announce(desk, on: boolean?)
	Net.Ring:FireAllClients(desk.id, desk.monitor.Position, on ~= false)
end

function NPCGuide.chairman(text: string, seconds: number?)
	Net.Chairman:FireAllClients(text, seconds or 6)
end

return NPCGuide
