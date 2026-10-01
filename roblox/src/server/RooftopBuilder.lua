-- The luxury rooftop, built high above floor 100 (same X/Z footprint, up at ROOF_Y). Open-air deck with a glass
-- parapet, a big pool and a hot tub, two bars, a DJ stage, sun loungers under parasols, planters, string lights,
-- scattered money and papers, and breakable soda / juice bottles. Players travel here with the elevator buttons
-- (RoofService). Falling off respawns you at your last safe deck spot.
local Workspace = game:GetService("Workspace")

local ArtLibrary = require(script.Parent:WaitForChild("ArtLibrary"))
local Props = require(script.Parent:WaitForChild("Props"))

local RooftopBuilder = {}

local S = ArtLibrary.S
local ROOF_Y = 90 -- studs above the office floor

local function part(props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
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

-- stud space: the deck spans the office footprint, centered on the office's center
local function deckCFrame(x: number, z: number, y: number?): CFrame
	return CFrame.new(x, ROOF_Y + (y or 0), z)
end

local function place(name: string, cf: CFrame, folder: Instance, movable: boolean?, force: number?)
	local m = ArtLibrary.place(name, cf, 1, folder)
	if movable then
		Props.movable(m, force)
	end
	return m
end

-- a glass-topped bottle that shatters into shards + a puddle when thrown or dropped hard
local function bottle(name: string, cf: CFrame, color: Color3, folder: Instance)
	local m = ArtLibrary.place(name, cf, 1, folder)
	m:AddTag("Bottle")
	m:SetAttribute("LiquidColor", color)
	Props.movable(m, 9000)
	return m
end

function RooftopBuilder.build(office)
	local folder = Instance.new("Folder")
	folder.Name = "Rooftop"
	folder.Parent = Workspace

	-- footprint: match the office extents (studs), centered on the office center
	local W, D = ArtLibrary.pos({ 24, 17, 0 }), nil
	local _ = D
	local halfX, halfZ = 24 * S, 17 * S
	local cx, cz = 0, 0 -- the office is centered on the Blender origin, so world X/Z center is 0
	local _ = W

	-- deck slab
	part({ Name = "Deck", Size = Vector3.new(halfX * 2, 2, halfZ * 2), CFrame = deckCFrame(cx, cz, -1),
		Color = Color3.fromRGB(205, 195, 180), Material = Enum.Material.WoodPlanks, Parent = folder })
	-- a warm wood sun-deck inlay
	part({ Name = "SunDeck", Size = Vector3.new(halfX * 1.1, 0.1, halfZ * 0.8), CFrame = deckCFrame(cx + halfX * 0.3, cz + halfZ * 0.3, 0.05),
		Color = Color3.fromRGB(150, 100, 55), Material = Enum.Material.WoodPlanks, Parent = folder })

	-- glass parapet around the edge
	local function rail(size: Vector3, pos: Vector3)
		part({ Name = "Parapet", Size = size, CFrame = CFrame.new(pos), Color = Color3.fromRGB(180, 210, 230),
			Material = Enum.Material.Glass, Transparency = 0.55, Reflectance = 0.1, Parent = folder })
		part({ Name = "RailCap", Size = Vector3.new(size.X > size.Z and size.X or 0.6, 0.4, size.Z > size.X and size.Z or 0.6),
			CFrame = CFrame.new(pos + Vector3.new(0, size.Y / 2, 0)), Color = Color3.fromRGB(220, 180, 90),
			Material = Enum.Material.Metal, Parent = folder })
	end
	local railH = 7
	for _, sx in { -1, 1 } do
		rail(Vector3.new(1, railH, halfZ * 2), Vector3.new(cx + sx * halfX, ROOF_Y + railH / 2, cz))
		rail(Vector3.new(halfX * 2, railH, 1), Vector3.new(cx, ROOF_Y + railH / 2, cz + sx * halfZ))
	end

	-- pool
	local poolX, poolZ = cx - halfX * 0.35, cz - halfZ * 0.2
	local poolW, poolL = halfX * 0.8, halfZ * 0.9
	part({ Name = "PoolBasin", Size = Vector3.new(poolW + 3, 5, poolL + 3), CFrame = deckCFrame(poolX, poolZ, -2.5),
		Color = Color3.fromRGB(60, 150, 180), Material = Enum.Material.Marble, Parent = folder })
	part({ Name = "PoolWater", Size = Vector3.new(poolW, 4, poolL), CFrame = deckCFrame(poolX, poolZ, -0.6),
		Color = Color3.fromRGB(70, 170, 210), Material = Enum.Material.Glass, Transparency = 0.35, Reflectance = 0.2,
		CanCollide = false, Parent = folder })
	-- infinity-edge glow strip
	part({ Name = "PoolGlow", Size = Vector3.new(poolW, 0.3, poolL), CFrame = deckCFrame(poolX, poolZ, 0.1),
		Color = Color3.fromRGB(120, 220, 255), Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false, Parent = folder })

	local rng = Random.new(100)
	local function face(deg)
		return CFrame.Angles(0, math.rad(deg), 0)
	end

	-- ---- DJ zone (back-left): stage, booth, speakers, truss, disco ball, dance floor, confetti
	local djZ = cz + halfZ * 0.78
	place("LEDDanceFloor", deckCFrame(cx - halfX * 0.1, djZ - halfZ * 0.3), folder, true, 60000)
	local dj = place("DJBooth", deckCFrame(cx - halfX * 0.1, djZ) * face(180), folder)
	dj:AddTag("DJStage")
	place("StageTruss", deckCFrame(cx - halfX * 0.1, djZ + 1.5), folder)
	place("DiscoBall", deckCFrame(cx - halfX * 0.1, djZ - halfZ * 0.3), folder)
	place("SpeakerStack", deckCFrame(cx - halfX * 0.42, djZ) * face(200), folder, true)
	place("SpeakerStack", deckCFrame(cx + halfX * 0.22, djZ) * face(160), folder, true)
	place("ConfettiCannonRT", deckCFrame(cx - halfX * 0.46, djZ - 2) * face(230), folder, true)
	place("ConfettiCannonRT", deckCFrame(cx + halfX * 0.26, djZ - 2) * face(130), folder, true)

	-- ---- bars (two) with stools, plus bar umbrellas
	place("RooftopBar", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.5) * face(180), folder)
	place("RooftopBar", deckCFrame(cx - halfX * 0.78, cz + halfZ * 0.4) * face(90), folder)
	place("BarUmbrella", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.5 - 2), folder, true)
	place("BarUmbrella", deckCFrame(cx - halfX * 0.78 + 2, cz + halfZ * 0.4), folder, true)

	-- ---- hot tub + a cabana (back-right)
	place("HotTub", deckCFrame(cx + halfX * 0.6, cz - halfZ * 0.55), folder)
	place("Cabana", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.0) * face(180), folder)
	place("CabanaBed", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.0) * face(180), folder, true, 40000)

	-- ---- pool zone (front-left): loungers under parasols, floaties in the water, ladders, diving board, slide, lifeguard
	for i = -2, 2 do
		local lx = cx - halfX * 0.75 + (i + 2) * 2.4
		place("PoolLounger", deckCFrame(lx, poolZ + poolL * 0.75) * face(180), folder, true, 20000)
		if i % 2 == 0 then
			place("Parasol", deckCFrame(lx + 1.3, poolZ + poolL * 0.75 + 1), folder, true)
		end
		place("TowelRack", deckCFrame(cx - halfX * 0.78, poolZ + poolL * 0.3 - i), folder, true)
	end
	place("FloatBull", deckCFrame(poolX - poolW * 0.2, poolZ, 0.2), folder, true, 8000)
	place("FloatFlamingo", deckCFrame(poolX + poolW * 0.1, poolZ - 2, 0.2), folder, true, 8000)
	place("FloatDonut", deckCFrame(poolX + poolW * 0.2, poolZ + 2, 0.2), folder, true, 8000)
	place("PoolLadder", deckCFrame(poolX + poolW / 2 - 0.3, poolZ) * face(90), folder)
	place("DivingBoard", deckCFrame(poolX - poolW / 2 - 1, poolZ) * face(270), folder)
	place("PoolSlide", deckCFrame(poolX, poolZ + poolL / 2 + 2) * face(0), folder)
	place("LifeguardChair", deckCFrame(poolX - poolW / 2 - 2, poolZ + poolL * 0.5) * face(300), folder)

	-- ---- lounge (front-right): sectionals, fire pit/table, egg chairs, hammock, rugs, telescope
	place("OutdoorRug", deckCFrame(cx + halfX * 0.1, cz - halfZ * 0.45), folder)
	place("SectionalSofa", deckCFrame(cx + halfX * 0.05, cz - halfZ * 0.5) * face(0), folder, true, 50000)
	place("FirePit", deckCFrame(cx + halfX * 0.1, cz - halfZ * 0.3), folder, true)
	place("FireTable", deckCFrame(cx + halfX * 0.35, cz - halfZ * 0.35) * face(90), folder, true)
	place("EggChair", deckCFrame(cx + halfX * 0.45, cz - halfZ * 0.6), folder, true)
	place("EggChair", deckCFrame(cx + halfX * 0.6, cz - halfZ * 0.4), folder, true)
	place("Hammock", deckCFrame(cx + halfX * 0.75, cz - halfZ * 0.75) * face(45), folder, true)
	place("Telescope", deckCFrame(cx + halfX * 0.85, cz + halfZ * 0.8) * face(225), folder, true)

	-- ---- VIP + features: velvet rope, gold bull statue, soda tower, ice wolf, neon sign, photo booth
	place("GoldBullStatue", deckCFrame(cx, cz + halfZ * 0.1) * face(180), folder)
	place("VIPRope", deckCFrame(cx - 2, cz + halfZ * 0.3) * face(0), folder, true)
	place("VIPRope", deckCFrame(cx + 2, cz + halfZ * 0.3) * face(0), folder, true)
	place("SodaTower", deckCFrame(cx + halfX * 0.3, cz + halfZ * 0.3), folder, true)
	place("IceWolf", deckCFrame(cx - halfX * 0.3, cz + halfZ * 0.2), folder, true)
	place("PhotoBooth", deckCFrame(cx - halfX * 0.85, cz - halfZ * 0.5) * face(60), folder)
	local sign = place("NeonWolfSign", CFrame.new(cx, ROOF_Y + 7, cz - halfZ + 0.5) * face(180), folder)
	sign.Name = "RoofNeonSign"

	-- ---- food & play (front-center): sushi + hot dog cart, basketball, giant chess, loose food pieces
	place("SushiTable", deckCFrame(cx - halfX * 0.4, cz - halfZ * 0.2) * face(0), folder, true, 40000)
	place("HotdogCart", deckCFrame(cx - halfX * 0.6, cz - halfZ * 0.0) * face(45), folder, true)
	place("BasketballHoop", deckCFrame(cx + halfX * 0.9, cz - halfZ * 0.05) * face(270), folder)
	place("GiantChess", deckCFrame(cx - halfX * 0.55, cz - halfZ * 0.75), folder)
	for i, food in { "Burger", "PizzaSlice", "Donut", "Sandwich", "Apple", "Banana" } do
		place(food, deckCFrame(cx - halfX * 0.4 + i * 0.4, cz - halfZ * 0.2, 1.4), folder, true, 6000)
	end

	-- ---- plants, lanterns, cash cart, money gun
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		place("PalmTree", deckCFrame(cx + corner[1] * halfX * 0.9, cz + corner[2] * halfZ * 0.88), folder)
		place("PlanterBox", deckCFrame(cx + corner[1] * halfX * 0.6, cz + corner[2] * halfZ * 0.9), folder, true)
	end
	for i = 0, 5 do
		place("Lantern", deckCFrame(cx - halfX * 0.8 + i * (halfX * 1.6 / 5), cz - halfZ * 0.95, 0), folder, true)
	end
	place("CashCart", deckCFrame(cx + halfX * 0.2, cz + halfZ * 0.6) * face(200), folder, true)
	place("MoneyGun", deckCFrame(cx + halfX * 0.25, cz + halfZ * 0.5, 1.2), folder, true, 6000)

	-- ---- string lights overhead across the deck
	for i = 0, 10 do
		local t = i / 10
		local sag = math.sin(t * math.pi) * 2
		part({ Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5),
			CFrame = deckCFrame(cx - halfX * 0.8 + t * halfX * 1.6, cz - halfZ * 0.9, 9 - sag),
			Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	end
	place("StringLights", deckCFrame(cx, cz + halfZ * 0.55, 0), folder)

	-- ---- helipad + helicopter, off to one side of the deck
	place("Helipad", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.78), folder)
	place("Helicopter", deckCFrame(cx + halfX * 0.55, cz + halfZ * 0.78) * face(200), folder)

	-- ---- breakable soda / juice bottles and cans on the bars and loose on the deck
	local BOTTLES = {
		{ "SodaBottle", Color3.fromRGB(90, 40, 20) },
		{ "JuiceBottle", Color3.fromRGB(240, 150, 40) },
		{ "CoconutDrink", Color3.fromRGB(220, 200, 160) },
	}
	for i = 1, 14 do
		local b = BOTTLES[(i % #BOTTLES) + 1]
		local pos = deckCFrame(cx + rng:NextNumber(-halfX * 0.7, halfX * 0.7), cz + rng:NextNumber(-halfZ * 0.3, halfZ * 0.7), 1.4)
		bottle(b[1], pos, b[2], folder)
	end
	for i = 1, 6 do
		place("SodaCan", deckCFrame(cx + rng:NextNumber(-halfX * 0.6, halfX * 0.6), cz + rng:NextNumber(-halfZ * 0.2, halfZ * 0.6),
			1.2), folder, true, 5000)
	end

	-- scattered money and papers on the deck
	Props.scatterChaos(folder, { { x = { cx - halfX * 0.8, cx + halfX * 0.8 }, z = { cz - halfZ * 0.3, cz + halfZ * 0.8 } } })
	-- lift the chaos up onto the deck (scatterChaos drops at low Y)
	local chaos = folder:FindFirstChild("Chaos")
	if chaos then
		for _, p in chaos:GetChildren() do
			if p:IsA("BasePart") then
				p.Position += Vector3.new(0, ROOF_Y + 1, 0)
			end
		end
	end

	-- a safety floor well below, so a fall is caught and the player is respawned (RoofService)
	local catch = part({ Name = "FallCatcher", Size = Vector3.new(halfX * 6, 2, halfZ * 6),
		CFrame = CFrame.new(cx, ROOF_Y - 60, cz), Transparency = 1, CanCollide = false, Parent = folder })
	catch.CanTouch = true

	local rooftop = {
		folder = folder,
		y = ROOF_Y,
		center = Vector3.new(cx, ROOF_Y, cz),
		-- where the elevator drops you off on the roof, and the safe-spawn used after a fall
		arrival = CFrame.new(cx - halfX * 0.1, ROOF_Y + 3.5, cz - halfZ * 0.7) * CFrame.Angles(0, math.rad(180), 0),
		catcher = catch,
		deckTop = ROOF_Y + 0.5,
		halfX = halfX,
		halfZ = halfZ,
	}
	local _ = office
	return rooftop
end

RooftopBuilder.ROOF_Y = ROOF_Y
return RooftopBuilder
