-- Physics props: anything here can be grabbed with the mouse (DragDetector), dragged, and flung.
-- Also scatters office chaos: papers, loose cash, cash stacks, crumpled paper balls and cups.
local CollectionService = game:GetService("CollectionService")

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
	-- grab + throw (Throwing.lua on the client, Physics.lua on the server)
	if target:IsA("Model") then
		CollectionService:AddTag(target, "Grabbable")
	else
		CollectionService:AddTag(root, "Grabbable")
	end
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
	brick.Size = Vector3.new(0.5, 0.25, 0.24)
	brick.CFrame = cf
	brick.Color = Color3.fromRGB(110, 170, 90)
	brick.Material = Enum.Material.Fabric
	brick.Parent = m
	local band = Instance.new("Part")
	band.Name = "Band"
	band.Size = Vector3.new(0.12, 0.27, 0.26)
	band.CFrame = cf
	band.Color = Color3.fromRGB(240, 220, 170)
	band.Material = Enum.Material.Cardboard
	band.CanCollide = false
	band.Parent = m
	m.PrimaryPart = brick
	m.Parent = parent
	Props.movable(m, 20000)
end

-- areas: open floor spots (aisles, lounge) in studs, { x = {min, max}, z = {min, max} }
function Props.scatterChaos(parent: Instance, areas: { { x: { number }, z: { number } } })
	local folder = Instance.new("Folder")
	folder.Name = "Chaos"
	folder.Parent = parent
	local rng = Random.new(42)
	local function spot(): CFrame
		local a = areas[rng:NextInteger(1, #areas)]
		local pos = Vector3.new(rng:NextNumber(a.x[1], a.x[2]), rng:NextNumber(0.3, 1.2), rng:NextNumber(a.z[1], a.z[2]))
		return CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	end
	for _ = 1, 110 do
		loose(folder, "Paper", Vector3.new(0.65, 0.03, 0.9), spot(), Color3.fromRGB(250, 250, 245), Enum.Material.SmoothPlastic)
	end
	for _ = 1, 70 do
		loose(folder, "Cash", Vector3.new(0.5, 0.02, 0.22), spot(), Color3.fromRGB(120, 180, 100), Enum.Material.Fabric)
	end
	for _ = 1, 18 do
		cashStack(folder, spot())
	end
	for _ = 1, 30 do
		loose(folder, "PaperBall", Vector3.new(0.35, 0.35, 0.35), spot(), Color3.fromRGB(240, 240, 235), Enum.Material.Fabric,
			Enum.PartType.Ball)
	end
	for _ = 1, 14 do
		loose(folder, "CoffeeCup", Vector3.new(0.45, 0.3, 0.3), spot() * CFrame.Angles(0, 0, math.pi / 2),
			Color3.fromRGB(245, 240, 230), Enum.Material.Cardboard, Enum.PartType.Cylinder)
	end
end

return Props
