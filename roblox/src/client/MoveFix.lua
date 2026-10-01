-- Safety net so the local player can always walk after spawning. Every frame, if something leaves the humanoid
-- frozen (WalkSpeed 0, anchored root, seated, platform-stand) or the camera gets stuck scriptable, it puts it right.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MoveFix = {}

local player = Players.LocalPlayer

function MoveFix.init()
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not (char and hum and hrp) then
			return
		end
		if hum.WalkSpeed < 8 then
			hum.WalkSpeed = 16
		end
		if hum.UseJumpPower and hum.JumpPower < 1 then
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
		local cam = Workspace.CurrentCamera
		if cam and cam.CameraType == Enum.CameraType.Scriptable then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = hum
		end
	end)
end

return MoveFix
