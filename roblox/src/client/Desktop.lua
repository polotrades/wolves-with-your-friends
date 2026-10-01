-- Shark OS: the full-screen desk computer, laid out like a familiar desktop (no real branding).
-- Wallpaper + desktop icons, windows, a taskbar with Start, pinned apps, the objective, PERSONAL, TEAM / QUOTA,
-- the review timer and a tray clock, a start menu, notifications and a right-click menu.
-- A compact copy of the desktop is sent to the server so your monitor shows it to people walking past.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent:WaitForChild("UI"))
local Window = require(script.Parent:WaitForChild("Window"))
local State = require(script.Parent:WaitForChild("State"))
local Wallpapers = require(script.Parent:WaitForChild("Wallpapers"))
local FileSystem = require(script.Parent:WaitForChild("FileSystem"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Deals = require(Shared:WaitForChild("Deals"))
local Config = require(Shared:WaitForChild("Config"))

export type AppDef = {
	id: string,
	name: string,
	glyph: string,
	color: Color3,
	open: () -> (),
	pinned: boolean?,
	desktop: boolean?,
	order: number?,
}

local Desktop = {
	onLeave = nil :: (() -> ())?,
	openFile = nil :: ((any) -> ())?, -- set by the Files app: opens a file from a desktop icon
	onOpen = nil :: (() -> ())?,
	onClose = nil :: (() -> ())?,
}

local TASKBAR_H = 48
local player = Players.LocalPlayer
local gui: ScreenGui
local wallpaper: Frame
local host: Frame
local iconArea: Frame
local center: Frame
local startMenu: Frame
local startGrid: ScrollingFrame
local startSearch: TextBox
local catcher: TextButton
local ctxMenu: Frame
local notifyHolder: Frame
local info = {} :: { [string]: TextLabel }
local apps: { [string]: AppDef } = {}
local appOrder: { AppDef } = {}
local taskButtons: { [string]: { button: TextButton, dot: Frame, pinned: boolean } } = {}
local wallpaperId = "sunset"
local booted = false
local savedWalk, savedJump
local mirrorDirty = true
local selectedIcon: GuiObject? = nil

-- ---------------------------------------------------------------- helpers
local function hoverable(b: GuiButton, base: number?)
	b.BackgroundTransparency = base or 1
	b.MouseEnter:Connect(function()
		b.BackgroundTransparency = 0.82
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundTransparency = base or 1
	end)
end

local function windowsFor(appId: string)
	local out = {}
	for _, w in Window.all() do
		if w.appId == appId then
			table.insert(out, w)
		end
	end
	return out
end

-- ---------------------------------------------------------------- taskbar
local function refreshTaskbar()
	local focused = Window.focused()
	for appId, tb in taskButtons do
		local wins = windowsFor(appId)
		if #wins == 0 and not tb.pinned then
			tb.button:Destroy()
			taskButtons[appId] = nil
		else
			local isFocused = focused ~= nil and focused.appId == appId and focused.frame.Visible
			tb.dot.Visible = #wins > 0
			tb.dot.Size = UDim2.fromOffset(isFocused and 16 or 6, 3)
			tb.dot.Position = UDim2.new(0.5, isFocused and -8 or -3, 1, -4)
			tb.dot.BackgroundColor3 = isFocused and UI.os.accent or UI.os.dim
			tb.button.BackgroundTransparency = isFocused and 0.85 or 1
		end
	end
	mirrorDirty = true
end

local function taskButton(def: AppDef, pinned: boolean)
	if taskButtons[def.id] then
		return
	end
	local b = UI.new("TextButton", { Name = def.id, Size = UDim2.fromOffset(44, 40), Text = "", AutoButtonColor = false,
		BackgroundColor3 = Color3.new(1, 1, 1), LayoutOrder = pinned and (def.order or 50) or 1000 + #center:GetChildren(),
		Parent = center })
	UI.corner(b, 6)
	hoverable(b)
	UI.icon(b, def.glyph, def.color, 26, { Position = UDim2.new(0.5, -13, 0.5, -15) })
	local dot = UI.new("Frame", { Size = UDim2.fromOffset(6, 3), Position = UDim2.new(0.5, -3, 1, -4),
		BackgroundColor3 = UI.os.dim, BorderSizePixel = 0, Visible = false, Parent = b })
	UI.corner(dot, 2)
	b.Activated:Connect(function()
		local wins = windowsFor(def.id)
		if #wins == 0 then
			def.open()
			return
		end
		local top = wins[#wins]
		if top:isFocused() then
			top:setMinimized(true)
		else
			top:setMinimized(false)
		end
	end)
	taskButtons[def.id] = { button = b, dot = dot, pinned = pinned }
end

-- ---------------------------------------------------------------- start menu
local function closeMenus()
	startMenu.Visible = false
	ctxMenu.Visible = false
	catcher.Visible = false
	mirrorDirty = true
end

local function fillStart(filter: string)
	for _, c in startGrid:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	filter = filter:lower()
	for _, def in appOrder do
		if filter == "" or def.name:lower():find(filter, 1, true) then
			local b = UI.new("TextButton", { Name = def.id, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1),
				LayoutOrder = def.order or 50, Parent = startGrid })
			UI.corner(b, 6)
			hoverable(b)
			UI.icon(b, def.glyph, def.color, 40, { Position = UDim2.new(0.5, -20, 0, 8) })
			UI.label(b, def.name, 12, { Size = UDim2.new(1, -4, 0, 30), Position = UDim2.new(0, 2, 0, 52),
				TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top })
			b.Activated:Connect(function()
				closeMenus()
				def.open()
			end)
		end
	end
end

local function toggleStart()
	local show = not startMenu.Visible
	closeMenus()
	if show then
		startSearch.Text = ""
		fillStart("")
		startMenu.Visible = true
		catcher.Visible = true
		startMenu.Position = UDim2.new(0.5, -270, 1, -TASKBAR_H - 12)
		TweenService:Create(startMenu, TweenInfo.new(0.15, Enum.EasingStyle.Quad),
			{ Position = UDim2.new(0.5, -270, 1, -TASKBAR_H - 16) }):Play()
	end
	mirrorDirty = true
end

local function leave()
	closeMenus()
	local fn = Desktop.onLeave
	if fn then
		fn()
	end
end

local function buildStartMenu()
	startMenu = UI.new("Frame", { Name = "StartMenu", Size = UDim2.fromOffset(540, 560), AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0.5, -270, 1, -TASKBAR_H - 16), BackgroundColor3 = UI.os.title, BackgroundTransparency = 0.04,
		Visible = false, ZIndex = 900, Parent = gui })
	UI.corner(startMenu, 10)
	UI.new("UIStroke", { Color = UI.os.border, Parent = startMenu })
	startSearch = UI.new("TextBox", { Size = UDim2.new(1, -48, 0, 34), Position = UDim2.fromOffset(24, 20),
		BackgroundColor3 = UI.os.surface2, TextColor3 = UI.os.text, PlaceholderText = "🔍  Type to search apps",
		PlaceholderColor3 = UI.os.dim, Font = UI.body, TextSize = 15, Text = "", ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = startMenu })
	UI.corner(startSearch, 17)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = startSearch })
	startSearch:GetPropertyChangedSignal("Text"):Connect(function()
		fillStart(startSearch.Text)
	end)
	UI.label(startMenu, "Pinned", 15, { Size = UDim2.new(1, -48, 0, 22), Position = UDim2.fromOffset(34, 66), Font = UI.bold })
	startGrid = UI.new("ScrollingFrame", { Size = UDim2.new(1, -40, 1, -170), Position = UDim2.fromOffset(20, 94),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = startMenu })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(80, 88), CellPadding = UDim2.fromOffset(4, 4),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = startGrid })
	-- bottom strip: you + Leave Desk
	local strip = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 64), Position = UDim2.new(0, 0, 1, -64),
		BackgroundColor3 = UI.os.taskbar, BorderSizePixel = 0, Parent = startMenu })
	UI.corner(strip, 10)
	local pic = UI.new("ImageLabel", { Size = UDim2.fromOffset(40, 40), Position = UDim2.fromOffset(28, 12),
		BackgroundColor3 = UI.os.surface3, Parent = strip })
	UI.corner(pic, 20)
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok then
			pic.Image = img
		end
	end)
	UI.label(strip, player.DisplayName, 15, { Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromOffset(80, 0),
		Font = UI.bold })
	local power = UI.flat(strip, "⏻  Leave Desk", UI.os.surface2, { Size = UDim2.fromOffset(140, 38),
		Position = UDim2.new(1, -164, 0, 13) }, leave)
	power.TextColor3 = UI.os.text
end

-- ---------------------------------------------------------------- right-click menu
local function showContext(pos: Vector2)
	closeMenus()
	for _, c in ctxMenu:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	local items = {
		{ "🖼️  Change background", "backgrounds" },
		{ "📁  Open Files", "files" },
		{ "🔄  Refresh", "" },
		{ "⏻  Leave desk", "__leave" },
	}
	for i, it in items do
		local b = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 30), Text = "   " .. it[1], Font = UI.body, TextSize = 14,
			TextColor3 = UI.os.text, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = Color3.new(1, 1, 1),
			AutoButtonColor = false, LayoutOrder = i, Parent = ctxMenu })
		UI.corner(b, 4)
		hoverable(b)
		b.Activated:Connect(function()
			closeMenus()
			if it[2] == "__leave" then
				leave()
			elseif it[2] == "" then
				iconArea.Visible = false
				task.delay(0.12, function()
					iconArea.Visible = true
				end)
			elseif apps[it[2]] then
				apps[it[2]].open()
			end
		end)
	end
	ctxMenu.Position = UDim2.fromOffset(pos.X, pos.Y)
	ctxMenu.Visible = true
	catcher.Visible = true
end

-- ---------------------------------------------------------------- desktop icons
local function selectIcon(b: GuiObject?)
	if selectedIcon and selectedIcon.Parent then
		(selectedIcon :: any).BackgroundTransparency = 1
	end
	selectedIcon = b
	if b then
		(b :: any).BackgroundTransparency = 0.75
	end
end

local function desktopIcon(name: string, glyph: string, color: Color3, order: number, open: () -> ())
	local b = UI.new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = UI.os.accent,
		BackgroundTransparency = 1, LayoutOrder = order, Parent = iconArea })
	UI.corner(b, 4)
	UI.icon(b, glyph, color, 44, { Position = UDim2.new(0.5, -22, 0, 6) })
	UI.label(b, name, 13, { Size = UDim2.new(1, -4, 0, 34), Position = UDim2.new(0, 2, 0, 54), TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, TextStrokeTransparency = 0.5,
		TextTruncate = Enum.TextTruncate.AtEnd })
	local last = 0
	b.Activated:Connect(function(input)
		local now = os.clock()
		-- double-click opens (a single tap opens on touch screens)
		if now - last < 0.4 or (input and input.UserInputType == Enum.UserInputType.Touch) then
			selectIcon(nil)
			open()
			last = 0
		else
			selectIcon(b)
			last = now
		end
	end)
end

local function refreshIcons()
	for _, c in iconArea:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	for _, def in appOrder do
		if def.desktop ~= false then
			desktopIcon(def.name, def.glyph, def.color, def.order or 50, def.open)
		end
	end
	for i, item in FileSystem.desktop.children or {} do
		desktopIcon(item.name, FileSystem.GLYPHS[item.kind] or "📄", FileSystem.COLORS[item.kind] or UI.os.surface3, 500 + i,
			function()
				local fn = Desktop.openFile
				if fn then
					fn(item)
				end
			end)
	end
end

-- ---------------------------------------------------------------- init
function Desktop.init()
	gui = UI.new("ScreenGui", {
		Name = "SharkOS", ResetOnSpawn = false, IgnoreGuiInset = true, Enabled = false, DisplayOrder = 5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui"),
	})
	wallpaper = UI.new("Frame", { Name = "Wallpaper", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Parent = gui })
	Wallpapers.draw(wallpaper, wallpaperId)
	-- Modal frees the mouse while the computer is open (the game is locked to first person)
	UI.new("TextButton", { Size = UDim2.fromScale(0, 0), BackgroundTransparency = 1, Text = "", Modal = true, Parent = gui })

	-- empty desktop: left click clears selection, right click opens the menu
	local back = UI.new("TextButton", { Name = "Back", Size = UDim2.new(1, 0, 1, -TASKBAR_H), BackgroundTransparency = 1,
		Text = "", AutoButtonColor = false, Parent = gui })
	back.Activated:Connect(function()
		selectIcon(nil)
		closeMenus()
	end)
	back.MouseButton2Click:Connect(function()
		local m = UserInputService:GetMouseLocation()
		showContext(Vector2.new(m.X, m.Y))
	end)

	host = UI.new("Frame", { Name = "Windows", Size = UDim2.new(1, 0, 1, -TASKBAR_H), BackgroundTransparency = 1, Parent = gui })
	iconArea = UI.new("Frame", { Name = "Icons", Size = UDim2.new(0, 300, 1, -16), Position = UDim2.fromOffset(8, 8),
		BackgroundTransparency = 1, Parent = host })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(86, 92), CellPadding = UDim2.fromOffset(4, 4),
		FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Parent = iconArea })

	-- taskbar
	local bar = UI.new("Frame", { Name = "Taskbar", Size = UDim2.new(1, 0, 0, TASKBAR_H), Position = UDim2.new(0, 0, 1, -TASKBAR_H),
		BackgroundColor3 = UI.os.taskbar, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 800, Parent = gui })
	UI.new("Frame", { Name = "Trim", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = UI.os.border, BorderSizePixel = 0,
		Parent = bar })

	-- left: objective
	local obj = UI.new("Frame", { Size = UDim2.fromOffset(330, TASKBAR_H), BackgroundTransparency = 1, Parent = bar })
	UI.text(obj, "🎯", { Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(12, 10) })
	UI.label(obj, "OBJECTIVE", 11, { Size = UDim2.new(1, -52, 0, 14), Position = UDim2.fromOffset(48, 6),
		TextColor3 = UI.os.dim, Font = UI.bold })
	info.objective = UI.label(obj, "", 14, { Size = UDim2.new(1, -52, 0, 20), Position = UDim2.fromOffset(48, 21),
		Font = UI.bold, TextTruncate = Enum.TextTruncate.AtEnd })

	-- middle: Start + pinned + running apps
	center = UI.new("Frame", { Name = "Apps", Size = UDim2.new(1, -760, 1, -8), Position = UDim2.fromOffset(340, 4),
		BackgroundTransparency = 1, Parent = bar })
	UI.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = center })
	local start = UI.new("TextButton", { Name = "Start", Size = UDim2.fromOffset(44, 40), Text = "", LayoutOrder = 0,
		AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1), Parent = center })
	UI.corner(start, 6)
	hoverable(start)
	UI.text(start, "🦈", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0.5, -14, 0.5, -14) })
	start.Activated:Connect(toggleStart)

	-- right: PERSONAL / TEAM / REVIEW, then the clock
	local right = UI.new("Frame", { Size = UDim2.fromOffset(410, TASKBAR_H), Position = UDim2.new(1, -410, 0, 0),
		BackgroundTransparency = 1, Parent = bar })
	local function stat(y: number, color: Color3): TextLabel
		return UI.label(right, "", 13, { Size = UDim2.fromOffset(250, 15), Position = UDim2.fromOffset(0, y), Font = UI.bold,
			TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Right })
	end
	info.personal = stat(2, UI.colors.green)
	info.team = stat(17, UI.colors.yellow)
	info.timer = stat(32, Color3.fromRGB(255, 130, 130))
	UI.new("Frame", { Size = UDim2.fromOffset(1, 30), Position = UDim2.fromOffset(262, 9), BackgroundColor3 = UI.os.border,
		BorderSizePixel = 0, Parent = right })
	info.clock = UI.label(right, "", 13, { Size = UDim2.fromOffset(96, 18), Position = UDim2.fromOffset(268, 7),
		TextXAlignment = Enum.TextXAlignment.Right })
	info.day = UI.label(right, "", 12, { Size = UDim2.fromOffset(96, 16), Position = UDim2.fromOffset(268, 25),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.os.dim })
	local exit = UI.new("TextButton", { Size = UDim2.fromOffset(32, 36), Position = UDim2.fromOffset(370, 6), Text = "⏻",
		Font = UI.bold, TextSize = 18, TextColor3 = UI.os.text, BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false,
		Parent = right })
	UI.corner(exit, 6)
	hoverable(exit)
	exit.Activated:Connect(leave)
	-- far-right sliver: show the desktop
	local peek = UI.new("TextButton", { Size = UDim2.fromOffset(6, TASKBAR_H), Position = UDim2.new(1, -6, 0, 0), Text = "",
		BackgroundColor3 = Color3.new(1, 1, 1), AutoButtonColor = false, Parent = bar })
	hoverable(peek)
	peek.Activated:Connect(function()
		for _, w in Window.all() do
			w:setMinimized(true)
		end
	end)

	-- menus sit above everything; the catcher closes them when you click elsewhere
	catcher = UI.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false,
		ZIndex = 850, Parent = gui })
	catcher.Activated:Connect(closeMenus)
	catcher.MouseButton2Click:Connect(closeMenus)
	buildStartMenu()
	ctxMenu = UI.new("Frame", { Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UI.os.title, Visible = false, ZIndex = 950, Parent = gui })
	UI.corner(ctxMenu, 8)
	UI.new("UIStroke", { Color = UI.os.border, Parent = ctxMenu })
	UI.pad(ctxMenu, 4)
	UI.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = ctxMenu })

	notifyHolder = UI.new("Frame", { Size = UDim2.fromOffset(340, 400), Position = UDim2.new(1, -352, 1, -TASKBAR_H - 408),
		BackgroundTransparency = 1, ZIndex = 870, Parent = gui })
	UI.new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = notifyHolder })

	Window.onAnyChange = refreshTaskbar
	FileSystem.onChange(refreshIcons)

	-- fit a 620px-tall window above the taskbar on any screen size
	local function fit()
		local cam = Workspace.CurrentCamera
		if cam then
			Window.setScale(math.clamp((cam.ViewportSize.Y - TASKBAR_H - 20) / 620, 0.5, 1))
		end
	end
	fit()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(fit)
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	-- the monitor mirror: send a compact copy of the desktop a few times a second while it changes
	local lastSent, lastMouse, nextSend = "", Vector2.zero, 0
	RunService.Heartbeat:Connect(function()
		if not gui.Enabled then
			return
		end
		local now = os.clock()
		if now < nextSend then
			return
		end
		nextSend = now + 0.25
		local m = UserInputService:GetMouseLocation()
		if (m - lastMouse).Magnitude > 4 then
			mirrorDirty = true
			lastMouse = m
		end
		if not mirrorDirty then
			return
		end
		mirrorDirty = false
		local s = Desktop.mirrorState()
		if s ~= lastSent then
			lastSent = s
			Net.DeskState:FireServer(s)
		end
	end)
	State.onChange(Desktop.refreshInfo)
end

-- ---------------------------------------------------------------- apps and windows
function Desktop.registerApp(def: AppDef)
	apps[def.id] = def
	table.insert(appOrder, def)
	table.sort(appOrder, function(a, b)
		return (a.order or 50) < (b.order or 50)
	end)
	if def.pinned then
		taskButton(def, true)
	end
	refreshIcons()
end

function Desktop.app(id: string): AppDef?
	return apps[id]
end

function Desktop.openApp(id: string)
	local def = apps[id]
	if def then
		def.open()
	end
end

function Desktop.host(): Frame
	return host
end

-- opens a window that belongs to an app: it gets the app's icon and a taskbar button
function Desktop.window(appId: string, title: string, size: Vector2, pos: UDim2?, resizable: boolean?)
	local def = apps[appId] or { id = appId, name = title, glyph = "▢", color = UI.os.accent, open = function() end }
	local n = #Window.all()
	local win = Window.new(host, {
		title = title,
		glyph = def.glyph,
		color = def.color,
		size = size,
		pos = pos or UDim2.fromOffset(170 + (n % 7) * 34, 16 + (n % 7) * 30),
		appId = appId,
		resizable = resizable,
	})
	taskButton(def, false)
	win:addCloseHandler(refreshTaskbar)
	refreshTaskbar()
	return win
end

-- the app's existing window, brought to the front, or nil
function Desktop.focusApp(appId: string)
	local wins = windowsFor(appId)
	local w = wins[#wins]
	if w then
		w:setMinimized(false)
	end
	return w
end

-- ---------------------------------------------------------------- notifications
function Desktop.notify(title: string, body: string, glyph: string?)
	if not gui then
		return
	end
	local card = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = UI.os.title, LayoutOrder = math.floor(os.clock() * 100),
		Parent = notifyHolder })
	UI.corner(card, 8)
	UI.new("UIStroke", { Color = UI.os.border, Parent = card })
	UI.text(card, glyph or "🔔", { Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(12, 12) })
	UI.label(card, title, 14, { Size = UDim2.new(1, -60, 0, 18), Position = UDim2.fromOffset(52, 10), Font = UI.bold })
	UI.label(card, body, 13, { Size = UDim2.new(1, -60, 0, 36), Position = UDim2.fromOffset(52, 30), TextWrapped = true,
		TextColor3 = UI.os.dim, TextYAlignment = Enum.TextYAlignment.Top })
	local scale = UI.new("UIScale", { Scale = 0.9, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	task.delay(4.5, function()
		if card.Parent then
			TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 0.01 }):Play()
			task.wait(0.16)
			card:Destroy()
		end
	end)
end

-- ---------------------------------------------------------------- wallpaper
function Desktop.setWallpaper(id: string)
	local w = Wallpapers.byId[id]
	if not w or (w.premium and not State.has(w.premium)) then
		return
	end
	wallpaperId = id
	Wallpapers.draw(wallpaper, id)
	mirrorDirty = true
end

function Desktop.wallpaper(): string
	return wallpaperId
end

-- ---------------------------------------------------------------- open / close
local function bootScreen()
	local boot = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 12), ZIndex = 1000,
		Parent = gui })
	if not booted then
		booted = true
		UI.text(boot, "🦈", { Size = UDim2.fromOffset(110, 110), Position = UDim2.new(0.5, -55, 0.38, -55), ZIndex = 1001 })
		UI.text(boot, "SHARK OS", { Size = UDim2.fromOffset(300, 40), Position = UDim2.new(0.5, -150, 0.52, 0),
			TextColor3 = Color3.fromRGB(230, 235, 255), ZIndex = 1001 })
		local dots = UI.new("Frame", { Size = UDim2.fromOffset(80, 10), Position = UDim2.new(0.5, -40, 0.66, 0),
			BackgroundTransparency = 1, ZIndex = 1001, Parent = boot })
		for i = 0, 4 do
			local d = UI.new("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(i * 16, 0),
				BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1002, Parent = dots })
			UI.corner(d, 4)
			TweenService:Create(d, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, i * 0.1),
				{ BackgroundTransparency = 0.8 }):Play()
		end
	else
		UI.text(boot, "Welcome back, " .. player.DisplayName, { Size = UDim2.fromOffset(500, 40),
			Position = UDim2.new(0.5, -250, 0.45, 0), TextColor3 = Color3.new(1, 1, 1), ZIndex = 1001 })
	end
	task.delay(booted and 0.5 or 1.3, function()
		local t = TweenService:Create(boot, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		for _, d in boot:GetDescendants() do
			if d:IsA("TextLabel") then
				TweenService:Create(d, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") then
				TweenService:Create(d, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			end
		end
		t:Play()
		t.Completed:Wait()
		boot:Destroy()
	end)
end

function Desktop.open(deskId: number?)
	State.deskId = deskId
	if gui.Enabled then
		return
	end
	gui.Enabled = true
	if Desktop.onOpen then
		Desktop.onOpen()
	end
	bootScreen()
	Desktop.refreshInfo()
	mirrorDirty = true
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		savedWalk, savedJump = hum.WalkSpeed, hum.JumpPower
		hum.WalkSpeed, hum.JumpPower = 0, 0
	end
	-- first person: look straight at this desk's monitor while working
	local floor = Workspace:FindFirstChild("Floor100")
	local desk = deskId and floor and floor:FindFirstChild("Desk" .. deskId)
	local monitor = desk and desk:FindFirstChild("Monitor") :: BasePart?
	if monitor then
		local cam = Workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Scriptable
		local front = monitor.CFrame.LookVector
		cam.CFrame = CFrame.lookAt(monitor.Position + front * 2.4 + Vector3.new(0, 0.25, 0), monitor.Position)
	end
end

function Desktop.close()
	if not gui.Enabled then
		return
	end
	closeMenus()
	gui.Enabled = false
	if Desktop.onClose then
		Desktop.onClose()
	end
	State.deskId = nil
	Net.LeaveDesk:FireServer()
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and savedWalk then
		hum.WalkSpeed, hum.JumpPower = savedWalk, savedJump
	end
end

function Desktop.isOpen(): boolean
	return gui.Enabled
end

-- ---------------------------------------------------------------- taskbar info
local function objective(): string
	local s = State.status
	if not s or s.state == "WAITING" then
		return "Get ready. The workday starts soon."
	elseif s.state == "MEETING" then
		return "Boss review in progress."
	elseif s.state ~= "DAY" then
		return "Everyone's fired. New run soon."
	end
	local c = State.call
	if not c then
		return "No call here. Find a RINGING desk."
	end
	local open = 0
	for _, d in Deals.list do
		if not State.claimed[d.id] then
			open += 1
		end
	end
	if open == 0 then
		return "All deals closed! Hang up, find another call."
	elseif c.trust < Config.REVEAL_TRUST then
		return string.format("Win their trust: %d / %d", c.trust, Config.REVEAL_TRUST)
	end
	return "Ask for their details, Verify in the deal apps."
end

function Desktop.refreshInfo()
	if not gui then
		return
	end
	info.personal.Text = "PERSONAL " .. UI.money(State.personal)
	info.objective.Text = objective()
	local s = State.status
	if not s then
		return
	end
	info.team.Text = string.format("TEAM %s / QUOTA %s", UI.money(s.team), UI.money(s.quota))
	info.team.TextColor3 = s.team >= s.quota and UI.colors.green or UI.colors.yellow
	info.timer.Text = s.state == "DAY" and ("REVIEW IN " .. UI.clock(s.timeLeft)) or s.state
	-- in-game clock runs 9:00 AM -> 5:00 PM over the workday
	local frac = s.state == "DAY" and (1 - s.timeLeft / Config.DAY_LENGTH) or (s.state == "WAITING" and 0 or 1)
	local minutes = 9 * 60 + math.floor(frac * 8 * 60)
	local h = minutes // 60
	info.clock.Text = string.format("%d:%02d %s", (h - 1) % 12 + 1, minutes % 60, h < 12 and "AM" or "PM")
	info.day.Text = "Day " .. s.day
end

function Desktop.setStatus(s)
	State.status = s
	Desktop.refreshInfo()
end

function Desktop.setPersonal(n: number)
	State.personal = n
	Desktop.refreshInfo()
end

function Desktop.lastStatus()
	return State.status
end

-- ---------------------------------------------------------------- monitor mirror
local function r3(n: number): number
	return math.floor(n * 1000 + 0.5) / 1000
end

function Desktop.mirrorState(): string
	local wins = {}
	for _, w in Window.all() do
		if w.frame.Visible and #wins < 8 then
			local x, y, ww, hh = w:rect()
			table.insert(wins, { w.appId or "", (w.title :: string):sub(1, 28), r3(x), r3(y), r3(ww), r3(hh), w:isFocused() and 1 or 0 })
		end
	end
	local running = {}
	for id in taskButtons do
		table.insert(running, id)
	end
	local m = UserInputService:GetMouseLocation()
	local size = gui.AbsoluteSize
	return HttpService:JSONEncode({
		w = wallpaperId,
		g = State.has("goldmouse") and 1 or 0,
		s = startMenu.Visible and 1 or 0,
		c = { r3(m.X / math.max(size.X, 1)), r3(m.Y / math.max(size.Y, 1)) },
		t = running,
		win = wins,
	})
end

-- big green "+$250" that floats up the screen
function Desktop.popMoney(amount: number)
	local target = gui.Enabled and gui or player.PlayerGui:FindFirstChild("Hud")
	if not target then
		return
	end
	local l = UI.text(target, "+" .. UI.money(amount), { Size = UDim2.fromScale(0.4, 0.2),
		Position = UDim2.fromScale(0.3, 0.35), TextColor3 = UI.colors.green, TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(10, 60, 20), ZIndex = 2000, Rotation = -6 })
	local t = TweenService:Create(l, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.3, 0.12), TextTransparency = 1, TextStrokeTransparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		l:Destroy()
	end)
end

return Desktop
