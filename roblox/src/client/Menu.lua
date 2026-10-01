-- Main menu before spawning: camera flies around the tower at sunset, helicopters circle,
-- and the luxury menu picks how you join. Quick Match spawns you straight onto floor 100.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent:WaitForChild("UI"))
local Voice = require(script.Parent:WaitForChild("Voice"))
local Customizer = require(script.Parent:WaitForChild("Customizer"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Menu = { onSpawn = nil :: (() -> ())? }

local player = Players.LocalPlayer
local gui: ScreenGui
local flyConn: RBXScriptConnection?
local helicopters: Folder?

local function buildHelicopter(parent: Instance, color: Color3)
	local m = Instance.new("Model")
	local function p(name: string, size: Vector3, offset: CFrame, c: Color3, shape: Enum.PartType?)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CastShadow = false
		if shape then
			part.Shape = shape
		end
		part.Size = size
		part.Color = c
		part.Material = Enum.Material.SmoothPlastic
		part.CFrame = offset
		part.Parent = m
		return part
	end
	local body = p("Body", Vector3.new(6, 6, 12), CFrame.new(), color, Enum.PartType.Ball)
	p("Tail", Vector3.new(1.4, 1.4, 12), CFrame.new(0, 0.8, 10), color)
	p("Fin", Vector3.new(0.4, 3, 2), CFrame.new(0, 2.5, 15.5), color)
	p("Window", Vector3.new(4.6, 3, 4), CFrame.new(0, 0.8, -3.6), Color3.fromRGB(120, 180, 230), Enum.PartType.Ball)
	local rotor = p("Rotor", Vector3.new(22, 0.3, 1.2), CFrame.new(0, 3.8, 0), Color3.fromRGB(30, 30, 30))
	m.PrimaryPart = body
	m.Parent = parent
	return m, rotor
end

local function startFlyover()
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local folder = Instance.new("Folder")
	folder.Name = "MenuHelicopters"
	folder.Parent = Workspace
	helicopters = folder
	local choppers = {}
	for i, c in { Color3.fromRGB(230, 60, 50), Color3.fromRGB(240, 240, 240), Color3.fromRGB(30, 30, 35) } do
		local m, rotor = buildHelicopter(folder, c)
		table.insert(choppers, { model = m, rotor = rotor, radius = 150 + i * 45, height = 30 + i * 18, speed = 0.08 + i * 0.03,
			phase = i * 2.1 })
	end
	local t0 = os.clock()
	flyConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local a = t * 0.05
		cam.CFrame = CFrame.lookAt(Vector3.new(math.cos(a) * 240, 60 + math.sin(t * 0.2) * 10, math.sin(a) * 240),
			Vector3.new(0, 12, 0))
		for _, h in choppers do
			local b = h.phase + t * h.speed
			local pos = Vector3.new(math.cos(b) * h.radius, h.height + math.sin(t + h.phase) * 4, math.sin(b) * h.radius)
			local ahead = Vector3.new(math.cos(b + 0.05) * h.radius, pos.Y, math.sin(b + 0.05) * h.radius)
			h.model:PivotTo(CFrame.lookAt(pos, ahead))
			h.rotor.CFrame = h.model:GetPivot() * CFrame.new(0, 3.8, 0) * CFrame.Angles(0, t * 25, 0)
		end
	end)
end

local function stopFlyover()
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end
	if helicopters then
		helicopters:Destroy()
		helicopters = nil
	end
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

local function toast(parent: Instance, text: string)
	local l = UI.text(parent, text, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, 8),
		TextColor3 = UI.colors.gold, Font = UI.bold })
	task.delay(2, function()
		l:Destroy()
	end)
end

local function settingsPanel()
	local panel = UI.new("Frame", { Size = UDim2.fromOffset(380, 220), Position = UDim2.new(0.5, -190, 0.5, -110),
		BackgroundColor3 = UI.colors.bg, ZIndex = 50, Parent = gui })
	UI.corner(panel, 12)
	UI.pad(panel, 16)
	UI.text(panel, "SETTINGS", { Size = UDim2.new(1, 0, 0, 34), TextColor3 = UI.colors.gold, ZIndex = 51 })
	local voices = UI.button(panel, "", UI.colors.panel2, { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 50),
		ZIndex = 51 })
	local function refresh()
		voices.Text = "Client voices: " .. (Voice.speakerOn and "ON" or "OFF")
	end
	refresh()
	voices.Activated:Connect(function()
		Voice.speakerOn = not Voice.speakerOn
		refresh()
	end)
	UI.button(panel, "CLOSE", UI.colors.red, { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 120), ZIndex = 51 },
		function()
			panel:Destroy()
		end)
end

function Menu.show()
	gui = UI.new("ScreenGui", { Name = "MainMenu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50,
		Parent = player:WaitForChild("PlayerGui") })
	-- a Modal button frees the mouse even though the game is locked to first person
	UI.new("TextButton", { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Parent = gui })
	local shade = UI.new("Frame", { Size = UDim2.fromScale(0.42, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.25, Parent = gui })
	UI.new("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = shade })
	local col = UI.new("Frame", { Size = UDim2.new(0, 420, 1, -80), Position = UDim2.fromOffset(60, 60), BackgroundTransparency = 1,
		Parent = gui })
	UI.text(col, "WOLVES", { Size = UDim2.new(1, 0, 0, 90), TextColor3 = UI.colors.gold, TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Left })
	UI.text(col, "WITH YOUR FRIENDS", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(4, 88),
		TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.4 })
	UI.text(col, "Floor 100 is hiring. Don't get fired.", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(4, 134),
		Font = UI.body, TextColor3 = Color3.fromRGB(230, 220, 200), TextXAlignment = Enum.TextXAlignment.Left })
	local buttons = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 380), Position = UDim2.fromOffset(0, 190), BackgroundTransparency = 1,
		Parent = col })
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), Parent = buttons })
	local spawned = false
	local function quickMatch(look)
		if spawned then
			return
		end
		spawned = true
		local fade = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
			ZIndex = 100, Parent = gui })
		TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 0 }):Play()
		Net.Spawn:FireServer(look)
		local char = player.Character or player.CharacterAdded:Wait()
		char:WaitForChild("HumanoidRootPart")
		stopFlyover()
		task.wait(0.3)
		gui:Destroy()
		if Menu.onSpawn then
			Menu.onSpawn()
		end
	end
	local items = {
		{ "QUICK MATCH", UI.colors.gold, quickMatch },
		{ "CREATE PRIVATE OFFICE", UI.colors.panel2, function()
			toast(buttons, "Private offices are coming in the next update!")
		end },
		{ "JOIN PRIVATE OFFICE", UI.colors.panel2, function()
			toast(buttons, "Private offices are coming in the next update!")
		end },
		{ "CUSTOMIZE CHARACTER", UI.colors.panel2, function()
			if spawned then
				return
			end
			gui.Enabled = false
			Customizer.open(function(look)
				if gui then
					gui.Enabled = true
				end
				if look then
					quickMatch(look)
				end
			end)
		end },
		{ "SHOP", UI.colors.panel2, function()
			toast(buttons, "The shop opens soon!")
		end },
		{ "SETTINGS", UI.colors.panel2, settingsPanel },
	}
	for i, item in items do
		local b = UI.button(buttons, item[1], item[2], { Size = UDim2.new(1, 0, 0, i == 1 and 64 or 48), LayoutOrder = i,
			TextColor3 = i == 1 and Color3.fromRGB(40, 25, 5) or Color3.new(1, 1, 1) }, item[3])
		UI.new("UIStroke", { Color = UI.colors.gold, Thickness = i == 1 and 0 or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = b })
	end
	startFlyover()
end

return Menu
