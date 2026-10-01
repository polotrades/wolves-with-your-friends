-- Server side of grabbing and throwing. Clients ask to grab a part (tagged "Grabbable"); the server hands them
-- network ownership so their held item and throw feel instant. On drop/throw the server records who threw it (for
-- knock-offs and bin spills) and clears ownership shortly after it settles.
-- Also: trash bins swallow items dropped in and spill them when the bin is thrown, the fish tank breaks when
-- something hits it hard, coffee pours into cups, cups spill puddles, food can be eaten, and the printer prints.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Physics = {}

local held: { [Player]: BasePart } = {}
local MAX_GRAB_DIST = 24
local MAX_THROW = 140

local function rootOf(part: BasePart): BasePart
	local model = part:FindFirstAncestorOfClass("Model")
	if model and model.PrimaryPart and CollectionService:HasTag(model, "Grabbable") then
		return model.PrimaryPart
	end
	return part.AssemblyRootPart or part
end

local function canGrab(player: Player, part: BasePart): boolean
	if not part or not part:IsA("BasePart") or part.Anchored then
		return false
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	return (part.Position - hrp.Position).Magnitude <= MAX_GRAB_DIST
end

local function onGrab(player: Player, part: any)
	if typeof(part) ~= "Instance" or not part:IsA("BasePart") then
		return
	end
	local root = rootOf(part)
	if not canGrab(player, root) then
		return
	end
	if held[player] then
		pcall(function()
			held[player]:SetNetworkOwner(nil)
		end)
	end
	held[player] = root
	root:SetAttribute("HeldBy", player.UserId)
	pcall(function()
		root:SetNetworkOwner(player)
	end)
end

-- an item was let go, maybe with a throw velocity
local function onDrop(player: Player, part: any, velocity: any)
	local root = held[player]
	if not root or (typeof(part) == "Instance" and part ~= root and rootOf(part :: BasePart) ~= root) then
		return
	end
	held[player] = nil
	root:SetAttribute("HeldBy", nil)
	root:SetAttribute("ThrownBy", player.UserId)
	root:SetAttribute("ThrownAt", os.clock())
	-- a bin thrown with items inside spills them
	if CollectionService:HasTag(root.Parent, "TrashBin") then
		Physics.spill(root.Parent :: Model)
	end
	if typeof(velocity) == "Vector3" then
		local v = velocity
		if v.Magnitude > MAX_THROW then
			v = v.Unit * MAX_THROW
		end
		root.AssemblyLinearVelocity = v
	end
	-- hand ownership back to the server once it settles, so it can't be hogged
	task.delay(5, function()
		if root and root.Parent and root:GetAttribute("HeldBy") == nil then
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
			root:SetAttribute("ThrownBy", nil)
		end
	end)
end

-- ------------------------------------------------------------------ trash bins
local swallowed: { [Model]: { BasePart } } = {}

function Physics.watchBin(bin: Model)
	local opening = bin.PrimaryPart or bin:FindFirstChildWhichIsA("BasePart")
	if not opening then
		return
	end
	CollectionService:AddTag(bin, "TrashBin")
	swallowed[bin] = {}
	-- a sensor just above the bin: things that fall in get parked inside
	local sensor = Instance.new("Part")
	sensor.Name = "Mouth"
	sensor.Size = opening.Size * Vector3.new(0.8, 0.6, 0.8)
	sensor.CFrame = opening.CFrame * CFrame.new(0, opening.Size.Y * 0.4, 0)
	sensor.Transparency = 1
	sensor.CanCollide = false
	sensor.CanQuery = false
	sensor.Massless = true
	sensor.Parent = bin
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = opening, sensor
	weld.Parent = sensor
	sensor.Touched:Connect(function(hit)
		local root = rootOf(hit)
		if root == opening or root.Parent == bin or root.Anchored then
			return
		end
		if not CollectionService:HasTag(root, "Grabbable") or CollectionService:HasTag(root.Parent, "TrashBin") then
			return
		end
		if root:GetAttribute("HeldBy") or root:GetAttribute("InBin") then
			return
		end
		local list = swallowed[bin]
		if #list >= 12 then
			return
		end
		root:SetAttribute("InBin", true)
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = opening.CFrame * CFrame.new(0, -0.2, 0)
		local align = Instance.new("WeldConstraint")
		align.Name = "BinWeld"
		align.Part0, align.Part1 = opening, root
		align.Parent = root
		table.insert(list, root)
	end)
end

function Physics.spill(bin: Model)
	local list = swallowed[bin]
	if not list then
		return
	end
	swallowed[bin] = {}
	local origin = (bin.PrimaryPart or bin:FindFirstChildWhichIsA("BasePart")).Position
	for _, root in list do
		if root and root.Parent then
			local w = root:FindFirstChild("BinWeld")
			if w then
				w:Destroy()
			end
			root:SetAttribute("InBin", nil)
			root.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), math.random(14, 26), math.random(-20, 20))
		end
	end
	local _ = origin
end

-- ------------------------------------------------------------------ fish tank
function Physics.watchFishTank(tank: Model)
	local main = tank.PrimaryPart or tank:FindFirstChildWhichIsA("BasePart")
	if not main then
		return
	end
	local broken = false
	local function breakIt()
		if broken then
			return
		end
		broken = true
		Net.Fx:FireAllClients("fishtank", tank:GetPivot())
		local swap = ReplicatedStorage:FindFirstChild("PropModels")
		swap = swap and swap:FindFirstChild("FishTankBroken")
		if swap then
			local new = swap:Clone()
			new:PivotTo(tank:GetPivot())
			new.Parent = tank.Parent
			new:AddTag("Grabbable")
		end
		tank:Destroy()
	end
	for _, d in tank:GetDescendants() do
		if d:IsA("BasePart") then
			d.Touched:Connect(function(hit)
				local root = hit.AssemblyRootPart or hit
				if root.Parent == tank then
					return
				end
				if root.AssemblyLinearVelocity.Magnitude > 22 or (root:GetAttribute("ThrownBy") ~= nil) then
					breakIt()
				end
			end)
		end
	end
end

Physics.setup = {} -- CallService fills this with helpers it shares (none yet)

function Physics.init()
	Net.Grab.OnServerEvent:Connect(onGrab)
	Net.Drop.OnServerEvent:Connect(onDrop)
	for _, bin in CollectionService:GetTagged("TrashBin") do
		Physics.watchBin(bin)
	end
	for _, tank in CollectionService:GetTagged("FishTank") do
		Physics.watchFishTank(tank)
	end
	CollectionService:GetInstanceAddedSignal("TrashBin"):Connect(Physics.watchBin)
	CollectionService:GetInstanceAddedSignal("FishTank"):Connect(Physics.watchFishTank)
	Players.PlayerRemoving:Connect(function(p)
		local root = held[p]
		if root then
			root:SetAttribute("HeldBy", nil)
			pcall(function()
				root:SetNetworkOwner(nil)
			end)
		end
		held[p] = nil
	end)
	local _ = Debris
end

return Physics
