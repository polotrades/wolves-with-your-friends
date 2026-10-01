-- Main menu before spawning. The whole background is a 2D painting of the trading floor at dusk (6-7pm):
-- a wall of windows over a city skyline, desks with monitors running live candlestick charts, an American flag,
-- and papers + cash tumbling through the air. It is pure GUI so it can never black-screen, and calm rich piano
-- plays over soft phone rings and the rustle of paper.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent:WaitForChild("UI"))
local Voice = require(script.Parent:WaitForChild("Voice"))
local Customizer = require(script.Parent:WaitForChild("Customizer"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))

local Menu = { onSpawn = nil :: (() -> ())? }

local player = Players.LocalPlayer
local gui: ScreenGui
local sceneConn: RBXScriptConnection?
local musicFolder: Folder?
local musicOn = false

local function frame(parent: Instance, props): Frame
	return UI.new("Frame", props) :: Frame
end

-- ---------------------------------------------------------------- audio
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

-- ---------------------------------------------------------------- 2D office scene
-- Builds the whole office interior as GUI into `root` and returns an update(t) callback for the animation loop.
local function buildOffice(root: Frame): (number) -> ()
	-- dusk sky seen through the windows (6-7pm): warm orange low, deep blue up high
	local sky = frame(root, { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 1,
		BackgroundColor3 = Color3.fromRGB(30, 34, 70), Parent = root })
	UI.new("UIGradient", { Rotation = 90, Parent = sky, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 28, 66)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(70, 60, 110)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(226, 126, 72)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 96)),
	}) })

	-- a hazy sun glow low on the horizon
	local sun = frame(root, { Size = UDim2.fromScale(0.26, 0.42), Position = UDim2.fromScale(0.58, 0.42),
		BorderSizePixel = 0, ZIndex = 2, BackgroundColor3 = Color3.fromRGB(255, 210, 150), Parent = root })
	UI.corner(sun, 999)
	UI.new("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }), Rotation = 90, Parent = sun })

	-- city skyline silhouette along the horizon, with lit windows
	local rng = Random.new(1337)
	local skyline = frame(root, { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.32),
		BackgroundTransparency = 1, ZIndex = 3, Parent = root })
	local x = -0.02
	while x < 1.02 do
		local w = 0.04 + rng:NextNumber() * 0.05
		local h = 0.3 + rng:NextNumber() * 0.62
		local shade = 18 + math.floor(rng:NextNumber() * 20)
		local b = frame(skyline, { Size = UDim2.fromScale(w, h), Position = UDim2.fromScale(x, 1 - h),
			BorderSizePixel = 0, ZIndex = 3, BackgroundColor3 = Color3.fromRGB(shade, shade + 4, shade + 22),
			Parent = skyline })
		-- scattered lit windows
		for _ = 1, math.floor(h * 14) do
			if rng:NextNumber() < 0.5 then
				frame(b, { Size = UDim2.fromScale(0.16, 0.03), BorderSizePixel = 0, ZIndex = 3,
					Position = UDim2.fromScale(0.1 + rng:NextNumber() * 0.7, 0.08 + rng:NextNumber() * 0.85),
					BackgroundColor3 = Color3.fromRGB(255, 220, 140), Parent = b })
			end
		end
		x += w + 0.004
	end

	-- the window wall: mullions dividing the glass into panes (thin dark frames over everything so far)
	local glass = frame(root, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Parent = root })
	local mull = Color3.fromRGB(16, 18, 26)
	for i = 0, 8 do
		frame(glass, { Size = UDim2.new(0, 6, 0.72, 0), Position = UDim2.new(i / 8, -3, 0, 0), BorderSizePixel = 0,
			ZIndex = 4, BackgroundColor3 = mull, Parent = glass })
	end
	for _, yy in { 0, 0.26, 0.52, 0.72 } do
		frame(glass, { Size = UDim2.new(1, 0, 0, yy == 0.72 and 12 or 6), Position = UDim2.fromScale(0, yy),
			BorderSizePixel = 0, ZIndex = 4, BackgroundColor3 = mull, Parent = glass })
	end
	-- faint glass reflection sheen
	local sheen = frame(glass, { Size = UDim2.fromScale(1, 0.72), BorderSizePixel = 0, ZIndex = 4,
		BackgroundColor3 = Color3.fromRGB(180, 200, 255), Parent = glass })
	UI.new("UIGradient", { Rotation = 25, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.5, 1), NumberSequenceKeypoint.new(1, 0.9) }),
		Parent = sheen })

	-- the office interior: wall below the windows, carpet floor, baseboard
	local wall = frame(root, { Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0.72), BorderSizePixel = 0,
		ZIndex = 5, BackgroundColor3 = Color3.fromRGB(44, 40, 52), Parent = root })
	UI.new("UIGradient", { Rotation = 90, Parent = wall, Color = ColorSequence.new(
		Color3.fromRGB(58, 52, 66), Color3.fromRGB(38, 34, 46)) })
	local floorC = frame(root, { Size = UDim2.fromScale(1, 0.18), Position = UDim2.fromScale(0, 0.82), BorderSizePixel = 0,
		ZIndex = 5, BackgroundColor3 = Color3.fromRGB(34, 28, 32), Parent = root })
	UI.new("UIGradient", { Rotation = 90, Parent = floorC, Color = ColorSequence.new(
		Color3.fromRGB(46, 38, 42), Color3.fromRGB(24, 20, 24)) })

	-- trading desks with monitors running live candlestick charts
	local bars: { { bar: Frame, wick: Frame } } = {}
	local deskXs = { 0.06, 0.3, 0.72 }
	for _, dx in deskXs do
		local desk = frame(root, { Size = UDim2.fromScale(0.22, 0.12), Position = UDim2.fromScale(dx, 0.73),
			BorderSizePixel = 0, ZIndex = 6, BackgroundColor3 = Color3.fromRGB(58, 44, 36), Parent = root })
		UI.corner(desk, 4)
		-- two monitors on the desk
		for m = 0, 1 do
			local screen = frame(root, { Size = UDim2.fromScale(0.095, 0.1), ZIndex = 7,
				Position = UDim2.fromScale(dx + 0.01 + m * 0.105, 0.62), BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(10, 14, 18), Parent = root })
			UI.corner(screen, 4)
			UI.new("UIStroke", { Color = Color3.fromRGB(8, 8, 10), Thickness = 3, Parent = screen })
			-- candlesticks across the screen
			local n = 9
			for k = 1, n do
				local up = rng:NextNumber() < 0.5
				local col = up and UI.colors.green or UI.colors.red
				local wick = frame(screen, { Size = UDim2.new(0, 1, 0.5, 0), ZIndex = 7,
					Position = UDim2.new((k - 0.5) / n, 0, 0.25, 0), AnchorPoint = Vector2.new(0.5, 0),
					BorderSizePixel = 0, BackgroundColor3 = col, Parent = screen })
				local bar = frame(screen, { Size = UDim2.new(0.6 / n, 0, 0.3, 0), ZIndex = 7,
					Position = UDim2.new((k - 0.5) / n, 0, 0.4, 0), AnchorPoint = Vector2.new(0.5, 0),
					BorderSizePixel = 0, BackgroundColor3 = col, Parent = screen })
				table.insert(bars, { bar = bar, wick = wick })
			end
		end
		-- a desk chair silhouette
		frame(root, { Size = UDim2.fromScale(0.05, 0.08), Position = UDim2.fromScale(dx + 0.085, 0.8), BorderSizePixel = 0,
			ZIndex = 6, BackgroundColor3 = Color3.fromRGB(26, 24, 28), Parent = root })
	end

	-- American flag on the wall between the windows
	local flag = frame(root, { Size = UDim2.fromScale(0.1, 0.07), Position = UDim2.fromScale(0.86, 0.1), BorderSizePixel = 0,
		ZIndex = 6, BackgroundColor3 = Color3.fromRGB(235, 235, 235), Parent = root })
	UI.new("UIStroke", { Color = Color3.fromRGB(20, 20, 24), Thickness = 2, Parent = flag })
	for s = 0, 6 do
		frame(flag, { Size = UDim2.fromScale(1, 1 / 13), Position = UDim2.fromScale(0, s * 2 / 13), BorderSizePixel = 0,
			ZIndex = 6, BackgroundColor3 = Color3.fromRGB(200, 40, 50), Parent = flag })
	end
	local canton = frame(flag, { Size = UDim2.fromScale(0.42, 7 / 13), Position = UDim2.fromScale(0, 0), BorderSizePixel = 0,
		ZIndex = 7, BackgroundColor3 = Color3.fromRGB(40, 50, 120), Parent = flag })
	for sy = 0, 3 do
		for sx = 0, 3 do
			frame(canton, { Size = UDim2.fromScale(0.08, 0.1), ZIndex = 7, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.18 + sx * 0.22, 0.2 + sy * 0.25), BorderSizePixel = 0,
				BackgroundColor3 = Color3.fromRGB(240, 240, 240), Parent = canton })
		end
	end
	frame(root, { Size = UDim2.new(0, 3, 0.09, 0), Position = UDim2.fromScale(0.858, 0.1), BorderSizePixel = 0,
		ZIndex = 6, BackgroundColor3 = Color3.fromRGB(120, 100, 60), Parent = root })

	-- papers + cash tumbling through the air
	type Bit = { f: Frame, x: number, y: number, vx: number, vy: number, spin: number, rot: number, sway: number, ph: number }
	local bits: { Bit } = {}
	for i = 1, 26 do
		local money = i % 3 == 0
		local f = frame(root, {
			Size = money and UDim2.fromOffset(34, 16) or UDim2.fromOffset(26, 34),
			BorderSizePixel = 0, ZIndex = 8, BackgroundColor3 = money and Color3.fromRGB(96, 170, 100) or Color3.fromRGB(248, 248, 240),
			AnchorPoint = Vector2.new(0.5, 0.5), Parent = root })
		UI.corner(f, 2)
		if money then
			UI.new("UIStroke", { Color = Color3.fromRGB(60, 120, 70), Thickness = 1, Parent = f })
			UI.text(f, "$", { TextColor3 = Color3.fromRGB(230, 245, 230), Font = UI.bold, ZIndex = 8 })
		else
			-- a couple of printed lines on the sheet
			for ln = 1, 3 do
				frame(f, { Size = UDim2.fromScale(0.7, 0.08), Position = UDim2.fromScale(0.15, 0.2 + ln * 0.18),
					BorderSizePixel = 0, ZIndex = 8, BackgroundColor3 = Color3.fromRGB(160, 160, 170), Parent = f })
			end
		end
		local b: Bit = { f = f, x = math.random(), y = math.random(), vx = (math.random() - 0.5) * 0.06,
			vy = -0.02 - math.random() * 0.05, spin = (math.random() - 0.5) * 4, rot = math.random() * 360,
			sway = 0.04 + math.random() * 0.06, ph = math.random() * 6.28 }
		table.insert(bits, b)
	end

	local lastChart = 0
	return function(dt: number)
		-- drift the papers/cash up and across, wrapping around the screen
		for _, b in bits do
			b.x += (b.vx + math.sin(os.clock() * 0.8 + b.ph) * b.sway) * dt
			b.y += b.vy * dt
			b.rot += b.spin * dt * 24
			if b.y < -0.08 then
				b.y = 1.08
				b.x = math.random()
			end
			if b.x < -0.08 then
				b.x = 1.08
			elseif b.x > 1.08 then
				b.x = -0.08
			end
			b.f.Position = UDim2.fromScale(b.x, b.y)
			b.f.Rotation = b.rot
		end
		-- re-roll the candlestick charts a few times a second so they look live
		if os.clock() - lastChart > 0.18 then
			lastChart = os.clock()
			for _, c in bars do
				local up = math.random() < 0.5
				local col = up and UI.colors.green or UI.colors.red
				local body = 0.12 + math.random() * 0.4
				local top = 0.1 + math.random() * (0.8 - body)
				c.bar.BackgroundColor3 = col
				c.bar.Size = UDim2.new(c.bar.Size.X.Scale, 0, body, 0)
				c.bar.Position = UDim2.new(c.bar.Position.X.Scale, 0, top, 0)
				c.wick.BackgroundColor3 = col
				c.wick.Size = UDim2.new(0, 1, body + 0.2, 0)
				c.wick.Position = UDim2.new(c.wick.Position.X.Scale, 0, math.max(0.02, top - 0.1), 0)
			end
		end
	end
end

local function startScene(scene: Frame)
	local update = buildOffice(scene)
	startMenuAudio()
	sceneConn = RunService.RenderStepped:Connect(function(dt)
		update(dt)
	end)
end

local function stopScene()
	if sceneConn then
		sceneConn:Disconnect()
		sceneConn = nil
	end
	stopMenuAudio()
end

local function toast(parent: Instance, text: string)
	local l = UI.text(parent, text, { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, 8),
		TextColor3 = UI.colors.gold, Font = UI.bold, ZIndex = 20 })
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
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
	-- a Modal button frees the mouse even though the game is locked to first person
	UI.new("TextButton", { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Parent = gui })

	-- the full-screen 2D office background (ZIndex 1, so everything else draws on top of it)
	local scene = frame(gui, { Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 1, ClipsDescendants = true,
		BackgroundColor3 = Color3.fromRGB(26, 28, 66), Parent = gui })

	-- a dark shade on the left so the title and buttons stay readable over the scene
	local shade = frame(gui, { Size = UDim2.new(0, 560, 1, 0), BorderSizePixel = 0, ZIndex = 10,
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.15, Parent = gui })
	UI.new("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Parent = shade })

	local col = UI.new("Frame", { Size = UDim2.new(0, 420, 1, -80), Position = UDim2.fromOffset(60, 60), BackgroundTransparency = 1,
		ZIndex = 11, Parent = gui })
	UI.text(col, "WOLVES", { Size = UDim2.new(1, 0, 0, 90), TextColor3 = UI.colors.gold, TextStrokeTransparency = 0.2,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 })
	UI.text(col, "WITH YOUR FRIENDS", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(4, 88),
		TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.4, ZIndex = 11 })
	UI.text(col, "Floor 100 is hiring. Don't get fired.", { Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(4, 134),
		Font = UI.body, TextColor3 = Color3.fromRGB(230, 220, 200), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11 })
	local buttons = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 380), Position = UDim2.fromOffset(0, 190), BackgroundTransparency = 1,
		ZIndex = 11, Parent = col })
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), Parent = buttons })
	local spawned = false
	local function quickMatch(look)
		if spawned then
			return
		end
		spawned = true
		-- fade the menu to black, then stop the menu scene straight away so the office can take over
		local fade = frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
			ZIndex = 100, Parent = gui })
		local status = UI.text(fade, "Joining Floor 100", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0.62, 0),
			TextColor3 = UI.colors.gold, Font = UI.body, ZIndex = 101 })
		TweenService:Create(fade, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
		task.wait(0.4)
		stopScene()

		-- ask the server to spawn us, and wait for a real character (with a timeout + retry so we never hang on black)
		local function waitForChar(timeout: number): Model?
			local c = player.Character
			if c and c:FindFirstChild("HumanoidRootPart") then
				return c
			end
			local deadline = os.clock() + timeout
			while os.clock() < deadline do
				c = player.Character
				if c and c:FindFirstChild("HumanoidRootPart") then
					return c
				end
				task.wait(0.1)
			end
			return nil
		end
		Net.Spawn:FireServer(look)
		local char = waitForChar(8)
		if not char then
			status.Text = "Still joining…"
			Net.Spawn:FireServer(look)
			char = waitForChar(10)
		end

		-- hand the camera back to the game (first person) and reveal the office
		local cam = Workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					cam.CameraSubject = hum
				end
			end
		end
		task.wait(0.3)
		if gui then
			gui:Destroy()
		end
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
			ZIndex = 11, TextColor3 = i == 1 and Color3.fromRGB(40, 25, 5) or Color3.new(1, 1, 1) }, item[3])
		UI.new("UIStroke", { Color = UI.colors.gold, Thickness = i == 1 and 0 or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = b })
	end
	startScene(scene)
end

return Menu
