-- First-person hands and gestures. Your own arms show in first person; number keys play hand poses (wave, point,
-- thumbs up, peace, fist, call-me, clap) and holding a thrown item puts your arms into a grab/aim pose. Poses are
-- driven by overlaying Motor6D.Transform on the shoulders/elbows, so they ride on top of the walk animation, and
-- they're replicated so everyone sees them. A small on-screen wheel (G) lists the gestures on touch screens.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("UI"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Gestures = {}
local player = Players.LocalPlayer

local A = CFrame.Angles
-- a pose = target Transform for each joint, how long it holds, and whether it waves
-- joints: rs = RightShoulder, re = RightElbow, ls = LeftShoulder, le = LeftElbow
type Pose = { rs: CFrame?, re: CFrame?, ls: CFrame?, le: CFrame?, hold: number, wave: boolean? }
local POSES: { [string]: Pose } = {
	wave = { rs = A(0, 0, math.rad(-150)), re = A(math.rad(30), 0, 0), hold = 1.6, wave = true },
	point = { rs = A(math.rad(-80), 0, math.rad(-6)), re = CFrame.new(), hold = 1.4 },
	thumbsup = { rs = A(math.rad(-20), 0, math.rad(-40)), re = A(math.rad(90), 0, 0), hold = 1.4 },
	peace = { rs = A(math.rad(-60), 0, math.rad(-20)), re = A(math.rad(60), 0, 0), hold = 1.4 },
	fist = { rs = A(math.rad(-30), 0, math.rad(-30)), re = A(math.rad(100), 0, 0), hold = 1.2 },
	callme = { rs = A(math.rad(-30), 0, math.rad(-70)), re = A(math.rad(80), 0, 0), hold = 1.6 },
	clap = { rs = A(math.rad(-70), 0, math.rad(-30)), re = A(math.rad(60), 0, 0),
		ls = A(math.rad(-70), 0, math.rad(30)), le = A(math.rad(60), 0, 0), hold = 1.4, wave = true },
	-- grab/aim pose while holding an item: both arms forward
	grab = { rs = A(math.rad(-85), 0, math.rad(-8)), re = A(math.rad(10), 0, 0),
		ls = A(math.rad(-85), 0, math.rad(8)), le = A(math.rad(10), 0, 0), hold = 1e9 },
}

local KEYS = {
	[Enum.KeyCode.One] = "wave", [Enum.KeyCode.Two] = "point", [Enum.KeyCode.Three] = "thumbsup",
	[Enum.KeyCode.Four] = "peace", [Enum.KeyCode.Five] = "fist", [Enum.KeyCode.Six] = "callme",
	[Enum.KeyCode.Seven] = "clap",
}

-- active poses per character: { pose, until, start }
local active: { [Model]: { pose: Pose, name: string, ends: number, start: number } } = {}

local function joints(char: Model)
	local function j(partName: string, motorName: string): Motor6D?
		local part = char:FindFirstChild(partName) :: BasePart?
		return part and part:FindFirstChild(motorName) :: Motor6D?
	end
	return {
		rs = j("RightUpperArm", "RightShoulder"),
		re = j("RightLowerArm", "RightElbow"),
		ls = j("LeftUpperArm", "LeftShoulder"),
		le = j("LeftLowerArm", "LeftElbow"),
	}
end

local function startPose(char: Model, name: string)
	local pose = POSES[name]
	if not pose then
		return
	end
	active[char] = { pose = pose, name = name, ends = os.clock() + pose.hold, start = os.clock() }
end

function Gestures.play(name: string)
	local char = player.Character
	if not char then
		return
	end
	startPose(char, name)
	Net.Gesture:FireServer(name)
end

-- hold a grab pose while carrying (called by Throwing)
function Gestures.setGrab(on: boolean)
	local char = player.Character
	if not char then
		return
	end
	if on then
		startPose(char, "grab")
		Net.Gesture:FireServer("grab")
	else
		Gestures.clear()
		Net.Gesture:FireServer("clear")
	end
end

function Gestures.clear()
	local char = player.Character
	if char then
		active[char] = nil
	end
end

local function wheel(gui: ScreenGui)
	local holder = UI.new("Frame", { Name = "Wheel", Size = UDim2.fromOffset(260, 60), AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10), BackgroundTransparency = 1, Visible = not UserInputService.KeyboardEnabled,
		Parent = gui })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = holder })
	local emoji = { wave = "👋", point = "👉", thumbsup = "👍", peace = "✌️", fist = "✊", callme = "🤙", clap = "👏" }
	for _, name in { "wave", "point", "thumbsup", "peace", "fist", "callme", "clap" } do
		local b = UI.button(holder, emoji[name], UI.os.surface2, { Size = UDim2.fromOffset(34, 34), TextSize = 20 }, function()
			Gestures.play(name)
		end)
		b.AutoButtonColor = true
	end
end

function Gestures.init()
	local gui = UI.new("ScreenGui", { Name = "Gestures", ResetOnSpawn = false, DisplayOrder = 3, Parent = player:WaitForChild("PlayerGui") })
	wheel(gui)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		local name = KEYS[input.KeyCode]
		if name then
			Gestures.play(name)
		end
	end)

	-- apply active poses every frame (overlay on the running animation)
	RunService.RenderStepped:Connect(function()
		for char, a in active do
			if not char.Parent or (a.ends < os.clock()) then
				active[char] = nil
			else
				local j = joints(char)
				local pose = a.pose
				local t = os.clock() - a.start
				local blend = math.clamp(t * 6, 0, 1)
				local waveOffset = pose.wave and A(0, 0, math.rad(18 * math.sin(t * 10))) or CFrame.identity
				local function apply(motor: Motor6D?, target: CFrame?, wavy: boolean?)
					if motor and target then
						local goal = wavy and (target * waveOffset) or target
						motor.Transform = CFrame.identity:Lerp(goal, blend)
					end
				end
				apply(j.rs, pose.rs, pose.wave)
				apply(j.re, pose.re)
				apply(j.ls, pose.ls, pose.wave)
				apply(j.le, pose.le)
			end
		end
	end)

	-- other players' gestures
	Net.Gesture.OnClientEvent:Connect(function(who, name)
		local other = who :: Player
		if other == player then
			return
		end
		local char = other.Character
		if not char then
			return
		end
		if name == "clear" then
			active[char] = nil
		else
			startPose(char, name)
		end
	end)
end

return Gestures
