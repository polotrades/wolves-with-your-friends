-- The raid. When office suspicion hits 100 the floor gets busted: helicopters swing up outside the windows and
-- officers rappel down on ropes, while cartoon officers pour out of the elevators with cartoon (water-blaster)
-- guns. It's played for everyone (client Raid draws the camera + siren), then the day ends in a firing.
-- `chaosHeat()` reports how messy the floor is so GameLoop can let a trashed office raise suspicion over time.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local RaidService = {}

local office, rooftop
local NAVY = Color3.fromRGB(28, 38, 70)
local VEST = Color3.fromRGB(20, 24, 40)

local function p(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?,
	shape: Enum.PartType?): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cf
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

-- a cartoon officer: blocky avatar in navy with a cap and a bright water-blaster
local function officer(parent: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Officer"
	local skin = Color3.fromRGB(240, 200, 165)
	p(m, "Torso", Vector3.new(2, 2, 1), cf * CFrame.new(0, 3, 0), VEST)
	p(m, "Badge", Vector3.new(0.5, 0.5, 0.1), cf * CFrame.new(0.5, 3.3, -0.55), Color3.fromRGB(240, 210, 80), Enum.Material.Metal)
	p(m, "Head", Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 4.6, 0), skin, nil, Enum.PartType.Ball)
	p(m, "Cap", Vector3.new(1.3, 0.5, 1.3), cf * CFrame.new(0, 5.2, 0), NAVY)
	p(m, "CapBrim", Vector3.new(1.3, 0.15, 0.6), cf * CFrame.new(0, 5.0, -0.7), NAVY)
	for _, sx in { -1, 1 } do
		p(m, "Leg", Vector3.new(0.8, 2, 0.8), cf * CFrame.new(sx * 0.5, 1, 0), NAVY)
		p(m, "Arm", Vector3.new(0.7, 1.8, 0.7), cf * CFrame.new(sx * 1.35, 3.1, 0), NAVY)
	end
	-- cartoon water blaster
	p(m, "Blaster", Vector3.new(0.5, 0.6, 1.8), cf * CFrame.new(1.35, 3.0, -1), Color3.fromRGB(255, 140, 40))
	p(m, "BlasterTank", Vector3.new(0.5, 0.7, 0.5), cf * CFrame.new(1.35, 3.5, 0.1), Color3.fromRGB(80, 180, 240),
		Enum.Material.Glass, Enum.PartType.Cylinder)
	m.PrimaryPart = m:FindFirstChild("Torso") :: BasePart
	m.Parent = parent
	return m
end

local function helicopter(parent: Instance, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "RaidChopper"
	local body = p(m, "Body", Vector3.new(6, 6, 12), cf, Color3.fromRGB(30, 34, 55), nil, Enum.PartType.Ball)
	p(m, "Tail", Vector3.new(1.4, 1.4, 12), cf * CFrame.new(0, 0.8, 10), Color3.fromRGB(30, 34, 55))
	p(m, "Window", Vector3.new(4.6, 3, 4), cf * CFrame.new(0, 0.8, -3.6), Color3.fromRGB(120, 180, 230), nil, Enum.PartType.Ball)
	p(m, "SearchLight", Vector3.new(1.2, 1.2, 1), cf * CFrame.new(0, -2.6, -4), Color3.fromRGB(255, 255, 210), Enum.Material.Neon,
		Enum.PartType.Cylinder)
	local rotor = p(m, "Rotor", Vector3.new(22, 0.3, 1.2), cf * CFrame.new(0, 3.8, 0), Color3.fromRGB(25, 25, 25))
	m.PrimaryPart = body
	m.Parent = parent
	return m, rotor
end

-- how messy the floor is: a trashed office slowly raises suspicion (0..~0.5 per second)
function RaidService.chaosHeat(): number
	local floor = office and office.folder
	if not floor then
		return 0
	end
	local chaos = floor:FindFirstChild("Chaos")
	local moved = 0
	if chaos then
		for _, part in chaos:GetChildren() do
			if part:IsA("BasePart") and part.AssemblyLinearVelocity.Magnitude > 6 then
				moved += 1
			end
		end
	end
	return math.clamp(moved * 0.02, 0, 0.5)
end

-- the cutscene: choppers + rappelling officers outside, cops marching from the elevators
function RaidService.run()
	local folder = Instance.new("Folder")
	folder.Name = "Raid"
	folder.Parent = Workspace
	Net.Raid:FireAllClients(9)

	local center = Vector3.new(0, 60, 0)
	-- choppers circle outside, officers rappel on ropes
	local choppers = {}
	for i = 1, 3 do
		local a = i / 3 * math.pi * 2
		local hpos = center + Vector3.new(math.cos(a) * 90, 8, math.sin(a) * 90)
		local m, rotor = helicopter(folder, CFrame.lookAt(hpos, center))
		local rope = p(folder, "Rope", Vector3.new(0.2, 24, 0.2), CFrame.new(hpos - Vector3.new(0, 12, 0)),
			Color3.fromRGB(40, 40, 40))
		local rappeller = officer(folder, CFrame.new(hpos - Vector3.new(0, 10, 0)))
		table.insert(choppers, { model = m, rotor = rotor, rope = rope, rappeller = rappeller, base = hpos })
	end
	-- cops stream out of each elevator and march onto the floor
	local cops = {}
	for _, e in office.elevators do
		local from = e.inside.Position
		for k = 1, 2 do
			local cop = officer(folder, e.inside * CFrame.new((k - 1.5) * 2, -3, 2))
			table.insert(cops, { model = cop, from = from, to = from + e.inside.LookVector * (10 + k * 3) })
		end
	end

	-- animate for ~8 seconds
	local t0 = os.clock()
	local conn
	conn = game:GetService("RunService").Heartbeat:Connect(function()
		local t = os.clock() - t0
		for _, h in choppers do
			h.rotor.CFrame = h.model:GetPivot() * CFrame.new(0, 3.8, 0) * CFrame.Angles(0, t * 30, 0)
			local drop = math.min(1, t / 4)
			h.rappeller:PivotTo(CFrame.new(h.base - Vector3.new(0, 10 + drop * 30, 0)))
			h.rope.Size = Vector3.new(0.2, 24 + drop * 30, 0.2)
			h.rope.CFrame = CFrame.new(h.base - Vector3.new(0, 12 + drop * 15, 0))
		end
		for _, c in cops do
			local walk = math.clamp((t - 1) / 3, 0, 1)
			c.model:PivotTo(CFrame.new(c.from:Lerp(c.to, walk)))
		end
	end)
	task.wait(8)
	if conn then
		conn:Disconnect()
	end
	Debris:AddItem(folder, 2)
end

function RaidService.init(builtOffice, builtRooftop)
	office, rooftop = builtOffice, builtRooftop
	local _ = rooftop
end

return RaidService
