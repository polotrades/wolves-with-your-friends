-- Builds a playable blockout of floor 100 in code: trading floor with ringing desk computers,
-- conference room, CEO office, break room, elevator lobby, floor-to-ceiling windows and a city far below.
-- Swap pieces for the real Blender models later; gameplay only relies on the names/tables returned here.
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local OfficeBuilder = {}

local W, D, H = 180, 120, 16 -- floor width (x), depth (z), ceiling height

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape -- shape first, so the size that follows sticks
	end
	for k, v in props do
		if k ~= "Parent" and k ~= "Shape" and k ~= "Size" and k ~= "CFrame" and k ~= "Position" then
			(p :: any)[k] = v
		end
	end
	if props.Size then
		p.Size = props.Size
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	p.Parent = props.Parent
	return p
end

local function surfaceGui(p: BasePart, pixels: number?): SurfaceGui
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pixels or 50
	g.LightInfluence = 0
	g.Parent = p
	return g
end

local function label(parent: Instance, text: string, props): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Size = UDim2.fromScale(1, 1)
	for k, v in props or {} do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

-- A part whose front face (where SurfaceGuis draw) points along `facing`.
local function panel(parent: Instance, name: string, pos: Vector3, facing: Vector3, size: Vector3, color: Color3): Part
	return part({
		Name = name,
		Size = size,
		CFrame = CFrame.lookAt(pos, pos + facing),
		Color = color,
		Material = Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

local function buildShell(folder: Folder)
	part({ Name = "Floor", Size = Vector3.new(W, 1, D), Position = Vector3.new(0, -0.5, 0),
		Color = Color3.fromRGB(46, 50, 78), Material = Enum.Material.Carpet, Parent = folder })
	part({ Name = "Ceiling", Size = Vector3.new(W, 1, D), Position = Vector3.new(0, H + 0.5, 0),
		Color = Color3.fromRGB(230, 222, 208), Material = Enum.Material.Plaster, Parent = folder })
	for x = -80, 80, 20 do
		for z = -50, 50, 25 do
			local lamp = part({ Name = "CeilingLight", Size = Vector3.new(10, 0.3, 1.2), Position = Vector3.new(x, H - 0.1, z),
				Color = Color3.fromRGB(255, 236, 200), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
			local l = Instance.new("SurfaceLight")
			l.Face = Enum.NormalId.Bottom
			l.Brightness = 0.6
			l.Range = 18
			l.Color = Color3.fromRGB(255, 225, 185)
			l.Parent = lamp
		end
	end
	-- floor-to-ceiling windows with dark mullions
	local sides = {
		{ Vector3.new(0, H / 2, -D / 2), Vector3.new(W, H, 0.4), "x" },
		{ Vector3.new(0, H / 2, D / 2), Vector3.new(W, H, 0.4), "x" },
		{ Vector3.new(-W / 2, H / 2, 0), Vector3.new(0.4, H, D), "z" },
		{ Vector3.new(W / 2, H / 2, 0), Vector3.new(0.4, H, D), "z" },
	}
	for _, s in sides do
		part({ Name = "Window", Size = s[2], Position = s[1], Color = Color3.fromRGB(170, 210, 235),
			Transparency = 0.72, Material = Enum.Material.Glass, Parent = folder })
		local len = s[3] == "x" and W or D
		for t = -len / 2, len / 2, 12 do
			local pos = s[3] == "x" and Vector3.new(t, H / 2, s[1].Z) or Vector3.new(s[1].X, H / 2, t)
			part({ Name = "Mullion", Size = Vector3.new(0.8, H, 0.8), Position = pos,
				Color = Color3.fromRGB(35, 35, 40), Material = Enum.Material.Metal, Parent = folder })
		end
	end
	-- the rest of the tower, straight down to the street
	part({ Name = "TowerBody", Size = Vector3.new(W + 4, 690, D + 4), Position = Vector3.new(0, -346, 0),
		Color = Color3.fromRGB(90, 120, 150), Material = Enum.Material.Glass, Reflectance = 0.2, Parent = folder })
end

local function buildCity(folder: Folder)
	local rng = Random.new(100)
	part({ Name = "Street", Size = Vector3.new(4000, 2, 4000), Position = Vector3.new(0, -701, 0),
		Color = Color3.fromRGB(45, 45, 50), Material = Enum.Material.Asphalt, Parent = folder })
	for i = -8, 8 do
		for _, horizontal in { true, false } do
			local size = horizontal and Vector3.new(4000, 0.2, 24) or Vector3.new(24, 0.2, 4000)
			local pos = horizontal and Vector3.new(0, -699.9, i * 220) or Vector3.new(i * 220, -699.9, 0)
			part({ Name = "Road", Size = size, Position = pos, Color = Color3.fromRGB(25, 25, 28),
				Material = Enum.Material.Asphalt, CanCollide = false, Parent = folder })
		end
	end
	local palette = {
		Color3.fromRGB(70, 90, 120), Color3.fromRGB(150, 140, 125), Color3.fromRGB(60, 70, 80),
		Color3.fromRGB(180, 170, 150), Color3.fromRGB(95, 120, 140),
	}
	for _ = 1, 170 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(170, 900)
		local x, z = math.cos(a) * r, math.sin(a) * r
		local w, d = rng:NextNumber(40, 110), rng:NextNumber(40, 110)
		local top = rng:NextNumber(-260, 60) - r * 0.08
		local h = top + 700
		local b = part({ Name = "Skyscraper", Size = Vector3.new(w, h, d), Position = Vector3.new(x, -700 + h / 2, z),
			Color = palette[rng:NextInteger(1, #palette)],
			Material = rng:NextNumber() < 0.5 and Enum.Material.Glass or Enum.Material.Concrete,
			Reflectance = 0.1, CastShadow = false, Parent = folder })
		if rng:NextNumber() < 0.35 then -- lit crown on top
			part({ Name = "Crown", Size = Vector3.new(w * 0.6, 3, d * 0.6), Position = b.Position + Vector3.new(0, h / 2 + 1.5, 0),
				Color = Color3.fromRGB(255, 200, 120), Material = Enum.Material.Neon, CastShadow = false, Parent = folder })
		end
	end
end

local function buildNPC(folder: Folder, name: string, cf: CFrame, colors): Model
	local m = Instance.new("Model")
	m.Name = name
	local root = part({ Name = "Root", Size = Vector3.new(2.6, 3, 1.6), CFrame = cf * CFrame.new(0, 3.6, 0),
		Color = colors.body, Material = Enum.Material.SmoothPlastic, Parent = m })
	part({ Name = "Legs", Size = Vector3.new(2, 2.1, 1.3), CFrame = cf * CFrame.new(0, 1.05, 0),
		Color = colors.legs, Material = Enum.Material.SmoothPlastic, Parent = m })
	local head = part({ Name = "Head", Shape = Enum.PartType.Ball, Size = Vector3.new(3.4, 3.4, 3.4),
		CFrame = cf * CFrame.new(0, 6.7, 0), Color = colors.skin, Material = Enum.Material.SmoothPlastic, Parent = m })
	for _, s in { -1, 1 } do
		part({ Name = "Eye", Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1),
			CFrame = cf * CFrame.new(0.55 * s, 7, -1.45), Color = Color3.new(1, 1, 1), Parent = m })
		part({ Name = "Pupil", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4),
			CFrame = cf * CFrame.new(0.55 * s, 7, -1.9), Color = Color3.new(0, 0, 0), Parent = m })
	end
	if colors.hat then
		part({ Name = "Hat", Size = Vector3.new(3.2, 0.9, 3.2), CFrame = cf * CFrame.new(0, 8.3, 0),
			Color = colors.hat, Parent = m })
	end
	m.PrimaryPart = root
	-- Real Blender character imported in Studio? (ServerStorage/CharacterModels/<modelName>) Use it as the visuals.
	local library = ServerStorage:FindFirstChild("CharacterModels")
	local art = library and colors.modelName and library:FindFirstChild(colors.modelName)
	if art then
		local visual = art:Clone()
		if visual:IsA("BasePart") then
			local wrap = Instance.new("Model")
			visual.Parent = wrap
			visual = wrap
		end
		local _, size = visual:GetBoundingBox()
		visual:ScaleTo(visual:GetScale() * (colors.height or 8) / size.Y)
		local bbCf, bbSize = visual:GetBoundingBox()
		-- move the bounding box so it stands on the floor at cf; ART_YAW fixes models that import facing sideways
		local target = cf * CFrame.Angles(0, math.rad(colors.yaw or 0), 0) * CFrame.new(0, bbSize.Y / 2, 0)
		visual:PivotTo(target * bbCf:Inverse() * visual:GetPivot())
		for _, d in visual:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
			end
		end
		visual.Name = "Art"
		visual.Parent = m
		for _, d in m:GetChildren() do
			if d:IsA("BasePart") then
				d.Transparency = 1
			end
		end
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Bubble"
	bb.Size = UDim2.fromOffset(260, 70)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 10.5, 0)
	bb.Adornee = head
	bb.MaxDistance = 120
	bb.Enabled = false
	bb.Parent = head
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.Parent = bb
	Instance.new("UICorner").Parent = frame
	label(frame, "", { Name = "Text", TextColor3 = Color3.fromRGB(20, 20, 30), Size = UDim2.new(1, -12, 1, -8),
		Position = UDim2.fromOffset(6, 4) })
	local nameTag = Instance.new("BillboardGui")
	nameTag.Size = UDim2.fromOffset(160, 24)
	nameTag.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	nameTag.Adornee = head
	nameTag.MaxDistance = 60
	nameTag.Parent = head
	label(nameTag, name, { TextColor3 = Color3.fromRGB(255, 90, 90), TextStrokeTransparency = 0.5 })
	m.Parent = folder
	return m
end

local function buildDesk(folder: Folder, id: number, cf: CFrame)
	-- cf: standing where the player sits, looking at the monitor (-Z)
	local m = Instance.new("Model")
	m.Name = "Desk" .. id
	local laminate = Color3.fromRGB(176, 124, 78)
	local metal = Color3.fromRGB(70, 72, 80)
	local rng = Random.new(id * 7919)
	-- desk: laminate top with a dark edge, metal side panels, modesty panel, drawer pedestal
	part({ Name = "Top", Size = Vector3.new(9, 0.5, 4.4), CFrame = cf * CFrame.new(0, 3, -2.2), Color = laminate,
		Material = Enum.Material.Wood, Parent = m })
	part({ Name = "Edge", Size = Vector3.new(9.1, 0.3, 0.2), CFrame = cf * CFrame.new(0, 2.95, -0.02), Color = metal, Parent = m })
	for _, x in { -4.3, 4.3 } do
		part({ Name = "SidePanel", Size = Vector3.new(0.3, 2.75, 4.2), CFrame = cf * CFrame.new(x, 1.38, -2.2), Color = metal,
			Material = Enum.Material.Metal, Parent = m })
	end
	part({ Name = "Modesty", Size = Vector3.new(8.3, 1.6, 0.2), CFrame = cf * CFrame.new(0, 2, -4.2), Color = metal, Parent = m })
	part({ Name = "Pedestal", Size = Vector3.new(1.9, 2.6, 3.4), CFrame = cf * CFrame.new(3.1, 1.35, -2.4), Color = laminate,
		Material = Enum.Material.Wood, Parent = m })
	for i = 0, 2 do
		part({ Name = "DrawerHandle", Size = Vector3.new(0.9, 0.12, 0.12), CFrame = cf * CFrame.new(3.1, 0.6 + i * 0.8, -0.66),
			Color = metal, Material = Enum.Material.Metal, Parent = m })
	end
	-- cubicle divider with an aluminium rail
	part({ Name = "Divider", Size = Vector3.new(9.6, 5, 0.4), CFrame = cf * CFrame.new(0, 3.8, -4.6),
		Color = Color3.fromRGB(45, 55, 105), Material = Enum.Material.Fabric, Parent = m })
	part({ Name = "DividerRail", Size = Vector3.new(9.8, 0.25, 0.55), CFrame = cf * CFrame.new(0, 6.35, -4.6),
		Color = Color3.fromRGB(190, 195, 205), Material = Enum.Material.Metal, Parent = m })
	-- monitor: bezel, screen, neck, round base
	part({ Name = "Bezel", Size = Vector3.new(4.9, 3.1, 0.3), CFrame = cf * CFrame.new(0, 5.5, -3.35),
		Color = Color3.fromRGB(18, 18, 22), Parent = m })
	local monitor = part({ Name = "Monitor", Size = Vector3.new(4.6, 2.8, 0.1),
		CFrame = cf * CFrame.new(0, 5.5, -3.16) * CFrame.Angles(0, math.pi, 0),
		Color = Color3.fromRGB(25, 25, 30), Parent = m })
	part({ Name = "Stand", Size = Vector3.new(0.45, 1.5, 0.35), CFrame = cf * CFrame.new(0, 3.95, -3.55),
		Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal, Parent = m })
	part({ Name = "StandBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 1.8, 1.8),
		CFrame = cf * CFrame.new(0, 3.3, -3.4) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal, Parent = m })
	-- keyboard with key rows, mouse on a pad
	part({ Name = "Keyboard", Size = Vector3.new(3.2, 0.18, 1.1), CFrame = cf * CFrame.new(-0.3, 3.34, -1.3),
		Color = Color3.fromRGB(225, 225, 230), Parent = m })
	for r = 0, 2 do
		part({ Name = "Keys", Size = Vector3.new(2.9, 0.08, 0.22), CFrame = cf * CFrame.new(-0.3, 3.46, -1.65 + r * 0.33),
			Color = Color3.fromRGB(245, 245, 248), CanCollide = false, Parent = m })
	end
	part({ Name = "MousePad", Size = Vector3.new(1.3, 0.05, 1.1), CFrame = cf * CFrame.new(2, 3.28, -1.3),
		Color = Color3.fromRGB(35, 35, 45), Parent = m })
	part({ Name = "Mouse", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45),
		CFrame = cf * CFrame.new(2, 3.42, -1.3), Color = Color3.fromRGB(230, 230, 235), Parent = m })
	-- desk phone: base, handset, little green display
	part({ Name = "DeskPhone", Size = Vector3.new(1.3, 0.45, 1.1), CFrame = cf * CFrame.new(-3.3, 3.48, -2.2),
		Color = Color3.fromRGB(55, 55, 62), Parent = m })
	part({ Name = "Handset", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.3, 0.35, 0.35),
		CFrame = cf * CFrame.new(-3.3, 3.8, -2.45), Color = Color3.fromRGB(40, 40, 46), Parent = m })
	part({ Name = "PhoneScreen", Size = Vector3.new(0.6, 0.05, 0.3), CFrame = cf * CFrame.new(-3.3, 3.72, -1.95),
		Color = Color3.fromRGB(120, 230, 140), Material = Enum.Material.Neon, CanCollide = false, Parent = m })
	-- personal clutter: mug, paper stack, pen cup, photo frame, sometimes a tiny plant
	local mugColors = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(60, 140, 230), Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(240, 240, 240), Color3.fromRGB(120, 200, 120) }
	part({ Name = "Mug", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 0.5, 0.5),
		CFrame = cf * CFrame.new(-2.3, 3.55, -0.9) * CFrame.Angles(0, 0, math.pi / 2),
		Color = mugColors[rng:NextInteger(1, #mugColors)], Parent = m })
	for i = 0, rng:NextInteger(2, 6) do
		local sheet = part({ Name = "Paper", Size = Vector3.new(1.1, 0.04, 1.4), CFrame = cf * CFrame.new(1.2, 3.27 + i * 0.045, -3.6)
			* CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0), Color = Color3.fromRGB(250, 250, 245), CanCollide = false,
			Parent = m })
		sheet.CastShadow = false
	end
	part({ Name = "PenCup", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.7, 0.4, 0.4),
		CFrame = cf * CFrame.new(-3.9, 3.6, -3.6) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(30, 30, 35), Parent = m })
	part({ Name = "PhotoFrame", Size = Vector3.new(0.8, 0.65, 0.08), CFrame = cf * CFrame.new(2.6, 3.6, -3.7)
		* CFrame.Angles(math.rad(-12), math.rad(-20), 0), Color = Color3.fromRGB(200, 160, 90), Parent = m })
	if rng:NextNumber() < 0.4 then
		part({ Name = "DeskPlantPot", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = cf * CFrame.new(-3.8, 3.5, -1),
			Color = Color3.fromRGB(190, 110, 70), Parent = m })
		part({ Name = "DeskPlant", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = cf * CFrame.new(-3.8, 4.1, -1),
			Color = Color3.fromRGB(80, 170, 80), CanCollide = false, Parent = m })
	end
	local cam = part({ Name = "Webcam", Size = Vector3.new(0.8, 0.4, 0.4), CFrame = cf * CFrame.new(0, 7.25, -3.35),
		Color = Color3.fromRGB(20, 20, 20), Parent = m })
	part({ Name = "WebcamLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.18, 0.18, 0.18),
		CFrame = cam.CFrame * CFrame.new(0.25, 0, -0.2), Color = Color3.fromRGB(255, 40, 40),
		Material = Enum.Material.Neon, Parent = m })
	local lamp = part({ Name = "RingLamp", Shape = Enum.PartType.Ball, Size = Vector3.new(0.7, 0.7, 0.7),
		CFrame = cf * CFrame.new(2.9, 7.3, -3.35), Color = Color3.fromRGB(80, 80, 80), Material = Enum.Material.Neon, Parent = m })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 50, 50)
	light.Range = 14
	light.Brightness = 3
	light.Enabled = false
	light.Parent = lamp
	-- office chair (loose on purpose: people will throw it): seat, backrest, gas lift, 5-star base with casters
	local seat = Instance.new("Seat")
	seat.Name = "Chair"
	seat.Size = Vector3.new(2.6, 0.6, 2.6)
	seat.CFrame = cf * CFrame.new(0, 2.2, 1)
	seat.Color = Color3.fromRGB(38, 38, 44)
	seat.Material = Enum.Material.Leather
	seat.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.3, 0.1)
	seat.Parent = m
	local function chairPart(props)
		props.Anchored = false
		props.CanCollide = props.CanCollide ~= false
		props.Parent = m
		local p = part(props)
		local w = Instance.new("WeldConstraint")
		w.Part0, w.Part1 = seat, p
		w.Parent = p
		return p
	end
	chairPart({ Name = "ChairBack", Size = Vector3.new(2.4, 2.8, 0.35), CFrame = cf * CFrame.new(0, 3.8, 2.35)
		* CFrame.Angles(math.rad(-8), 0, 0), Color = Color3.fromRGB(38, 38, 44), Material = Enum.Material.Leather })
	chairPart({ Name = "GasLift", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 0.35, 0.35),
		CFrame = cf * CFrame.new(0, 1.3, 1) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(150, 150, 160),
		Material = Enum.Material.Metal, CanCollide = false })
	for k = 0, 4 do
		local a = k * math.pi * 2 / 5
		chairPart({ Name = "StarArm", Size = Vector3.new(0.3, 0.2, 1.4), CFrame = cf * CFrame.new(0, 0.55, 1)
			* CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.7), Color = Color3.fromRGB(30, 30, 34) })
		-- frictionless rubber casters: the chair actually rolls when bumped, sat on or thrown
		chairPart({ Name = "Caster", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), CFrame = cf * CFrame.new(0, 0.2, 1)
			* CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -1.35), Color = Color3.fromRGB(20, 20, 22), Material = Enum.Material.Rubber,
			CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 0.1, 100, 1) })
	end
	for _ = 1, 3 do
		local note = part({ Name = "StickyNote", Size = Vector3.new(0.9, 0.9, 0.05),
			CFrame = cf * CFrame.new(rng:NextNumber(-4, 4), rng:NextNumber(4.4, 5.8), -4.38),
			Color = Color3.fromRGB(255, 225, 120), CanCollide = false, Parent = m })
		note.Orientation += Vector3.new(0, 0, rng:NextNumber(-12, 12))
	end

	-- screen that everyone walking past can read
	local gui = surfaceGui(monitor, 60)
	gui.Name = "Mirror"
	monitor:AddTag("DeskScreen") -- the client draws a live trading screen here while nobody is on a call
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(20, 30, 60)
	bg.Parent = gui
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(40, 30, 90), Color3.fromRGB(230, 120, 60))
	grad.Rotation = 90
	grad.Parent = bg
	label(bg, "SHARK OS", { Name = "Title", Size = UDim2.fromScale(1, 0.22), TextColor3 = Color3.fromRGB(255, 215, 120) })
	label(bg, "", { Name = "Caller", Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.24) })
	local barBack = Instance.new("Frame")
	barBack.Name = "TrustBack"
	barBack.Size = UDim2.fromScale(0.8, 0.1)
	barBack.Position = UDim2.fromScale(0.1, 0.48)
	barBack.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	barBack.Visible = false
	barBack.Parent = bg
	local bar = Instance.new("Frame")
	bar.Name = "Trust"
	bar.Size = UDim2.fromScale(0.25, 1)
	bar.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
	bar.BorderSizePixel = 0
	bar.Parent = barBack
	label(bg, "", { Name = "Line", Size = UDim2.fromScale(0.92, 0.3), Position = UDim2.fromScale(0.04, 0.64),
		Font = Enum.Font.Gotham })

	local ring = Instance.new("BillboardGui")
	ring.Name = "RingTag"
	ring.AlwaysOnTop = true
	ring.Size = UDim2.fromOffset(170, 46)
	ring.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	ring.Enabled = false
	ring.Parent = monitor
	local rf = Instance.new("Frame")
	rf.Size = UDim2.fromScale(1, 1)
	rf.BackgroundColor3 = Color3.fromRGB(230, 40, 50)
	rf.Parent = ring
	Instance.new("UICorner").Parent = rf
	label(rf, "RING RING! Desk " .. id, { Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3) })

	local answer = Instance.new("ProximityPrompt")
	answer.Name = "Answer"
	answer.ActionText = "Answer"
	answer.ObjectText = "Desk " .. id
	answer.KeyboardKeyCode = Enum.KeyCode.E
	answer.MaxActivationDistance = 11
	answer.RequiresLineOfSight = false
	answer.Enabled = false
	answer.Parent = monitor
	local takeover = Instance.new("ProximityPrompt")
	takeover.Name = "TakeOver"
	takeover.ActionText = "Take Over Call"
	takeover.ObjectText = "Desk " .. id
	takeover.KeyboardKeyCode = Enum.KeyCode.F
	takeover.HoldDuration = 0.4
	takeover.MaxActivationDistance = 11
	takeover.RequiresLineOfSight = false
	takeover.Enabled = false
	takeover.UIOffset = Vector2.new(0, 70)
	takeover.Parent = monitor

	m.Parent = folder
	return {
		id = id,
		model = m,
		monitor = monitor,
		lamp = lamp,
		light = light,
		ringTag = ring,
		answer = answer,
		takeover = takeover,
		mirror = bg,
		seatCFrame = cf * CFrame.new(0, 3.2, 1.2),
		state = "idle",
	}
end

local function buildConference(folder: Folder)
	local wall = Color3.fromRGB(60, 50, 60)
	-- x 55..88, z -58..-22 ; glass front at z = -22 with a door gap
	part({ Name = "ConfWallWest", Size = Vector3.new(1, H, 36), Position = Vector3.new(55, H / 2, -40), Color = wall, Parent = folder })
	part({ Name = "ConfGlassA", Size = Vector3.new(22, H, 0.4), Position = Vector3.new(66, H / 2, -22),
		Transparency = 0.6, Material = Enum.Material.Glass, Color = Color3.fromRGB(180, 210, 230), Parent = folder })
	part({ Name = "ConfGlassB", Size = Vector3.new(4, H, 0.4), Position = Vector3.new(88, H / 2, -22),
		Transparency = 0.6, Material = Enum.Material.Glass, Color = Color3.fromRGB(180, 210, 230), Parent = folder })
	part({ Name = "ConfTable", Size = Vector3.new(10, 1, 24), Position = Vector3.new(70, 3.2, -40),
		Color = Color3.fromRGB(120, 25, 30), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "ConfTableBase", Size = Vector3.new(3, 3, 16), Position = Vector3.new(70, 1.5, -40),
		Color = Color3.fromRGB(30, 20, 20), Parent = folder })
	local seats = {}
	for i = 0, 4 do
		for _, s in { -1, 1 } do
			local pos = Vector3.new(70 + s * 8, 0, -50 + i * 5)
			local cf = CFrame.lookAt(pos, Vector3.new(88, 0, -40))
			table.insert(seats, cf * CFrame.new(0, 3, 0))
			local chair = Instance.new("Seat")
			chair.Size = Vector3.new(2.6, 0.8, 2.6)
			chair.CFrame = cf * CFrame.new(0, 2, 0)
			chair.Color = Color3.fromRGB(30, 30, 35)
			chair.Anchored = false
			chair.Parent = folder
		end
	end
	local screen = panel(folder, "MeetingScreen", Vector3.new(87.2, 8, -40), Vector3.new(-1, 0, 0),
		Vector3.new(22, 11, 0.4), Color3.fromRGB(15, 15, 20))
	local gui = surfaceGui(screen, 40)
	local bg = Instance.new("Frame")
	bg.Name = "Board"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(245, 205, 60)
	bg.Parent = gui
	label(bg, "CALL ANALYSIS", { Name = "Title", Size = UDim2.fromScale(1, 0.18), TextColor3 = Color3.fromRGB(40, 20, 10) })
	label(bg, "", { Name = "Body", Size = UDim2.fromScale(0.92, 0.74), Position = UDim2.fromScale(0.04, 0.22),
		TextColor3 = Color3.fromRGB(40, 20, 10), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
	return { screen = screen, board = bg, seats = seats, fireSpots = { Vector3.new(70, 4, -46), Vector3.new(70, 4, -34),
		Vector3.new(62, 0.5, -52), Vector3.new(78, 0.5, -28), Vector3.new(62, 0.5, -30) } }
end

local function buildRooms(folder: Folder)
	-- CEO office: glass box, gold desk
	for _, spec in {
		{ Vector3.new(66, H / 2, 22), Vector3.new(22, H, 0.4) },
		{ Vector3.new(55, H / 2, 40), Vector3.new(0.4, H, 36) },
	} do
		part({ Name = "CEOGlass", Size = spec[2], Position = spec[1], Transparency = 0.6, Material = Enum.Material.Glass,
			Color = Color3.fromRGB(200, 190, 150), Parent = folder })
	end
	part({ Name = "GoldDesk", Size = Vector3.new(12, 3.4, 5), Position = Vector3.new(74, 1.7, 44),
		Color = Color3.fromRGB(230, 180, 50), Material = Enum.Material.Metal, Reflectance = 0.3, Parent = folder })
	part({ Name = "CEORug", Size = Vector3.new(26, 0.1, 30), Position = Vector3.new(72, 0.05, 40),
		Color = Color3.fromRGB(120, 20, 30), Material = Enum.Material.Fabric, Parent = folder })
	-- break room: counter, fridge, water cooler, whiteboard, plants (loose)
	part({ Name = "Counter", Size = Vector3.new(4, 3.4, 16), Position = Vector3.new(86, 1.7, 0),
		Color = Color3.fromRGB(200, 170, 130), Parent = folder })
	part({ Name = "Fridge", Size = Vector3.new(4, 9, 4), Position = Vector3.new(86, 4.5, 11),
		Color = Color3.fromRGB(235, 235, 235), Material = Enum.Material.Metal, Parent = folder })
	part({ Name = "Microwave", Size = Vector3.new(2.6, 1.6, 2), Position = Vector3.new(86, 4.2, -3),
		Color = Color3.fromRGB(230, 230, 230), Anchored = false, Parent = folder })
	part({ Name = "WaterCooler", Size = Vector3.new(2, 5, 2), Position = Vector3.new(80, 2.5, -14),
		Color = Color3.fromRGB(150, 200, 255), Anchored = false, Parent = folder })
	local board = panel(folder, "Whiteboard", Vector3.new(87.6, 8, 0), Vector3.new(-1, 0, 0), Vector3.new(12, 6, 0.3),
		Color3.fromRGB(245, 245, 245))
	local g = surfaceGui(board, 40)
	label(g, "DAILY TARGETS\n1. DIAL\n2. CLOSE\n3. DIAL AGAIN\n4. YACHT :)", {
		TextColor3 = Color3.fromRGB(20, 40, 120), Font = Enum.Font.PermanentMarker })
	for _, pos in { Vector3.new(60, 2, -16), Vector3.new(60, 2, 16), Vector3.new(-30, 2, -52), Vector3.new(-30, 2, 52) } do
		local pot = part({ Name = "Plant", Size = Vector3.new(2.2, 3, 2.2), Position = pos, Color = Color3.fromRGB(150, 100, 70),
			Anchored = false, Parent = folder })
		local leaves = part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4),
			Position = pos + Vector3.new(0, 3.2, 0), Color = Color3.fromRGB(80, 170, 70), Anchored = false, Parent = folder })
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = pot, leaves
		weld.Parent = pot
	end
	-- elevator lobby with the giant LED logo
	for _, z in { -12, 0, 12 } do
		part({ Name = "ElevatorDoor", Size = Vector3.new(0.6, 11, 7), Position = Vector3.new(-89.4, 5.5, z),
			Color = Color3.fromRGB(190, 170, 110), Material = Enum.Material.Metal, Reflectance = 0.3, Parent = folder })
	end
	local logo = panel(folder, "LEDLogo", Vector3.new(-89, 13.5, 0), Vector3.new(1, 0, 0), Vector3.new(40, 4, 0.3),
		Color3.fromRGB(10, 10, 15))
	local lg = surfaceGui(logo, 30)
	label(lg, "WOLVES WITH YOUR FRIENDS", { TextColor3 = Color3.fromRGB(255, 200, 80) })
	part({ Name = "ReceptionDesk", Size = Vector3.new(4, 4, 16), Position = Vector3.new(-66, 2, 0),
		Color = Color3.fromRGB(240, 235, 225), Parent = folder })
end

local TICKER_TEXT = table.concat({
	'<font color="#6CFF7A">BANANA MOON MINING +12.4%</font>',
	'<font color="#FF6A6A">DUCK YACHTS -3.1%</font>',
	'<font color="#6CFF7A">HOVERCAR INC +44.0%</font>',
	'<font color="#6CFF7A">WOLF &amp; CO +100%</font>',
	'<font color="#FF6A6A">UBER FOR SANDWICHES -7.7%</font>',
	'<font color="#6CFF7A">PIGEON DRONES +9.9%</font>',
	'<font color="#FF6A6A">CLOUD FARMS -12.0%</font>',
	'<font color="#6CFF7A">MOON BINGO +21.5%</font>',
	'<font color="#6CFF7A">GOLD TOILETS +6.6%</font>',
}, "     |     ")

-- A scrolling LED stock ticker. The client scrolls every part tagged "Ticker".
local function ticker(parent: Instance, pos: Vector3, facing: Vector3, length: number)
	local p = panel(parent, "Ticker", pos, facing, Vector3.new(length, 1.6, 0.3), Color3.fromRGB(10, 10, 14))
	p.CanCollide = false
	local g = surfaceGui(p, 30)
	g.ClipsDescendants = true
	local tape = label(g, TICKER_TEXT .. "     |     " .. TICKER_TEXT, { Name = "Tape", RichText = true,
		Size = UDim2.new(4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold })
	tape.TextScaled = true
	p:AddTag("Ticker")
	return p
end

local function sofa(folder: Folder, cf: CFrame, width: number, color: Color3)
	local leather = { Color = color, Material = Enum.Material.Leather, Parent = folder }
	local function sp(name, size, offset)
		local props = table.clone(leather)
		props.Name, props.Size, props.CFrame = name, size, cf * offset
		return part(props)
	end
	sp("SofaSeat", Vector3.new(width, 1.6, 4), CFrame.new(0, 1.3, 0))
	sp("SofaBack", Vector3.new(width, 3.2, 1.2), CFrame.new(0, 2.6, 1.6))
	sp("SofaArm", Vector3.new(1, 2.4, 4), CFrame.new(-width / 2 - 0.5, 1.7, 0))
	sp("SofaArm", Vector3.new(1, 2.4, 4), CFrame.new(width / 2 + 0.5, 1.7, 0))
	for x = -width / 2 + 1.5, width / 2 - 1.5, 3 do
		sp("Cushion", Vector3.new(2.8, 0.5, 3.4), CFrame.new(x, 2.3, -0.2))
	end
end

local function plantPot(folder: Folder, pos: Vector3, scale: number)
	local pot = part({ Name = "Planter", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3 * scale, 2.6 * scale, 2.6 * scale),
		CFrame = CFrame.new(pos + Vector3.new(0, 1.5 * scale, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(235, 232, 225), Material = Enum.Material.Concrete, Parent = folder })
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		part({ Name = "Leaf", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2) * scale,
			Position = pos + Vector3.new(math.cos(a) * 0.9 * scale, (3.6 + (i % 2) * 0.8) * scale, math.sin(a) * 0.9 * scale),
			Color = Color3.fromRGB(60 + i * 8, 150 + i * 6, 70), Material = Enum.Material.LeafyGrass, CanCollide = false,
			Parent = folder })
	end
	return pot
end

local function buildRestroom(folder: Folder, zs: number, title: string, accent: Color3)
	-- room: x -88..-66, z 36..58 (mirrored to -36..-58 when zs = -1), door on the east wall
	local plaster = Color3.fromRGB(240, 236, 228)
	local zIn, zOut = 36 * zs, 58 * zs
	local zMid = (zIn + zOut) / 2
	part({ Name = "RestroomFloor", Size = Vector3.new(24, 0.1, 22), Position = Vector3.new(-78, 0.05, zMid),
		Color = Color3.fromRGB(215, 225, 235), Material = Enum.Material.CeramicTiles, Parent = folder })
	part({ Name = "RestroomWall", Size = Vector3.new(24, H, 0.6), Position = Vector3.new(-78, H / 2, zIn),
		Color = plaster, Material = Enum.Material.Plaster, Parent = folder })
	part({ Name = "RestroomWall", Size = Vector3.new(0.6, H, 8), Position = Vector3.new(-66, H / 2, zIn + 4 * zs),
		Color = plaster, Material = Enum.Material.Plaster, Parent = folder })
	part({ Name = "RestroomWall", Size = Vector3.new(0.6, H, 8), Position = Vector3.new(-66, H / 2, zOut - 4 * zs),
		Color = plaster, Material = Enum.Material.Plaster, Parent = folder })
	part({ Name = "DoorHeader", Size = Vector3.new(0.6, H - 9, 6), Position = Vector3.new(-66, 9 + (H - 9) / 2, zMid),
		Color = plaster, Material = Enum.Material.Plaster, Parent = folder })
	part({ Name = "FrostedWindow", Size = Vector3.new(24, H, 0.3), Position = Vector3.new(-78, H / 2, zOut + 1.2 * zs),
		Color = Color3.fromRGB(235, 240, 245), Transparency = 0.25, Material = Enum.Material.Glass, Parent = folder })
	local sign = panel(folder, "RestroomSign", Vector3.new(-65.6, 10.5, zMid), Vector3.new(1, 0, 0), Vector3.new(5, 1.4, 0.2), accent)
	label(surfaceGui(sign, 40), title, { TextColor3 = Color3.new(1, 1, 1) })
	-- three stalls against the outer wall
	for i = 0, 2 do
		local x = -85 + i * 5.5
		local stallBack = zOut - 0.6 * zs
		part({ Name = "Toilet", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 2.2, 2.2),
			CFrame = CFrame.new(x, 0.8, stallBack - 2.6 * zs) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(250, 250, 252),
			Material = Enum.Material.Marble, Parent = folder })
		part({ Name = "ToiletSeat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 2.4, 2.4),
			CFrame = CFrame.new(x, 1.7, stallBack - 2.6 * zs) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(235, 235, 240),
			Material = Enum.Material.Plastic, Parent = folder })
		part({ Name = "ToiletTank", Size = Vector3.new(2.2, 2.6, 1), Position = Vector3.new(x, 2.3, stallBack - 1 * zs),
			Color = Color3.fromRGB(250, 250, 252), Material = Enum.Material.Marble, Parent = folder })
		part({ Name = "StallWall", Size = Vector3.new(0.25, 7, 6.5), Position = Vector3.new(x - 2.75, 4, zOut - 3.9 * zs),
			Color = accent, Material = Enum.Material.Metal, Parent = folder })
		local door = part({ Name = "StallDoor", Size = Vector3.new(4.6, 6.2, 0.2), Position = Vector3.new(x, 3.8, zOut - 7.1 * zs),
			Color = accent, Material = Enum.Material.Metal, Anchored = false, Parent = folder })
		local hinge = part({ Name = "StallHinge", Size = Vector3.new(0.2, 0.2, 0.2), Position = Vector3.new(x - 2.4, 3.8, zOut - 7.1 * zs),
			Transparency = 1, CanCollide = false, Parent = folder })
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent, a1.Parent = hinge, door
		a0.Axis, a1.Axis = Vector3.new(0, 1, 0), Vector3.new(0, 1, 0)
		a1.Position = Vector3.new(-2.35, 0, 0)
		local h = Instance.new("HingeConstraint") -- swinging stall doors
		h.Attachment0, h.Attachment1 = a0, a1
		h.LimitsEnabled = true
		h.LowerAngle, h.UpperAngle = -100, 100
		h.Parent = door
	end
	part({ Name = "StallWall", Size = Vector3.new(0.25, 7, 6.5), Position = Vector3.new(-85 + 3 * 5.5 - 2.75, 4, zOut - 3.9 * zs),
		Color = accent, Material = Enum.Material.Metal, Parent = folder })
	-- sinks + mirror along the inner wall
	local zc = zIn + 1.6 * zs
	part({ Name = "SinkCounter", Size = Vector3.new(14, 0.6, 3), Position = Vector3.new(-80, 3.3, zc),
		Color = Color3.fromRGB(235, 235, 238), Material = Enum.Material.Marble, Parent = folder })
	part({ Name = "CounterBase", Size = Vector3.new(14, 3, 2.6), Position = Vector3.new(-80, 1.5, zc),
		Color = Color3.fromRGB(120, 90, 60), Material = Enum.Material.Wood, Parent = folder })
	for i = 0, 2 do
		local x = -84.5 + i * 4.5
		part({ Name = "Basin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2, 2),
			CFrame = CFrame.new(x, 3.5, zc) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(250, 250, 252),
			Material = Enum.Material.Marble, Parent = folder })
		part({ Name = "Faucet", Size = Vector3.new(0.25, 1, 0.25), Position = Vector3.new(x, 4.1, zc + 0.9 * zs),
			Color = Color3.fromRGB(200, 200, 210), Material = Enum.Material.Metal, Reflectance = 0.3, Parent = folder })
	end
	part({ Name = "Mirror", Size = Vector3.new(13, 5, 0.1), Position = Vector3.new(-80, 7.5, zIn + 0.35 * zs),
		Color = Color3.fromRGB(200, 215, 225), Material = Enum.Material.Glass, Reflectance = 0.6, Parent = folder })
	part({ Name = "HandDryer", Size = Vector3.new(1.6, 1.8, 1), Position = Vector3.new(-70, 5, zIn + 0.8 * zs),
		Color = Color3.fromRGB(210, 210, 215), Material = Enum.Material.Metal, Parent = folder })
end

local function buildDecor(folder: Folder)
	-- carpet runners down the two main aisles, marble lobby
	for _, z in { -13.4, 13.4 } do
		part({ Name = "Runner", Size = Vector3.new(110, 0.06, 7), Position = Vector3.new(-7, 0.03, z),
			Color = Color3.fromRGB(140, 30, 40), Material = Enum.Material.Carpet, Parent = folder })
		for _, facing in { -1, 1 } do
			ticker(folder, Vector3.new(-7, 13.2, z + 0.16 * facing), Vector3.new(0, 0, facing), 104)
		end
	end
	part({ Name = "LobbyMarble", Size = Vector3.new(26, 0.08, 64), Position = Vector3.new(-77, 0.04, 0),
		Color = Color3.fromRGB(235, 230, 222), Material = Enum.Material.Marble, Parent = folder })
	part({ Name = "LobbyRug", Size = Vector3.new(14, 0.1, 20), Position = Vector3.new(-77, 0.1, 0),
		Color = Color3.fromRGB(120, 20, 30), Material = Enum.Material.Carpet, Parent = folder })
	sofa(folder, CFrame.lookAt(Vector3.new(-84, 0, -20), Vector3.new(-84, 0, 0)), 9, Color3.fromRGB(30, 30, 34))
	sofa(folder, CFrame.lookAt(Vector3.new(-84, 0, 20), Vector3.new(-84, 0, 0)), 9, Color3.fromRGB(30, 30, 34))
	for _, z in { -28, 28 } do
		plantPot(folder, Vector3.new(-70, 0, z), 1.2)
	end
	for _, z in { -12, 0, 12 } do -- gold elevator frames
		part({ Name = "ElevatorFrame", Size = Vector3.new(0.8, 12, 8.6), Position = Vector3.new(-89.2, 6, z),
			Color = Color3.fromRGB(215, 170, 70), Material = Enum.Material.Metal, Reflectance = 0.2, Parent = folder })
	end

	-- north strip: vending machines, filing cabinets, printer station, ping-pong table
	for i, spec in { { "SNACKS", Color3.fromRGB(200, 40, 50) }, { "ENERGY", Color3.fromRGB(40, 90, 200) } } do
		local x = -44 + (i - 1) * 6
		part({ Name = "VendingMachine", Size = Vector3.new(5, 9, 3.5), Position = Vector3.new(x, 4.5, -56.5),
			Color = spec[2], Material = Enum.Material.Metal, Parent = folder })
		local front = panel(folder, "VendingFront", Vector3.new(x - 0.6, 5.5, -54.7), Vector3.new(0, 0, 1),
			Vector3.new(3.2, 6, 0.1), Color3.fromRGB(20, 25, 35))
		front.Material = Enum.Material.Neon
		label(surfaceGui(front, 30), spec[1], { Size = UDim2.fromScale(1, 0.2), TextColor3 = Color3.fromRGB(255, 240, 180) })
	end
	for i = 0, 5 do
		local x = -24 + i * 3.4
		part({ Name = "FilingCabinet", Size = Vector3.new(3.2, 5.2, 3), Position = Vector3.new(x, 2.6, -57),
			Color = Color3.fromRGB(150, 155, 165), Material = Enum.Material.Metal, Parent = folder })
		for d = 0, 2 do
			part({ Name = "CabinetHandle", Size = Vector3.new(1, 0.2, 0.2), Position = Vector3.new(x, 1.2 + d * 1.6, -55.45),
				Color = Color3.fromRGB(60, 60, 65), Material = Enum.Material.Metal, Parent = folder })
		end
	end
	part({ Name = "PrinterTable", Size = Vector3.new(6, 3, 4), Position = Vector3.new(8, 1.5, -56),
		Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "Printer", Size = Vector3.new(4, 2.4, 3), Position = Vector3.new(8, 4.2, -56),
		Color = Color3.fromRGB(235, 235, 238), Material = Enum.Material.Plastic, Parent = folder })
	part({ Name = "PrinterTray", Size = Vector3.new(2.6, 0.1, 1.6), Position = Vector3.new(8, 4.6, -54.2),
		Color = Color3.fromRGB(250, 250, 250), Material = Enum.Material.Plastic, Parent = folder })
	part({ Name = "PingPongTable", Size = Vector3.new(9, 0.4, 5), Position = Vector3.new(30, 3, -47),
		Color = Color3.fromRGB(30, 110, 70), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "PingPongLine", Size = Vector3.new(9, 0.05, 0.1), Position = Vector3.new(30, 3.23, -47),
		Color = Color3.new(1, 1, 1), CanCollide = false, Parent = folder })
	part({ Name = "PingPongNet", Size = Vector3.new(0.1, 0.6, 5.2), Position = Vector3.new(30, 3.5, -47),
		Color = Color3.fromRGB(240, 240, 240), Material = Enum.Material.Fabric, Parent = folder })
	for _, x in { 26.5, 33.5 } do
		part({ Name = "PingPongLeg", Size = Vector3.new(0.4, 2.8, 4), Position = Vector3.new(x, 1.4, -47),
			Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal, Parent = folder })
	end
	part({ Name = "PingPongBall", Shape = Enum.PartType.Ball, Size = Vector3.new(0.4, 0.4, 0.4), Position = Vector3.new(28, 3.6, -46),
		Color = Color3.fromRGB(255, 150, 40), Anchored = false, Parent = folder })

	-- south strip: lounge with TV, fish tank, arcade cabinet, the deal gong, bookshelf
	part({ Name = "LoungeRug", Size = Vector3.new(22, 0.08, 14), Position = Vector3.new(-32, 0.05, 49),
		Color = Color3.fromRGB(60, 50, 90), Material = Enum.Material.Carpet, Parent = folder })
	sofa(folder, CFrame.lookAt(Vector3.new(-32, 0, 54), Vector3.new(-32, 0, 40)), 12, Color3.fromRGB(120, 60, 30))
	part({ Name = "CoffeeTable", Size = Vector3.new(8, 0.5, 3.5), Position = Vector3.new(-32, 1.8, 48),
		Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "CoffeeTableBase", Size = Vector3.new(6, 1.6, 2.5), Position = Vector3.new(-32, 0.8, 48),
		Color = Color3.fromRGB(80, 50, 30), Material = Enum.Material.Wood, Parent = folder })
	local tv = panel(folder, "LoungeTV", Vector3.new(-32, 6, 40.5), Vector3.new(0, 0, 1), Vector3.new(12, 6.5, 0.4),
		Color3.fromRGB(10, 10, 12))
	label(surfaceGui(tv, 30), "WOLF NEWS 24/7\nBANANA MOON HITS ALL-TIME HIGH", { TextColor3 = Color3.fromRGB(255, 220, 120),
		BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(20, 30, 70) })
	part({ Name = "TVStand", Size = Vector3.new(10, 2.5, 2), Position = Vector3.new(-32, 1.25, 40.2),
		Color = Color3.fromRGB(40, 35, 35), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "FishTank", Size = Vector3.new(10, 4, 3), Position = Vector3.new(0, 4.5, 56.5),
		Color = Color3.fromRGB(80, 170, 230), Transparency = 0.5, Material = Enum.Material.Glass, Parent = folder })
	part({ Name = "FishTankStand", Size = Vector3.new(10.4, 2.5, 3.4), Position = Vector3.new(0, 1.25, 56.5),
		Color = Color3.fromRGB(30, 30, 35), Material = Enum.Material.Wood, Parent = folder })
	part({ Name = "Gravel", Size = Vector3.new(9.8, 0.4, 2.8), Position = Vector3.new(0, 2.7, 56.5),
		Color = Color3.fromRGB(200, 180, 140), Material = Enum.Material.Pebble, Parent = folder })
	for i = 1, 5 do
		part({ Name = "Fish", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.4, 0.4),
			Position = Vector3.new(-4 + i * 1.6, 3.6 + (i % 3) * 0.8, 56.5), Color = Color3.fromRGB(255, 140 - i * 10, 40),
			CanCollide = false, Parent = folder })
	end
	part({ Name = "ArcadeCabinet", Size = Vector3.new(3.4, 7.5, 3.4), Position = Vector3.new(15, 3.75, 56),
		Color = Color3.fromRGB(60, 20, 90), Material = Enum.Material.Wood, Parent = folder })
	local arcade = panel(folder, "ArcadeScreen", Vector3.new(15, 5.6, 54.2), Vector3.new(0, 0, -1), Vector3.new(2.8, 2.2, 0.1),
		Color3.fromRGB(10, 10, 20))
	arcade.Material = Enum.Material.Neon
	label(surfaceGui(arcade, 40), "WOLF RUN\nINSERT COIN", { TextColor3 = Color3.fromRGB(120, 255, 160) })
	part({ Name = "GongFrame", Size = Vector3.new(7, 0.6, 0.6), Position = Vector3.new(36, 9, 50),
		Color = Color3.fromRGB(90, 50, 25), Material = Enum.Material.Wood, Parent = folder })
	for _, x in { 32.8, 39.2 } do
		part({ Name = "GongPost", Size = Vector3.new(0.6, 9, 0.6), Position = Vector3.new(x, 4.5, 50),
			Color = Color3.fromRGB(90, 50, 25), Material = Enum.Material.Wood, Parent = folder })
	end
	part({ Name = "Gong", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 5, 5),
		CFrame = CFrame.new(36, 5.6, 50) * CFrame.Angles(0, math.pi / 2, 0), Color = Color3.fromRGB(220, 170, 60),
		Material = Enum.Material.Metal, Reflectance = 0.25, Parent = folder })
	local gongSign = panel(folder, "GongSign", Vector3.new(36, 10, 49.6), Vector3.new(0, 0, -1), Vector3.new(6, 1, 0.1),
		Color3.fromRGB(20, 20, 20))
	label(surfaceGui(gongSign, 40), "RING FOR BIG DEALS", { TextColor3 = Color3.fromRGB(255, 210, 90) })
	part({ Name = "Bookshelf", Size = Vector3.new(8, 9, 2), Position = Vector3.new(48, 4.5, 57.5),
		Color = Color3.fromRGB(100, 65, 40), Material = Enum.Material.Wood, Parent = folder })
	local bookColors = { Color3.fromRGB(180, 40, 40), Color3.fromRGB(40, 80, 160), Color3.fromRGB(230, 180, 50),
		Color3.fromRGB(40, 120, 70) }
	for shelf = 0, 2 do
		for b = 0, 9 do
			part({ Name = "Book", Size = Vector3.new(0.5, 1.8, 1.4), Position = Vector3.new(44.6 + b * 0.7, 1.4 + shelf * 2.8, 57),
				Color = bookColors[(b + shelf) % #bookColors + 1], Material = Enum.Material.Leather, Parent = folder })
		end
	end
	for _, pos in { Vector3.new(-58, 0, -52), Vector3.new(50, 0, -52), Vector3.new(-58, 0, 52), Vector3.new(25, 0, 40) } do
		plantPot(folder, pos, 1)
	end
	-- trash bins at the ends of every pod
	for _, z in { -26.7, 0, 26.7 } do
		for _, x in { -61.5, 48 } do
			if x < 0 and z == 0 then
				continue -- the Receptionist stands here
			end
			part({ Name = "TrashBin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 1.8, 1.8),
				CFrame = CFrame.new(x, 1.2, z) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(90, 95, 105),
				Material = Enum.Material.Metal, Anchored = false, Parent = folder })
		end
	end
	buildRestroom(folder, 1, "GENTS", Color3.fromRGB(60, 100, 170))
	buildRestroom(folder, -1, "LADIES", Color3.fromRGB(170, 70, 120))
	-- rooftop sign, seen from the main menu flyover
	for _, facing in { Vector3.new(0, 0, -1), Vector3.new(0, 0, 1) } do
		local sign = panel(folder, "RoofSign", Vector3.new(0, 26, facing.Z * 20), facing, Vector3.new(70, 14, 0.5),
			Color3.fromRGB(10, 10, 12))
		sign.Material = Enum.Material.Neon
		label(surfaceGui(sign, 12), "WOLF & CO.", { TextColor3 = Color3.fromRGB(255, 200, 80) })
	end
end

function OfficeBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "Floor100"
	folder.Parent = Workspace
	local city = Instance.new("Folder")
	city.Name = "City"
	city.Parent = Workspace

	buildShell(folder)
	buildCity(city)
	buildRooms(folder)

	-- 48 desks: three double-sided pods (back-to-back rows sharing a divider), 8 desks per row
	local desks = {}
	local id = 1
	local rows = {
		{ z = -22, facing = -1 }, { z = -31.4, facing = 1 }, -- north pod
		{ z = -4.7, facing = 1 }, { z = 4.7, facing = -1 }, -- center pod
		{ z = 22, facing = 1 }, { z = 31.4, facing = -1 }, -- south pod
	}
	for _, row in rows do
		for i = 0, 7 do
			local pos = Vector3.new(-56 + i * 14, 0, row.z)
			table.insert(desks, buildDesk(folder, id, CFrame.lookAt(pos, pos + Vector3.new(0, 0, row.facing))))
			id += 1
		end
	end
	buildDecor(folder)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ElevatorSpawn"
	spawn.Size = Vector3.new(10, 1, 20)
	spawn.Position = Vector3.new(-80, 0.1, 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = folder

	local npcs = {
		receptionist = buildNPC(folder, "Receptionist", CFrame.lookAt(Vector3.new(-62, 0, 0), Vector3.new(0, 0, 0)), {
			body = Color3.fromRGB(30, 140, 140), legs = Color3.fromRGB(100, 30, 80), skin = Color3.fromRGB(185, 115, 80),
			modelName = "Receptionist", height = 7.5 }),
		guard = buildNPC(folder, "Security Guard", CFrame.lookAt(Vector3.new(50, 0, -13), Vector3.new(0, 0, 0)), {
			body = Color3.fromRGB(30, 40, 80), legs = Color3.fromRGB(25, 30, 60), skin = Color3.fromRGB(150, 95, 65),
			hat = Color3.fromRGB(30, 40, 80), modelName = "SecurityGuard", height = 8.5 }),
		chairman = buildNPC(folder, "The Chairman", CFrame.lookAt(Vector3.new(74, 0, 49), Vector3.new(74, 0, 0)), {
			body = Color3.fromRGB(240, 180, 50), legs = Color3.fromRGB(220, 160, 40), skin = Color3.fromRGB(235, 150, 95),
			modelName = "TheChairman", height = 9 }),
	}

	return {
		folder = folder,
		desks = desks,
		conference = buildConference(folder),
		npcs = npcs,
		lobby = CFrame.new(-78, 3, 0),
	}
end

return OfficeBuilder
