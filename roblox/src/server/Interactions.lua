-- Prop interactions driven by ProximityPrompts: eat food, pour a coffee into a fresh cup, and print a page.
-- Cups that get knocked over or thrown leave a puddle (handled with the client via the Fx remote).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))

local Interactions = {}

local Props -- set in init to avoid a cycle

local function prompt(parent: BasePart, action: string, key: Enum.KeyCode, dist: number): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = ""
	p.KeyboardKeyCode = key
	p.MaxActivationDistance = dist
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function mainPart(model: any): BasePart?
	if model:IsA("BasePart") then
		return model
	end
	return (model :: Model).PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

-- ------------------------------------------------------------------ food
local function watchEdible(model: any)
	local part = mainPart(model)
	if not part or model:FindFirstChild("EatPrompt") then
		return
	end
	local p = prompt(part, "Eat", Enum.KeyCode.E, 8)
	p.Name = "EatPrompt"
	p.Triggered:Connect(function()
		if model:GetAttribute("Eaten") then
			return
		end
		model:SetAttribute("Eaten", true)
		Net.Fx:FireAllClients("eat", model:GetPivot())
		-- three quick bites, then it's gone
		task.spawn(function()
			for _ = 1, 3 do
				if not model.Parent then
					return
				end
				if model:IsA("Model") then
					model:ScaleTo(math.max(0.2, model:GetScale() * 0.7))
				end
				task.wait(0.22)
			end
			model:Destroy()
		end)
	end)
end

-- ------------------------------------------------------------------ coffee
local function pourCup(at: CFrame)
	local models = ReplicatedStorage:FindFirstChild("PropModels")
	local template = models and models:FindFirstChild("PaperCup")
	local cup: Model
	if template then
		cup = template:Clone() :: Model
		cup:PivotTo(at)
	else
		local c = Instance.new("Part")
		c.Name = "PaperCup"
		c.Shape = Enum.PartType.Cylinder
		c.Size = Vector3.new(0.45, 0.3, 0.3)
		c.CFrame = at * CFrame.Angles(0, 0, math.pi / 2)
		c.Color = Color3.fromRGB(245, 240, 230)
		c.Material = Enum.Material.Cardboard
		cup = c
		local m = Instance.new("Model")
		c.Parent = m
		m.PrimaryPart = c
		m.Name = "PaperCup"
		cup = m
	end
	cup:AddTag("Cup")
	cup:SetAttribute("Full", true)
	cup.Parent = workspace
	if Props then
		Props.movable(cup, 15000)
	end
	Interactions.watchCup(cup)
	return cup
end

local function watchCoffee(model: any)
	local part = mainPart(model)
	if not part or model:FindFirstChild("PourPrompt") then
		return
	end
	local p = prompt(part, "Pour Coffee", Enum.KeyCode.E, 9)
	p.Name = "PourPrompt"
	p.Triggered:Connect(function()
		local spout = part.CFrame * CFrame.new(0, 0.1, -0.6)
		Net.Fx:FireAllClients("pour", spout)
		task.delay(0.6, function()
			pourCup(part.CFrame * CFrame.new(0, 0.35, -0.6))
		end)
	end)
end

-- a cup leaves a puddle when it tips over or is thrown while full
function Interactions.watchCup(model: any)
	local part = mainPart(model)
	if not part then
		return
	end
	task.spawn(function()
		while part.Parent and model.Parent do
			task.wait(0.4)
			if model:GetAttribute("Full") then
				local tipped = math.abs(part.CFrame.UpVector:Dot(Vector3.yAxis)) < 0.45
				local thrown = part.AssemblyLinearVelocity.Magnitude > 10
				if tipped or thrown then
					model:SetAttribute("Full", false)
					local ground = part.Position - Vector3.new(0, part.Position.Y, 0) + Vector3.new(0, 0.03, 0)
					Net.Fx:FireAllClients("puddle", CFrame.new(ground))
				end
			end
		end
	end)
end

-- ------------------------------------------------------------------ printer
local function watchPrinter(model: any)
	local part = mainPart(model)
	if not part or model:FindFirstChild("PrintPrompt") then
		return
	end
	local p = prompt(part, "Print", Enum.KeyCode.E, 9)
	p.Name = "PrintPrompt"
	p.Triggered:Connect(function()
		if model:GetAttribute("Busy") then
			return
		end
		model:SetAttribute("Busy", true)
		Net.Fx:FireAllClients("print", part:GetPivot())
		task.delay(0.9, function()
			local paper = Instance.new("Part")
			paper.Name = "Paper"
			paper.Size = Vector3.new(0.62, 0.03, 0.86)
			paper.CFrame = part.CFrame * CFrame.new(0, 0.1, -0.55)
			paper.Color = Color3.fromRGB(250, 250, 245)
			paper.Material = Enum.Material.SmoothPlastic
			paper.Parent = workspace
			if Props then
				Props.movable(paper, 8000)
			end
			paper.AssemblyLinearVelocity = part.CFrame.LookVector * -3 + Vector3.new(0, 2, 0)
			model:SetAttribute("Busy", nil)
		end)
	end)
end

function Interactions.init(props)
	Props = props
	local function wire(tag: string, fn)
		for _, m in CollectionService:GetTagged(tag) do
			fn(m)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	end
	wire("Edible", watchEdible)
	wire("CoffeeSource", watchCoffee)
	wire("Printer", watchPrinter)
	wire("Cup", Interactions.watchCup)
	local _ = Debris
end

return Interactions
