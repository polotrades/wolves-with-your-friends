-- Rooftop gameplay: elevator buttons travel between the office and the roof, the DJ stage plays music, bottles
-- shatter when thrown, thrown items can knock players off the edge, and a fall respawns you at your last safe
-- spot on the deck (or back in the office).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))

local RoofService = {}

local office, rooftop
local lastSafe: { [Player]: CFrame } = {}
local onRoof: { [Player]: boolean } = {}

local function officeArrival(): CFrame
	local e = office.elevators[math.max(1, math.ceil(#office.elevators / 2))]
	return (e and e.inside) or office.lobby
end

local function teleport(player: Player, cf: CFrame)
	local char = player.Character
	if char then
		char:PivotTo(cf)
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end
end

local function goTo(player: Player, where: any)
	if where == "roof" and rooftop then
		onRoof[player] = true
		teleport(player, rooftop.arrival)
	elseif where == "office" then
		onRoof[player] = nil
		teleport(player, officeArrival())
	end
end

-- a floor-call button players press (E) somewhere in the world
local function callButton(parent: BasePart, text: string, color: Color3, offset: CFrame, where: string)
	local pad = Instance.new("Part")
	pad.Name = "FloorButton"
	pad.Size = Vector3.new(2.4, 3.4, 0.4)
	pad.CFrame = parent.CFrame * offset
	pad.Anchored = true
	pad.Color = Color3.fromRGB(20, 20, 24)
	pad.Material = Enum.Material.Metal
	pad.Parent = parent.Parent
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.PixelsPerStud = 50
	sg.Parent = pad
	local btn = Instance.new("TextLabel")
	btn.Size = UDim2.fromScale(0.9, 0.5)
	btn.Position = UDim2.fromScale(0.05, 0.25)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBlack
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = sg
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = "Elevator"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		if Config.ELEVATOR_DING_ID ~= "" then
			local s = Instance.new("Sound")
			s.SoundId = Config.ELEVATOR_DING_ID
			s.Parent = pad
			s:Play()
			Debris:AddItem(s, 3)
		end
		goTo(player, where)
	end)
	return pad
end

-- shatter a bottle: splash + shards, leave a puddle, remove the bottle
local function shatter(model: any)
	if model:GetAttribute("Broken") then
		return
	end
	model:SetAttribute("Broken", true)
	local pivot = model:GetPivot()
	local color = model:GetAttribute("LiquidColor") or Color3.fromRGB(200, 150, 60)
	Net.Fx:FireAllClients("puddle", CFrame.new(pivot.Position - Vector3.new(0, pivot.Position.Y % 1, 0)))
	for _ = 1, 8 do
		local shard = Instance.new("Part")
		shard.Size = Vector3.new(0.2, 0.2, 0.05)
		shard.CFrame = pivot * CFrame.new(math.random(-3, 3) / 10, math.random(0, 5) / 10, math.random(-3, 3) / 10)
		shard.Color = color
		shard.Material = Enum.Material.Glass
		shard.Transparency = 0.3
		shard.CanCollide = false
		shard.Parent = model.Parent
		shard.AssemblyLinearVelocity = Vector3.new(math.random(-14, 14), math.random(6, 16), math.random(-14, 14))
		Debris:AddItem(shard, 2.5)
	end
	model:Destroy()
end

local function watchBottle(model: any)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Touched:Connect(function()
				local root = (model :: any).PrimaryPart or d
				if root.AssemblyLinearVelocity.Magnitude > 20 or model:GetAttribute("ThrownBy") then
					shatter(model)
				end
			end)
		end
	end
end

-- thrown items that hit a player give them a shove (enough to knock them off the roof)
local function watchKnockoff(model: any)
	local root = (model :: any).PrimaryPart
	if not root then
		return
	end
	root.Touched:Connect(function(hit)
		local char = hit.Parent
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hum and hrp and model:GetAttribute("ThrownBy") then
			local v = root.AssemblyLinearVelocity
			if v.Magnitude > 24 then
				hrp.AssemblyLinearVelocity += v * 0.6 + Vector3.new(0, 20, 0)
				model:SetAttribute("ThrownBy", nil)
			end
		end
	end)
end

function RoofService.init(builtOffice, builtRooftop)
	office, rooftop = builtOffice, builtRooftop
	Net.Floor.OnServerEvent:Connect(goTo)

	-- ROOFTOP button in each office elevator car, OFFICE button on the roof deck
	for _, e in office.elevators do
		local car = e.model:FindFirstChild("CarMirror") :: BasePart?
		if car then
			callButton(car, "ROOFTOP", Color3.fromRGB(220, 150, 40), CFrame.new(0, 0, -0.3) * CFrame.Angles(0, math.pi, 0), "roof")
		end
	end
	if rooftop then
		-- a small elevator kiosk on the roof near the arrival point
		local kiosk = Instance.new("Part")
		kiosk.Name = "RoofElevator"
		kiosk.Anchored = true
		kiosk.Size = Vector3.new(3, 7, 1)
		kiosk.CFrame = rooftop.arrival * CFrame.new(0, 1.5, -2)
		kiosk.Color = Color3.fromRGB(40, 40, 46)
		kiosk.Material = Enum.Material.Metal
		kiosk.Parent = rooftop.folder
		callButton(kiosk, "OFFICE", Color3.fromRGB(60, 120, 230), CFrame.new(0, 0, 0.55), "office")

		-- DJ music
		local djStage = CollectionService:GetTagged("DJStage")[1]
		if djStage then
			local main = (djStage :: any).PrimaryPart or djStage:FindFirstChildWhichIsA("BasePart")
			if main and Config.DJ_MUSIC_ID ~= "" then
				local music = Instance.new("Sound")
				music.Name = "DJMusic"
				music.SoundId = Config.DJ_MUSIC_ID
				music.Looped = true
				music.Volume = 0.6
				music.RollOffMaxDistance = 120
				music.RollOffMinDistance = 10
				music.Parent = main
				music:Play()
			end
		end

		local function wire(tag: string, fn)
			for _, m in CollectionService:GetTagged(tag) do
				fn(m)
			end
			CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
		end
		wire("Bottle", watchBottle)
		wire("Grabbable", watchKnockoff)
	end

	-- fall respawn: remember the last grounded spot, catch anyone who drops below the deck
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hum and hrp then
				if hum.FloorMaterial ~= Enum.Material.Air and hrp.AssemblyLinearVelocity.Magnitude < 30 then
					lastSafe[player] = hrp.CFrame + Vector3.new(0, 1, 0)
				end
				-- fell off the roof (below the deck but above the office) -> back to the last safe spot
				if onRoof[player] and hrp.Position.Y < rooftop.y - 10 then
					teleport(player, lastSafe[player] or rooftop.arrival)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		lastSafe[p] = nil
		onRoof[p] = nil
	end)
end

return RoofService
