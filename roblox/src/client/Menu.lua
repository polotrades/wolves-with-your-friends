-- Main menu before spawning: camera flies around the tower at sunset, helicopters circle,
-- and the luxury menu picks how you join. Quick Match spawns you straight onto floor 100.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local UI = require(script.Parent:WaitForChild("UI"))
local Voice = require(script.Parent:WaitForChild("Voice"))
local Customizer = require(script.Parent:WaitForChild("Customizer"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Menu = { onSpawn = nil :: (() -> ())? }

local player = Players.LocalPlayer
local gui: ScreenGui
local flyConn: RBXScriptConnection?
local menuScene: Folder?
local musicFolder: Folder?
local musicOn = false
local savedClock: number?

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

-- the menu diorama is built far above the map so it never clips the office/city
local MENU_BASE = Vector3.new(0, 2000, 0)

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

-- a tall glass tower covered in warm-lit windows, with a few chaotic office floors you can see into
local function buildTower(folder: Instance, base: Vector3, floors: number, flicker: { Part }, interiors: { any })
	local W = 46
	local fh = 12 -- floor height
	local glass = Color3.fromRGB(26, 32, 54)
	local frame = Color3.fromRGB(18, 20, 30)
	local warm = Color3.fromRGB(255, 206, 120)
	local chaosFloors = { math.floor(floors * 0.5), math.floor(floors * 0.5) + 1, math.floor(floors * 0.62) }
	local function isChaos(f)
		for _, c in chaosFloors do
			if c == f then
				return true
			end
		end
		return false
	end
	-- core slab + corners
	mPart(folder, Vector3.new(W, floors * fh, W), CFrame.new(base + Vector3.new(0, floors * fh / 2, 0)), glass, Enum.Material.Glass)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			mPart(folder, Vector3.new(1.6, floors * fh, 1.6), CFrame.new(base + Vector3.new(sx * W / 2, floors * fh / 2, sz * W / 2)),
				frame, Enum.Material.Metal)
		end
	end
	local rng = Random.new(99)
	-- windows on all four faces
	for f = 0, floors - 1 do
		local z = base.Y + f * fh + fh / 2
		-- floor slab line
		for _, face in { 0, 1 } do
			-- face 0 = +/-Z faces, face 1 = +/-X faces
		end
		mPart(folder, Vector3.new(W + 0.4, 0.6, W + 0.4), CFrame.new(base.X, z - fh / 2, base.Z), frame)
		local chaos = isChaos(f)
		for col = -3, 3 do
			for _, face in { "px", "nx", "pz", "nz" } do
				local lit = chaos or rng:NextNumber() < 0.78
				local col3 = lit and (chaos and Color3.fromRGB(255, 170, 90) or warm) or Color3.fromRGB(40, 48, 72)
				local winSize, cf
				local off = col * 5.6
				if face == "pz" then
					cf = CFrame.new(base.X + off, z, base.Z + W / 2 + 0.1)
					winSize = Vector3.new(4.4, fh - 2.4, 0.3)
				elseif face == "nz" then
					cf = CFrame.new(base.X + off, z, base.Z - W / 2 - 0.1)
					winSize = Vector3.new(4.4, fh - 2.4, 0.3)
				elseif face == "px" then
					cf = CFrame.new(base.X + W / 2 + 0.1, z, base.Z + off)
					winSize = Vector3.new(0.3, fh - 2.4, 4.4)
				else
					cf = CFrame.new(base.X - W / 2 - 0.1, z, base.Z + off)
					winSize = Vector3.new(0.3, fh - 2.4, 4.4)
				end
				local w = mPart(folder, winSize, cf, col3, lit and Enum.Material.Neon or Enum.Material.Glass)
				if lit and (chaos or rng:NextNumber() < 0.15) and #flicker < 60 then
					table.insert(flicker, w)
				end
				-- interior hint on the front (-Z) chaos floors: desks + figures behind the glass
				if chaos and face == "nz" and col % 2 == 0 then
					local ix = base.X + off
					mPart(folder, Vector3.new(3.4, 1.2, 1.6), CFrame.new(ix, z - fh / 2 + 1.6, base.Z - W / 2 + 1.6),
						Color3.fromRGB(60, 44, 30), Enum.Material.Wood) -- desk
					local fig = mPart(folder, Vector3.new(1.1, 2.4, 1.1), CFrame.new(ix, z - fh / 2 + 2.6, base.Z - W / 2 + 2.6),
						Color3.fromRGB(20, 22, 34)) -- a silhouette worker, waving
					mPart(folder, Vector3.new(0.9, 0.9, 0.9), CFrame.new(ix, z - fh / 2 + 4.0, base.Z - W / 2 + 2.6),
						Color3.fromRGB(230, 190, 150), nil) -- head
					table.insert(interiors, { part = fig, base = fig.CFrame, phase = rng:NextNumber(0, 6) })
				end
			end
		end
	end
	-- a glowing WOLF & CO. neon sign high on the front face
	local signY = base.Y + (floors - 2) * fh
	local signBack = mPart(folder, Vector3.new(34, 7, 1), CFrame.new(base.X, signY, base.Z - W / 2 - 0.6),
		Color3.fromRGB(10, 10, 14))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.PixelsPerStud = 24
	sg.Parent = signBack
	-- face -Z: SurfaceGui Front points +Z by default, so rotate the sign to face the camera side
	signBack.CFrame = CFrame.new(base.X, signY, base.Z - W / 2 - 0.6) * CFrame.Angles(0, math.pi, 0)
	local neon = Instance.new("TextLabel")
	neon.Size = UDim2.fromScale(1, 0.6)
	neon.Position = UDim2.fromScale(0, 0.08)
	neon.BackgroundTransparency = 1
	neon.Font = Enum.Font.FredokaOne
	neon.Text = "WOLF & CO."
	neon.TextColor3 = UI.colors.gold
	neon.TextScaled = true
	neon.Parent = sg
	local neon2 = Instance.new("TextLabel")
	neon2.Size = UDim2.fromScale(1, 0.28)
	neon2.Position = UDim2.fromScale(0, 0.68)
	neon2.BackgroundTransparency = 1
	neon2.Font = Enum.Font.GothamBold
	neon2.Text = "FLOOR 100"
	neon2.TextColor3 = Color3.fromRGB(120, 200, 255)
	neon2.TextScaled = true
	neon2.Parent = sg
	local signGlow = mPart(folder, Vector3.new(34, 7, 0.3), CFrame.new(base.X, signY, base.Z - W / 2 - 1.1),
		UI.colors.gold, Enum.Material.Neon)
	signGlow.Transparency = 0.75
	-- rooftop parapet + antenna + helipad H
	local roofY = base.Y + floors * fh
	mPart(folder, Vector3.new(W + 2, 1.5, W + 2), CFrame.new(base.X, roofY + 0.75, base.Z), frame, Enum.Material.Metal)
	mPart(folder, Vector3.new(0.8, 20, 0.8), CFrame.new(base.X + 12, roofY + 10, base.Z + 12), Color3.fromRGB(60, 60, 70),
		Enum.Material.Metal)
	mPart(folder, Vector3.new(1.2, 1.2, 1.2), CFrame.new(base.X + 12, roofY + 20, base.Z + 12), Color3.fromRGB(255, 70, 70),
		Enum.Material.Neon)
	return Vector3.new(base.X, roofY, base.Z)
end

-- an American flag on a pole; returns the cloth segments so the loop can wave them
local function buildFlag(folder: Instance, at: Vector3): { any }
	mPart(folder, Vector3.new(0.6, 26, 0.6), CFrame.new(at + Vector3.new(0, 13, 0)), Color3.fromRGB(220, 220, 230),
		Enum.Material.Metal)
	mPart(folder, Vector3.new(1, 1, 1), CFrame.new(at + Vector3.new(0, 26, 0)), UI.colors.gold, Enum.Material.Neon)
	local segs = {}
	local top = at + Vector3.new(0, 24, 0)
	local segW = 1.7
	for s = 0, 7 do
		local x = top.X + 0.4 + s * segW
		local seg = Instance.new("Model")
		seg.Name = "FlagSeg"
		for stripe = 0, 12 do
			local red = stripe % 2 == 0
			local p = mPart(seg, Vector3.new(segW, 0.75, 0.15),
				CFrame.new(x, top.Y - stripe * 0.75, at.Z), red and Color3.fromRGB(200, 40, 50) or Color3.fromRGB(245, 245, 248))
			if stripe < 7 and s < 4 then
				p.Color = Color3.fromRGB(30, 50, 130) -- blue canton over the first 7 stripes / 4 segments
				if (stripe % 2 == 0) and (s % 2 == 0) then
					mPart(seg, Vector3.new(0.25, 0.25, 0.2), CFrame.new(x, top.Y - stripe * 0.75, at.Z - 0.1),
						Color3.fromRGB(255, 255, 255))
				end
			end
		end
		seg.Parent = folder
		table.insert(segs, { model = seg, x = s, basePivot = seg:GetPivot() })
	end
	return segs
end

-- a ring of simpler background skyscrapers for a city-at-dusk skyline
local function buildSkyline(folder: Instance, base: Vector3)
	local rng = Random.new(7)
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		local r = rng:NextNumber(170, 340)
		local h = rng:NextNumber(120, 320)
		local w = rng:NextNumber(26, 46)
		local pos = base + Vector3.new(math.cos(a) * r, h / 2 - 40, math.sin(a) * r)
		local tint = Color3.fromRGB(rng:NextInteger(24, 40), rng:NextInteger(28, 44), rng:NextInteger(44, 66))
		mPart(folder, Vector3.new(w, h, w), CFrame.new(pos), tint, Enum.Material.Glass)
		-- a few lit window bands
		for b = 1, math.floor(h / 24) do
			if rng:NextNumber() < 0.6 then
				mPart(folder, Vector3.new(w + 0.3, 2, w + 0.3), CFrame.new(pos + Vector3.new(0, -h / 2 + b * 24, 0)),
					Color3.fromRGB(255, 200, 130), Enum.Material.Neon).Transparency = 0.1
			end
		end
	end
end

-- gentle piano-style background music, synthesised from the built-in tone so nothing needs uploading
local function startMusic()
	if musicOn then
		return
	end
	musicOn = true
	local folder = Instance.new("Folder")
	folder.Name = "MenuMusic"
	folder.Parent = SoundService
	musicFolder = folder
	-- a calm vi-IV-I-V progression, arpeggiated (semitones relative to A3)
	local chords = { { -12, -8, -5, 0 }, { -16, -9, -5, -1 }, { -17, -12, -8, -5 }, { -14, -10, -7, -2 } }
	task.spawn(function()
		local step = 0
		while musicOn and folder.Parent do
			local chord = chords[(step // 4) % #chords + 1]
			local semi = chord[(step % 4) + 1]
			local s = Instance.new("Sound")
			s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			s.PlaybackSpeed = 2 ^ (semi / 12) * 0.5
			s.Volume = 0.28
			s.Parent = folder
			s:Play()
			task.delay(2.5, function()
				s:Destroy()
			end)
			step += 1
			task.wait(0.5)
		end
	end)
end

local function stopMusic()
	musicOn = false
	if musicFolder then
		musicFolder:Destroy()
		musicFolder = nil
	end
end

local function startFlyover()
	local cam = Workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	-- dusk: 6:30 PM
	savedClock = Lighting.ClockTime
	Lighting.ClockTime = 18.5
	local folder = Instance.new("Folder")
	folder.Name = "MenuScene"
	folder.Parent = Workspace
	menuScene = folder

	local flicker: { Part } = {}
	local interiors: { any } = {}
	local roofTop = buildTower(folder, MENU_BASE, 26, flicker, interiors)
	buildSkyline(folder, MENU_BASE)
	local flagSegs = buildFlag(folder, roofTop + Vector3.new(-16, 0, -16))

	-- flying papers swirling out of the chaos floors
	local papers = {}
	local chaosY = MENU_BASE.Y + 26 * 12 * 0.55
	for _ = 1, 46 do
		local pp = mPart(folder, Vector3.new(1.1, 0.05, 1.5),
			CFrame.new(MENU_BASE + Vector3.new(math.random(-40, 40), chaosY - MENU_BASE.Y + math.random(-30, 30),
				math.random(-40, 40))), Color3.fromRGB(250, 250, 245))
		table.insert(papers, { part = pp, phase = math.random() * 6.28, radius = math.random(28, 60),
			y0 = pp.Position.Y, spin = math.random(2, 6) })
	end

	local choppers = {}
	for i, c in { Color3.fromRGB(230, 60, 50), Color3.fromRGB(240, 240, 240), Color3.fromRGB(30, 30, 35) } do
		local m, rotor = buildHelicopter(folder, c)
		table.insert(choppers, { model = m, rotor = rotor, radius = 150 + i * 55, height = 150 + i * 40, speed = 0.08 + i * 0.03,
			phase = i * 2.1 })
	end

	startMusic()
	local t0 = os.clock()
	flyConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local a = t * 0.04
		local look = MENU_BASE + Vector3.new(0, 170, 0)
		cam.CFrame = CFrame.lookAt(MENU_BASE + Vector3.new(math.cos(a) * 430, 150 + math.sin(t * 0.2) * 20, math.sin(a) * 430),
			look)
		-- flicker the chaos windows
		for _, w in flicker do
			w.Transparency = (math.sin(t * 8 + w.Position.Y) > 0.3) and 0 or 0.4
		end
		-- waving flag: offset each segment from its stored base pivot (further segments wave more)
		for _, seg in flagSegs do
			local wave = math.sin(t * 3 - seg.x * 0.6) * (0.3 + seg.x * 0.25)
			seg.model:PivotTo(seg.basePivot * CFrame.new(0, 0, wave) * CFrame.Angles(0, math.rad(wave * 6), 0))
		end
		-- swirling papers
		for _, pr in papers do
			local b = pr.phase + t * 0.6
			pr.part.CFrame = CFrame.new(MENU_BASE.X + math.cos(b) * pr.radius, pr.y0 + math.sin(t * 0.5 + pr.phase) * 14,
				MENU_BASE.Z + math.sin(b) * pr.radius) * CFrame.Angles(t * pr.spin, t * pr.spin * 0.7, 0)
		end
		-- insane workers inside: shaking
		for _, it in interiors do
			it.part.CFrame = it.base * CFrame.Angles(0, 0, math.sin(t * 10 + it.phase) * 0.25)
		end
		for _, h in choppers do
			local b = h.phase + t * h.speed
			local pos = MENU_BASE + Vector3.new(math.cos(b) * h.radius, h.height + math.sin(t + h.phase) * 6, math.sin(b) * h.radius)
			local ahead = MENU_BASE + Vector3.new(math.cos(b + 0.05) * h.radius, pos.Y - MENU_BASE.Y, math.sin(b + 0.05) * h.radius)
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
	stopMusic()
	if menuScene then
		menuScene:Destroy()
		menuScene = nil
	end
	if savedClock then
		Lighting.ClockTime = savedClock
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
