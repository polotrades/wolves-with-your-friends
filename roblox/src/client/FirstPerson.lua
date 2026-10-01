-- The custom characters are built from solid parts welded over the hidden Roblox avatar. In forced first person the
-- camera sits inside your own head, so the opaque head/face parts (and the headset) would black out your view.
-- Roblox only auto-hides the default avatar, not our custom parts, so here we keep every part tagged "HeadPiece" on
-- the LOCAL character locally transparent. LocalTransparencyModifier is client-only, so other players still see the
-- full face. We re-apply every frame because the default camera's transparency controller resets it.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FirstPerson = {}

local player = Players.LocalPlayer
local parts: { BasePart } = {}

local function rescan(char: Model)
	table.clear(parts)
	for _, d in char:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("HeadPiece") then
			table.insert(parts, d)
		end
	end
end

local function hook(char: Model)
	rescan(char)
	-- the custom look is added a moment after the character spawns, and can be rebuilt; rescan when it changes
	char.ChildAdded:Connect(function(c)
		if c.Name == "LookExtras" or c.Name == "Gear" then
			task.defer(rescan, char)
		end
	end)
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			task.defer(function()
				if d:GetAttribute("HeadPiece") and d.Parent then
					table.insert(parts, d)
				end
			end)
		end
	end)
end

function FirstPerson.init()
	if player.Character then
		hook(player.Character)
	end
	player.CharacterAdded:Connect(hook)
	RunService.RenderStepped:Connect(function()
		for i = #parts, 1, -1 do
			local p = parts[i]
			if p and p.Parent then
				p.LocalTransparencyModifier = 1
			else
				table.remove(parts, i)
			end
		end
	end)
end

return FirstPerson
