-- Guarantees the local player can actually walk after spawning, and shows a tiny live status readout so any
-- remaining problem is visible instead of a mystery. Runs every frame: if something leaves the humanoid frozen
-- (WalkSpeed 0, anchored, seated, platform-stand, a scriptable camera), it puts it right.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MoveFix = {}

local player = Players.LocalPlayer

function MoveFix.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "MoveDebug"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 200
	gui.Parent = player:WaitForChild("PlayerGui")
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(360, 70)
	label.Position = UDim2.fromOffset(8, 8)
	label.BackgroundColor3 = Color3.new(0, 0, 0)
	label.BackgroundTransparency = 0.35
	label.TextColor3 = Color3.fromRGB(120, 255, 140)
	label.Font = Enum.Font.Code
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = "move: waiting for character…"
	label.Parent = gui

	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local cam = Workspace.CurrentCamera
		if not (char and hum and hrp) then
			label.Text = "move: no character/humanoid yet"
			return
		end
		-- force everything that would stop movement back to a walkable state
		if hum.WalkSpeed < 8 then
			hum.WalkSpeed = 16
		end
		if hum.JumpPower < 1 and hum.UseJumpPower then
			hum.JumpPower = 50
		end
		hum.PlatformStand = false
		hum.AutoRotate = true
		if hum.Sit then
			hum.Sit = false
		end
		if hrp.Anchored then
			hrp.Anchored = false
		end
		if cam and cam.CameraType == Enum.CameraType.Scriptable then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum
		end
		local pos = hrp.Position
		label.Text = string.format(
			"ws=%d anch=%s sit=%s state=%s\ncam=%s subj=%s\npos=%d,%d,%d",
			math.floor(hum.WalkSpeed),
			tostring(hrp.Anchored),
			tostring(hum.Sit),
			tostring(hum:GetState()):gsub("Enum.HumanoidStateType.", ""),
			tostring(cam and cam.CameraType):gsub("Enum.CameraType.", ""),
			cam and cam.CameraSubject == hum and "self" or "other",
			math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
		)
	end)
end

return MoveFix
