-- Shark OS windows: title bar with minimize / maximize / close, drag, snap (drag to the left or right edge for a
-- half screen, to the top to maximize), double-click the title to maximize, and a resize grip.
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local UI = require(script.Parent:WaitForChild("UI"))

local Window = {}
Window.__index = Window
Window.TITLE_H = 32

local topZ = 10
local scale = 1
local live = {} -- open windows, so a screen-size change can rescale them all
local focused = nil
Window.onAnyChange = nil :: (() -> ())? -- the desktop listens so it can refresh the taskbar and the monitor mirror

local function changed()
	local fn = Window.onAnyChange
	if fn then
		fn()
	end
end

-- Shrink every window on small screens so nothing gets cut off at the bottom.
function Window.setScale(s: number)
	scale = s
	for w in live do
		w.uiScale.Scale = s
		w:applyLayout()
	end
end

function Window.focused()
	return focused
end

function Window.all()
	local out = {}
	for w in live do
		table.insert(out, w)
	end
	table.sort(out, function(a, b)
		return a.frame.ZIndex < b.frame.ZIndex
	end)
	return out
end

type Options = {
	title: string,
	glyph: string?,
	color: Color3?,
	size: Vector2,
	pos: UDim2?,
	minSize: Vector2?,
	resizable: boolean?,
	appId: string?,
}

function Window.new(host: GuiObject, opts: Options)
	local self = setmetatable({}, Window)
	topZ += 1
	self.host = host
	self.appId = opts.appId
	self.title = opts.title
	self.glyph = opts.glyph or "▢"
	self.color = opts.color or UI.os.accent
	self.normalSize = opts.size
	self.minSize = opts.minSize or Vector2.new(260, 180)
	self.normalPos = opts.pos or UDim2.fromOffset(120, 40)
	self.mode = "normal" -- normal | max | left | right
	self.onClose = nil :: (() -> ())?
	self.conns = {}

	local frame = UI.new("Frame", { Name = opts.title, Size = UDim2.fromOffset(opts.size.X, opts.size.Y),
		Position = self.normalPos, BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, ZIndex = topZ, Parent = host })
	UI.corner(frame, 8)
	self.stroke = UI.new("UIStroke", { Color = UI.os.border, Thickness = 1, Parent = frame })
	self.uiScale = UI.new("UIScale", { Scale = scale, Parent = frame })

	local bar = UI.new("Frame", { Name = "TitleBar", Size = UDim2.new(1, 0, 0, Window.TITLE_H),
		BackgroundColor3 = UI.os.title, BorderSizePixel = 0, Parent = frame })
	UI.corner(bar, 8)
	UI.new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -8), BackgroundColor3 = UI.os.title,
		BorderSizePixel = 0, Parent = bar, Name = "Square" })
	UI.icon(bar, self.glyph, self.color, 20, { Position = UDim2.fromOffset(8, 6) })
	self.titleLabel = UI.label(bar, opts.title, 14, { Size = UDim2.new(1, -180, 1, 0), Position = UDim2.fromOffset(36, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Font = UI.body })
	local content = UI.new("Frame", { Name = "Content", Size = UDim2.new(1, 0, 1, -Window.TITLE_H),
		Position = UDim2.fromOffset(0, Window.TITLE_H), BackgroundTransparency = 1, ClipsDescendants = true, Parent = frame })
	self.frame, self.content, self.bar = frame, content, bar

	local function barButton(x: number, glyph: string, hover: Color3, fn)
		local b = UI.new("TextButton", { Size = UDim2.fromOffset(46, Window.TITLE_H), Position = UDim2.new(1, x, 0, 0),
			BackgroundColor3 = hover, BackgroundTransparency = 1, AutoButtonColor = false, Font = UI.body, TextSize = 16,
			TextColor3 = UI.os.text, Text = glyph, Parent = bar })
		b.MouseEnter:Connect(function()
			b.BackgroundTransparency = 0
		end)
		b.MouseLeave:Connect(function()
			b.BackgroundTransparency = 1
		end)
		b.Activated:Connect(fn)
		return b
	end
	barButton(-46, "✕", Color3.fromRGB(196, 43, 28), function()
		self:close()
	end)
	self.maxButton = barButton(-92, "☐", UI.os.hover, function()
		self:toggleMax()
	end)
	barButton(-138, "—", UI.os.hover, function()
		self:setMinimized(true)
	end)

	-- snap preview shown while dragging to an edge
	local preview = UI.new("Frame", { Name = "SnapPreview", BackgroundColor3 = UI.os.accent, BackgroundTransparency = 0.75,
		Visible = false, ZIndex = 1, Parent = host })
	UI.corner(preview, 8)
	UI.new("UIStroke", { Color = UI.os.accent, Thickness = 2, Parent = preview })
	self.preview = preview

	local dragging, dragStart, startPos, snapTarget, lastClick = false, Vector2.zero, UDim2.new(), nil, 0
	local resizing, resizeStart, startSize = false, Vector2.zero, Vector2.zero
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	bar.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		self:focus()
		local now = os.clock()
		if now - lastClick < 0.35 then
			self:toggleMax()
			lastClick = 0
			return
		end
		lastClick = now
		dragging, dragStart, startPos = true, Vector2.new(input.Position.X, input.Position.Y), frame.Position
	end)
	frame.InputBegan:Connect(function(input)
		if isPress(input) then
			self:focus()
		end
	end)

	local grip = UI.new("TextButton", { Name = "Grip", Size = UDim2.fromOffset(16, 16), Position = UDim2.new(1, -16, 1, -16),
		BackgroundTransparency = 1, Text = "◢", TextColor3 = UI.os.border, TextSize = 12, Font = UI.body, ZIndex = 50,
		Visible = opts.resizable ~= false, Parent = frame })
	grip.InputBegan:Connect(function(input)
		if isPress(input) and self.mode == "normal" then
			resizing, resizeStart, startSize = true, Vector2.new(input.Position.X, input.Position.Y), self.normalSize
		end
	end)

	table.insert(self.conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local p = Vector2.new(input.Position.X, input.Position.Y)
		if resizing then
			local d = (p - resizeStart) / scale
			self.normalSize = Vector2.new(math.max(self.minSize.X, startSize.X + d.X), math.max(self.minSize.Y, startSize.Y + d.Y))
			frame.Size = UDim2.fromOffset(self.normalSize.X, self.normalSize.Y)
			return
		end
		if not dragging then
			return
		end
		local delta = p - dragStart
		if self.mode ~= "normal" then
			if delta.Magnitude < 8 then
				return
			end
			-- pull a maximized / snapped window off the edge: restore it under the cursor
			local rel = (dragStart.X - frame.AbsolutePosition.X) / math.max(frame.AbsoluteSize.X, 1)
			self.mode = "normal"
			self:applyLayout()
			local hostPos = host.AbsolutePosition
			startPos = UDim2.fromOffset(dragStart.X - hostPos.X - rel * self.normalSize.X * scale, 0)
		end
		local hostSize = host.AbsoluteSize
		local x = startPos.X.Offset + delta.X
		local y = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, hostSize.Y - 40))
		frame.Position = UDim2.fromOffset(x, y)
		local mouse = p - host.AbsolutePosition
		snapTarget = nil
		if mouse.X <= 6 then
			snapTarget = "left"
		elseif mouse.X >= hostSize.X - 6 then
			snapTarget = "right"
		elseif mouse.Y <= 4 then
			snapTarget = "max"
		end
		preview.Visible = snapTarget ~= nil
		if snapTarget == "left" then
			preview.Position, preview.Size = UDim2.fromOffset(6, 6), UDim2.new(0.5, -9, 1, -12)
		elseif snapTarget == "right" then
			preview.Position, preview.Size = UDim2.new(0.5, 3, 0, 6), UDim2.new(0.5, -9, 1, -12)
		elseif snapTarget == "max" then
			preview.Position, preview.Size = UDim2.fromOffset(6, 6), UDim2.new(1, -12, 1, -12)
		end
	end))
	table.insert(self.conns, UserInputService.InputEnded:Connect(function(input)
		if not isPress(input) then
			return
		end
		if dragging then
			dragging = false
			preview.Visible = false
			if snapTarget then
				self.mode = snapTarget
				snapTarget = nil
				self:applyLayout()
			else
				self.normalPos = frame.Position
			end
			changed()
		end
		if resizing then
			resizing = false
			changed()
		end
	end))

	live[self] = true
	self:focus()
	UI.sound("open", 0.3)
	-- open animation
	self.uiScale.Scale = scale * 0.92
	TweenService:Create(self.uiScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = scale }):Play()
	return self
end

-- place the frame for its mode; snapped / maximized windows fill part of the host whatever the UI scale is
function Window:applyLayout()
	local f = self.frame
	local inv = 1 / scale
	if self.mode == "max" then
		f.Position, f.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(inv, inv)
	elseif self.mode == "left" then
		f.Position, f.Size = UDim2.fromOffset(0, 0), UDim2.fromScale(0.5 * inv, inv)
	elseif self.mode == "right" then
		f.Position, f.Size = UDim2.fromScale(0.5, 0), UDim2.fromScale(0.5 * inv, inv)
	else
		f.Position, f.Size = self.normalPos, UDim2.fromOffset(self.normalSize.X, self.normalSize.Y)
	end
	self.maxButton.Text = self.mode == "normal" and "☐" or "❐"
	for _, c in f:GetChildren() do
		if c:IsA("UICorner") then
			c.CornerRadius = UDim.new(0, self.mode == "normal" and 8 or 0)
		end
	end
end

function Window:setTitle(text: string)
	self.title = text
	self.titleLabel.Text = text
	changed()
end

function Window:focus()
	if focused and focused ~= self and not focused.closed then
		focused.bar.BackgroundColor3 = UI.os.titleBlur
		focused.bar.Square.BackgroundColor3 = UI.os.titleBlur
		focused.stroke.Color = UI.os.border
	end
	focused = self
	topZ += 1
	self.frame.ZIndex = topZ
	self.bar.BackgroundColor3 = UI.os.title
	self.bar.Square.BackgroundColor3 = UI.os.title
	self.stroke.Color = UI.os.accent
	changed()
end

function Window:isFocused(): boolean
	return focused == self and self.frame.Visible
end

function Window:setMinimized(on: boolean)
	self.frame.Visible = not on
	if on then
		if focused == self then
			focused = nil
		end
	else
		self:focus()
	end
	changed()
end

function Window:toggleMax()
	self.mode = self.mode == "normal" and "max" or "normal"
	self:applyLayout()
	changed()
end

-- rect as fractions of the host, for the monitor mirror
function Window:rect(): (number, number, number, number)
	local h = self.host.AbsoluteSize
	local p = self.frame.AbsolutePosition - self.host.AbsolutePosition
	local s = self.frame.AbsoluteSize
	return p.X / math.max(h.X, 1), p.Y / math.max(h.Y, 1), s.X / math.max(h.X, 1), s.Y / math.max(h.Y, 1)
end

function Window:close()
	if self.closed then
		return
	end
	self.closed = true
	UI.sound("close", 0.25)
	if self.onClose then
		self.onClose()
	end
	live[self] = nil
	if focused == self then
		focused = nil
	end
	for _, conn in self.conns do
		conn:Disconnect()
	end
	self.preview:Destroy()
	self.frame:Destroy()
	changed()
end

-- chain another close handler onto a window
function Window:addCloseHandler(fn: () -> ())
	local prev = self.onClose
	self.onClose = function()
		if prev then
			prev()
		end
		fn()
	end
end

return Window
