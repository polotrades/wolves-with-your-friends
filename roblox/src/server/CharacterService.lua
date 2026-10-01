-- Dresses each player's character with the look they chose in the menu (Appearance), and applies their animation
-- pack. Called from Main when a player spawns; the look rides in on the Spawn remote.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Appearance = require(Shared:WaitForChild("Appearance"))

local CharacterService = {}

local looks: { [Player]: any } = {}

-- swap the default Animate script's animation ids for a pack (best effort; bad ids just fall back)
local function applyAnimPack(char: Model, packName: string)
	if packName == "default" then
		return
	end
	local ids = Appearance.ANIM_IDS[packName]
	local hum = char:FindFirstChildOfClass("Humanoid")
	if packName == "bouncy" and hum then
		hum.UseJumpPower = true
		hum.JumpPower = 60
		return
	end
	if not ids then
		return
	end
	local animate = char:FindFirstChild("Animate")
	if not animate then
		return
	end
	local map = { idle = { "idle", "Animation1" }, walk = { "walk", "WalkAnim" }, run = { "run", "RunAnim" },
		jump = { "jump", "JumpAnim" }, fall = { "fall", "FallAnim" } }
	for key, id in ids do
		local group = animate:FindFirstChild(key)
		if group then
			for _, anim in group:GetChildren() do
				if anim:IsA("Animation") then
					anim.AnimationId = id
				end
			end
		end
	end
	local _ = map
end

function CharacterService.setLook(player: Player, look: any)
	looks[player] = Appearance.sanitize(look)
end

function CharacterService.dress(player: Player, char: Model)
	local look = looks[player] or Appearance.default()
	-- wait for the R15 parts to exist
	task.spawn(function()
		char:WaitForChild("Humanoid", 5)
		char:WaitForChild("UpperTorso", 5)
		char:WaitForChild("Head", 5)
		local ok, err = pcall(function()
			Appearance.apply(char, look)
			Appearance.addGear(char)
			applyAnimPack(char, Appearance.ANIM_PACKS[look.anim])
		end)
		if not ok then
			warn("[CharacterService] dress failed:", err)
		end
	end)
end

function CharacterService.init()
	Players.PlayerRemoving:Connect(function(p)
		looks[p] = nil
	end)
end

return CharacterService
