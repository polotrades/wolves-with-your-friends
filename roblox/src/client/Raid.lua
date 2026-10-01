-- Client side of the raid: red-and-blue siren flashes over the screen, a "FLOOR 100 RAIDED" banner, a camera that
-- pulls back to show the choppers and officers, and a shake. The server (RaidService) spawns the actual models.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent:WaitForChild("UI"))
local Net = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Net"))

local Raid = {}
local player = Players.LocalPlayer

local function play(seconds: number)
	local gui = UI.new("ScreenGui", { Name = "Raid", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 80,
		Parent = player:WaitForChild("PlayerGui") })
	local flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(220, 30, 40),
		BackgroundTransparency = 0.6, BorderSizePixel = 0, Parent = gui })
	local banner = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 120), Position = UDim2.new(0, 0, 0.4, 0),
		BackgroundColor3 = Color3.fromRGB(10, 10, 14), BackgroundTransparency = 0.1, BorderSizePixel = 0, Parent = gui })
	UI.text(banner, "🚨 FLOOR 100 RAIDED 🚨", { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.05),
		TextColor3 = Color3.fromRGB(255, 220, 80) })
	UI.text(banner, "Everybody freeze! Drop the phones!", { Size = UDim2.fromScale(1, 0.3), Position = UDim2.fromScale(0, 0.6),
		TextColor3 = Color3.new(1, 1, 1), Font = UI.body })

	-- flashing red/blue siren
	local flipConn = RunService.RenderStepped:Connect(function()
		local blue = math.floor(os.clock() * 4) % 2 == 0
		flash.BackgroundColor3 = blue and Color3.fromRGB(40, 80, 230) or Color3.fromRGB(220, 30, 40)
		flash.BackgroundTransparency = 0.55 + 0.15 * math.sin(os.clock() * 20)
	end)

	-- pull the camera back and up to take in the choppers and the elevators, with a shake
	local cam = Workspace.CurrentCamera
	local prevType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable
	local char = player.Character
	local look = char and char:GetPivot().Position or Vector3.new(0, 60, 0)
	local camConn = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local shake = Vector3.new(math.sin(t * 40), math.cos(t * 37), math.sin(t * 31)) * 0.6
		local pos = look + Vector3.new(18, 10, 18) + shake
		cam.CFrame = CFrame.lookAt(pos, look)
	end)

	task.delay(seconds, function()
		flipConn:Disconnect()
		camConn:Disconnect()
		if cam then
			cam.CameraType = prevType
		end
		TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		task.wait(0.5)
		gui:Destroy()
	end)
end

function Raid.init()
	Net.Raid.OnClientEvent:Connect(function(seconds)
		play(tonumber(seconds) or 8)
	end)
end

return Raid
