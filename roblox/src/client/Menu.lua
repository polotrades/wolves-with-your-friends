-- Main menu before spawning: camera flies around the tower at sunset, helicopters circle,
-- and the luxury menu picks how you join. Quick Match spawns you straight onto floor 100.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local UI = require(script.Parent:WaitForChild("UI"))
local Voice = require(script.Parent:WaitForChild("Voice"))
local Customizer = require(script.Parent:WaitForChild("Customizer"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))

local Menu = { onSpawn = nil :: (() -> ())? }

local player = Players.LocalPlayer
local gui: ScreenGui
local flyConn: RBXScriptConnection?
local menuScene: Folder?
local musicFolder: Folder?
local musicOn = false

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

-- The menu background is the real office floor: the camera sweeps the trading floor while papers and cash swirl in
-- the air and the desk monitors keep running their live charts. Calm, rich piano plays over soft phone rings and
-- the rustle of paper, and helicopters circle outside the windows.
local function mPart(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- calm chorded piano (with reverb) + an occasional phone ring + shuffling paper, all from built-in sounds
local function startMenuAudio()
	if musicOn then
		return
	end
	musicOn = true
	local group = Instance.new("SoundGroup")
	group.Name = "MenuAudio"
	group.Volume = 1
	group.Parent = SoundService
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 2.4
	reverb.WetLevel = -3
	reverb.Parent = group
	musicFolder = group
	local function tone(semi: number, vol: number, life: number)
		local s = Instance.new("Sound")
		s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		s.PlaybackSpeed = 2 ^ (semi / 12) * 0.5
		s.Volume = vol
		s.SoundGroup = group
		s.Parent = group
		s:Play()
		task.delay(life, function()
			s:Destroy()
		end)
	end
	-- rich vi-IV-I-V chords (root/third/fifth) with a gentle top note between them
	local chords = { { -12, -8, -5 }, { -16, -9, -5 }, { -17, -13, -8 }, { -14, -10, -7 } }
	task.spawn(function()
		local step = 0
		while musicOn and group.Parent do
			local c = chords[step % #chords + 1]
			for _, semi in c do
				tone(semi, 0.17, 3)
			end
			task.wait(1.1)
			tone(c[1] + 12 + (step % 3) * 2, 0.11, 2)
			task.wait(1.1)
			step += 1
		end
	end)
	-- a desk phone ringing now and then (two short rings)
	task.spawn(function()
		while musicOn and group.Parent do
			task.wait(6 + math.random() * 4)
			for _ = 1, 2 do
				if not (musicOn and group.Parent) then
					break
				end
				local s = Instance.new("Sound")
				s.SoundId = Config.SOUNDS.ring ~= "" and Config.SOUNDS.ring or "rbxasset://sounds/electronicpingshort.wav"
				s.Volume = 0.22
				s.PlaybackSpeed = 1.5
				s.Parent = group
				s:Play()
				task.delay(1.2, function()
					s:Destroy()
				end)
				task.wait(0.45)
			end
		end
	end)
	-- paper shuffling
	task.spawn(function()
		while musicOn and group.Parent do
			task.wait(1.5 + math.random() * 2)
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/clickfast.wav"
			s.Volume = 0.12
			s.PlaybackSpeed = 0.8 + math.random() * 0.5
			s.Parent = group
			s:Play()
			task.delay(1, function()
				s:Destroy()
			end)
		end
	end)
end

local function stopMenuAudio()
	musicOn = false
	if musicFolder then
		musicFolder:Destroy()
		musicFolder = nil
	end
end

local function startFlyover()
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local folder = Instance.new("Folder")
	folder.Name = "MenuScene"
	folder.Parent = Workspace
	menuScene = folder

	-- frame the real office interior (centre on Floor100's parts)
	local floor = Workspace:FindFirstChild("Floor100")
	local center = Vector3.new(0, 9, 0)
	local extent = 42
	if floor then
		local lo = Vector3.new(1e9, 1e9, 1e9)
		local hi = Vector3.new(-1e9, -1e9, -1e9)
		for _, d in floor:GetDescendants() do
			if d:IsA("BasePart") then
				lo = lo:Min(d.Position)
				hi = hi:Max(d.Position)
			end
		end
		if lo.X < hi.X then
			center = Vector3.new((lo.X + hi.X) / 2, (lo.Y + hi.Y) / 2 + 4, (lo.Z + hi.Z) / 2)
			extent = math.clamp(math.min(hi.X - lo.X, hi.Z - lo.Z) * 0.3, 24, 60)
		end
	end

	-- flying papers + money swirling over the floor
	local bits = {}
	for i = 1, 60 do
		local money = i % 3 == 0
		local pp = mPart(folder, money and Vector3.new(1.0, 0.04, 0.45) or Vector3.new(0.9, 0.03, 1.2),
			CFrame.new(center + Vector3.new(math.random(-30, 30), math.random(0, 16), math.random(-24, 24))),
			money and Color3.fromRGB(90, 170, 90) or Color3.fromRGB(250, 250, 245))
		table.insert(bits, { part = pp, phase = math.random() * 6.28, radius = math.random(10, 34),
			y0 = pp.Position.Y, spin = math.random(3, 8), rise = math.random(4, 12) })
	end

	-- helicopters circling outside the windows
	local choppers = {}
	for i, c in { Color3.fromRGB(230, 60, 50), Color3.fromRGB(240, 240, 240), Color3.fromRGB(30, 30, 35) } do
		local m, rotor = buildHelicopter(folder, c)
		table.insert(choppers, { model = m, rotor = rotor, radius = 120 + i * 40, height = center.Y + 40 + i * 16,
			speed = 0.08 + i * 0.03, phase = i * 2.1 })
	end

	startMenuAudio()
	local t0 = os.clock()
	flyConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local a = t * 0.08
		cam.CFrame = CFrame.lookAt(center + Vector3.new(math.cos(a) * extent, 5 + math.sin(t * 0.3) * 2, math.sin(a) * extent),
			center + Vector3.new(math.cos(a + 1.4) * 6, -2, math.sin(a + 1.4) * 6))
		for _, pr in bits do
			local b = pr.phase + t * 0.5
			local y = pr.y0 + math.sin(t * 0.6 + pr.phase) * pr.rise
			pr.part.CFrame = CFrame.new(center.X + math.cos(b) * pr.radius, y, center.Z + math.sin(b) * pr.radius)
				* CFrame.Angles(t * pr.spin * 0.3, t * pr.spin * 0.2, t * pr.spin * 0.25)
		end
		for _, h in choppers do
			local b = h.phase + t * h.speed
			local pos = Vector3.new(math.cos(b) * h.radius, h.height, math.sin(b) * h.radius)
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
	stopMenuAudio()
	if menuScene then
		menuScene:Destroy()
		menuScene = nil
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
