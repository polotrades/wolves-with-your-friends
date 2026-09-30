-- Desktop wallpapers, drawn with frames and gradients so they scale to any size: the full desktop, the
-- Backgrounds app previews and the tiny copy on a desk monitor. Premium ones unlock in Shark Mart's Store.
local UI = require(script.Parent:WaitForChild("UI"))

local Wallpapers = {}

local function grad(parent: Instance, colors: { Color3 }, rotation: number)
	local keys = {}
	for i, c in colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(#colors - 1, 1), c))
	end
	return UI.new("UIGradient", { Color = ColorSequence.new(keys), Rotation = rotation, Parent = parent })
end

local function box(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, props)
	local f = UI.new("Frame", { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundColor3 = color,
		BorderSizePixel = 0, Parent = parent })
	for k, v in props or {} do
		(f :: any)[k] = v
	end
	return f
end

local function skyline(parent: Instance, seed: number, color: Color3, lit: Color3?)
	local rng = Random.new(seed)
	for i = 0, 26 do
		local h = rng:NextNumber(0.12, 0.42)
		local b = box(parent, i * 0.038, 0.94 - h, 0.04, h + 0.06, color)
		if lit then
			for _ = 1, 4 do
				box(b, rng:NextNumber(0.15, 0.7), rng:NextNumber(0.05, 0.8), 0.15, 0.03, lit,
					{ BackgroundTransparency = rng:NextNumber(0, 0.5) })
			end
		end
	end
end

local function blob(parent: Instance, x: number, y: number, s: number, colors: { Color3 }, rot: number, transp: number)
	local f = box(parent, x - s / 2, y - s / 2, s, s, Color3.new(1, 1, 1), { BackgroundTransparency = transp })
	UI.new("UIAspectRatioConstraint", { AspectRatio = 1, Parent = f })
	UI.new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = f })
	grad(f, colors, rot)
	return f
end

Wallpapers.list = {
	{ id = "sunset", name = "Tower Sunset", draw = function(f)
		grad(f, { Color3.fromRGB(40, 30, 95), Color3.fromRGB(200, 90, 110), Color3.fromRGB(255, 175, 80) }, 90)
		skyline(f, 7, Color3.fromRGB(35, 25, 60), Color3.fromRGB(255, 210, 120))
	end },
	{ id = "petals", name = "Petals", draw = function(f)
		grad(f, { Color3.fromRGB(10, 20, 60), Color3.fromRGB(20, 60, 140) }, 45)
		blob(f, 0.62, 0.5, 0.7, { Color3.fromRGB(60, 140, 255), Color3.fromRGB(30, 60, 200) }, 30, 0.1)
		blob(f, 0.48, 0.58, 0.5, { Color3.fromRGB(120, 200, 255), Color3.fromRGB(40, 90, 230) }, 120, 0.25)
		blob(f, 0.7, 0.35, 0.32, { Color3.fromRGB(180, 230, 255), Color3.fromRGB(70, 140, 255) }, 200, 0.35)
	end },
	{ id = "night", name = "City Night", draw = function(f)
		grad(f, { Color3.fromRGB(5, 8, 25), Color3.fromRGB(25, 30, 70) }, 90)
		local rng = Random.new(3)
		for _ = 1, 40 do
			box(f, rng:NextNumber(), rng:NextNumber(0, 0.45), 0.003, 0.005, Color3.new(1, 1, 1),
				{ BackgroundTransparency = rng:NextNumber(0, 0.6) })
		end
		blob(f, 0.82, 0.18, 0.12, { Color3.fromRGB(255, 250, 225), Color3.fromRGB(220, 220, 200) }, 90, 0)
		skyline(f, 11, Color3.fromRGB(12, 14, 30), Color3.fromRGB(255, 220, 120))
	end },
	{ id = "market", name = "Green Day", draw = function(f)
		f.BackgroundColor3 = Color3.fromRGB(6, 16, 14)
		for i = 1, 9 do
			box(f, 0, i / 10, 1, 0.002, Color3.fromRGB(20, 60, 45))
			box(f, i / 10, 0, 0.001, 1, Color3.fromRGB(20, 60, 45))
		end
		local rng = Random.new(5)
		local y = 0.8
		for i = 0, 38 do
			local up = rng:NextNumber() < 0.62
			local h = rng:NextNumber(0.02, 0.07)
			y = math.clamp(y + (up and -h or h) * 0.6, 0.15, 0.85)
			box(f, 0.03 + i * 0.025, y, 0.014, h, up and Color3.fromRGB(40, 230, 110) or Color3.fromRGB(255, 70, 80))
		end
	end },
	{ id = "mint", name = "Mint Waves", draw = function(f)
		grad(f, { Color3.fromRGB(20, 110, 110), Color3.fromRGB(120, 220, 190) }, 60)
		for i = 0, 3 do
			blob(f, 0.2 + i * 0.25, 1.05 - i * 0.04, 0.6, { Color3.fromRGB(230, 255, 245), Color3.fromRGB(80, 200, 180) },
				90, 0.55 + i * 0.08)
		end
	end },
	{ id = "ocean", name = "Deep Blue", draw = function(f)
		grad(f, { Color3.fromRGB(120, 200, 255), Color3.fromRGB(20, 80, 170), Color3.fromRGB(5, 25, 70) }, 90)
		for i = 0, 5 do
			box(f, 0, 0.55 + i * 0.08, 1, 0.012, Color3.fromRGB(180, 230, 255), { BackgroundTransparency = 0.6 + i * 0.06 })
		end
	end },
	{ id = "graphite", name = "Graphite", draw = function(f)
		grad(f, { Color3.fromRGB(45, 45, 52), Color3.fromRGB(20, 20, 24) }, 90)
	end },
	{ id = "coral", name = "Coral", draw = function(f)
		grad(f, { Color3.fromRGB(255, 120, 110), Color3.fromRGB(255, 190, 140) }, 30)
	end },
	{ id = "goldrush", name = "Gold Rush", premium = "wp_goldrush", draw = function(f)
		grad(f, { Color3.fromRGB(90, 60, 10), Color3.fromRGB(230, 180, 50), Color3.fromRGB(255, 235, 150) }, 70)
		local rng = Random.new(9)
		for _ = 1, 18 do
			local s = rng:NextNumber(0.04, 0.1)
			local l = UI.text(f, "$", { Size = UDim2.fromScale(s, s * 1.6), Position = UDim2.fromScale(rng:NextNumber(0, 0.95),
				rng:NextNumber(0, 0.9)), TextColor3 = Color3.fromRGB(255, 250, 220), TextTransparency = rng:NextNumber(0.3, 0.7),
				Rotation = rng:NextNumber(-25, 25) })
			l.ZIndex = f.ZIndex + 1
		end
	end },
	{ id = "neon", name = "Neon Grid", premium = "wp_neon", draw = function(f)
		grad(f, { Color3.fromRGB(20, 0, 40), Color3.fromRGB(90, 10, 110), Color3.fromRGB(255, 60, 160) }, 90)
		blob(f, 0.5, 0.62, 0.34, { Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 60, 140) }, 90, 0)
		box(f, 0, 0.62, 1, 0.38, Color3.fromRGB(25, 0, 45))
		for i = 0, 6 do
			box(f, 0, 0.64 + i * i * 0.008, 1, 0.004, Color3.fromRGB(255, 80, 220))
		end
		for i = -6, 6 do
			box(f, 0.5 + i * 0.08, 0.62, 0.003, 0.38, Color3.fromRGB(255, 80, 220), { Rotation = i * 8 })
		end
	end },
	{ id = "yacht", name = "Yacht Life", premium = "wp_yacht", draw = function(f)
		grad(f, { Color3.fromRGB(110, 200, 255), Color3.fromRGB(200, 240, 255) }, 90)
		blob(f, 0.8, 0.2, 0.14, { Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 200, 80) }, 90, 0)
		box(f, 0, 0.62, 1, 0.38, Color3.fromRGB(20, 110, 190))
		box(f, 0.3, 0.52, 0.4, 0.1, Color3.fromRGB(250, 250, 255))
		box(f, 0.38, 0.44, 0.22, 0.08, Color3.fromRGB(235, 240, 250))
		box(f, 0.44, 0.38, 0.1, 0.06, Color3.fromRGB(40, 60, 90))
		for i = 0, 4 do
			box(f, 0, 0.66 + i * 0.07, 1, 0.01, Color3.fromRGB(150, 210, 255), { BackgroundTransparency = 0.5 })
		end
	end },
}

Wallpapers.byId = {}
for _, w in Wallpapers.list do
	Wallpapers.byId[w.id] = w
end

-- clears a frame and paints a wallpaper into it
function Wallpapers.draw(frame: Frame, id: string)
	for _, c in frame:GetChildren() do
		if not c:GetAttribute("KeepOnWallpaper") then
			c:Destroy()
		end
	end
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.ClipsDescendants = true
	local w = Wallpapers.byId[id] or Wallpapers.list[1];
	(w.draw :: any)(frame)
end

return Wallpapers
