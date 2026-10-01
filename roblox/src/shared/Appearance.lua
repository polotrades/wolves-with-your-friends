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
	"ponytail", "mohawk", "afro", "mullet", "frostedtips", "combover", "emo", "dreads", "pigtails", "fauxhawk",
	"bedhead", "flattop", "topknot", "cornrows" }
Appearance.HATS = { "none", "fedora", "beanie", "cap", "visor", "headband", "crown", "guardcap", "cowboy", "party",
	"chef", "hardhat", "bucket", "propeller", "halo", "durag", "wizard", "santa", "sweatband" }
Appearance.GLASSES = { "none", "square", "round", "shades", "aviators", "nerd", "monocle", "heart", "star", "3d",
	"skigoggles", "eyepatch", "visor", "pitviper" }
-- torso / clothing styles, several lifted from the cast plus a lot of funny extras
Appearance.TORSOS = { "chairmanSuit", "cryptoHoodie", "rookieSuit", "internShirt", "guardUniform", "ceoPinstripe",
	"receptionBlazer", "plainSuit", "hoodie", "vest", "turtleneck", "tracksuit", "tank", "moneyTee", "hawaiian",
	"chefCoat", "labCoat", "varsity", "overalls", "poncho", "sharkOnesie", "dealerVest", "bullSuit", "lifeguard",
	"puffer", "flannel", "jersey", "robe" }
Appearance.ARMS = { "sleeves", "hoodie", "bare", "muscular", "guard", "tattoo", "floaties", "rolled", "cast", "longgloves" }
Appearance.HANDS = { "bare", "fists", "gloves", "goldrings", "fingerless", "watch", "foamfinger", "boxing", "moneystack",
	"claw" }
Appearance.LEGS = { "slacks", "khakis", "jeans", "shorts", "skirt", "trackpants", "guardpants", "ripped", "cargo",
	"swimtrunks", "kilt", "pajama", "chaps", "leather" }
Appearance.SHOES = { "sneakers", "dress", "boots", "heels", "sandals", "clown", "flippers", "cowboyboots", "rollerskates",
	"crocs" }
Appearance.ACCESSORY = { "none", "goldchain", "cryptochain", "tie", "bowtie", "backpack", "badge", "lanyard", "suspenders",
	"duckfloatie", "briefcase", "cape", "angelwings", "moneybelt", "neckbrace", "scarf", "medal", "parrot", "jetpack",
	"flowerlei", "fannypack" }
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
local SPARK = Color3.fromRGB(255, 255, 255)
local function buildHead(folder: Instance, head: BasePart, skin: Color3)
	local hs = head.Size
	-- a big rounded cartoon head over the hidden real head
	shell(folder, head, "CartoonHead", Vector3.new(1.18, 1.14, 1.18), skin, CFrame.new(0, 0, 0), nil, Enum.PartType.Ball)
	-- ears
	for _, sx in { -1, 1 } do
		piece(folder, head, "Ear", Vector3.new(hs.X * 0.18, hs.Y * 0.34, hs.Z * 0.28),
			CFrame.new(sx * hs.X * 0.6, -hs.Y * 0.02, 0), skin, nil, Enum.PartType.Ball)
	end
	-- the cast's signature big round eyes: a white eyeball, a dark pupil and a glossy spark
	for _, sx in { -1, 1 } do
		piece(folder, head, "EyeWhite", Vector3.new(hs.X * 0.3, hs.Y * 0.36, hs.Z * 0.28),
			CFrame.new(sx * hs.X * 0.24, hs.Y * 0.08, -hs.Z * 0.5), WHITE, nil, Enum.PartType.Ball)
		piece(folder, head, "Pupil", Vector3.new(hs.X * 0.14, hs.Y * 0.17, hs.Z * 0.14),
			CFrame.new(sx * hs.X * 0.24, hs.Y * 0.06, -hs.Z * 0.62), DARK, nil, Enum.PartType.Ball)
		piece(folder, head, "Spark", Vector3.new(hs.X * 0.05, hs.Y * 0.06, hs.Z * 0.05),
			CFrame.new(sx * hs.X * 0.21, hs.Y * 0.12, -hs.Z * 0.66), SPARK, Enum.Material.Neon, Enum.PartType.Ball)
		piece(folder, head, "Brow", Vector3.new(hs.X * 0.3, hs.Y * 0.06, hs.Z * 0.12),
			CFrame.new(sx * hs.X * 0.24, hs.Y * 0.3, -hs.Z * 0.52), skin:Lerp(DARK, 0.55))
	end
	-- a rounded nose and a friendly smile
	piece(folder, head, "Nose", Vector3.new(hs.X * 0.16, hs.Y * 0.16, hs.Z * 0.22),
		CFrame.new(0, -hs.Y * 0.04, -hs.Z * 0.64), skin:Lerp(DARK, 0.08), nil, Enum.PartType.Ball)
	piece(folder, head, "Smile", Vector3.new(hs.X * 0.3, hs.Y * 0.1, hs.Z * 0.1),
		CFrame.new(0, -hs.Y * 0.32, -hs.Z * 0.55), Color3.fromRGB(90, 40, 45), nil, Enum.PartType.Ball)
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
	elseif style == "frostedtips" then
		h("HairBase", 1.15, 0.4, 1.15, top)
		for i = -1, 1 do
			local tip = piece(folder, head, "Spike", Vector3.new(hs.X * 0.28, hs.Y * 0.7, hs.Z * 0.28),
				top * CFrame.new(i * hs.X * 0.3, hs.Y * 0.2, 0) * CFrame.Angles(0, 0, i * 0.25), color:Lerp(WHITE, 0.7))
			local _ = tip
		end
	elseif style == "combover" then
		h("Hair", 1.2, 0.4, 1.2, top)
		h("Sweep", 1.1, 0.22, 1.0, top * CFrame.new(hs.X * 0.18, hs.Y * 0.16, 0) * CFrame.Angles(0, 0, 0.3))
	elseif style == "emo" then
		h("Hair", 1.22, 0.5, 1.22, top)
		h("Fringe", 1.0, 0.5, 0.35, CFrame.new(hs.X * 0.18, -hs.Y * 0.18, -hs.Z * 0.55) * CFrame.Angles(0.2, 0, 0.2))
	elseif style == "dreads" then
		h("HairBase", 1.15, 0.45, 1.15, top)
		for _, o in { Vector3.new(0.4, 0, 0.4), Vector3.new(-0.4, 0, 0.4), Vector3.new(0.4, 0, -0.4),
			Vector3.new(-0.4, 0, -0.4), Vector3.new(0.5, 0, 0), Vector3.new(-0.5, 0, 0) } do
			h("Dread", 0.22, 1.5, 0.22, CFrame.new(o.X * hs.X, -hs.Y * 0.3, o.Z * hs.Z))
		end
	elseif style == "pigtails" then
		h("Hair", 1.18, 0.5, 1.18, top)
		for _, sx in { -1, 1 } do
			h("Pigtail", 0.5, 1.1, 0.5, CFrame.new(sx * hs.X * 0.7, hs.Y * 0.1, 0))
		end
	elseif style == "fauxhawk" then
		h("HairBase", 1.12, 0.35, 1.12, top)
		h("Hawk", 0.35, 0.7, 1.0, top * CFrame.new(0, hs.Y * 0.18, 0))
	elseif style == "bedhead" then
		h("HairBase", 1.2, 0.5, 1.2, top)
		for i = -1, 1 do
			for j = -1, 1 do
				h("Tuft", 0.4, 0.5, 0.4, top * CFrame.new(i * hs.X * 0.3, hs.Y * 0.1, j * hs.Z * 0.3)
					* CFrame.Angles(j * 0.3, 0, i * 0.3), Enum.PartType.Ball)
			end
		end
	elseif style == "flattop" then
		h("Flattop", 1.2, 0.55, 1.2, top * CFrame.new(0, hs.Y * 0.05, 0))
	elseif style == "topknot" then
		h("Hair", 1.1, 0.35, 1.1, top)
		h("Knot", 0.45, 0.6, 0.45, CFrame.new(0, hs.Y * 0.85, 0), Enum.PartType.Ball)
	elseif style == "cornrows" then
		h("HairBase", 1.12, 0.3, 1.12, top)
		for i = -2, 2 do
			h("Row", 0.12, 0.42, 1.15, top * CFrame.new(i * hs.X * 0.22, hs.Y * 0.05, 0))
		end
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
	elseif style == "cowboy" then
		h("Brim", 2.1, 0.08, 1.7, top, Color3.fromRGB(120, 85, 45))
		h("Crown", 1.0, 0.7, 1.0, top * CFrame.new(0, hs.Y * 0.32, 0), Color3.fromRGB(120, 85, 45))
		h("Band", 1.04, 0.12, 1.04, top * CFrame.new(0, hs.Y * 0.12, 0), Color3.fromRGB(60, 40, 25))
	elseif style == "party" then
		piece(folder, head, "PartyCone", Vector3.new(hs.X * 0.9, hs.Y * 1.2, hs.Z * 0.9),
			top * CFrame.new(0, hs.Y * 0.5, 0), Color3.fromRGB(240, 70, 140))
		piece(folder, head, "Pom", Vector3.new(hs.X * 0.3, hs.Y * 0.3, hs.Z * 0.3),
			top * CFrame.new(0, hs.Y * 1.1, 0), Color3.fromRGB(255, 230, 90), nil, Enum.PartType.Ball)
	elseif style == "chef" then
		h("Band", 1.2, 0.3, 1.2, top, WHITE)
		h("Puff", 1.35, 0.7, 1.35, top * CFrame.new(0, hs.Y * 0.4, 0), WHITE)
	elseif style == "hardhat" then
		h("Shell", 1.3, 0.55, 1.35, top, Color3.fromRGB(245, 200, 40))
		h("Brim", 1.4, 0.08, 0.9, top * CFrame.new(0, -hs.Y * 0.08, -hs.Z * 0.5), Color3.fromRGB(245, 200, 40))
		h("Ridge", 0.22, 0.5, 1.4, top, Color3.fromRGB(220, 175, 30))
	elseif style == "bucket" then
		h("Crown", 1.25, 0.55, 1.25, top, Color3.fromRGB(90, 150, 90))
		h("Brim", 1.6, 0.12, 1.6, top * CFrame.new(0, -hs.Y * 0.1, 0), Color3.fromRGB(80, 135, 80))
	elseif style == "propeller" then
		h("Cap", 1.25, 0.5, 1.25, top, Color3.fromRGB(230, 70, 70))
		h("Button", 0.2, 0.2, 0.2, top * CFrame.new(0, hs.Y * 0.3, 0), GOLD)
		for _, sx in { -1, 1 } do
			piece(folder, head, "Blade", Vector3.new(hs.X * 0.9, 0.06, hs.Z * 0.18),
				top * CFrame.new(sx * hs.X * 0.3, hs.Y * 0.42, 0) * CFrame.Angles(0, sx * 0.4, 0), Color3.fromRGB(90, 170, 230))
		end
	elseif style == "halo" then
		piece(folder, head, "Halo", Vector3.new(hs.X * 1.1, hs.Y * 0.12, hs.Z * 1.1),
			top * CFrame.new(0, hs.Y * 0.55, 0), Color3.fromRGB(255, 240, 150), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif style == "durag" then
		h("Durag", 1.22, 0.65, 1.25, top, Color3.fromRGB(30, 30, 40))
		h("Tail", 0.5, 0.5, 0.6, CFrame.new(0, hs.Y * 0.2, hs.Z * 0.55), Color3.fromRGB(30, 30, 40))
	elseif style == "wizard" then
		piece(folder, head, "WizardCone", Vector3.new(hs.X * 1.0, hs.Y * 1.6, hs.Z * 1.0),
			top * CFrame.new(0, hs.Y * 0.7, 0) * CFrame.Angles(0.15, 0, 0), Color3.fromRGB(60, 40, 140))
		h("Brim", 1.7, 0.1, 1.7, top, Color3.fromRGB(60, 40, 140))
	elseif style == "santa" then
		h("Band", 1.3, 0.25, 1.3, top, WHITE)
		piece(folder, head, "SantaCone", Vector3.new(hs.X * 0.9, hs.Y * 1.1, hs.Z * 0.9),
			top * CFrame.new(0, hs.Y * 0.55, hs.Z * 0.1) * CFrame.Angles(0.3, 0, 0), Color3.fromRGB(200, 40, 50))
		piece(folder, head, "Pom", Vector3.new(hs.X * 0.3, hs.Y * 0.3, hs.Z * 0.3),
			top * CFrame.new(0, hs.Y * 1.0, hs.Z * 0.5), WHITE, nil, Enum.PartType.Ball)
	elseif style == "sweatband" then
		h("Sweatband", 1.26, 0.2, 1.26, CFrame.new(0, hs.Y * 0.34, 0), Color3.fromRGB(230, 70, 90))
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
	elseif style == "heart" then
		for _, sx in { -1, 1 } do
			piece(folder, head, "HeartLens", Vector3.new(hs.X * 0.36, hs.Y * 0.34, 0.06),
				front * CFrame.new(sx * hs.X * 0.27, 0, 0), Color3.fromRGB(240, 80, 140), Enum.Material.Glass)
		end
		piece(folder, head, "Bridge", Vector3.new(hs.X * 0.18, 0.05, 0.05), front, Color3.fromRGB(240, 80, 140))
	elseif style == "star" then
		for _, sx in { -1, 1 } do
			piece(folder, head, "StarLens", Vector3.new(hs.X * 0.4, hs.Y * 0.38, 0.05),
				front * CFrame.new(sx * hs.X * 0.27, 0, 0) * CFrame.Angles(0, 0, math.rad(45)), GOLD, Enum.Material.Neon)
		end
	elseif style == "3d" then
		piece(folder, head, "Frame3D", Vector3.new(hs.X * 0.98, hs.Y * 0.3, 0.05), front, WHITE)
		piece(folder, head, "LensRed", Vector3.new(hs.X * 0.34, hs.Y * 0.26, 0.06),
			front * CFrame.new(-hs.X * 0.24, 0, -0.01), Color3.fromRGB(230, 50, 60), Enum.Material.Glass)
		piece(folder, head, "LensBlue", Vector3.new(hs.X * 0.34, hs.Y * 0.26, 0.06),
			front * CFrame.new(hs.X * 0.24, 0, -0.01), Color3.fromRGB(50, 120, 230), Enum.Material.Glass)
	elseif style == "skigoggles" then
		piece(folder, head, "Goggles", Vector3.new(hs.X * 1.05, hs.Y * 0.42, hs.Z * 0.3),
			front * CFrame.new(0, 0, 0.04), Color3.fromRGB(90, 200, 230), Enum.Material.Glass)
		piece(folder, head, "GoggleStrap", Vector3.new(hs.X * 1.3, hs.Y * 0.16, hs.Z * 0.1),
			CFrame.new(0, hs.Y * 0.1, 0), Color3.fromRGB(40, 40, 50))
	elseif style == "eyepatch" then
		piece(folder, head, "Patch", Vector3.new(hs.X * 0.36, hs.Y * 0.42, 0.08),
			front * CFrame.new(-hs.X * 0.24, 0, 0), DARK)
		piece(folder, head, "PatchStrap", Vector3.new(hs.X * 1.3, hs.Y * 0.08, hs.Z * 0.1),
			CFrame.new(0, hs.Y * 0.14, 0) * CFrame.Angles(0, 0, math.rad(10)), DARK)
	elseif style == "visor" then
		piece(folder, head, "Visor", Vector3.new(hs.X * 1.02, hs.Y * 0.34, 0.06), front, Color3.fromRGB(40, 220, 180),
			Enum.Material.Glass)
	elseif style == "pitviper" then
		piece(folder, head, "Shield", Vector3.new(hs.X * 1.05, hs.Y * 0.4, hs.Z * 0.35),
			front * CFrame.new(0, 0, 0.03), Color3.fromRGB(255, 120, 40), Enum.Material.Neon)
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
	elseif style == "moneyTee" then
		piece(folder, u, "DollarSign", Vector3.new(ts.X * 0.35, ts.Y * 0.6, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), GOLD,
			Enum.Material.Metal)
		piece(folder, u, "SignBarT", Vector3.new(ts.X * 0.5, 0.06, 0.06), CFrame.new(0, ts.Y * 0.22, -ts.Z * 0.63), GOLD,
			Enum.Material.Metal)
		piece(folder, u, "SignBarB", Vector3.new(ts.X * 0.5, 0.06, 0.06), CFrame.new(0, -ts.Y * 0.22, -ts.Z * 0.63), GOLD,
			Enum.Material.Metal)
	elseif style == "hawaiian" then
		for _, p in { Vector3.new(-0.3, 0.2, 0), Vector3.new(0.25, -0.1, 0), Vector3.new(-0.1, -0.3, 0),
			Vector3.new(0.3, 0.3, 0), Vector3.new(0, 0.05, 0) } do
			piece(folder, u, "Flower", Vector3.new(ts.X * 0.22, ts.Y * 0.22, 0.05),
				CFrame.new(p.X * ts.X, p.Y * ts.Y, -ts.Z * 0.62), Color3.fromRGB(255, 120, 60), nil, Enum.PartType.Ball)
		end
		piece(folder, u, "Collar", Vector3.new(ts.X * 0.8, ts.Y * 0.18, 0.08), CFrame.new(0, ts.Y * 0.45, -ts.Z * 0.5), WHITE)
	elseif style == "chefCoat" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Lapel", Vector3.new(ts.X * 0.34, ts.Y * 1.0, 0.09), CFrame.new(sx * ts.X * 0.2, 0, -ts.Z * 0.62)
				* CFrame.Angles(0, 0, sx * 0.1), WHITE)
			for i = -1, 1 do
				piece(folder, u, "Button", Vector3.new(0.08, 0.08, 0.06), CFrame.new(sx * ts.X * 0.18, i * ts.Y * 0.25, -ts.Z * 0.64),
					DARK, nil, Enum.PartType.Ball)
			end
		end
	elseif style == "labCoat" then
		shell(folder, u, "Coat", Vector3.new(1.42, 1.32, 1.4), WHITE, CFrame.new(0, -ts.Y * 0.3, 0))
		piece(folder, u, "Pocket", Vector3.new(ts.X * 0.3, ts.Y * 0.3, 0.06), CFrame.new(-ts.X * 0.3, -ts.Y * 0.2, -ts.Z * 0.66),
			Color3.fromRGB(225, 225, 230))
		piece(folder, u, "Pen", Vector3.new(0.05, ts.Y * 0.3, 0.05), CFrame.new(ts.X * 0.28, ts.Y * 0.2, -ts.Z * 0.66),
			Color3.fromRGB(40, 120, 220))
	elseif style == "varsity" then
		shell(folder, u, "Jacket", Vector3.new(1.4, 1.28, 1.38), color, CFrame.new(0, -ts.Y * 0.2, 0))
		for _, sx in { -1, 1 } do
			shell(folder, u, "Sleeve", Vector3.new(0.3, 1.2, 0.5), WHITE, CFrame.new(sx * ts.X * 0.7, 0, 0))
		end
		piece(folder, u, "Letter", Vector3.new(ts.X * 0.3, ts.Y * 0.4, 0.06), CFrame.new(-ts.X * 0.25, 0, -ts.Z * 0.64), WHITE)
	elseif style == "overalls" then
		piece(folder, u, "Bib", Vector3.new(ts.X * 0.7, ts.Y * 0.8, 0.1), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.6),
			Color3.fromRGB(60, 90, 160))
		for _, sx in { -1, 1 } do
			piece(folder, u, "Strap", Vector3.new(0.12, ts.Y * 1.1, 0.06), CFrame.new(sx * ts.X * 0.3, 0, -ts.Z * 0.58),
				Color3.fromRGB(60, 90, 160))
			piece(folder, u, "Buckle", Vector3.new(0.1, 0.1, 0.05), CFrame.new(sx * ts.X * 0.3, ts.Y * 0.1, -ts.Z * 0.64), GOLD,
				Enum.Material.Metal)
		end
	elseif style == "poncho" then
		shell(folder, u, "Poncho", Vector3.new(1.55, 1.4, 1.5), color, CFrame.new(0, -ts.Y * 0.35, 0))
		for i = -2, 2 do
			piece(folder, u, "Stripe", Vector3.new(ts.X * 1.5, 0.08, 0.04), CFrame.new(0, i * ts.Y * 0.22, -ts.Z * 0.72),
				color:Lerp(WHITE, 0.5))
		end
	elseif style == "sharkOnesie" then
		shell(folder, u, "Onesie", Vector3.new(1.4, 1.3, 1.4), Color3.fromRGB(110, 150, 180), CFrame.new(0, -ts.Y * 0.2, 0))
		piece(folder, u, "Belly", Vector3.new(ts.X * 0.7, ts.Y * 0.9, 0.08), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.62), WHITE)
		piece(folder, u, "Fin", Vector3.new(0.12, ts.Y * 0.5, ts.Z * 0.5), CFrame.new(0, ts.Y * 0.4, ts.Z * 0.5)
			* CFrame.Angles(math.rad(20), 0, 0), Color3.fromRGB(90, 130, 160))
	elseif style == "dealerVest" then
		shell(folder, u, "Vest", Vector3.new(1.32, 1.1, 1.3), Color3.fromRGB(120, 30, 40), CFrame.new(0, -ts.Y * 0.1, 0))
		piece(folder, u, "Shirt", Vector3.new(ts.X * 0.4, ts.Y * 1.0, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), WHITE)
		piece(folder, u, "Bowtie", Vector3.new(ts.X * 0.4, ts.Y * 0.16, 0.08), CFrame.new(0, ts.Y * 0.4, -ts.Z * 0.62), DARK)
	elseif style == "bullSuit" then
		shell(folder, u, "SuitBulk", Vector3.new(1.5, 1.3, 1.4), color, CFrame.new(0, -ts.Y * 0.2, 0))
		for _, sx in { -1, 1 } do
			piece(folder, u, "Horn", Vector3.new(0.12, 0.12, ts.Z * 0.5), CFrame.new(sx * ts.X * 0.5, ts.Y * 0.45, 0)
				* CFrame.Angles(0, sx * 0.5, 0), WHITE)
		end
		piece(folder, u, "Tie", Vector3.new(ts.X * 0.16, ts.Y * 1.0, 0.07), CFrame.new(0, -ts.Y * 0.1, -ts.Z * 0.64),
			Color3.fromRGB(200, 60, 40))
	elseif style == "lifeguard" then
		shell(folder, u, "Tank", Vector3.new(1.3, 1.2, 1.28), Color3.fromRGB(220, 50, 60), CFrame.new(0, -ts.Y * 0.3, 0))
		piece(folder, u, "Cross", Vector3.new(ts.X * 0.4, ts.Y * 0.14, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), WHITE)
		piece(folder, u, "CrossV", Vector3.new(ts.X * 0.14, ts.Y * 0.4, 0.06), CFrame.new(0, 0, -ts.Z * 0.62), WHITE)
	elseif style == "puffer" then
		for i = -2, 2 do
			shell(folder, u, "Puff", Vector3.new(1.45, 0.3, 1.42), color, CFrame.new(0, i * ts.Y * 0.26 - ts.Y * 0.1, 0))
		end
	elseif style == "flannel" then
		shell(folder, u, "Flannel", Vector3.new(1.36, 1.26, 1.34), color, CFrame.new(0, -ts.Y * 0.2, 0))
		for i = -2, 2 do
			piece(folder, u, "CheckV", Vector3.new(0.05, ts.Y * 1.3, 0.04), CFrame.new(i * ts.X * 0.22, 0, -ts.Z * 0.66),
				color:Lerp(DARK, 0.5))
		end
		for i = -1, 1 do
			piece(folder, u, "CheckH", Vector3.new(ts.X * 1.3, 0.05, 0.04), CFrame.new(0, i * ts.Y * 0.35, -ts.Z * 0.66),
				color:Lerp(DARK, 0.5))
		end
	elseif style == "jersey" then
		shell(folder, u, "Jersey", Vector3.new(1.34, 1.2, 1.32), color, CFrame.new(0, -ts.Y * 0.25, 0))
		piece(folder, u, "Number", Vector3.new(ts.X * 0.4, ts.Y * 0.5, 0.05), CFrame.new(0, 0, -ts.Z * 0.63), WHITE)
	elseif style == "robe" then
		shell(folder, u, "Robe", Vector3.new(1.48, 1.4, 1.46), color, CFrame.new(0, -ts.Y * 0.3, 0))
		piece(folder, u, "Sash", Vector3.new(ts.X * 1.4, ts.Y * 0.2, 0.08), CFrame.new(0, -ts.Y * 0.35, 0), color:Lerp(DARK, 0.4))
		piece(folder, u, "Collar", Vector3.new(ts.X * 0.5, ts.Y * 1.0, 0.1), CFrame.new(0, ts.Y * 0.1, -ts.Z * 0.58),
			color:Lerp(WHITE, 0.3))
	end
end

-- ---------------------------------------------------------------- arms
local function buildArms(folder: Instance, b, style: string, color: Color3, skin: Color3)
	local sleeve = (style == "sleeves" or style == "rolled") and color or style == "hoodie" and color:Lerp(DARK, 0.2)
		or style == "guard" and DARK or skin
	for _, side in { "Left", "Right" } do
		local up = b[side .. "UpperArm"]
		local lo = b[side .. "LowerArm"]
		if up then
			shell(folder, up, "Sleeve", Vector3.new(1.3, 1.05, 1.3), (style == "muscular") and skin or sleeve)
			if style == "floaties" then
				shell(folder, up, "Floatie", Vector3.new(1.7, 0.6, 1.7), Color3.fromRGB(255, 150, 60), CFrame.new(0, -up.Size.Y * 0.2, 0),
					nil, Enum.PartType.Ball)
			end
		end
		if lo then
			local lowerColor = (style == "sleeves" or style == "hoodie" or style == "guard") and sleeve or skin
			shell(folder, lo, "Forearm", Vector3.new(1.25, 1.05, 1.25), lowerColor)
			if style == "tattoo" then
				piece(folder, lo, "Tattoo", Vector3.new(lo.Size.X * 1.3, lo.Size.Y * 0.4, 0.04),
					CFrame.new(0, 0, -lo.Size.Z * 0.6), Color3.fromRGB(40, 60, 120))
			elseif style == "muscular" then
				shell(folder, up, "Bicep", Vector3.new(1.5, 0.6, 1.5), skin, CFrame.new(0, up.Size.Y * 0.1, 0),
					nil, Enum.PartType.Ball)
			elseif style == "cast" and side == "Left" then
				shell(folder, lo, "Cast", Vector3.new(1.5, 1.1, 1.5), Color3.fromRGB(240, 240, 245))
			elseif style == "longgloves" then
				shell(folder, lo, "Glove", Vector3.new(1.3, 1.1, 1.3), color:Lerp(DARK, 0.3))
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
			elseif style == "boxing" then
				shell(folder, hand, "BoxGlove", Vector3.new(2.0, 2.0, 2.2), Color3.fromRGB(220, 40, 50),
					CFrame.new(0, 0, -hand.Size.Z * 0.2), nil, Enum.PartType.Ball)
			elseif style == "foamfinger" and side == "Right" then
				shell(folder, hand, "Foam", Vector3.new(1.6, 1.4, 1.6), Color3.fromRGB(255, 120, 60))
				piece(folder, hand, "FoamTip", Vector3.new(hand.Size.X * 1.2, hand.Size.Y * 2.2, hand.Size.Z * 0.6),
					CFrame.new(0, -hand.Size.Y * 1.3, 0), Color3.fromRGB(255, 120, 60))
			elseif style == "moneystack" and side == "Right" then
				for i = 0, 3 do
					piece(folder, hand, "Cash", Vector3.new(hand.Size.X * 1.6, 0.12, hand.Size.Z * 0.9),
						CFrame.new(0, -hand.Size.Y * 0.2 + i * 0.14, 0), Color3.fromRGB(100, 170, 100))
				end
			elseif style == "claw" then
				for i = -1, 1, 2 do
					piece(folder, hand, "Pincer", Vector3.new(hand.Size.X * 0.3, hand.Size.Y * 0.4, hand.Size.Z * 1.2),
						CFrame.new(i * hand.Size.X * 0.3, 0, -hand.Size.Z * 0.5), Color3.fromRGB(150, 150, 160), Enum.Material.Metal)
				end
			end
		end
	end
end

-- ---------------------------------------------------------------- legs (pants) + shoes
local function buildLegs(folder: Instance, b, style: string, color: Color3, skin: Color3)
	local short = style == "shorts" or style == "skirt" or style == "swimtrunks"
	for _, side in { "Left", "Right" } do
		local up = b[side .. "UpperLeg"]
		local lo = b[side .. "LowerLeg"]
		local sx = side == "Left" and -1 or 1
		if up then
			shell(folder, up, "Thigh", Vector3.new(1.3, 1.05, 1.3), (style == "swimtrunks") and color or color)
			if style == "swimtrunks" then
				shell(folder, up, "Trunks", Vector3.new(1.5, 0.8, 1.5), color, CFrame.new(0, up.Size.Y * 0.1, 0))
			elseif style == "chaps" then
				piece(folder, up, "Fringe", Vector3.new(0.06, up.Size.Y * 1.1, up.Size.Z * 0.9), CFrame.new(sx * up.Size.X * 0.6, 0, 0),
					Color3.fromRGB(150, 110, 60))
			end
		end
		if lo then
			shell(folder, lo, "Shin", Vector3.new(1.25, 1.05, 1.25), short and skin or color)
			if style == "trackpants" then
				piece(folder, lo, "Stripe", Vector3.new(0.05, lo.Size.Y, lo.Size.Z * 0.9), CFrame.new(lo.Size.X * 0.55, 0, 0), WHITE)
			elseif style == "ripped" then
				piece(folder, lo, "Rip", Vector3.new(lo.Size.X * 0.9, lo.Size.Y * 0.2, 0.04), CFrame.new(0, 0, -lo.Size.Z * 0.6), skin)
			elseif style == "guardpants" then
				piece(folder, lo, "GuardStripe", Vector3.new(0.06, lo.Size.Y, lo.Size.Z * 0.9), CFrame.new(lo.Size.X * 0.55, 0, 0), GOLD)
			elseif style == "cargo" then
				piece(folder, lo, "Pocket", Vector3.new(lo.Size.X * 1.3, lo.Size.Y * 0.4, lo.Size.Z * 0.3),
					CFrame.new(sx * lo.Size.X * 0.4, 0, -lo.Size.Z * 0.5), color:Lerp(DARK, 0.2))
			elseif style == "leather" then
				shell(folder, lo, "Boot", Vector3.new(1.3, 0.5, 1.3), DARK, CFrame.new(0, -lo.Size.Y * 0.3, 0))
			end
		end
	end
	if style == "skirt" or style == "kilt" then
		local waist = b.LowerTorso
		if waist then
			local skColor = style == "kilt" and Color3.fromRGB(70, 90, 70) or color
			shell(folder, waist, "Skirt", Vector3.new(1.7, 1.4, 1.7), skColor, CFrame.new(0, -waist.Size.Y * 0.8, 0))
			if style == "kilt" then
				for i = -2, 2 do
					piece(folder, waist, "Plaid", Vector3.new(0.05, waist.Size.Y * 1.4, waist.Size.Z * 1.8),
						CFrame.new(i * waist.Size.X * 0.4, -waist.Size.Y * 0.8, 0), Color3.fromRGB(120, 40, 40))
				end
			end
		end
	elseif style == "pajama" then
		local waist = b.LowerTorso
		if waist then
			for _, p in { Vector3.new(0.3, 0.2, 0), Vector3.new(-0.3, -0.1, 0), Vector3.new(0.1, -0.3, 0) } do
				piece(folder, waist, "Dot", Vector3.new(0.12, 0.12, 0.06), CFrame.new(p.X, p.Y, -waist.Size.Z * 0.6),
					color:Lerp(WHITE, 0.6), nil, Enum.PartType.Ball)
			end
		end
	end
end

local function buildShoes(folder: Instance, b, style: string)
	local col = ({ sneakers = WHITE, dress = DARK, boots = Color3.fromRGB(60, 40, 25), heels = Color3.fromRGB(150, 30, 50),
		sandals = Color3.fromRGB(120, 90, 60), clown = Color3.fromRGB(230, 50, 60), flippers = Color3.fromRGB(40, 120, 200),
		cowboyboots = Color3.fromRGB(120, 80, 45), rollerskates = WHITE, crocs = Color3.fromRGB(90, 200, 140) })[style] or WHITE
	for _, side in { "Left", "Right" } do
		local foot = b[side .. "Foot"]
		local sh = b[side .. "LowerLeg"]
		if foot then
			local length = style == "clown" and 2.4 or style == "flippers" and 2.2 or 1.45
			shell(folder, foot, "Shoe", Vector3.new(1.3, 1.3, length), col, CFrame.new(0, 0, -foot.Size.Z * 0.1))
			if style == "heels" then
				piece(folder, foot, "Heel", Vector3.new(foot.Size.X * 0.3, foot.Size.Y * 1.2, foot.Size.Z * 0.3),
					CFrame.new(0, -foot.Size.Y * 0.6, foot.Size.Z * 0.5), col)
			elseif (style == "boots" or style == "cowboyboots") and sh then
				shell(folder, sh, "BootTop", Vector3.new(1.3, 0.7, 1.3), col, CFrame.new(0, 0, 0))
				if style == "cowboyboots" then
					piece(folder, foot, "Toe", Vector3.new(foot.Size.X * 0.6, foot.Size.Y * 0.6, foot.Size.Z * 0.5),
						CFrame.new(0, 0, -foot.Size.Z * 0.7), col)
				end
			elseif style == "rollerskates" then
				for i = -1, 1, 2 do
					piece(folder, foot, "Wheel", Vector3.new(0.18, foot.Size.Y * 0.5, foot.Size.Z * 0.5),
						CFrame.new(i * foot.Size.X * 0.3, -foot.Size.Y * 0.5, 0), DARK, nil, Enum.PartType.Ball)
				end
			elseif style == "crocs" then
				for _, p in { Vector3.new(0.2, 0, -0.3), Vector3.new(-0.2, 0, -0.3), Vector3.new(0, 0, -0.5) } do
					piece(folder, foot, "Hole", Vector3.new(0.08, 0.08, 0.08), CFrame.new(p.X * foot.Size.X, foot.Size.Y * 0.4,
						p.Z * foot.Size.Z), col:Lerp(DARK, 0.3), nil, Enum.PartType.Ball)
				end
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
	elseif style == "duckfloatie" then
		local waist = b.LowerTorso or u
		shell(folder, waist, "DuckRing", Vector3.new(2.1, 1.2, 2.1), Color3.fromRGB(255, 210, 60), CFrame.new(0, 0, 0),
			nil, Enum.PartType.Ball)
		piece(folder, waist, "DuckHead", Vector3.new(waist.Size.X * 0.5, waist.Size.Y * 0.8, waist.Size.Z * 0.5),
			CFrame.new(0, waist.Size.Y * 0.3, -waist.Size.Z * 1.1), Color3.fromRGB(255, 210, 60), nil, Enum.PartType.Ball)
		piece(folder, waist, "DuckBeak", Vector3.new(waist.Size.X * 0.3, waist.Size.Y * 0.2, waist.Size.Z * 0.4),
			CFrame.new(0, waist.Size.Y * 0.25, -waist.Size.Z * 1.5), Color3.fromRGB(240, 140, 40))
	elseif style == "briefcase" then
		local hand = b.RightHand
		if hand then
			piece(folder, hand, "Briefcase", Vector3.new(hand.Size.X * 2.2, hand.Size.Y * 1.6, hand.Size.Z * 0.6),
				CFrame.new(0, -hand.Size.Y * 1.2, 0), Color3.fromRGB(90, 60, 35))
			piece(folder, hand, "CaseHandle", Vector3.new(hand.Size.X * 0.8, hand.Size.Y * 0.3, 0.06),
				CFrame.new(0, -hand.Size.Y * 0.3, 0), DARK)
		end
	elseif style == "cape" then
		piece(folder, u, "Cape", Vector3.new(ts.X * 1.5, ts.Y * 1.6, 0.1), CFrame.new(0, -ts.Y * 0.2, ts.Z * 0.6),
			Color3.fromRGB(150, 30, 50))
		piece(folder, u, "CapeClasp", Vector3.new(ts.X * 0.8, 0.1, 0.08), CFrame.new(0, ts.Y * 0.45, ts.Z * 0.3), GOLD,
			Enum.Material.Metal)
	elseif style == "angelwings" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Wing", Vector3.new(ts.X * 0.9, ts.Y * 1.3, 0.12), CFrame.new(sx * ts.X * 0.5, ts.Y * 0.1, ts.Z * 0.6)
				* CFrame.Angles(0, sx * 0.4, 0), WHITE)
		end
	elseif style == "moneybelt" then
		local waist = b.LowerTorso or u
		piece(folder, waist, "Belt", Vector3.new(waist.Size.X * 1.3, waist.Size.Y * 0.3, waist.Size.Z * 1.3),
			CFrame.new(0, waist.Size.Y * 0.3, 0), DARK)
		piece(folder, waist, "Buckle", Vector3.new(waist.Size.X * 0.4, waist.Size.Y * 0.3, 0.08),
			CFrame.new(0, waist.Size.Y * 0.3, -waist.Size.Z * 0.62), GOLD, Enum.Material.Metal)
	elseif style == "neckbrace" then
		piece(folder, u, "Brace", Vector3.new(ts.X * 0.9, ts.Y * 0.35, ts.Z * 0.9), CFrame.new(0, ts.Y * 0.5, 0),
			Color3.fromRGB(235, 235, 240), nil, Enum.PartType.Cylinder)
	elseif style == "scarf" then
		piece(folder, u, "Scarf", Vector3.new(ts.X * 1.1, ts.Y * 0.3, ts.Z * 1.1), CFrame.new(0, ts.Y * 0.45, 0),
			Color3.fromRGB(200, 60, 70))
		piece(folder, u, "ScarfTail", Vector3.new(ts.X * 0.3, ts.Y * 0.8, 0.08), CFrame.new(ts.X * 0.2, -ts.Y * 0.1, -ts.Z * 0.62),
			Color3.fromRGB(200, 60, 70))
	elseif style == "medal" then
		piece(folder, u, "Ribbon", Vector3.new(ts.X * 0.3, ts.Y * 0.5, 0.05), CFrame.new(0, ts.Y * 0.2, -ts.Z * 0.63),
			Color3.fromRGB(60, 80, 180))
		piece(folder, u, "Medal", Vector3.new(ts.X * 0.3, ts.Y * 0.3, 0.06), CFrame.new(0, -ts.Y * 0.05, -ts.Z * 0.65), GOLD,
			Enum.Material.Metal, Enum.PartType.Ball)
	elseif style == "parrot" then
		local arm = b.RightUpperArm or u
		piece(folder, arm, "ParrotBody", Vector3.new(0.5, 0.7, 0.5), CFrame.new(0, arm.Size.Y * 0.5, 0),
			Color3.fromRGB(60, 170, 80), nil, Enum.PartType.Ball)
		piece(folder, arm, "ParrotHead", Vector3.new(0.35, 0.35, 0.35), CFrame.new(0, arm.Size.Y * 0.85, -0.1),
			Color3.fromRGB(230, 70, 60), nil, Enum.PartType.Ball)
		piece(folder, arm, "ParrotBeak", Vector3.new(0.14, 0.14, 0.2), CFrame.new(0, arm.Size.Y * 0.82, -0.3),
			Color3.fromRGB(240, 200, 60))
	elseif style == "jetpack" then
		for _, sx in { -1, 1 } do
			piece(folder, u, "Tank", Vector3.new(ts.X * 0.3, ts.Y * 1.1, ts.Z * 0.4), CFrame.new(sx * ts.X * 0.35, 0, ts.Z * 0.7),
				Color3.fromRGB(150, 155, 165), Enum.Material.Metal, Enum.PartType.Cylinder)
			piece(folder, u, "Flame", Vector3.new(ts.X * 0.25, ts.Y * 0.4, ts.Z * 0.25),
				CFrame.new(sx * ts.X * 0.35, -ts.Y * 0.7, ts.Z * 0.7), Color3.fromRGB(255, 140, 40), Enum.Material.Neon)
		end
	elseif style == "flowerlei" then
		for i = 0, 11 do
			local a = i / 12 * math.pi * 2
			piece(folder, u, "Petal", Vector3.new(0.14, 0.14, 0.14),
				CFrame.new(math.sin(a) * ts.X * 0.5, ts.Y * 0.4, -math.abs(math.cos(a)) * ts.Z * 0.5 - ts.Z * 0.1),
				i % 2 == 0 and Color3.fromRGB(255, 120, 60) or Color3.fromRGB(255, 220, 90), nil, Enum.PartType.Ball)
		end
	elseif style == "fannypack" then
		local waist = b.LowerTorso or u
		piece(folder, waist, "Pack", Vector3.new(waist.Size.X * 0.9, waist.Size.Y * 0.5, waist.Size.Z * 0.5),
			CFrame.new(0, 0, -waist.Size.Z * 0.6), Color3.fromRGB(230, 90, 140))
		piece(folder, waist, "Strap", Vector3.new(waist.Size.X * 1.3, waist.Size.Y * 0.2, waist.Size.Z * 1.3),
			CFrame.new(0, 0, 0), Color3.fromRGB(200, 70, 120))
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
	-- everything built so far is head-region: mark it so the owner's own first-person camera can hide it
	-- (otherwise the opaque head/face parts sit right on top of the camera and black out the view)
	for _, d in folder:GetChildren() do
		if d:IsA("BasePart") then
			d:SetAttribute("HeadPiece", true)
		end
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
		p:SetAttribute("HeadPiece", true)
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
