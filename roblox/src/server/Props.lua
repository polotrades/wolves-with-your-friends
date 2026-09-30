-- Physics props: anything here can be grabbed with the mouse (DragDetector), dragged, and flung.
-- Also scatters office chaos: papers, loose cash, cash stacks, crumpled paper balls and cups.
local Props = {}

-- Welds every part of a model to its root and makes the whole thing draggable.
function Props.movable(target: Instance, maxForce: number?)
	local root: BasePart?
	if target:IsA("BasePart") then
		root = target
	elseif target:IsA("Model") then
		root = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
		target.PrimaryPart = root
	end
	if not root then
		return
	end
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = root, d
			w.Parent = d
			d.Anchored = false
		end
	end
	root.Anchored = false
	local drag = Instance.new("DragDetector")
	drag.DragStyle = Enum.DragDetectorDragStyle.TranslateViewPlane
	drag.ResponseStyle = Enum.DragDetectorResponseStyle.Physical
	drag.ApplyAtCenterOfMass = true
	drag.MaxForce = maxForce or 60000
	drag.Responsiveness = 18
	drag.MaxActivationDistance = 22
	drag.Parent = target
	return root
end

local function loose(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material,
	shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	Props.movable(p, 20000)
	return p
end

local function cashStack(parent: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "CashStack"
	local brick = Instance.new("Part")
	brick.Name = "Bills"
	brick.Size = Vector3.new(1.3, 0.55, 0.65)
	brick.CFrame = cf
	brick.Color = Color3.fromRGB(110, 170, 90)
	brick.Material = Enum.Material.Fabric
	brick.Parent = m
	local band = Instance.new("Part")
	band.Name = "Band"
	band.Size = Vector3.new(0.3, 0.58, 0.68)
	band.CFrame = cf
	band.Color = Color3.fromRGB(240, 220, 170)
	band.Material = Enum.Material.Cardboard
	band.CanCollide = false
	band.Parent = m
	m.PrimaryPart = brick
	m.Parent = parent
	Props.movable(m, 20000)
end

-- Open floor spots (aisles, lobby, lounge) where chaos can land without burying desks.
local AREAS = {
	{ x = { -60, 46 }, z = { -16, -10 } }, -- north aisle
	{ x = { -60, 46 }, z = { 10, 16 } }, -- south aisle
	{ x = { -60, 46 }, z = { -46, -37 } }, -- behind the north pod
	{ x = { -60, 46 }, z = { 37, 46 } }, -- behind the south pod
	{ x = { -86, -66 }, z = { -30, 30 } }, -- lobby
	{ x = { 58, 86 }, z = { -18, 18 } }, -- break room
}

function Props.scatterChaos(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Chaos"
	folder.Parent = parent
	local rng = Random.new(42)
	local function spot(): CFrame
		local a = AREAS[rng:NextInteger(1, #AREAS)]
		local pos = Vector3.new(rng:NextNumber(a.x[1], a.x[2]), rng:NextNumber(0.3, 1.2), rng:NextNumber(a.z[1], a.z[2]))
		return CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	end
	for _ = 1, 110 do
		loose(folder, "Paper", Vector3.new(1.1, 0.04, 1.4), spot(), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic)
	end
	for _ = 1, 70 do
		loose(folder, "Cash", Vector3.new(1.3, 0.03, 0.6), spot(), Color3.fromRGB(120, 180, 100), Enum.Material.Fabric)
	end
	for _ = 1, 18 do
		cashStack(folder, spot())
	end
	for _ = 1, 30 do
		loose(folder, "PaperBall", Vector3.new(0.7, 0.7, 0.7), spot(), Color3.fromRGB(240, 240, 235), Enum.Material.Fabric,
			Enum.PartType.Ball)
	end
	for _ = 1, 14 do
		loose(folder, "CoffeeCup", Vector3.new(0.9, 0.6, 0.6), spot() * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(245, 240, 230), Enum.Material.Cardboard, Enum.PartType.Cylinder)
	end
end

return Props
