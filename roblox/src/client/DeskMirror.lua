-- Monitors show what their user is doing: when someone is working at a desk, their Shark OS desktop (wallpaper,
-- windows, taskbar and cursor) is drawn on that desk's monitor for everyone walking past. The server copies each
-- player's compact desktop state onto their monitor as the "DeskState" attribute.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")

local UI = require(script.Parent:WaitForChild("UI"))
local Wallpapers = require(script.Parent:WaitForChild("Wallpapers"))
local Desktop = require(script.Parent:WaitForChild("Desktop"))

local DeskMirror = {}

type Mirror = { root: Frame, wall: Frame, windows: Frame, taskbar: Frame, cursor: TextLabel, start: Frame, wallId: string? }

local mirrors: { [BasePart]: Mirror } = {}

local function new(class: string, props): any
	local i = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then
			(i :: any)[k] = v
		end
	end
	i.Parent = props.Parent
	return i
end

local function build(monitor: BasePart): Mirror?
	local gui = monitor:WaitForChild("Mirror", 10)
	local bg = gui and gui:FindFirstChildWhichIsA("Frame")
	if not bg then
		return nil
	end
	local root = new("Frame", { Name = "Desktop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0, ZIndex = 15, Visible = false, ClipsDescendants = true, Parent = bg })
	local wall = new("Frame", { Size = UDim2.new(1, 0, 0.92, 0), BorderSizePixel = 0, Parent = root })
	local windows = new("Frame", { Size = UDim2.new(1, 0, 0.92, 0), BackgroundTransparency = 1, Parent = root })
	local taskbar = new("Frame", { Size = UDim2.new(1, 0, 0.08, 0), Position = UDim2.fromScale(0, 0.92),
		BackgroundColor3 = UI.os.taskbar, BorderSizePixel = 0, Parent = root })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.004, 0), Parent = taskbar })
	local start = new("Frame", { Size = UDim2.fromScale(0.34, 0.55), Position = UDim2.fromScale(0.33, 0.36),
		BackgroundColor3 = UI.os.title, Visible = false, ZIndex = 5, Parent = root })
	new("UICorner", { CornerRadius = UDim.new(0.04, 0), Parent = start })
	local cursor = new("TextLabel", { Size = UDim2.fromScale(0.05, 0.08), BackgroundTransparency = 1, Text = "➤", TextScaled = true,
		Rotation = -110, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0, Font = Enum.Font.GothamBold, ZIndex = 20,
		Parent = root })
	return { root = root, wall = wall, windows = windows, taskbar = taskbar, cursor = cursor, start = start }
end

local function glyphFor(appId: string): (string, Color3)
	local def = Desktop.app(appId)
	if def then
		return def.glyph, def.color
	end
	if appId == "adware" then
		return "💥", Color3.fromRGB(250, 80, 60)
	end
	return "▢", UI.os.accent
end

-- a window as a little rectangle: title bar with icon + title, and some fake content lines in the app's color
local function drawWindow(m: Mirror, w, z: number)
	local appId, title, x, y, ww, hh, focused = w[1], w[2], w[3], w[4], w[5], w[6], w[7]
	local glyph, color = glyphFor(appId)
	local f = new("Frame", { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(ww, hh), BackgroundColor3 = UI.os.surface,
		BorderSizePixel = 0, ZIndex = z, Parent = m.windows })
	new("UIStroke", { Color = focused == 1 and UI.os.accent or UI.os.border, Thickness = 1, Parent = f })
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 7), BackgroundColor3 = UI.os.title, BorderSizePixel = 0, ZIndex = z,
		Parent = f })
	new("TextLabel", { Size = UDim2.new(1, -4, 1, 0), Position = UDim2.fromOffset(2, 0), BackgroundTransparency = 1,
		Text = glyph .. " " .. title, TextScaled = true, TextColor3 = UI.os.text, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = z, Parent = bar })
	local rng = Random.new(#title + math.floor(ww * 100))
	for i = 1, 5 do
		new("Frame", { Position = UDim2.new(0.06, 0, 0, 7 + i * (hh * 60 / 6)), Size = UDim2.new(rng:NextNumber(0.3, 0.85), 0, 0, 2),
			BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.3), BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = z,
			Parent = f })
	end
end

local function render(monitor: BasePart, m: Mirror)
	local raw = monitor:GetAttribute("DeskState")
	if type(raw) ~= "string" or raw == "" then
		m.root.Visible = false
		return
	end
	local ok, s = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(s) ~= "table" then
		m.root.Visible = false
		return
	end
	m.root.Visible = true
	if m.wallId ~= s.w then
		m.wallId = s.w
		Wallpapers.draw(m.wall, tostring(s.w))
	end
	for _, c in m.windows:GetChildren() do
		c:Destroy()
	end
	for i, w in (type(s.win) == "table" and s.win or {}) do
		if type(w) == "table" and #w >= 7 then
			drawWindow(m, w, i + 1)
		end
	end
	for _, c in m.taskbar:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local gold = s.g == 1
	m.taskbar.BackgroundColor3 = gold and Color3.fromRGB(90, 70, 20) or UI.os.taskbar
	new("TextLabel", { Size = UDim2.fromScale(0.04, 0.8), BackgroundTransparency = 1, Text = "🦈", TextScaled = true, LayoutOrder = 0,
		Parent = m.taskbar })
	for i, id in (type(s.t) == "table" and s.t or {}) do
		local glyph, color = glyphFor(tostring(id))
		local tile = new("Frame", { Size = UDim2.fromScale(0.035, 0.7), BackgroundColor3 = color, LayoutOrder = i, Parent = m.taskbar })
		new("UICorner", { CornerRadius = UDim.new(0.25, 0), Parent = tile })
		new("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = glyph, TextScaled = true, Parent = tile })
	end
	m.start.Visible = s.s == 1
	local c = type(s.c) == "table" and s.c or { 0.5, 0.5 }
	m.cursor.Position = UDim2.fromScale(tonumber(c[1]) or 0.5, (tonumber(c[2]) or 0.5) * 0.92)
	m.cursor.TextColor3 = gold and Color3.fromRGB(255, 205, 60) or Color3.new(1, 1, 1)
end

local function attach(monitor: Instance)
	if not monitor:IsA("BasePart") or monitor.Name ~= "Monitor" or mirrors[monitor] then
		return
	end
	task.spawn(function()
		local m = build(monitor)
		if not m then
			return
		end
		mirrors[monitor] = m
		render(monitor, m)
		monitor:GetAttributeChangedSignal("DeskState"):Connect(function()
			render(monitor, m)
		end)
	end)
end

function DeskMirror.init()
	for _, m in CollectionService:GetTagged("DeskScreen") do
		attach(m)
	end
	CollectionService:GetInstanceAddedSignal("DeskScreen"):Connect(attach)
end

return DeskMirror
