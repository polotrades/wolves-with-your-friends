-- Custom cartoon characters, mix-and-matched from the Wolf & Co. cast. The real Roblox avatar is hidden and a
-- part-built body is welded over the (invisible) skeleton, so the character still walks and animates but looks like
-- our own characters, never a default Roblox avatar. Every region is chosen independently: head, hair, face, torso
-- (clothing), arms, hands, legs (pants), shoes, accessory, plus skin tone, colors, body type and move pack.
-- Everything is built from parts, so it works in an unpublished place with nothing to import.
local Appearance = {}

-- ---------------------------------------------------------------- option lists (all mix-and-matchable)
Appearance.SKINS = {
	Color3.fromRGB(255, 221, 189), Color3.fromRGB(241, 194, 160), Color3.fromRGB(224, 172, 138),
	Color3.fromRGB(198, 134, 100), Color3.fromRGB(161, 102, 74), Color3.fromRGB(120, 74, 55),
	Color3.fromRGB(86, 54, 42), Color3.fromRGB(255, 205, 170), Color3.fromRGB(210, 160, 120),
	Color3.fromRGB(240, 180, 210), Color3.fromRGB(170, 210, 160), Color3.fromRGB(160, 190, 235),
	Color3.fromRGB(200, 170, 230), Color3.fromRGB(150, 230, 220),
}

Appearance.HAIR_COLORS = {
	Color3.fromRGB(28, 22, 20), Color3.fromRGB(70, 45, 30), Color3.fromRGB(120, 80, 45),
	Color3.fromRGB(190, 150, 80), Color3.fromRGB(225, 215, 215), Color3.fromRGB(120, 120, 130),
	Color3.fromRGB(230, 90, 60), Color3.fromRGB(60, 110, 220), Color3.fromRGB(220, 80, 180),
	Color3.fromRGB(90, 200, 150), Color3.fromRGB(150, 90, 230), Color3.fromRGB(255, 196, 64),
	Color3.fromRGB(40, 200, 220), Color3.fromRGB(250, 250, 250),
}

-- shared clothing palette for tops and bottoms
Appearance.CLOTH_COLORS = {
	Color3.fromRGB(30, 34, 48), Color3.fromRGB(20, 20, 24), Color3.fromRGB(120, 30, 40),
	Color3.fromRGB(30, 70, 120), Color3.fromRGB(235, 235, 240), Color3.fromRGB(200, 160, 60),
	Color3.fromRGB(60, 130, 90), Color3.fromRGB(150, 70, 180), Color3.fromRGB(230, 120, 40),
	Color3.fromRGB(40, 45, 55), Color3.fromRGB(90, 60, 40), Color3.fromRGB(70, 90, 110),
	Color3.fromRGB(255, 90, 140), Color3.fromRGB(40, 180, 160),
}

Appearance.HAIR = { "bald", "short", "slick", "messy", "buzz", "long", "bun", "manbun", "spiky", "curly",
	"ponytail", "mohawk", "afro", "mullet" }
Appearance.HATS = { "none", "fedora", "beanie", "cap", "visor", "headband", "crown", "guardcap" }
Appearance.GLASSES = { "none", "square", "round", "shades", "aviators", "nerd", "monocle" }
-- torso / clothing styles, several lifted from the cast
Appearance.TORSOS = { "chairmanSuit", "cryptoHoodie", "rookieSuit", "internShirt", "guardUniform", "ceoPinstripe",
	"receptionBlazer", "plainSuit", "hoodie", "vest", "turtleneck", "tracksuit", "tank" }
Appearance.ARMS = { "sleeves", "hoodie", "bare", "muscular", "guard", "tattoo" }
Appearance.HANDS = { "bare", "fists", "gloves", "goldrings", "fingerless", "watch" }
Appearance.LEGS = { "slacks", "khakis", "jeans", "shorts", "skirt", "trackpants", "guardpants", "ripped" }
Appearance.SHOES = { "sneakers", "dress", "boots", "heels", "sandals" }
Appearance.ACCESSORY = { "none", "goldchain", "cryptochain", "tie", "bowtie", "backpack", "badge", "lanyard", "suspenders" }
Appearance.BODIES = { "average", "slim", "buff", "short", "tall", "round", "chairman" }
Appearance.GENDERS = { "neutral", "masc", "femme" }
Appearance.ANIM_PACKS = { "default", "cool", "bouncy", "robot", "zombie", "ninja" }

-- body-type scales (height, width, head, proportion)
local BODY_SCALE = {
	average = { h = 1.0, w = 1.0, head = 1.0, prop = 0.4 },
	slim = { h = 1.04, w = 0.86, head = 1.0, prop = 0.1 },
	buff = { h = 1.03, w = 1.22, head = 0.95, prop = 0.9 },
	short = { h = 0.86, w = 1.0, head = 1.1, prop = 0.3 },
	tall = { h = 1.14, w = 0.98, head = 0.95, prop = 0.5 },
	round = { h = 0.95, w = 1.2, head = 1.05, prop = 1.0 },
	chairman = { h = 1.08, w = 1.3, head = 0.95, prop = 1.0 },
}
local GENDER_SCALE = {
	neutral = { w = 1.0, prop = 0.0 },
	masc = { w = 1.06, prop = 0.3 },
	femme = { w = 0.94, prop = -0.1 },
}

-- Roblox default animation packs (real asset ids). Missing ids just fall back to the normal animation.
Appearance.ANIM_IDS = {
	cool = { idle = "rbxassetid://5319726697", walk = "rbxassetid://5319703869", run = "rbxassetid://5319703869",
		jump = "rbxassetid://5319717161", fall = "rbxassetid://5319717572" },
	robot = { idle = "rbxassetid://3334699487", walk = "rbxassetid://3334691349", run = "rbxassetid://3334691349",
		jump = "rbxassetid://3334699487", fall = "rbxassetid://3334699487" },
	zombie = { idle = "rbxassetid://3489171152", walk = "rbxassetid://3489174223", run = "rbxassetid://3489174223",
		jump = "rbxassetid://3489114820", fall = "rbxassetid://3489130079" },
	ninja = { idle = "rbxassetid://656117400", walk = "rbxassetid://656121766", run = "rbxassetid://656118852",
		jump = "rbxassetid://656116841", fall = "rbxassetid://656115606" },
	bouncy = {},
}

function Appearance.default()
	return {
		skin = 1, hair = 2, hairColor = 1, glasses = 1, hat = 1,
		torso = 8, topColor = 1, arms = 1, hands = 1, legs = 1, bottomColor = 10, shoes = 1,
		accessory = 1, body = 1, gender = 1, anim = 1,
	}
end

local function idx(value: any, list: { any }): number
	value = tonumber(value) or 1
	if value < 1 or value > #list then
		return 1
	end
	return math.floor(value)
end

function Appearance.sanitize(look: any)
	look = type(look) == "table" and look or {}
	return {
		skin = idx(look.skin, Appearance.SKINS),
		hair = idx(look.hair, Appearance.HAIR),
		hairColor = idx(look.hairColor, Appearance.HAIR_COLORS),
		glasses = idx(look.glasses, Appearance.GLASSES),
		hat = idx(look.hat, Appearance.HATS),
		torso = idx(look.torso, Appearance.TORSOS),
		topColor = idx(look.topColor, Appearance.CLOTH_COLORS),
		arms = idx(look.arms, Appearance.ARMS),
		hands = idx(look.hands, Appearance.HANDS),
		legs = idx(look.legs, Appearance.LEGS),
		bottomColor = idx(look.bottomColor, Appearance.CLOTH_COLORS),
		shoes = idx(look.shoes, Appearance.SHOES),
		accessory = idx(look.accessory, Appearance.ACCESSORY),
		body = idx(look.body, Appearance.BODIES),
		gender = idx(look.gender, Appearance.GENDERS),
		anim = idx(look.anim, Appearance.ANIM_PACKS),
	}
end

-- ---------------------------------------------------------------- part helpers
local R15 = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm",
	"RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg",
	"RightFoot" }

local function bones(char: Model)
	local b = {}
	for _, n in R15 do
		b[n] = char:FindFirstChild(n) :: BasePart?
	end
	return b
end

local function weld(to: BasePart, p: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, p
	w.Parent = p
end

-- a part welded to a bone at a local offset (custom body piece)
local function piece(folder: Instance, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3,
	material: Enum.Material?, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.CFrame = to.CFrame * offset
	p.Parent = folder
	weld(to, p)
	return p
end

-- a chunky shell sized as a multiple of a bone, so it scales with the avatar
local function shell(folder: Instance, bone: BasePart?, name: string, mult: Vector3, color: Color3, offset: CFrame?,
	material: Enum.Material?, shape: Enum.PartType?): BasePart?
	if not bone then
		return nil
	end
	local s = bone.Size
	return piece(folder, bone, name, Vector3.new(s.X * mult.X, s.Y * mult.Y, s.Z * mult.Z), offset or CFrame.new(), color,
		material, shape)
end

local DARK = Color3.fromRGB(22, 22, 28)
local WHITE = Color3.fromRGB(240, 240, 245)
local GOLD = Color3.fromRGB(230, 185, 70)

-- ---------------------------------------------------------------- head, hair, hat, glasses
local function buildHead(folder: Instance, head: BasePart, skin: Color3)
	local hs = head.Size
	-- a rounded cartoon head over the hidden real head
	shell(folder, head, "CartoonHead", Vector3.new(1.15, 1.1, 1.15), skin, CFrame.new(0, 0, 0), nil, Enum.PartType.Ball)
	-- eyes
	for _, sx in { -1, 1 } do
		local eye = piece(folder, head, "Eye", Vector3.new(hs.X * 0.22, hs.Y * 0.26, 0.1),
			CFrame.new(sx * hs.X * 0.26, hs.Y * 0.08, -hs.Z * 0.55), WHITE)
		piece(folder, head, "Pupil", Vector3.new(hs.X * 0.1, hs.Y * 0.13, 0.08),
			CFrame.new(sx * hs.X * 0.26, hs.Y * 0.08, -hs.Z * 0.6), DARK)
		local _ = eye
		piece(folder, head, "Brow", Vector3.new(hs.X * 0.26, hs.Y * 0.05, 0.06),
			CFrame.new(sx * hs.X * 0.26, hs.Y * 0.26, -hs.Z * 0.58), skin:Lerp(DARK, 0.5))
	end
	-- nose
	piece(folder, head, "Nose", Vector3.new(hs.X * 0.14, hs.Y * 0.14, hs.Z * 0.2),
		CFrame.new(0, -hs.Y * 0.02, -hs.Z * 0.62), skin:Lerp(DARK, 0.1), nil, Enum.PartType.Ball)
end

local function buildHair(folder: Instance, head: BasePart, style: string, color: Color3)
	local hs = head.Size
	local top = CFrame.new(0, hs.Y * 0.46, 0)
	local function h(name, mx, my, mz, off, shape)
		piece(folder, head, name, Vector3.new(hs.X * mx, hs.Y * my, hs.Z * mz), off, color, nil, shape)
	end
	if style == "bald" then
		return
	elseif style == "short" or style == "buzz" then
		h("Hair", 1.2, style == "buzz" and 0.35 or 0.55, 1.2, top)
	elseif style == "slick" then
		h("Hair", 1.2, 0.5, 1.2, top)
		h("SlickBack", 1.15, 0.3, 0.6, CFrame.new(0, hs.Y * 0.3, hs.Z * 0.4))
	elseif style == "messy" then
		for i = -1, 1 do
			h("Tuft", 0.5, 0.6, 0.5, top * CFrame.new(i * hs.X * 0.3, hs.Y * 0.1, 0) * CFrame.Angles(0, 0, i * 0.4),
				Enum.PartType.Ball)
		end
		h("HairBase", 1.18, 0.4, 1.18, top)
	elseif style == "long" then
		h("Hair", 1.2, 0.6, 1.2, top)
		h("HairBack", 1.1, 1.3, 0.55, CFrame.new(0, -hs.Y * 0.2, hs.Z * 0.5))
	elseif style == "bun" or style == "manbun" then
		h("Hair", 1.18, 0.5, 1.18, top)
		h("Bun", 0.6, 0.6, 0.6, CFrame.new(0, hs.Y * 0.75, hs.Z * (style == "manbun" and 0.3 or 0.1)), Enum.PartType.Ball)
	elseif style == "spiky" then
		for i = -1, 1 do
			h("Spike", 0.34, 0.8, 0.34, top * CFrame.new(i * hs.X * 0.32, hs.Y * 0.22, 0) * CFrame.Angles(0, 0, i * 0.3))
		end
		h("HairBase", 1.15, 0.3, 1.15, top)
	elseif style == "curly" then
		for _, o in { Vector3.new(0.33, 0, 0.33), Vector3.new(-0.33, 0, 0.33), Vector3.new(0.33, 0, -0.33),
			Vector3.new(-0.33, 0, -0.33), Vector3.new(0, 0.12, 0) } do
			h("Curl", 0.6, 0.6, 0.6, top * CFrame.new(o.X * hs.X, o.Y * hs.Y, o.Z * hs.Z), Enum.PartType.Ball)
		end
	elseif style == "ponytail" then
		h("Hair", 1.15, 0.5, 1.15, top)
		h("Tail", 0.38, 1.3, 0.38, CFrame.new(0, hs.Y * 0.1, hs.Z * 0.55) * CFrame.Angles(math.rad(18), 0, 0))
	elseif style == "mohawk" then
		h("Mohawk", 0.22, 0.8, 1.05, top * CFrame.new(0, hs.Y * 0.22, 0))
	elseif style == "afro" then
		h("Afro", 1.6, 1.4, 1.6, top * CFrame.new(0, hs.Y * 0.18, 0), Enum.PartType.Ball)
	elseif style == "mullet" then
		h("Hair", 1.18, 0.5, 1.18, top)
		h("Mullet", 1.1, 0.5, 0.5, CFrame.new(0, -hs.Y * 0.05, hs.Z * 0.52))
	end
end

local function buildHat(folder: Instance, head: BasePart, style: string)
	local hs = head.Size
	local top = CFrame.new(0, hs.Y * 0.6, 0)
	local function h(name, mx, my, mz, off, color, material)
		piece(folder, head, name, Vector3.new(hs.X * mx, hs.Y * my, hs.Z * mz), off, color, material)
	end
	if style == "fedora" then
		h("Brim", 1.8, 0.1, 1.8, top, DARK)
		h("Crown", 1.05, 0.6, 1.05, top * CFrame.new(0, hs.Y * 0.3, 0), DARK)
		h("Band", 1.08, 0.14, 1.08, top * CFrame.new(0, hs.Y * 0.12, 0), GOLD)
	elseif style == "beanie" then
		h("Beanie", 1.25, 0.6, 1.25, top, Color3.fromRGB(180, 60, 70))
	elseif style == "cap" then
		h("Cap", 1.2, 0.5, 1.2, top, Color3.fromRGB(30, 60, 140))
		h("Brim", 1.1, 0.1, 0.8, top * CFrame.new(0, -hs.Y * 0.15, -hs.Z * 0.7), Color3.fromRGB(30, 60, 140))
	elseif style == "guardcap" then
		h("Cap", 1.22, 0.45, 1.22, top, DARK)
		h("Brim", 1.1, 0.1, 0.85, top * CFrame.new(0, -hs.Y * 0.15, -hs.Z * 0.72), DARK)
		h("Badge", 0.3, 0.3, 0.1, top * CFrame.new(0, hs.Y * 0.05, -hs.Z * 0.6), GOLD, Enum.Material.Metal)
	elseif style == "visor" then
		h("VisorBand", 1.25, 0.2, 1.25, CFrame.new(0, hs.Y * 0.35, 0), Color3.fromRGB(240, 220, 60))
		h("Brim", 1.15, 0.08, 0.85, CFrame.new(0, hs.Y * 0.35, -hs.Z * 0.7), Color3.fromRGB(240, 220, 60))
	elseif style == "headband" then
		h("Headband", 1.25, 0.18, 1.25, CFrame.new(0, hs.Y * 0.3, 0), Color3.fromRGB(220, 50, 60))
	elseif style == "crown" then
		h("Crown", 1.15, 0.4, 1.15, top, GOLD, Enum.Material.Metal)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			piece(folder, head, "Spire", Vector3.new(hs.X * 0.15, hs.Y * 0.35, hs.Z * 0.15),
				top * CFrame.new(math.cos(a) * hs.X * 0.5, hs.Y * 0.3, math.sin(a) * hs.Z * 0.5), GOLD, Enum.Material.Metal)
		end
	end
end

local function buildGlasses(folder: Instance, head: BasePart, style: string)
	if style == "none" then
		return
	end
	local hs = head.Size
	local front = CFrame.new(0, hs.Y * 0.08, -hs.Z * 0.62)
	if style == "square" or style == "round" or style == "nerd" then
		local col = style == "nerd" and Color3.fromRGB(40, 30, 25) or DARK
		for _, sx in { -1, 1 } do
			local lens = piece(folder, head, "Lens", Vector3.new(hs.X * 0.34, hs.Y * 0.3, 0.06),
				front * CFrame.new(sx * hs.X * 0.26, 0, 0), style == "nerd" and WHITE or col)
			if style == "round" then
				lens.Shape = Enum.PartType.Cylinder
				lens.Size = Vector3.new(0.06, hs.X * 0.34, hs.Y * 0.32)
				lens.CFrame = head.CFrame * front * CFrame.new(sx * hs.X * 0.26, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
		piece(folder, head, "Bridge", Vector3.new(hs.X * 0.18, 0.05, 0.05), front, col)
	elseif style == "shades" then
		piece(folder, head, "Shades", Vector3.new(hs.X * 0.98, hs.Y * 0.3, 0.08), front, DARK, Enum.Material.Glass)
	elseif style == "aviators" then
		for _, sx in { -1, 1 } do
			local l = piece(folder, head, "Aviator", Vector3.new(0.06, hs.X * 0.36, hs.Y * 0.32),
				front * CFrame.new(sx * hs.X * 0.26, -hs.Y * 0.02, 0) * CFrame.Angles(0, math.rad(90), 0),
				Color3.fromRGB(120, 90, 40), Enum.Material.Glass)
			l.Shape = Enum.PartType.Cylinder
		end
		piece(folder, head, "Bridge", Vector3.new(hs.X * 0.2, 0.05, 0.05), front, GOLD, Enum.Material.Metal)
	elseif style == "monocle" then
		local lens = piece(folder, head, "Monocle", Vector3.new(0.06, hs.X * 0.34, hs.Y * 0.34),
			front * CFrame.new(hs.X * 0.26, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(200, 230, 240),
			Enum.Material.Glass)
		lens.Shape = Enum.PartType.Cylinder
	end
end

-- ---------------------------------------------------------------- torso (clothing)
local function buildTorso(folder: Instance, b, style: string, color: Color3, skin: Color3)
	local u = b.UpperTorso
	if not u then
		return
	end
	-- a cartoon torso shell covering upper + lower torso
	local body = shell(folder, u, "Torso", Vector3.new(1.35, 1.25, 1.3), color, CFrame.new(0, -u.Size.Y * 0.35, 0))
	shell(folder, b.LowerTorso, "Waist", Vector3.new(1.3, 1.2, 1.25), color, CFrame.new())
	local ts = u.Size
	local accent = color:Lerp(DARK, 0.35)
	if style == "chairmanSuit" then
		shell(folder, u, "SuitBulk", Vector3.new(1.5, 1.3, 1.4), GOLD, CFrame.new(0, -ts.Y * 0.2, 0))
		for _, sx in { -1, 1 } do
			piece(folder, u, "Lapel", Vector3.new(ts.X * 0.4, ts.Y * 1.1, 0.1), CFrame.new(sx * ts.X * 0.3, 0, -ts.Z * 0.62)
				* CFrame.Angles(0, 0, sx * 0.2), Color3.fromRGB(200, 155, 50))
		end
		piece(folder, u, "Shirt", Vector3.new(ts.X * 0.4, ts.Y * 1.1, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), WHITE)
		piece(folder, u, "Tie", Vector3.new(ts.X * 0.16, ts.Y * 1.0, 0.07), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.64),
			Color3.fromRGB(150, 30, 40))
		local _ = body
	elseif style == "cryptoHoodie" or style == "hoodie" then
		shell(folder, u, "Hood", Vector3.new(1.3, 0.5, 1.3), accent, CFrame.new(0, ts.Y * 0.55, ts.Z * 0.2))
		piece(folder, u, "Pocket", Vector3.new(ts.X * 0.9, ts.Y * 0.5, 0.08), CFrame.new(0, -ts.Y * 0.3, -ts.Z * 0.62), accent)
		piece(folder, u, "Zip", Vector3.new(0.05, ts.Y * 1.1, 0.06), CFrame.new(0, 0, -ts.Z * 0.64), WHITE)
	elseif style == "rookieSuit" or style == "plainSuit" or style == "ceoPinstripe" or style == "receptionBlazer" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Lapel", Vector3.new(ts.X * 0.34, ts.Y * 1.0, 0.09), CFrame.new(sx * ts.X * 0.28, 0, -ts.Z * 0.62)
				* CFrame.Angles(0, 0, sx * 0.22), accent)
		end
		piece(folder, u, "Shirt", Vector3.new(ts.X * 0.4, ts.Y * 1.0, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), WHITE)
		piece(folder, u, "Tie", Vector3.new(ts.X * 0.14, ts.Y * 0.9, 0.06), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.64),
			style == "receptionBlazer" and Color3.fromRGB(180, 60, 120) or Color3.fromRGB(60, 80, 160))
		if style == "ceoPinstripe" then
			for i = -2, 2 do
				piece(folder, u, "Stripe", Vector3.new(0.03, ts.Y * 1.2, 0.04), CFrame.new(i * ts.X * 0.2, 0, -ts.Z * 0.66), WHITE)
			end
		end
	elseif style == "internShirt" then
		piece(folder, u, "Collar", Vector3.new(ts.X * 0.7, ts.Y * 0.2, 0.08), CFrame.new(0, ts.Y * 0.45, -ts.Z * 0.5), WHITE)
		piece(folder, u, "Tie", Vector3.new(ts.X * 0.14, ts.Y * 0.9, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.64),
			Color3.fromRGB(40, 130, 60))
		piece(folder, u, "Pen", Vector3.new(0.05, ts.Y * 0.3, 0.05), CFrame.new(ts.X * 0.3, ts.Y * 0.2, -ts.Z * 0.64), WHITE)
	elseif style == "guardUniform" then
		shell(folder, u, "Vest", Vector3.new(1.42, 1.0, 1.36), DARK, CFrame.new(0, -ts.Y * 0.1, 0))
		piece(folder, u, "Badge", Vector3.new(ts.X * 0.2, ts.Y * 0.2, 0.06), CFrame.new(-ts.X * 0.3, ts.Y * 0.25, -ts.Z * 0.64),
			GOLD, Enum.Material.Metal)
		piece(folder, u, "Belt", Vector3.new(ts.X * 1.3, ts.Y * 0.18, ts.Z * 1.2), CFrame.new(0, -ts.Y * 0.5, 0), DARK)
	elseif style == "turtleneck" then
		piece(folder, u, "Collar", Vector3.new(ts.X * 0.7, ts.Y * 0.3, ts.Z * 0.9), CFrame.new(0, ts.Y * 0.5, 0), color)
	elseif style == "tracksuit" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Stripe", Vector3.new(0.08, ts.Y * 1.3, ts.Z * 1.0), CFrame.new(sx * ts.X * 0.5, 0, 0), WHITE)
		end
	elseif style == "vest" or style == "tank" then
		shell(folder, u, "Tank", Vector3.new(1.3, 1.2, 1.28), color, CFrame.new(0, -u.Size.Y * 0.3, 0))
	end
end

-- ---------------------------------------------------------------- arms
local function buildArms(folder: Instance, b, style: string, color: Color3, skin: Color3)
	local sleeve = style == "sleeves" and color or style == "hoodie" and color:Lerp(DARK, 0.2)
		or style == "guard" and DARK or skin
	for _, side in { "Left", "Right" } do
		local up = b[side .. "UpperArm"]
		local lo = b[side .. "LowerArm"]
		if up then
			shell(folder, up, "Sleeve", Vector3.new(1.3, 1.05, 1.3), (style == "muscular") and skin or sleeve)
		end
		if lo then
			local lowerColor = (style == "sleeves" or style == "hoodie" or style == "guard") and sleeve or skin
			shell(folder, lo, "Forearm", Vector3.new(1.25, 1.05, 1.25), lowerColor)
			if style == "tattoo" then
				piece(folder, lo, "Tattoo", Vector3.new(lo.Size.X * 1.3, lo.Size.Y * 0.4, 0.04),
					CFrame.new(0, 0, -lo.Size.Z * 0.6), Color3.fromRGB(40, 60, 120))
			end
			if style == "muscular" then
				shell(folder, up, "Bicep", Vector3.new(1.5, 0.6, 1.5), skin, CFrame.new(0, up.Size.Y * 0.1, 0),
					nil, Enum.PartType.Ball)
			end
		end
	end
end

-- ---------------------------------------------------------------- hands
local function buildHands(folder: Instance, b, style: string, skin: Color3)
	local glove = style == "gloves" and DARK or style == "fingerless" and DARK or skin
	for _, side in { "Left", "Right" } do
		local hand = b[side .. "Hand"]
		if hand then
			shell(folder, hand, "Hand", Vector3.new(1.3, 1.2, 1.3), glove, nil, nil, Enum.PartType.Ball)
			if style == "goldrings" then
				for i = -1, 1 do
					piece(folder, hand, "Ring", Vector3.new(hand.Size.X * 0.4, hand.Size.Y * 0.2, hand.Size.Z * 0.4),
						CFrame.new(i * hand.Size.X * 0.25, -hand.Size.Y * 0.3, 0), GOLD, Enum.Material.Metal)
				end
			elseif style == "fingerless" then
				shell(folder, hand, "Knuckle", Vector3.new(1.1, 0.5, 1.1), skin, CFrame.new(0, -hand.Size.Y * 0.3, 0))
			elseif style == "watch" and side == "Left" then
				piece(folder, hand, "Watch", Vector3.new(hand.Size.X * 0.5, hand.Size.Y * 0.3, hand.Size.Z * 1.1),
					CFrame.new(0, hand.Size.Y * 0.4, 0), GOLD, Enum.Material.Metal)
			end
		end
	end
end

-- ---------------------------------------------------------------- legs (pants) + shoes
local function buildLegs(folder: Instance, b, style: string, color: Color3, skin: Color3)
	local short = style == "shorts" or style == "skirt"
	for _, side in { "Left", "Right" } do
		local up = b[side .. "UpperLeg"]
		local lo = b[side .. "LowerLeg"]
		if up then
			shell(folder, up, "Thigh", Vector3.new(1.3, 1.05, 1.3), color)
		end
		if lo then
			shell(folder, lo, "Shin", Vector3.new(1.25, 1.05, 1.25), short and skin or color)
			if style == "trackpants" then
				piece(folder, lo, "Stripe", Vector3.new(0.05, lo.Size.Y, lo.Size.Z * 0.9), CFrame.new(lo.Size.X * 0.55, 0, 0), WHITE)
			elseif style == "ripped" then
				piece(folder, lo, "Rip", Vector3.new(lo.Size.X * 0.9, lo.Size.Y * 0.2, 0.04), CFrame.new(0, 0, -lo.Size.Z * 0.6), skin)
			elseif style == "guardpants" then
				piece(folder, lo, "GuardStripe", Vector3.new(0.06, lo.Size.Y, lo.Size.Z * 0.9), CFrame.new(lo.Size.X * 0.55, 0, 0), GOLD)
			end
		end
	end
	if style == "skirt" then
		local waist = b.LowerTorso
		if waist then
			shell(folder, waist, "Skirt", Vector3.new(1.7, 1.4, 1.7), color, CFrame.new(0, -waist.Size.Y * 0.8, 0))
		end
	end
end

local function buildShoes(folder: Instance, b, style: string)
	local col = ({ sneakers = WHITE, dress = DARK, boots = Color3.fromRGB(60, 40, 25), heels = Color3.fromRGB(150, 30, 50),
		sandals = Color3.fromRGB(120, 90, 60) })[style] or WHITE
	for _, side in { "Left", "Right" } do
		local foot = b[side .. "Foot"]
		if foot then
			shell(folder, foot, "Shoe", Vector3.new(1.3, 1.3, 1.45), col, CFrame.new(0, 0, -foot.Size.Z * 0.1))
			if style == "heels" then
				piece(folder, foot, "Heel", Vector3.new(foot.Size.X * 0.3, foot.Size.Y * 1.2, foot.Size.Z * 0.3),
					CFrame.new(0, -foot.Size.Y * 0.6, foot.Size.Z * 0.5), col)
			elseif style == "boots" then
				local sh = b[side .. "LowerLeg"]
				shell(folder, sh, "BootTop", Vector3.new(1.3, 0.7, 1.3), col, CFrame.new(0, -sh and 0 or 0, 0))
			end
		end
	end
end

-- ---------------------------------------------------------------- accessories
local function buildAccessory(folder: Instance, b, style: string)
	local u = b.UpperTorso
	if not u or style == "none" then
		return
	end
	local ts = u.Size
	if style == "goldchain" or style == "cryptochain" then
		local col = style == "cryptochain" and Color3.fromRGB(210, 210, 220) or GOLD
		piece(folder, u, "Chain", Vector3.new(ts.X * 0.7, ts.Y * 0.1, 0.08), CFrame.new(0, ts.Y * 0.3, -ts.Z * 0.6), col,
			Enum.Material.Metal)
		piece(folder, u, "Pendant", Vector3.new(ts.X * 0.2, ts.Y * 0.25, 0.1), CFrame.new(0, ts.Y * 0.1, -ts.Z * 0.64), col,
			Enum.Material.Metal)
	elseif style == "tie" then
		piece(folder, u, "Tie", Vector3.new(ts.X * 0.16, ts.Y * 1.0, 0.07), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.64),
			Color3.fromRGB(150, 30, 40))
	elseif style == "bowtie" then
		piece(folder, u, "Bowtie", Vector3.new(ts.X * 0.4, ts.Y * 0.18, 0.08), CFrame.new(0, ts.Y * 0.35, -ts.Z * 0.62),
			Color3.fromRGB(150, 30, 40))
	elseif style == "backpack" then
		shell(folder, u, "Backpack", Vector3.new(1.1, 1.0, 0.6), Color3.fromRGB(230, 120, 40), CFrame.new(0, 0, ts.Z * 0.7))
		for _, sx in { -1, 1 } do
			piece(folder, u, "Strap", Vector3.new(0.1, ts.Y * 1.0, 0.06), CFrame.new(sx * ts.X * 0.3, 0, -ts.Z * 0.55),
				Color3.fromRGB(150, 80, 30))
		end
	elseif style == "badge" then
		piece(folder, u, "Badge", Vector3.new(ts.X * 0.25, ts.Y * 0.2, 0.06), CFrame.new(-ts.X * 0.3, ts.Y * 0.2, -ts.Z * 0.64),
			GOLD, Enum.Material.Metal)
	elseif style == "lanyard" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Lanyard", Vector3.new(0.05, ts.Y * 0.8, 0.05), CFrame.new(sx * ts.X * 0.2, ts.Y * 0.1, -ts.Z * 0.6),
				Color3.fromRGB(40, 60, 160))
		end
		piece(folder, u, "IDCard", Vector3.new(ts.X * 0.25, ts.Y * 0.3, 0.04), CFrame.new(0, -ts.Y * 0.25, -ts.Z * 0.63), WHITE)
	elseif style == "suspenders" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Suspender", Vector3.new(0.08, ts.Y * 1.1, 0.05), CFrame.new(sx * ts.X * 0.3, 0, -ts.Z * 0.6), DARK)
		end
	end
end

-- ---------------------------------------------------------------- scale
function Appearance.applyScale(char: Model, look)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local b = BODY_SCALE[Appearance.BODIES[look.body]] or BODY_SCALE.average
	local g = GENDER_SCALE[Appearance.GENDERS[look.gender]] or GENDER_SCALE.neutral
	local function set(name: string, value: number)
		local v = hum:FindFirstChild(name) :: NumberValue?
		if v then
			v.Value = value
		end
	end
	set("BodyHeightScale", b.h)
	set("BodyWidthScale", b.w * g.w)
	set("BodyDepthScale", b.w * g.w)
	set("HeadScale", b.head)
	set("BodyProportionScale", math.clamp(b.prop + g.prop, 0, 1))
	set("BodyTypeScale", math.clamp(b.prop + g.prop, 0, 1))
end

-- ---------------------------------------------------------------- main entry
function Appearance.apply(char: Model, look)
	look = Appearance.sanitize(look)
	local b = bones(char)
	local old = char:FindFirstChild("LookExtras")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "LookExtras"
	folder.Parent = char
	-- hide the default Roblox avatar; our custom body shows instead
	for _, n in R15 do
		local part = b[n]
		if part then
			part.Transparency = 1
			local face = part:FindFirstChildOfClass("Decal")
			if face then
				face.Transparency = 1
			end
		end
	end
	for _, d in char:GetChildren() do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		end
	end
	local skin = Appearance.SKINS[look.skin]
	local topC = Appearance.CLOTH_COLORS[look.topColor]
	local botC = Appearance.CLOTH_COLORS[look.bottomColor]
	if b.Head then
		buildHead(folder, b.Head, skin)
		buildHair(folder, b.Head, Appearance.HAIR[look.hair], Appearance.HAIR_COLORS[look.hairColor])
		buildHat(folder, b.Head, Appearance.HATS[look.hat])
		buildGlasses(folder, b.Head, Appearance.GLASSES[look.glasses])
	end
	buildTorso(folder, b, Appearance.TORSOS[look.torso], topC, skin)
	buildArms(folder, b, Appearance.ARMS[look.arms], topC, skin)
	buildHands(folder, b, Appearance.HANDS[look.hands], skin)
	buildLegs(folder, b, Appearance.LEGS[look.legs], botC, skin)
	buildShoes(folder, b, Appearance.SHOES[look.shoes])
	buildAccessory(folder, b, Appearance.ACCESSORY[look.accessory])
	Appearance.applyScale(char, look)
end

-- A headset (band + earcups + boom mic) and a mouth, welded to the head. Mouth is animated by TalkingMouths.
function Appearance.addGear(char: Model)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local old = char:FindFirstChild("Gear")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Gear"
	folder.Parent = char
	local hs = head.Size
	local function part(name, size, offset, color, shape)
		local p = Instance.new("Part")
		p.Name = name
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.CFrame = head.CFrame * offset
		p.Parent = folder
		weld(head, p)
		return p
	end
	local dark = Color3.fromRGB(28, 28, 32)
	part("HeadsetBand", Vector3.new(hs.X * 1.3, hs.Y * 0.2, hs.Z * 0.35), CFrame.new(0, hs.Y * 0.6, 0), dark)
	for _, sx in { -1, 1 } do
		part("Earcup", Vector3.new(hs.X * 0.22, hs.Y * 0.45, hs.Z * 0.55), CFrame.new(sx * hs.X * 0.62, hs.Y * 0.05, 0), dark)
	end
	part("MicBoom", Vector3.new(0.08, 0.08, hs.Z * 0.75), CFrame.new(-hs.X * 0.55, -hs.Y * 0.15, -hs.Z * 0.4)
		* CFrame.Angles(math.rad(20), math.rad(30), 0), dark)
	part("MicTip", Vector3.new(0.16, 0.16, 0.16), CFrame.new(-hs.X * 0.18, -hs.Y * 0.3, -hs.Z * 0.6),
		Color3.fromRGB(60, 60, 70), Enum.PartType.Ball)
	local mouth = part("Mouth", Vector3.new(hs.X * 0.3, hs.Y * 0.06, 0.06), CFrame.new(0, -hs.Y * 0.24, -hs.Z * 0.6),
		Color3.fromRGB(90, 40, 45))
	mouth:SetAttribute("BaseY", mouth.Size.Y)
	return mouth
end

return Appearance
