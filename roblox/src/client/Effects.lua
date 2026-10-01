-- Shared visual effects fired by the server over the Fx remote: coffee puddles, pouring, eating crumbs, printing
-- and the fish tank shattering with a splash. All drawn locally so they're cheap.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Effects = {}

local function burst(at: CFrame, count: number, color: Color3, size: number, speed: number, life: number)
	for _ = 1, count do
		local p = Instance.new("Part")
		p.Size = Vector3.one * (size * math.random(6, 12) / 10)
		p.CFrame = at * CFrame.new(math.random(-5, 5) / 10, math.random(0, 6) / 10, math.random(-5, 5) / 10)
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Anchored = false
		p.Massless = true
		p.Shape = Enum.PartType.Ball
		p.Parent = workspace
		p.AssemblyLinearVelocity = Vector3.new(math.random(-speed, speed), math.random(speed, speed * 2),
			math.random(-speed, speed))
		Debris:AddItem(p, life)
	end
end

local function puddle(at: CFrame, color: Color3, size: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(size, 0.04, size)
	p.CFrame = at
	p.Color = color
	p.Material = Enum.Material.Glass
	p.Transparency = 0.25
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = workspace
	local round = Instance.new("CylinderMesh")
	round.Parent = p
	-- grows then slowly fades away
	local grow = 0
	task.spawn(function()
		while grow < 1 and p.Parent do
			grow += 0.1
			p.Size = Vector3.new(size * grow, 0.04, size * grow)
			task.wait(0.03)
		end
		task.wait(18)
		for i = 1, 10 do
			if not p.Parent then
				return
			end
			p.Transparency = 0.25 + i * 0.075
			task.wait(0.08)
		end
		p:Destroy()
	end)
	Debris:AddItem(p, 25)
end

local HANDLERS: { [string]: (CFrame) -> () } = {
	puddle = function(cf)
		puddle(cf, Color3.fromRGB(90, 55, 30), 2.4)
	end,
	pour = function(cf)
		burst(cf, 10, Color3.fromRGB(90, 55, 30), 0.14, 2, 0.8)
	end,
	eat = function(cf)
		burst(cf * CFrame.new(0, 1, 0), 8, Color3.fromRGB(220, 190, 120), 0.12, 3, 0.7)
	end,
	print = function(cf)
		burst(cf * CFrame.new(0, 0.4, 0), 5, Color3.fromRGB(250, 250, 245), 0.1, 1.5, 0.5)
	end,
	fishtank = function(cf)
		burst(cf * CFrame.new(0, 0.8, 0), 26, Color3.fromRGB(120, 200, 230), 0.18, 10, 1.4)
		puddle(CFrame.new(cf.Position - Vector3.new(0, cf.Position.Y, 0) + Vector3.new(0, 0.03, 0)),
			Color3.fromRGB(120, 190, 220), 5)
	end,
}

function Effects.init()
	Net.Fx.OnClientEvent:Connect(function(kind, cf)
		local h = HANDLERS[kind]
		if h and typeof(cf) == "CFrame" then
			h(cf)
		end
	end)
end

return Effects
