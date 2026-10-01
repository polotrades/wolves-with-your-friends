-- Builds floor 100 from blender/office_scene.py's layout (shared/OfficeLayout.lua): walls, glass, floors and every
-- prop exactly where they are in the Blender renders, plus the gameplay pieces the art can't do on its own:
-- working desk computers, sliding elevator doors, live chart walls, tickers, room signs and the city far below.
-- Gameplay only relies on the tables returned by OfficeBuilder.build().
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Layout = require(Shared:WaitForChild("OfficeLayout"))
local ArtLibrary = require(script.Parent:WaitForChild("ArtLibrary"))
local Props = require(script.Parent:WaitForChild("Props"))

local OfficeBuilder = {}

local S = ArtLibrary.S
local W, D = Layout.floor.w * S, Layout.floor.l * S

-- Props that stay put: built-ins, wall-mounted things, big furniture and anything gameplay depends on.
-- Everything else can be grabbed, dragged and thrown.
local FIXED = {}
for _, n in {
	"DeskSet", "ExecutiveDesk", "ReceptionDesk", "ElevatorDoors", "ElevatorPanel", "Column", "CafeteriaCounter",
	"MenuBoard", "WolfLetters", "GlassWall", "OfficeDoor", "Toilet", "GoldToilet", "VanitySink", "HandDryer", "PhoneBooth",
	"ServerRack", "TradingRig", "EspressoBar", "VendingMachine", "Fridge", "MeetingTable", "Bookshelf", "TrophyCase",
	"WallTV", "PaintingBull", "PaintingAbstract", "PaintingSunset", "PosterHustle", "PosterGreed", "PosterTeam", "NeonSign",
	"NeonSignMoney", "NeonSignDial", "CorkBoard", "WorldClocks", "ExitSign", "FireAlarm", "SecurityCamera", "SingingFish",
	"AwardPlaque", "Dartboard", "CueRack", "WallClock", "CeilingLight", "Chandelier", "PendantLamp", "HangingPlant",
	"PoolTable", "PingPongTable", "AirHockey", "GrandPiano", "PuttingGreen", "PersianRug", "CoffeePuddle", "FishTank",
	"RoomSign", "ArcadeCabinet", "Gong", "DealBell", "Printer", "FilingCabinet", "WaterBottlePallet", "MassageChair",
	"Podium", "SkylineModel", "GoldWolfStatue", "GoldBull", "MarbleBust", "VaultSafe", "AmericanFlag",
} do
	FIXED[n] = true
end

-- props the physics step treats specially
local EDIBLE = {}
for _, n in { "Donut", "Burger", "PizzaSlice", "Sandwich", "Apple", "Banana" } do
	EDIBLE[n] = true
end
local INTERACT_TAG = {
	CoffeeMachine = "CoffeeSource", EspressoBar = "CoffeeSource", Printer = "Printer",
	TrashBin = "TrashBin", RecyclingBins = "TrashBin", PaperCup = "Cup",
}
-- props that give off light, and how
local GLOW = {
	CeilingLight = { kind = "SurfaceLight", brightness = 1.2, range = 22, color = Color3.fromRGB(255, 244, 228) },
	PendantLamp = { kind = "PointLight", brightness = 1.2, range = 14, color = Color3.fromRGB(255, 210, 150) },
	Chandelier = { kind = "PointLight", brightness = 1.6, range = 24, color = Color3.fromRGB(255, 214, 150) },
	FloorLamp = { kind = "PointLight", brightness = 1, range = 12, color = Color3.fromRGB(255, 214, 160) },
	BankerLamp = { kind = "PointLight", brightness = 0.8, range = 8, color = Color3.fromRGB(255, 220, 160) },
}

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

-- a thin panel at pos whose Front face (where SurfaceGuis draw) looks along `facing`
local function panel(parent: Instance, name: string, pos: Vector3, facing: Vector3, size: Vector3, color: Color3): Part
	return part({ Name = name, Size = size, CFrame = CFrame.lookAt(pos, pos + facing), Color = color,
		Material = Enum.Material.SmoothPlastic, Parent = parent })
end

local function look(name: string): (Enum.Material, Color3, number)
	local l = Layout.looks[name]
	if not l then
		return Enum.Material.SmoothPlastic, Color3.fromRGB(200, 200, 200), 0
	end
	local ok, material = pcall(function()
		return (Enum.Material :: any)[l.material]
	end)
	return ok and material or Enum.Material.SmoothPlastic, Color3.fromRGB(l.color[1], l.color[2], l.color[3]), l.transparency
end

-- ---------------------------------------------------------------- shell
local function buildParts(folder: Folder)
	for _, spec in Layout.parts do
		local material, color, transparency = look(spec.m)
		local s = spec.s
		local p = part({
			Name = spec.n,
			Size = Vector3.new(math.max(s[1] * S, 0.05), math.max(s[3] * S, 0.05), math.max(s[2] * S, 0.05)),
			CFrame = ArtLibrary.cf(spec.p, spec.r),
			Material = material,
			Color = color,
			Transparency = transparency,
			CastShadow = transparency == 0,
			Parent = folder,
		})
		if material == Enum.Material.Glass then
			p.Reflectance = 0.08
		end
	end
	for _, l in Layout.lights do
		local p = part({ Name = "RoomLight", Size = Vector3.new(0.2, 0.2, 0.2), Position = ArtLibrary.pos(l.p),
			Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
		local light = Instance.new("PointLight")
		light.Brightness = 0.9
		light.Range = 36
		light.Color = Color3.fromRGB(255, 238, 215)
		light.Parent = p
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

-- ---------------------------------------------------------------- screens, tickers, signs
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
	local p = panel(parent, "Ticker", pos, facing, Vector3.new(length, 0.3 * S, 0.1), Color3.fromRGB(10, 10, 14))
	p.CanCollide = false
	local g = surfaceGui(p, 30)
	g.ClipsDescendants = true
	local tape = label(g, TICKER_TEXT .. "     |     " .. TICKER_TEXT, { Name = "Tape", RichText = true,
		Size = UDim2.new(4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold })
	tape.TextScaled = true
	p:AddTag("Ticker")
	return p
end

-- A wall screen the client fills with a live candlestick chart (same renderer as idle desk monitors).
local function chartWall(parent: Instance, pos: Vector3, facing: Vector3, w: number, h: number)
	local p = panel(parent, "ChartWall", pos, facing, Vector3.new(w, h, 0.1), Color3.fromRGB(8, 12, 22))
	p.CanCollide = false
	local g = surfaceGui(p, 22)
	g.Name = "Mirror"
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(8, 12, 22)
	bg.Parent = g
	p:AddTag("DeskScreen")
	return p
end

local function buildScreensAndSigns(folder: Folder)
	for _, sc in Layout.screens do
		local dir = ArtLibrary.facing(sc.r)
		chartWall(folder, ArtLibrary.pos(sc.p) + dir * 0.08 * S, dir, sc.w * S, sc.h * S)
	end
	for _, t in Layout.tickers do
		local dir = ArtLibrary.facing(t.r)
		local pos = ArtLibrary.pos(t.p)
		ticker(folder, pos + dir * 0.05 * S, dir, t.len * S)
		ticker(folder, pos - dir * 0.05 * S, -dir, t.len * S)
	end
	for _, sg in Layout.signs do
		local cf = ArtLibrary.cf(sg.p, sg.r)
		ArtLibrary.place("RoomSign", cf, 1, folder)
		local dir = ArtLibrary.facing(sg.r)
		local pos = (cf * CFrame.new(ArtLibrary.offset(0, -0.024, 0.12))).Position
		local plate = panel(folder, "SignText", pos, dir, Vector3.new(0.54 * S, 0.14 * S, 0.02), Color3.new())
		plate.Transparency = 1
		plate.CanCollide = false
		label(surfaceGui(plate, 60), sg.label, { TextColor3 = Color3.fromRGB(45, 28, 10), Font = Enum.Font.GothamBlack,
			Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	end
end

-- Live wall boards (LED clock, office suspicion, day goal). The client draws and updates them (OfficeBoards).
local function buildBoards(folder: Folder)
	for _, b in Layout.boards do
		local dir = ArtLibrary.facing(b.r)
		local frame = panel(folder, "BoardFrame", ArtLibrary.pos(b.p), dir, Vector3.new((b.w + 0.1) * S, (b.h + 0.1) * S, 0.15),
			Color3.fromRGB(14, 14, 16))
		frame.Material = Enum.Material.Metal
		frame.CanCollide = false
		local screen = panel(folder, "OfficeBoard", ArtLibrary.pos(b.p) + dir * 0.09, dir, Vector3.new(b.w * S, b.h * S, 0.02),
			Color3.new())
		screen.Transparency = 1
		screen.CanCollide = false
		local g = surfaceGui(screen, 40)
		g.Name = "Board"
		screen:SetAttribute("Kind", b.kind)
		screen:AddTag("OfficeBoard")
	end
end

-- ---------------------------------------------------------------- elevators
-- Sliding gold doors in the west core wall with a car behind each. Players spawn in the middle car, doors open.
-- In a prop frame the office is in front (Roblox local +Z) and the car is behind (local -Z).
local function buildElevator(folder: Folder, cf: CFrame)
	local o = ArtLibrary.offset
	local m = Instance.new("Model")
	m.Name = "Elevator"
	local gold = Color3.fromRGB(230, 180, 80)
	local dark = Color3.fromRGB(20, 20, 24)
	for _, sx in { -1, 1 } do
		part({ Name = "Jamb", Size = Vector3.new(0.12 * S, 2.45 * S, 0.12 * S), CFrame = cf * CFrame.new(o(0.8 * sx, -0.02, 1.225)),
			Color = dark, Material = Enum.Material.Marble, Parent = m })
	end
	part({ Name = "Header", Size = Vector3.new(1.72 * S, 0.24 * S, 0.12 * S), CFrame = cf * CFrame.new(o(0, -0.02, 2.42)),
		Color = dark, Material = Enum.Material.Marble, Parent = m })
	local leaves = {}
	for _, sx in { -1, 1 } do
		local closed = cf * CFrame.new(o(0.36 * sx, 0.0, 1.15))
		local leaf = part({ Name = "DoorLeaf", Size = Vector3.new(0.72 * S, 2.3 * S, 0.05 * S), CFrame = closed, Color = gold,
			Material = Enum.Material.Metal, Reflectance = 0.15, Parent = m })
		table.insert(leaves, { part = leaf, closed = closed, open = cf * CFrame.new(o(1.1 * sx, 0.0, 1.15)) })
	end
	-- the car behind the doors
	local depth, width, tall = 2.1, 1.9, 2.7
	local mid = 0.35 + depth / 2
	part({ Name = "CarFloor", Size = Vector3.new(width * S, 0.1 * S, depth * S), CFrame = cf * CFrame.new(o(0, mid, -0.05)),
		Color = Color3.fromRGB(30, 30, 34), Material = Enum.Material.Marble, Parent = m })
	part({ Name = "CarCeiling", Size = Vector3.new(width * S, 0.1 * S, depth * S), CFrame = cf * CFrame.new(o(0, mid, tall)),
		Color = gold, Material = Enum.Material.Metal, Parent = m })
	part({ Name = "CarMirror", Size = Vector3.new(width * S, tall * S, 0.1 * S), CFrame = cf * CFrame.new(o(0, 0.35 + depth, tall / 2)),
		Color = Color3.fromRGB(200, 205, 210), Material = Enum.Material.Glass, Reflectance = 0.5, Parent = m })
	for _, sx in { -1, 1 } do
		part({ Name = "CarWall", Size = Vector3.new(0.1 * S, tall * S, depth * S), CFrame = cf * CFrame.new(o(sx * width / 2, mid, tall / 2)),
			Color = Color3.fromRGB(120, 70, 35), Material = Enum.Material.Wood, Parent = m })
		part({ Name = "HandRail", Size = Vector3.new(0.05 * S, 0.05 * S, depth * 0.9 * S),
			CFrame = cf * CFrame.new(o(sx * (width / 2 - 0.08), mid, 0.95)), Color = gold, Material = Enum.Material.Metal, Parent = m })
	end
	local lamp = part({ Name = "CarLight", Size = Vector3.new(width * 0.7 * S, 0.03 * S, depth * 0.7 * S),
		CFrame = cf * CFrame.new(o(0, mid, tall - 0.06)), Color = Color3.fromRGB(255, 240, 210), Material = Enum.Material.Neon,
		CanCollide = false, Parent = m })
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Bottom
	light.Brightness = 1.5
	light.Range = 12
	light.Parent = lamp
	-- floor number above the doorway, readable from inside the car (a part's Front is its local -Z = into the car)
	local display = part({ Name = "FloorDisplay", Size = Vector3.new(0.5 * S, 0.14 * S, 0.02),
		CFrame = cf * CFrame.new(o(0, 0.4, 2.5)), Color = Color3.fromRGB(10, 10, 10), CanCollide = false, Parent = m })
	label(surfaceGui(display, 60), "100", { Name = "Floor", TextColor3 = Color3.fromRGB(255, 60, 50), Font = Enum.Font.Code })
	m.Parent = folder

	local elevator = {
		model = m,
		display = display,
		-- inside the car, facing out through the doors toward the office
		inside = cf * CFrame.new(o(0, mid, 0)) * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.pi, 0),
		outside = cf * CFrame.new(o(0, -1.2, 0)) * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.pi, 0),
		isOpen = false,
	}
	function elevator.setOpen(open: boolean, instant: boolean?)
		elevator.isOpen = open
		for _, l in leaves do
			local goal = open and l.open or l.closed
			if instant then
				l.part.CFrame = goal
			else
				TweenService:Create(l.part, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { CFrame = goal }):Play()
			end
		end
	end
	return elevator
end

-- ---------------------------------------------------------------- desks
-- The DeskSet art plus the working computer: a screen people can read, ring visuals and the prompts.
-- cf = the desk's floor point turned like Blender; the monitor faces local +Z, where the player sits.
local function buildDesk(folder: Folder, id: number, cf: CFrame)
	local o = ArtLibrary.offset
	local m = Instance.new("Model")
	m.Name = "Desk" .. id
	local art, real = ArtLibrary.place("DeskSet", cf, 1, m)
	art.Name = "Art"
	if not real then
		-- no imported art yet: a simple desk + monitor so it still reads as a workstation
		art:ClearAllChildren()
		part({ Name = "Top", Size = Vector3.new(1.6 * S, 0.05 * S, 0.78 * S), CFrame = cf * CFrame.new(o(0, 0, 0.74)),
			Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Wood, Parent = art })
		part({ Name = "Legs", Size = Vector3.new(1.5 * S, 0.72 * S, 0.05 * S), CFrame = cf * CFrame.new(o(0, 0.34, 0.36)),
			Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal, Parent = art })
		part({ Name = "Bezel", Size = Vector3.new(0.66 * S, 0.4 * S, 0.035 * S), CFrame = cf * CFrame.new(o(0, -0.2, 1.08)),
			Color = Color3.fromRGB(15, 15, 18), Parent = art })
		part({ Name = "Neck", Size = Vector3.new(0.05 * S, 0.3 * S, 0.05 * S), CFrame = cf * CFrame.new(o(0, -0.17, 0.9)),
			Color = Color3.fromRGB(40, 40, 45), Material = Enum.Material.Metal, Parent = art })
	end

	-- the screen: a thin invisible panel over the monitor glass, facing the chair
	local monitor = part({ Name = "Monitor", Size = Vector3.new(0.62 * S, 0.36 * S, 0.02),
		CFrame = cf * CFrame.new(o(0, -0.226, 1.085)) * CFrame.Angles(0, math.pi, 0),
		Transparency = 1, CanCollide = false, Parent = m })
	local gui = surfaceGui(monitor, 110)
	gui.Name = "Mirror"
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
	-- big orange INCOMING card shown while the desk rings (drawn above the idle chart)
	local incoming = Instance.new("Frame")
	incoming.Name = "Incoming"
	incoming.Size = UDim2.fromScale(1, 1)
	incoming.BackgroundColor3 = Color3.fromRGB(240, 110, 40)
	incoming.ZIndex = 20
	incoming.Visible = false
	incoming.Parent = bg
	label(incoming, "INCOMING CALL", { Size = UDim2.fromScale(0.9, 0.36), Position = UDim2.fromScale(0.05, 0.32), ZIndex = 21 })
	monitor:AddTag("DeskScreen") -- the client draws a live trading screen here while nobody is on a call

	-- ring visuals: a "phone + seconds left" pill above the monitor (the yellow outline around the desk and chair
	-- is added by CallService while it rings; no arrows)
	local ring = Instance.new("BillboardGui")
	ring.Name = "RingTag"
	ring.AlwaysOnTop = true
	ring.Size = UDim2.fromOffset(120, 50)
	ring.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
	ring.Enabled = false
	ring.Parent = monitor
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = Color3.fromRGB(20, 22, 26)
	pill.Parent = ring
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0.5, 0)
	pc.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 2
	stroke.Parent = pill
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(36, 36)
	icon.Position = UDim2.fromOffset(7, 7)
	icon.BackgroundColor3 = Color3.fromRGB(40, 200, 90)
	icon.Parent = pill
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0.5, 0)
	ic.Parent = icon
	label(icon, "☎", { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.1, 0.1), Font = Enum.Font.GothamBold })
	label(pill, "10s", { Name = "Count", Size = UDim2.new(1, -52, 0.8, 0), Position = UDim2.new(0, 48, 0.1, 0),
		Font = Enum.Font.GothamBlack })

	local chairSpot = cf * CFrame.new(o(0, -0.85, 0))
	local answer = Instance.new("ProximityPrompt")
	answer.Name = "Answer"
	answer.ActionText = "Answer"
	answer.ObjectText = "Desk " .. id
	answer.KeyboardKeyCode = Enum.KeyCode.E
	answer.MaxActivationDistance = 9
	answer.RequiresLineOfSight = false
	answer.Enabled = false
	answer.Parent = monitor
	local use = Instance.new("ProximityPrompt")
	use.Name = "UseComputer"
	use.ActionText = "Use Computer"
	use.ObjectText = "Desk " .. id
	use.KeyboardKeyCode = Enum.KeyCode.E
	use.MaxActivationDistance = 8
	use.RequiresLineOfSight = false
	use.Parent = monitor
	local takeover = Instance.new("ProximityPrompt")
	takeover.Name = "TakeOver"
	takeover.ActionText = "Take Over Call"
	takeover.ObjectText = "Desk " .. id
	takeover.KeyboardKeyCode = Enum.KeyCode.F
	takeover.HoldDuration = 0.4
	takeover.MaxActivationDistance = 9
	takeover.RequiresLineOfSight = false
	takeover.Enabled = false
	takeover.UIOffset = Vector2.new(0, 70)
	takeover.Parent = monitor

	m.Parent = folder
	return {
		id = id,
		model = m,
		art = art,
		monitor = monitor,
		ringTag = ring,
		answer = answer,
		use = use,
		takeover = takeover,
		mirror = bg,
		incoming = incoming,
		chair = nil :: Model?, -- the closest OfficeChair, found after all props are placed
		chairSpot = chairSpot,
		webcam = cf * CFrame.new(o(0, -0.24, 1.3)),
		-- standing where the chair is, looking at the monitor
		seatCFrame = chairSpot * CFrame.new(0, 3, 0.2),
		state = "idle",
	}
end

-- ---------------------------------------------------------------- props
local function addGlow(model: Model, spec)
	local target = model:FindFirstChildWhichIsA("BasePart", true)
	if not target then
		return
	end
	local l = Instance.new(spec.kind)
	l.Brightness = spec.brightness
	l.Range = spec.range
	l.Color = spec.color
	if l:IsA("SurfaceLight") then
		l.Face = Enum.NormalId.Bottom
	end
	l.Parent = target
end

local function buildProps(folder: Folder, office)
	local propsFolder = Instance.new("Folder")
	propsFolder.Name = "Props"
	propsFolder.Parent = folder
	local chairs = {}
	for _, spec in Layout.props do
		local cf = ArtLibrary.cf(spec.p, spec.r)
		if spec.n == "DeskSet" then
			table.insert(office.desks, buildDesk(folder, #office.desks + 1, cf))
		elseif spec.n == "ElevatorDoors" then
			table.insert(office.elevators, buildElevator(folder, cf))
		else
			local m = ArtLibrary.place(spec.n, cf, spec.s, propsFolder)
			if GLOW[spec.n] then
				addGlow(m, GLOW[spec.n])
			end
			if spec.n == "OfficeChair" then
				table.insert(chairs, m)
			end
			if spec.n == "FishTank" then
				m:AddTag("FishTank")
			end
			if EDIBLE[spec.n] then
				m:AddTag("Edible")
			end
			if INTERACT_TAG[spec.n] then
				m:AddTag(INTERACT_TAG[spec.n])
			end
			if not FIXED[spec.n] then
				Props.movable(m, spec.n == "Sofa" and 90000 or nil)
			end
		end
	end
	-- give each desk its chair (the closest one) so the ring outline can include it
	for _, desk in office.desks do
		local best, bestDist = nil, 6
		for _, chair in chairs do
			local d = (chair:GetPivot().Position - desk.chairSpot.Position).Magnitude
			if d < bestDist then
				best, bestDist = chair, d
			end
		end
		desk.chair = best
	end
end

-- ---------------------------------------------------------------- meeting room
local function buildConference(folder: Folder)
	local pt = Layout.points.meetingBoard
	local dir = ArtLibrary.facing(pt.r)
	local screen = panel(folder, "MeetingScreen", ArtLibrary.pos(pt.p) + dir * 0.06 * S, dir,
		Vector3.new(pt.w * S, pt.h * S, 0.05), Color3.fromRGB(15, 15, 20))
	screen.CanCollide = false
	local gui = surfaceGui(screen, 60)
	local bg = Instance.new("Frame")
	bg.Name = "Board"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(245, 205, 60)
	bg.Parent = gui
	label(bg, "CALL ANALYSIS", { Name = "Title", Size = UDim2.fromScale(1, 0.18), TextColor3 = Color3.fromRGB(40, 20, 10) })
	label(bg, "", { Name = "Body", Size = UDim2.fromScale(0.92, 0.74), Position = UDim2.fromScale(0.04, 0.22),
		TextColor3 = Color3.fromRGB(40, 20, 10), Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true })
	local center = ArtLibrary.pos(Layout.points.meetingCenter.p)
	local seats = {}
	for _, s in Layout.meetingSeats do
		local pos = ArtLibrary.pos(s.p) + Vector3.new(0, 3, 0)
		table.insert(seats, CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)))
	end
	local fireSpots = {}
	for _, off in { Vector3.new(-6, 0.5, -4), Vector3.new(6, 0.5, 4), Vector3.new(-6, 0.5, 4), Vector3.new(6, 0.5, -4),
		Vector3.new(0, 3, 0) } do
		table.insert(fireSpots, center + off)
	end
	return { screen = screen, board = bg, seats = seats, fireSpots = fireSpots }
end

function OfficeBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "Floor100"
	folder.Parent = Workspace
	local city = Instance.new("Folder")
	city.Name = "City"
	city.Parent = Workspace

	local office = { folder = folder, desks = {}, elevators = {} }
	buildParts(folder)
	buildCity(city)
	buildScreensAndSigns(folder)
	buildBoards(folder)
	buildProps(folder, office)
	office.conference = buildConference(folder)

	-- open the doors and spawn inside the middle elevator, looking out at the office
	for _, e in office.elevators do
		e.setOpen(true, true)
	end
	local middle = office.elevators[math.max(1, math.ceil(#office.elevators / 2))]
	office.lobby = middle and middle.inside or CFrame.new(ArtLibrary.pos(Layout.points.spawn.p) + Vector3.new(0, 3, 0))
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ElevatorSpawn"
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.CFrame = office.lobby * CFrame.new(0, -2.6, 0)
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = folder

	local areas = {}
	for _, a in Layout.chaos do
		table.insert(areas, { x = { a.x[1] * S, a.x[2] * S }, z = { -a.y[2] * S, -a.y[1] * S } })
	end
	Props.scatterChaos(folder, areas)
	return office
end

return OfficeBuilder
