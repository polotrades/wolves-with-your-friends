-- Cartoon caller portraits drawn from frames: shoulders in the caller's color, a head in their skin tone, hair
-- (by style), eyes, brows and a mouth that can flap while they talk.
local UI = require(script.Parent:WaitForChild("UI"))

local Avatar = {}

local function round(f: GuiObject, r: number?)
	UI.new("UICorner", { CornerRadius = UDim.new(r or 0.5, 0), Parent = f })
	return f
end

local function part(parent: Instance, x: number, y: number, w: number, h: number, color: Color3, props)
	local f = UI.new("Frame", { Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(w, h), BackgroundColor3 = color,
		BorderSizePixel = 0, Parent = parent })
	for k, v in props or {} do
		(f :: any)[k] = v
	end
	return f
end

-- look = { skin, hair, style }, shirt = Color3. Returns the mouth frame (Size.Y can be animated).
function Avatar.draw(parent: GuiObject, look, shirt: Color3): Frame
	local bg = part(parent, 0, 0, 1, 1, Color3.fromRGB(220, 230, 245), { Name = "Avatar", ClipsDescendants = true })
	round(bg)
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(235, 242, 255), Color3.fromRGB(170, 190, 225)),
		Parent = bg })
	-- shoulders
	round(part(bg, 0.12, 0.74, 0.76, 0.5, shirt), 0.4)
	part(bg, 0.42, 0.72, 0.16, 0.1, look.skin) -- neck
	local style = look.style
	-- long hair sits behind the head
	if style == "long" then
		round(part(bg, 0.22, 0.2, 0.56, 0.62, look.hair), 0.35)
	end
	local head = round(part(bg, 0.27, 0.2, 0.46, 0.54, look.skin), 0.48)
	-- ears
	round(part(bg, 0.23, 0.42, 0.07, 0.12, look.skin))
	round(part(bg, 0.7, 0.42, 0.07, 0.12, look.skin))
	head.ZIndex += 1
	local z = head.ZIndex + 1
	local function onHead(x, y, w, h, color, r)
		local f = part(head, x, y, w, h, color, { ZIndex = z })
		if r then
			round(f, r)
		end
		return f
	end
	-- hair on top
	if style == "short" or style == "long" or style == "curly" or style == "bun" then
		onHead(-0.02, -0.04, 1.04, 0.3, look.hair, 0.4)
	end
	if style == "curly" then
		for i = 0, 4 do
			onHead(-0.08 + i * 0.24, -0.1, 0.3, 0.26, look.hair, 0.5)
		end
	elseif style == "bun" then
		onHead(0.32, -0.28, 0.36, 0.3, look.hair, 0.5)
	elseif style == "spiky" then
		for i = 0, 4 do
			onHead(0.02 + i * 0.2, -0.14, 0.16, 0.3, look.hair, 0.2).Rotation = (i - 2) * 12
		end
		onHead(0, -0.02, 1, 0.2, look.hair, 0.4)
	elseif style == "bald" then
		onHead(-0.04, 0.3, 0.14, 0.2, look.hair, 0.5)
		onHead(0.9, 0.3, 0.14, 0.2, look.hair, 0.5)
	elseif style == "cap" then
		onHead(-0.04, -0.06, 1.08, 0.3, look.hair:Lerp(Color3.fromRGB(200, 40, 40), 0.7), 0.4)
		onHead(0.45, 0.16, 0.7, 0.08, look.hair:Lerp(Color3.fromRGB(150, 30, 30), 0.7), 0.4)
	elseif style == "hat" then
		local hatColor = look.hair:Lerp(Color3.fromRGB(60, 40, 30), 0.6)
		onHead(-0.25, 0.08, 1.5, 0.1, hatColor, 0.4)
		onHead(0.08, -0.3, 0.84, 0.42, hatColor, 0.2)
	end
	-- face
	for _, x in { 0.24, 0.6 } do
		local eye = onHead(x, 0.4, 0.16, 0.15, Color3.new(1, 1, 1), 0.5)
		local pupil = part(eye, 0.3, 0.3, 0.45, 0.5, Color3.fromRGB(25, 25, 35), { ZIndex = z + 1 })
		round(pupil)
		onHead(x - 0.02, 0.32, 0.2, 0.04, look.hair:Lerp(Color3.new(0, 0, 0), 0.4), 0.5)
	end
	onHead(0.46, 0.55, 0.08, 0.1, look.skin:Lerp(Color3.new(0, 0, 0), 0.15), 0.5) -- nose
	local mouth = onHead(0.36, 0.72, 0.28, 0.06, Color3.fromRGB(120, 30, 40), 0.5)
	mouth.Name = "Mouth"
	return mouth
end

return Avatar
