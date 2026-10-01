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

	-- hot tub, bars, DJ, loungers, parasols, planters, speakers
	place("HotTub", deckCFrame(cx + halfX * 0.55, cz - halfZ * 0.55), folder)
	place("RooftopBar", deckCFrame(cx + halfX * 0.5, cz + halfZ * 0.6) * CFrame.Angles(0, math.pi, 0), folder)
	place("RooftopBar", deckCFrame(cx - halfX * 0.75, cz + halfZ * 0.55) * CFrame.Angles(0, math.rad(90), 0), folder)
	local djCF = deckCFrame(cx + halfX * 0.1, cz + halfZ * 0.75) * CFrame.Angles(0, math.pi, 0)
	local dj = place("DJBooth", djCF, folder)
	dj.Name = "DJBooth"
	dj:AddTag("DJStage")
	place("SpeakerStack", deckCFrame(cx - halfX * 0.15, cz + halfZ * 0.78), folder)
	place("SpeakerStack", deckCFrame(cx + halfX * 0.35, cz + halfZ * 0.78), folder)

	local rng = Random.new(100)
	for i = -2, 2 do
		local lx = cx - halfX * 0.75 + (i + 2) * 2.2
		place("PoolLounger", deckCFrame(lx, poolZ + poolL * 0.7) * CFrame.Angles(0, math.pi, 0), folder, true, 20000)
		if i % 2 == 0 then
			place("Parasol", deckCFrame(lx + 1.2, poolZ + poolL * 0.7 + 1), folder)
		end
	end
	for _, corner in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		place("PlanterBox", deckCFrame(cx + corner[1] * halfX * 0.8, cz + corner[2] * halfZ * 0.8), folder)
	end

	-- string lights across the deck
	for i = 0, 10 do
		local t = i / 10
		local sag = math.sin(t * math.pi) * 2
		part({ Name = "Bulb", Shape = Enum.PartType.Ball, Size = Vector3.new(0.5, 0.5, 0.5),
			CFrame = deckCFrame(cx - halfX * 0.8 + t * halfX * 1.6, cz - halfZ * 0.9, 9 - sag),
			Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	end

	-- breakable bottles on the bars and loose on the deck
	local BOTTLES = {
		{ "SodaBottle", Color3.fromRGB(90, 40, 20) },
		{ "JuiceBottle", Color3.fromRGB(240, 150, 40) },
	}
	for i = 1, 10 do
		local b = BOTTLES[(i % 2) + 1]
		local pos = deckCFrame(cx + rng:NextNumber(-halfX * 0.6, halfX * 0.6), cz + rng:NextNumber(-halfZ * 0.3, halfZ * 0.6), 1.4)
		bottle(b[1], pos, b[2], folder)
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
