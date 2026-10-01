-- Character creator shown before you spawn: a draggable, zoomable 3D preview on the left and option tabs on the
-- right (Body, Skin, Hair, Face, Clothes, Hats, Moves). The chosen look is applied live to the preview and sent
-- with Spawn so you drop onto floor 100 looking exactly like the preview.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Appearance = require(Shared:WaitForChild("Appearance"))

local Customizer = {
	rebuildTab = nil :: any,
	spin = nil :: RBXScriptConnection?,
	look = nil :: any,
}

local player = Players.LocalPlayer
local look = Appearance.default()
local gui, viewport, rig, yaw, pitch, dist, dragging, lastDrag
local onDone: ((any) -> ())?

-- a plain R15 rig for the preview; falls back to nil if the engine won't build one
local function buildRig(): Model?
	local ok, model = pcall(function()
		local desc = Instance.new("HumanoidDescription")
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and model then
		return model
	end
	return nil
end

local function refreshRig()
	if not rig then
		return
	end
	-- re-dress the preview with the current look
	pcall(function()
		Appearance.apply(rig, look)
	end)
end

local function rebuildRig()
	if rig then
		rig:Destroy()
		rig = nil
	end
	rig = buildRig()
	if not rig then
		return
	end
	local hum = rig:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		-- apply body scale directly to the preview numbers
	end
	rig.Parent = viewport:FindFirstChildOfClass("WorldModel")
	refreshRig()
end

-- ------------------------------------------------------------------ option tabs
type Tab = { name: string, build: (Frame) -> () }

local function swatchRow(parent: Frame, label: string, colors: { Color3 }, current: () -> number, set: (number) -> ())
	UI.label(parent, label, 14, { Size = UDim2.new(1, 0, 0, 20), Font = UI.bold, TextColor3 = UI.os.dim })
	local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Parent = parent })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(40, 40), CellPadding = UDim2.fromOffset(8, 8), Parent = row })
	for i, c in colors do
		local b = UI.new("TextButton", { Text = "", BackgroundColor3 = c, LayoutOrder = i, Parent = row })
		UI.corner(b, 8)
		if current() == i then
			UI.new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, Parent = b })
		end
		b.Activated:Connect(function()
			set(i)
		end)
	end
end

local function optionRow(parent: Frame, label: string, options: { string }, current: () -> number, set: (number) -> ())
	local holder = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = UI.os.surface2, Parent = parent })
	UI.corner(holder, 8)
	UI.label(holder, label, 12, { Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(12, 6), TextColor3 = UI.os.dim,
		Font = UI.bold })
	local value = UI.label(holder, "", 16, { Size = UDim2.new(1, -120, 0, 24), Position = UDim2.fromOffset(60, 24),
		Font = UI.bold, TextXAlignment = Enum.TextXAlignment.Center })
	local function show()
		value.Text = (options[current()] or "?"):gsub("^%l", string.upper)
	end
	UI.flat(holder, "‹", UI.os.surface3, { Size = UDim2.fromOffset(40, 38), Position = UDim2.fromOffset(10, 10), TextSize = 22 },
		function()
			set((current() - 2) % #options + 1)
			show()
		end)
	UI.flat(holder, "›", UI.os.surface3, { Size = UDim2.fromOffset(40, 38), Position = UDim2.new(1, -50, 0, 10), TextSize = 22 },
		function()
			set(current() % #options + 1)
			show()
		end)
	show()
end

local TABS: { Tab } = {
	{ name = "Body", build = function(p)
		optionRow(p, "Build", Appearance.GENDERS, function() return look.gender end, function(v) look.gender = v; refreshRig() end)
		optionRow(p, "Body type", Appearance.BODIES, function() return look.body end, function(v) look.body = v; refreshRig() end)
		optionRow(p, "Moves", Appearance.ANIM_PACKS, function() return look.anim end, function(v) look.anim = v end)
	end },
	{ name = "Skin", build = function(p)
		swatchRow(p, "Skin tone", Appearance.SKINS, function() return look.skin end, function(v) look.skin = v; refreshRig(); Customizer.rebuildTab() end)
	end },
	{ name = "Hair", build = function(p)
		optionRow(p, "Style", Appearance.HAIR, function() return look.hair end, function(v) look.hair = v; refreshRig() end)
		swatchRow(p, "Color", Appearance.HAIR_COLORS, function() return look.hairColor end, function(v) look.hairColor = v; refreshRig(); Customizer.rebuildTab() end)
	end },
	{ name = "Face", build = function(p)
		optionRow(p, "Glasses", Appearance.GLASSES, function() return look.glasses end, function(v) look.glasses = v; refreshRig() end)
	end },
	{ name = "Clothes", build = function(p)
		optionRow(p, "Outfit", Appearance.OUTFITS, function() return look.outfit end, function(v) look.outfit = v; refreshRig() end)
		swatchRow(p, "Color", Appearance.OUTFIT_COLORS, function() return look.outfitColor end, function(v) look.outfitColor = v; refreshRig(); Customizer.rebuildTab() end)
	end },
	{ name = "Hats", build = function(p)
		optionRow(p, "Hat", Appearance.HATS, function() return look.hat end, function(v) look.hat = v; refreshRig() end)
	end },
}

local currentTab = 1
local tabContent

function Customizer.rebuildTab()
	if not tabContent then
		return
	end
	for _, c in tabContent:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	TABS[currentTab].build(tabContent)
end

-- ------------------------------------------------------------------ background: candlesticks, cash, ticker
local function background(parent: Instance)
	local bg = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 12, 22), BorderSizePixel = 0,
		Parent = parent })
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(14, 18, 36), Color3.fromRGB(6, 8, 16)),
		Parent = bg })
	-- candlesticks drifting across
	local rng = Random.new(21)
	local y = 0.6
	for i = 0, 40 do
		local up = rng:NextNumber() < 0.6
		local h = rng:NextNumber(0.03, 0.09)
		y = math.clamp(y + (up and -h or h) * 0.5, 0.2, 0.85)
		UI.new("Frame", { Size = UDim2.fromScale(0.012, h), Position = UDim2.fromScale(0.02 + i * 0.024, y),
			BackgroundColor3 = up and Color3.fromRGB(40, 180, 100) or Color3.fromRGB(200, 60, 70), BorderSizePixel = 0,
			BackgroundTransparency = 0.35, Parent = bg })
	end
	-- floating cash + $
	for _ = 1, 14 do
		UI.text(bg, rng:NextNumber() < 0.5 and "$" or "💵", { Size = UDim2.fromScale(0.05, 0.08),
			Position = UDim2.fromScale(rng:NextNumber(0, 0.95), rng:NextNumber(0, 0.9)), TextColor3 = Color3.fromRGB(90, 200, 120),
			TextTransparency = rng:NextNumber(0.4, 0.8), Rotation = rng:NextNumber(-30, 30) })
	end
	-- ticker along the bottom
	local tickerBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -30),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.3, BorderSizePixel = 0, ClipsDescendants = true,
		Parent = bg })
	local syms = "BMM +4.2%   WOLF +9.9%   YACHT -1.1%   MOON +42%   DUCK +0.4%   PUMP +15%   GOLD +2.0%   LAMBO +88%   "
	local ticker = UI.label(tickerBack, syms:rep(3), 16, { Size = UDim2.new(4, 0, 1, 0), Position = UDim2.fromScale(1, 0),
		TextColor3 = Color3.fromRGB(90, 220, 130), Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Left })
	task.spawn(function()
		while ticker.Parent do
			ticker.Position = UDim2.fromScale(1 - (os.clock() * 0.05) % 2, 0)
			RunService.RenderStepped:Wait()
		end
	end)
end

function Customizer.open(done: (any) -> ())
	onDone = done
	yaw, pitch, dist = 0, 0, 11
	gui = UI.new("ScreenGui", { Name = "Customizer", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 60,
		Parent = player:WaitForChild("PlayerGui") })
	UI.new("TextButton", { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Parent = gui })
	background(gui)
	UI.text(gui, "CREATE YOUR BROKER", { Size = UDim2.fromOffset(600, 50), Position = UDim2.fromOffset(50, 24),
		TextColor3 = UI.colors.gold, TextXAlignment = Enum.TextXAlignment.Left })

	-- preview
	viewport = UI.new("ViewportFrame", { Size = UDim2.new(0.42, 0, 1, -200), Position = UDim2.fromOffset(50, 90),
		BackgroundColor3 = Color3.fromRGB(16, 20, 34), Parent = gui })
	UI.corner(viewport, 12)
	UI.new("UIStroke", { Color = UI.os.border, Parent = viewport })
	local cam = Instance.new("Camera")
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	UI.new("WorldModel", { Parent = viewport })
	viewport.Ambient = Color3.fromRGB(150, 150, 160)
	viewport.LightColor = Color3.fromRGB(255, 250, 240)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	UI.label(viewport, "drag to rotate · scroll to zoom", 12, { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -22),
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.os.dim })

	-- rotate / zoom input over the viewport
	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastDrag = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	viewport.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			dist = math.clamp(dist - input.Position.Z * 1.5, 6, 20)
		elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = p - lastDrag
			lastDrag = p
			yaw -= d.X * 0.01
			pitch = math.clamp(pitch - d.Y * 0.01, -0.6, 0.6)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	Customizer.spin = RunService.RenderStepped:Connect(function()
		if not rig or not rig.PrimaryPart then
			return
		end
		if not dragging then
			yaw += 0.004
		end
		local center = rig:GetPivot().Position + Vector3.new(0, 0.5, 0)
		local offset = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * CFrame.new(0, 0, dist)
		cam.CFrame = CFrame.new(center) * offset
		cam.Focus = CFrame.new(center)
	end)

	-- right panel: tabs + options + spawn
	local panel = UI.new("Frame", { Size = UDim2.new(0.5, -40, 1, -200), Position = UDim2.new(0.5, 10, 0, 90),
		BackgroundColor3 = UI.os.surface, BackgroundTransparency = 0.05, Parent = gui })
	UI.corner(panel, 12)
	local tabBar = UI.new("Frame", { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
		Parent = panel })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), Parent = tabBar })
	local tabButtons = {}
	tabContent = UI.new("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -60), Position = UDim2.fromOffset(10, 56),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = panel })
	UI.new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabContent })
	UI.new("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = tabContent })
	for i, tab in TABS do
		local b = UI.flat(tabBar, tab.name, i == 1 and UI.colors.gold or UI.os.surface2, { Size = UDim2.fromOffset(78, 36),
			TextSize = 13 }, nil)
		b.LayoutOrder = i
		tabButtons[i] = b
		b.Activated:Connect(function()
			currentTab = i
			for j, tb in tabButtons do
				tb.BackgroundColor3 = j == i and UI.colors.gold or UI.os.surface2
			end
			Customizer.rebuildTab()
		end)
	end
	Customizer.rebuildTab()

	-- bottom buttons
	local function finish(spawn: boolean)
		if Customizer.spin then
			Customizer.spin:Disconnect()
		end
		gui:Destroy()
		gui = nil
		if rig then
			rig:Destroy()
			rig = nil
		end
		local fn = onDone
		onDone = nil
		if fn then
			fn(spawn and look or nil)
		end
	end
	-- RANDOM + BACK under the preview, ENTER under the panel
	UI.button(gui, "🎲 RANDOM", UI.os.surface2, { Size = UDim2.new(0.21, 0, 0, 54), Position = UDim2.new(0, 50, 1, -94) }, function()
		for key, list in { skin = Appearance.SKINS, hair = Appearance.HAIR, hairColor = Appearance.HAIR_COLORS,
			hat = Appearance.HATS, glasses = Appearance.GLASSES, outfit = Appearance.OUTFITS, outfitColor = Appearance.OUTFIT_COLORS,
			body = Appearance.BODIES, gender = Appearance.GENDERS, anim = Appearance.ANIM_PACKS } do
			(look :: any)[key] = math.random(1, #list)
		end
		refreshRig()
		Customizer.rebuildTab()
	end)
	UI.button(gui, "BACK", UI.os.surface2, { Size = UDim2.new(0.19, 0, 0, 54), Position = UDim2.new(0.22, 50, 1, -94) }, function()
		finish(false)
	end)
	UI.button(gui, "ENTER FLOOR 100", UI.colors.gold, { Size = UDim2.new(0.5, -40, 0, 64), Position = UDim2.new(0.5, 10, 1, -94),
		TextColor3 = Color3.fromRGB(40, 25, 5) }, function()
		finish(true)
	end)
	rebuildRig()
end

Customizer.look = look
return Customizer
