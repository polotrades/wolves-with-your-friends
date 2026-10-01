-- Character looks shared by the customizer preview and the server that dresses your real character, so what you see
-- in the menu is what you spawn as. Everything is built from parts (no external catalog assets), so it works in an
-- unpublished place. A "look" is a small table of option ids; Appearance.apply(character, look) dresses an R15 rig.
local Appearance = {}

Appearance.SKINS = {
	Color3.fromRGB(255, 221, 189), Color3.fromRGB(241, 194, 160), Color3.fromRGB(224, 172, 138),
	Color3.fromRGB(198, 134, 100), Color3.fromRGB(161, 102, 74), Color3.fromRGB(120, 74, 55),
	Color3.fromRGB(86, 54, 42), Color3.fromRGB(240, 180, 210), Color3.fromRGB(170, 200, 160),
	Color3.fromRGB(170, 180, 230),
}

Appearance.HAIR_COLORS = {
	Color3.fromRGB(28, 22, 20), Color3.fromRGB(70, 45, 30), Color3.fromRGB(120, 80, 45),
	Color3.fromRGB(190, 150, 80), Color3.fromRGB(225, 215, 215), Color3.fromRGB(230, 90, 60),
	Color3.fromRGB(60, 110, 220), Color3.fromRGB(220, 80, 180), Color3.fromRGB(90, 200, 150),
	Color3.fromRGB(150, 90, 230),
}

Appearance.OUTFIT_COLORS = {
	Color3.fromRGB(30, 34, 48), Color3.fromRGB(20, 20, 24), Color3.fromRGB(120, 30, 40),
	Color3.fromRGB(30, 70, 120), Color3.fromRGB(230, 230, 235), Color3.fromRGB(200, 160, 60),
	Color3.fromRGB(60, 130, 90), Color3.fromRGB(150, 70, 180),
}

-- hair styles: bald, short, long, bun, spiky, curly, ponytail, mohawk, cap, afro
Appearance.HAIR = { "bald", "short", "long", "bun", "spiky", "curly", "ponytail", "mohawk", "afro", "cap" }
-- head accessories
Appearance.HATS = { "none", "fedora", "beanie", "cap", "visor", "headband", "crown" }
Appearance.GLASSES = { "none", "square", "round", "shades", "monocle" }
Appearance.OUTFITS = { "suit", "dress", "hoodie", "vest", "turtleneck", "tracksuit" }
Appearance.BODIES = { "average", "slim", "buff", "short", "tall", "round" }
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
	bouncy = {}, -- handled with a jump-power tweak instead of asset ids
}

function Appearance.default()
	return {
		skin = 1, hair = 2, hairColor = 1, hat = 1, glasses = 1, outfit = 1, outfitColor = 1,
		body = 1, gender = 1, anim = 1,
	}
end

-- clamp a look's indices so a bad client payload can't error the server
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
		hat = idx(look.hat, Appearance.HATS),
		glasses = idx(look.glasses, Appearance.GLASSES),
		outfit = idx(look.outfit, Appearance.OUTFITS),
		outfitColor = idx(look.outfitColor, Appearance.OUTFIT_COLORS),
		body = idx(look.body, Appearance.BODIES),
		gender = idx(look.gender, Appearance.GENDERS),
		anim = idx(look.anim, Appearance.ANIM_PACKS),
	}
end

-- find the R15 parts we dress
local function parts(char: Model)
	local function f(name: string): BasePart?
		return char:FindFirstChild(name) :: BasePart?
	end
	return {
		head = f("Head"),
		torsoU = f("UpperTorso"),
		torsoL = f("LowerTorso"),
		armsU = { f("LeftUpperArm"), f("RightUpperArm") },
		armsL = { f("LeftLowerArm"), f("RightLowerArm") },
		legsU = { f("LeftUpperLeg"), f("RightUpperLeg") },
		legsL = { f("LeftLowerLeg"), f("RightLowerLeg") },
		handL = f("LeftHand"),
		handR = f("RightHand"),
	}
end

local function weld(to: BasePart, p: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = to, p
	w.Parent = p
end

-- a decorative part welded onto a body part at a local offset
local function piece(parent: Instance, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3,
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
	p.Parent = parent
	weld(to, p)
	return p
end

local function buildHair(folder: Instance, head: BasePart, style: string, color: Color3)
	local hs = head.Size
	local top = CFrame.new(0, hs.Y * 0.42, 0)
	if style == "bald" then
		return
	elseif style == "short" then
		piece(folder, head, "Hair", hs * Vector3.new(1.06, 0.5, 1.06), top, color)
	elseif style == "long" then
		piece(folder, head, "Hair", hs * Vector3.new(1.08, 0.6, 1.08), top, color)
		piece(folder, head, "HairBack", hs * Vector3.new(1.02, 1.1, 0.5), CFrame.new(0, -hs.Y * 0.1, hs.Z * 0.42), color)
	elseif style == "bun" then
		piece(folder, head, "Hair", hs * Vector3.new(1.05, 0.5, 1.05), top, color)
		piece(folder, head, "Bun", Vector3.new(hs.X * 0.6, hs.Y * 0.6, hs.Z * 0.6), CFrame.new(0, hs.Y * 0.7, hs.Z * 0.2), color,
			nil, Enum.PartType.Ball)
	elseif style == "spiky" then
		for i = -1, 1 do
			piece(folder, head, "Spike", Vector3.new(hs.X * 0.3, hs.Y * 0.7, hs.Z * 0.3),
				top * CFrame.new(i * hs.X * 0.3, hs.Y * 0.2, 0) * CFrame.Angles(0, 0, i * 0.3), color)
		end
		piece(folder, head, "HairBase", hs * Vector3.new(1.05, 0.3, 1.05), top, color)
	elseif style == "curly" then
		for _, o in { Vector3.new(0.3, 0, 0.3), Vector3.new(-0.3, 0, 0.3), Vector3.new(0.3, 0, -0.3),
			Vector3.new(-0.3, 0, -0.3), Vector3.new(0, 0.1, 0) } do
			piece(folder, head, "Curl", Vector3.new(hs.X * 0.55, hs.Y * 0.55, hs.Z * 0.55),
				top * CFrame.new(o.X * hs.X, o.Y * hs.Y, o.Z * hs.Z), color, nil, Enum.PartType.Ball)
		end
	elseif style == "ponytail" then
		piece(folder, head, "Hair", hs * Vector3.new(1.05, 0.5, 1.05), top, color)
		piece(folder, head, "Tail", Vector3.new(hs.X * 0.35, hs.Y * 1.2, hs.Z * 0.35),
			CFrame.new(0, 0, hs.Z * 0.5) * CFrame.Angles(math.rad(20), 0, 0), color)
	elseif style == "mohawk" then
		piece(folder, head, "Mohawk", Vector3.new(hs.X * 0.2, hs.Y * 0.7, hs.Z * 1.0), top * CFrame.new(0, hs.Y * 0.2, 0), color)
	elseif style == "afro" then
		piece(folder, head, "Afro", hs * Vector3.new(1.5, 1.3, 1.5), top * CFrame.new(0, hs.Y * 0.15, 0), color, nil,
			Enum.PartType.Ball)
	elseif style == "cap" then
		piece(folder, head, "Cap", hs * Vector3.new(1.08, 0.45, 1.08), top, color)
		piece(folder, head, "CapBrim", Vector3.new(hs.X * 1.0, hs.Y * 0.1, hs.Z * 0.7),
			CFrame.new(0, hs.Y * 0.28, -hs.Z * 0.6), color)
	end
end

local function buildHat(folder: Instance, head: BasePart, style: string)
	local hs = head.Size
	local top = CFrame.new(0, hs.Y * 0.55, 0)
	if style == "fedora" then
		piece(folder, head, "Brim", Vector3.new(hs.X * 1.7, hs.Y * 0.1, hs.Z * 1.7), top, Color3.fromRGB(40, 30, 25))
		piece(folder, head, "Crown", Vector3.new(hs.X * 1.0, hs.Y * 0.6, hs.Z * 1.0), top * CFrame.new(0, hs.Y * 0.3, 0),
			Color3.fromRGB(40, 30, 25))
		piece(folder, head, "Band", Vector3.new(hs.X * 1.02, hs.Y * 0.12, hs.Z * 1.02), top * CFrame.new(0, hs.Y * 0.12, 0),
			Color3.fromRGB(200, 160, 60))
	elseif style == "beanie" then
		piece(folder, head, "Beanie", hs * Vector3.new(1.12, 0.6, 1.12), top, Color3.fromRGB(180, 60, 70))
	elseif style == "cap" then
		piece(folder, head, "Cap", hs * Vector3.new(1.1, 0.5, 1.1), top, Color3.fromRGB(30, 60, 140))
		piece(folder, head, "Brim", Vector3.new(hs.X * 1.0, hs.Y * 0.1, hs.Z * 0.8), top * CFrame.new(0, -hs.Y * 0.15, -hs.Z * 0.7),
			Color3.fromRGB(30, 60, 140))
	elseif style == "visor" then
		piece(folder, head, "VisorBand", hs * Vector3.new(1.12, 0.2, 1.12), top * CFrame.new(0, -hs.Y * 0.2, 0),
			Color3.fromRGB(240, 220, 60))
		piece(folder, head, "Brim", Vector3.new(hs.X * 1.1, hs.Y * 0.08, hs.Z * 0.8), top * CFrame.new(0, -hs.Y * 0.2, -hs.Z * 0.7),
			Color3.fromRGB(240, 220, 60))
	elseif style == "headband" then
		piece(folder, head, "Headband", hs * Vector3.new(1.12, 0.18, 1.12), CFrame.new(0, hs.Y * 0.25, 0),
			Color3.fromRGB(220, 50, 60))
	elseif style == "crown" then
		piece(folder, head, "Crown", hs * Vector3.new(1.05, 0.4, 1.05), top, Color3.fromRGB(240, 200, 70),
			Enum.Material.Metal)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			piece(folder, head, "Spire", Vector3.new(hs.X * 0.15, hs.Y * 0.35, hs.Z * 0.15),
				top * CFrame.new(math.cos(a) * hs.X * 0.45, hs.Y * 0.3, math.sin(a) * hs.Z * 0.45), Color3.fromRGB(240, 200, 70),
				Enum.Material.Metal)
		end
	end
end

local function buildGlasses(folder: Instance, head: BasePart, style: string)
	if style == "none" then
		return
	end
	local hs = head.Size
	local front = CFrame.new(0, hs.Y * 0.05, -hs.Z * 0.52)
	local dark = Color3.fromRGB(20, 20, 24)
	if style == "square" or style == "round" then
		for _, sx in { -1, 1 } do
			local lens = piece(folder, head, "Lens", Vector3.new(hs.X * 0.34, hs.Y * 0.3, 0.06),
				front * CFrame.new(sx * hs.X * 0.26, 0, 0), dark)
			if style == "round" then
				lens.Shape = Enum.PartType.Cylinder
				lens.Size = Vector3.new(0.06, hs.X * 0.34, hs.Y * 0.3)
				lens.CFrame = head.CFrame * front * CFrame.new(sx * hs.X * 0.26, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
		piece(folder, head, "Bridge", Vector3.new(hs.X * 0.18, 0.05, 0.05), front, dark)
	elseif style == "shades" then
		piece(folder, head, "Shades", Vector3.new(hs.X * 0.95, hs.Y * 0.3, 0.08), front, dark, Enum.Material.Glass)
	elseif style == "monocle" then
		local lens = piece(folder, head, "Monocle", Vector3.new(0.06, hs.X * 0.34, hs.Y * 0.34),
			front * CFrame.new(hs.X * 0.26, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(200, 230, 240),
			Enum.Material.Glass)
		lens.Shape = Enum.PartType.Cylinder
	end
end

local function tintOutfit(p: any, color: Color3, outfit: string)
	-- color torso + arms + legs as the outfit; hands/head keep skin
	local function col(part: BasePart?, c: Color3)
		if part then
			part.Color = c
		end
	end
	col(p.torsoU, color)
	col(p.torsoL, color)
	local sleeves = outfit ~= "vest" -- vests leave the arms as skin
	for _, a in p.armsU do
		col(a, sleeves and color or a and a.Color)
	end
	for _, a in p.armsL do
		if outfit == "suit" or outfit == "turtleneck" or outfit == "hoodie" or outfit == "tracksuit" then
			col(a, color)
		end
	end
	local pants = outfit == "dress" and color or color:Lerp(Color3.new(0, 0, 0), 0.4)
	for _, l in p.legsU do
		col(l, pants)
	end
	for _, l in p.legsL do
		col(l, pants)
	end
end

local function buildOutfitExtras(folder: Instance, p: any, outfit: string, color: Color3)
	local torso = p.torsoU
	if not torso then
		return
	end
	local ts = torso.Size
	if outfit == "suit" then
		-- lapels + tie
		for _, sx in { -1, 1 } do
			piece(folder, torso, "Lapel", Vector3.new(ts.X * 0.25, ts.Y * 0.7, 0.08), CFrame.new(sx * ts.X * 0.22, 0, -ts.Z * 0.5)
				* CFrame.Angles(0, 0, sx * 0.2), color:Lerp(Color3.new(0, 0, 0), 0.3))
		end
		piece(folder, torso, "Tie", Vector3.new(ts.X * 0.14, ts.Y * 0.7, 0.05), CFrame.new(0, 0, -ts.Z * 0.52),
			Color3.fromRGB(180, 40, 50))
		piece(folder, torso, "Shirt", Vector3.new(ts.X * 0.3, ts.Y * 0.8, 0.04), CFrame.new(0, 0, -ts.Z * 0.5),
			Color3.fromRGB(240, 240, 245))
	elseif outfit == "dress" then
		piece(folder, p.torsoL or torso, "Skirt", Vector3.new(ts.X * 1.5, ts.Y * 0.9, ts.Z * 1.5),
			CFrame.new(0, -ts.Y * 0.9, 0), color)
	elseif outfit == "hoodie" then
		piece(folder, torso, "Hood", Vector3.new(ts.X * 1.1, ts.Y * 0.4, ts.Z * 1.1), CFrame.new(0, ts.Y * 0.5, ts.Z * 0.2),
			color:Lerp(Color3.new(0, 0, 0), 0.2))
		piece(folder, torso, "Pocket", Vector3.new(ts.X * 0.7, ts.Y * 0.3, 0.06), CFrame.new(0, -ts.Y * 0.2, -ts.Z * 0.5),
			color:Lerp(Color3.new(0, 0, 0), 0.2))
	elseif outfit == "turtleneck" and p.head then
		piece(folder, torso, "Collar", Vector3.new(ts.X * 0.6, ts.Y * 0.3, ts.Z * 0.9), CFrame.new(0, ts.Y * 0.5, 0), color)
	elseif outfit == "tracksuit" then
		for _, sx in { -1, 1 } do
			piece(folder, torso, "Stripe", Vector3.new(0.06, ts.Y, ts.Z * 0.9), CFrame.new(sx * ts.X * 0.45, 0, 0),
				Color3.fromRGB(240, 240, 245))
		end
	end
end

-- scale an R15 character to the chosen body type (Humanoid body-type values)
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

-- The main entry: dress an R15 character. Safe to call again (it clears old extras first).
function Appearance.apply(char: Model, look)
	look = Appearance.sanitize(look)
	local p = parts(char)
	-- clear previous extras
	local old = char:FindFirstChild("LookExtras")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "LookExtras"
	folder.Parent = char
	-- skin
	local skin = Appearance.SKINS[look.skin]
	for _, name in { "Head", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm" } do
		local part = char:FindFirstChild(name) :: BasePart?
		if part then
			part.Color = skin
		end
	end
	-- outfit
	local outfitColor = Appearance.OUTFIT_COLORS[look.outfitColor]
	tintOutfit(p, outfitColor, Appearance.OUTFITS[look.outfit])
	if p.head then
		buildOutfitExtras(folder, p, Appearance.OUTFITS[look.outfit], outfitColor)
		buildHair(folder, p.head, Appearance.HAIR[look.hair], Appearance.HAIR_COLORS[look.hairColor])
		buildHat(folder, p.head, Appearance.HATS[look.hat])
		buildGlasses(folder, p.head, Appearance.GLASSES[look.glasses])
	end
	Appearance.applyScale(char, look)
end

return Appearance
