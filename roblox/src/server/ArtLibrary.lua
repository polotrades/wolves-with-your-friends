-- Puts the Blender props into the world.
-- Imported models live in ServerStorage.PropModels (import blender/export/props/PropPack*.fbx; one Model per prop,
-- MeshParts named after their Blender material like "Leather_Black"). Each model is measured once, scaled to its real
-- size, turned to match Blender, and given its Roblox materials from PropLooks. A prop that hasn't been imported yet
-- shows up as a plain box of the right size, so the office always works.
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PropLooks = require(Shared:WaitForChild("PropLooks"))

local ArtLibrary = {}

local S = Config.STUDS_PER_METER
ArtLibrary.S = S

type Vec = { number }

-- Blender meters (x, y, z-up) -> Roblox studs (x, y-up, z). Blender's -Y (a prop's front) becomes Roblox +Z.
function ArtLibrary.pos(p: Vec): Vector3
	return Vector3.new(p[1] * S, p[3] * S, -p[2] * S)
end

-- the same conversion for an offset inside a prop's own frame
function ArtLibrary.offset(x: number, y: number, z: number): Vector3
	return Vector3.new(x * S, z * S, -y * S)
end

-- where a prop stands (floor point + turn around the vertical axis, in Blender's convention)
function ArtLibrary.cf(p: Vec, r: number): CFrame
	return CFrame.new(ArtLibrary.pos(p)) * CFrame.Angles(0, r, 0)
end

-- the direction a prop with turn r faces, in Roblox space
function ArtLibrary.facing(r: number): Vector3
	return Vector3.new(math.sin(r), 0, math.cos(r))
end

local function worldBox(model: Instance): (Vector3, Vector3)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local half = d.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						local c = d.CFrame:PointToWorldSpace(Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
						lo = lo:Min(c)
						hi = hi:Max(c)
					end
				end
			end
		end
	end
	return lo, hi
end

local function applyLooks(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local key = d.Name:gsub("%.%d+$", "")
			local look = PropLooks.looks[key]
			if look then
				d.Material = look.material
				d.Color = look.color
				d.Transparency = look.transparency
				if look.material == Enum.Material.Neon or look.transparency > 0 then
					d.CastShadow = false
				end
			end
			d.Anchored = true
		end
	end
end

-- the prop's Blender box, converted to Roblox axes: expected size and the offset of its center from the origin
local function expected(name: string): (Vector3?, Vector3?)
	local b = PropLooks.bounds[name]
	if not b then
		return nil, nil
	end
	local lo, hi = b.lo, b.hi
	local size = Vector3.new(hi[1] - lo[1], hi[3] - lo[3], hi[2] - lo[2]) * S
	local center = ArtLibrary.offset((lo[1] + hi[1]) / 2, (lo[2] + hi[2]) / 2, (lo[3] + hi[3]) / 2)
	return size, center
end

local prepared: { [string]: Model | false } = {}
local preparedFolder: Folder

-- Measure an imported model once and fix it up so its pivot is the Blender origin with Blender's orientation.
local function prepare(name: string): Model | false
	local cached = prepared[name]
	if cached ~= nil then
		return cached
	end
	prepared[name] = false
	local folder = ServerStorage:FindFirstChild("PropModels")
	local src = folder and folder:FindFirstChild(name, true)
	local want, center = expected(name)
	if not (src and want and center) then
		return false
	end
	local model: Model
	if src:IsA("Model") then
		model = src:Clone()
	else
		model = Instance.new("Model")
		src:Clone().Parent = model
	end
	model.Name = name
	applyLooks(model)
	if not model:FindFirstChildWhichIsA("BasePart", true) then
		return false
	end

	-- 1) uniform scale, trusting the height unless the importer clearly mixed up the axes
	local lo, hi = worldBox(model)
	local size = hi - lo
	local ratio = want.Y / math.max(size.Y, 1e-3)
	local byMax = math.max(want.X, want.Y, want.Z) / math.max(size.X, size.Y, size.Z, 1e-3)
	if math.abs(ratio / byMax - 1) > 0.3 then
		ratio = byMax
	end
	model:ScaleTo(model:GetScale() * ratio)

	-- 2) width and depth swapped -> quarter turn; plus the global turn if imports face backwards
	lo, hi = worldBox(model)
	size = hi - lo
	local yaw = math.rad(Config.PROP_TURN_DEGREES)
	if math.abs(want.X - want.Z) > 0.1 * math.max(want.X, want.Z) and (size.X > size.Z) ~= (want.X > want.Z) then
		yaw += math.pi / 2
	end
	local mid = (lo + hi) / 2
	model:PivotTo(CFrame.new(mid) * CFrame.Angles(0, yaw, 0) * CFrame.new(-mid) * model:GetPivot())

	-- 3) pivot = Blender origin: the box center minus where Blender says the center sits
	lo, hi = worldBox(model)
	model.WorldPivot = CFrame.new((lo + hi) / 2 - center)
	model:PivotTo(CFrame.new())
	preparedFolder = preparedFolder or ServerStorage:FindFirstChild("PreparedProps") or Instance.new("Folder")
	preparedFolder.Name = "PreparedProps"
	preparedFolder.Parent = ServerStorage
	model.Parent = preparedFolder
	prepared[name] = model
	return model
end

function ArtLibrary.has(name: string): boolean
	return prepare(name) ~= false
end

-- A stand-in box for props that haven't been imported yet.
local function fallback(name: string, cf: CFrame, scale: number): Model
	local m = Instance.new("Model")
	m.Name = name
	local want, center = expected(name)
	local box = Instance.new("Part")
	box.Name = "Placeholder"
	box.Anchored = true
	box.Size = (want or Vector3.new(2, 2, 2)) * scale
	box.CFrame = cf * CFrame.new((center or Vector3.new(0, 1, 0)) * scale)
	box.Color = Color3.fromRGB(170, 165, 158)
	box.Material = Enum.Material.SmoothPlastic
	box.TopSurface = Enum.SurfaceType.Smooth
	box.BottomSurface = Enum.SurfaceType.Smooth
	box.Parent = m
	m.PrimaryPart = box
	m.WorldPivot = cf
	return m
end

-- Place a prop with its origin (the floor point it stands on) at cf. Returns the model and whether it's real art.
function ArtLibrary.place(name: string, cf: CFrame, scale: number?, parent: Instance?): (Model, boolean)
	local s = scale or 1
	local template = prepare(name)
	local m: Model
	if template then
		m = (template :: Model):Clone()
		if s ~= 1 then
			m:ScaleTo(m:GetScale() * s)
		end
		m:PivotTo(cf)
	else
		m = fallback(name, cf, s)
	end
	m.Parent = parent
	return m, template ~= false
end

return ArtLibrary
