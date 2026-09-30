-- The office wall boards (parts tagged "OfficeBoard", attribute Kind):
--   clock      red LED time of day (the workday runs 9:00 AM -> 5:00 PM)
--   suspicion  OFFICE SUSPICION meter, LOW / MEDIUM / HIGH / RAID
--   goal       time left in the day, firm money vs the target, deposited and rank
-- Everything comes from the server's Status broadcast.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))

local OfficeBoards = {}

type Board = { kind: string, refs: { [string]: any } }
local boards: { Board } = {}
local last

local LED = Color3.fromRGB(255, 45, 35)
local GOLD = Color3.fromRGB(255, 200, 70)
local LEVELS = {
	{ at = 0, name = "LOW", color = Color3.fromRGB(90, 230, 110) },
	{ at = 35, name = "MEDIUM", color = Color3.fromRGB(255, 200, 60) },
	{ at = 65, name = "HIGH", color = Color3.fromRGB(255, 120, 40) },
	{ at = 90, name = "RAID!", color = Color3.fromRGB(255, 50, 50) },
}
local RANKS = { { 0, "INTERN" }, { 0.25, "JUNIOR BROKER" }, { 0.5, "BROKER" }, { 0.8, "SHARK" }, { 1, "WOLF" } }

local function text(parent: Instance, t: string, props): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = t
	for k, v in props do
		(l :: any)[k] = v
	end
	l.Parent = parent
	return l
end

local function build(part: Instance)
	local gui = part:WaitForChild("Board", 10)
	local kind = part:GetAttribute("Kind")
	if not gui or type(kind) ~= "string" then
		return
	end
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local refs = {}
	if kind == "clock" then
		bg.BackgroundColor3 = Color3.fromRGB(8, 6, 6)
		refs.time = text(bg, "9:00 AM", { Size = UDim2.fromScale(0.92, 0.8), Position = UDim2.fromScale(0.04, 0.1),
			Font = Enum.Font.Code, TextColor3 = LED, TextStrokeColor3 = LED, TextStrokeTransparency = 0.6 })
	elseif kind == "suspicion" then
		bg.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
		text(bg, "OFFICE SUSPICION", { Size = UDim2.fromScale(0.6, 0.24), Position = UDim2.fromScale(0.04, 0.08),
			TextXAlignment = Enum.TextXAlignment.Left, Rotation = -1.5 })
		refs.level = text(bg, "LOW", { Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0.66, 0.05),
			TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = LEVELS[1].color, Rotation = -3 })
		local back = Instance.new("Frame")
		back.Size = UDim2.fromScale(0.92, 0.22)
		back.Position = UDim2.fromScale(0.04, 0.42)
		back.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
		back.BorderSizePixel = 0
		back.Parent = bg
		UI.corner(back, 6)
		refs.bar = Instance.new("Frame")
		refs.bar.Size = UDim2.fromScale(0.05, 1)
		refs.bar.BackgroundColor3 = LEVELS[1].color
		refs.bar.BorderSizePixel = 0
		refs.bar.Parent = back
		UI.corner(refs.bar, 6)
		text(bg, "Keep it down. Bad things happen at 100%.", { Size = UDim2.fromScale(0.92, 0.16),
			Position = UDim2.fromScale(0.04, 0.74), TextXAlignment = Enum.TextXAlignment.Left, Rotation = -1 })
	elseif kind == "goal" then
		bg.BackgroundColor3 = Color3.fromRGB(70, 8, 14)
		refs.timeLeft = text(bg, "TIME LEFT IN DAY 10:00", { Size = UDim2.fromScale(0.6, 0.12), Position = UDim2.fromScale(0.38, 0.05),
			TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right })
		refs.money = text(bg, "$0 OF $600", { Size = UDim2.fromScale(0.7, 0.26), Position = UDim2.fromScale(0.04, 0.2),
			TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.PermanentMarker })
		refs.reached = text(bg, "GOAL NOT REACHED", { Size = UDim2.fromScale(0.5, 0.1), Position = UDim2.fromScale(0.04, 0.48),
			TextXAlignment = Enum.TextXAlignment.Left })
		text(bg, "DEPOSITED", { Size = UDim2.fromScale(0.4, 0.1), Position = UDim2.fromScale(0.04, 0.64), TextColor3 = GOLD })
		text(bg, "RANK", { Size = UDim2.fromScale(0.4, 0.1), Position = UDim2.fromScale(0.56, 0.64), TextColor3 = GOLD })
		refs.deposited = text(bg, "$0", { Size = UDim2.fromScale(0.4, 0.14), Position = UDim2.fromScale(0.04, 0.78) })
		refs.rank = text(bg, "INTERN", { Size = UDim2.fromScale(0.4, 0.14), Position = UDim2.fromScale(0.56, 0.78) })
	end
	table.insert(boards, { kind = kind, refs = refs })
	if last then
		OfficeBoards.update(last)
	end
end

local function clockText(s): string
	local frac = s.state == "DAY" and (1 - s.timeLeft / Config.DAY_LENGTH) or (s.state == "WAITING" and 0 or 1)
	local minutes = 9 * 60 + math.floor(math.clamp(frac, 0, 1) * 8 * 60)
	local h = minutes // 60
	return string.format("%d:%02d %s", (h - 1) % 12 + 1, minutes % 60, h < 12 and "AM" or "PM")
end

function OfficeBoards.update(s)
	last = s
	local suspicion = math.clamp(tonumber(s.suspicion) or 0, 0, 100)
	local level = LEVELS[1]
	for _, l in LEVELS do
		if suspicion >= l.at then
			level = l
		end
	end
	local ratio = s.team / math.max(s.quota, 1)
	local rank = RANKS[1][2]
	for _, r in RANKS do
		if ratio >= r[1] then
			rank = r[2]
		end
	end
	for _, b in boards do
		local r = b.refs
		if b.kind == "clock" then
			r.time.Text = clockText(s)
		elseif b.kind == "suspicion" then
			r.level.Text = level.name
			r.level.TextColor3 = level.color
			r.bar.Size = UDim2.fromScale(math.max(suspicion / 100, 0.05), 1)
			r.bar.BackgroundColor3 = level.color
		elseif b.kind == "goal" then
			r.timeLeft.Text = "TIME LEFT IN DAY " .. (s.state == "DAY" and UI.clock(s.timeLeft) or "--:--")
			r.money.Text = string.format("%s OF %s", UI.money(s.team), UI.money(s.quota))
			r.reached.Text = s.team >= s.quota and "GOAL REACHED!" or "GOAL NOT REACHED"
			r.reached.TextColor3 = s.team >= s.quota and Color3.fromRGB(110, 255, 130) or Color3.new(1, 1, 1)
			r.deposited.Text = UI.money(s.team)
			r.rank.Text = rank
		end
	end
end

function OfficeBoards.init()
	for _, p in CollectionService:GetTagged("OfficeBoard") do
		task.spawn(build, p)
	end
	CollectionService:GetInstanceAddedSignal("OfficeBoard"):Connect(function(p)
		task.spawn(build, p)
	end)
end

return OfficeBoards
