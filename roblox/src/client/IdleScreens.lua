-- Live idle screens: every desk monitor (tagged "DeskScreen") shows a moving trading terminal while nobody is on a
-- call there. Each screen flips between a candlestick chart and a flashing stock screener, with a news crawl along the
-- bottom. Drawn client-side, and only screens near the camera are updated.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local IdleScreens = {}

local SYMBOLS = { "BMM", "WOLF", "YACHT", "DUCK", "MOON", "PUMP", "GOLD", "LAMBO", "HYPE", "BAG", "SHRK", "STONK", "CASH",
	"BULL", "FOMO", "TOAST", "ZOOM", "RICH" }
local NEWS = {
	"BANANA MOON MINING UP 400% ON RUMORS OF A BANANA ON THE MOON",
	"CEO OF DUCK CORP SAYS 'QUACK' IN EARNINGS CALL, STOCK SOARS",
	"ANALYSTS: NUMBER WILL GO UP, OR POSSIBLY DOWN",
	"WOLF & CO. BREAKS FLOOR 100 RECORD FOR MOST PHONE CALLS IN A DAY",
	"YACHT FUTURES SINK, THEN FLOAT AGAIN",
	"LOCAL MAN BUYS HIGH, SELLS LOW, CALLS IT A STRATEGY",
	"FED CHAIR SPOTTED EATING A VERY EXPENSIVE SANDWICH",
	"PUMP INDUSTRIES ANNOUNCES NEW PUMP",
	"GOLDEN TOILET INDEX HITS ALL-TIME HIGH",
}
local UP = Color3.fromRGB(40, 230, 110)
local DOWN = Color3.fromRGB(255, 70, 80)
local BG = Color3.fromRGB(8, 12, 22)
local DIM = Color3.fromRGB(120, 140, 170)
local CANDLES = 28
local ROWS = 7
local UPDATE_RANGE = 90

type Candle = { o: number, h: number, l: number, c: number }
type Screen = {
	monitor: BasePart,
	root: Frame,
	trust: GuiObject?,
	chartView: Frame,
	listView: Frame,
	sym: string,
	price: number,
	candles: { Candle },
	wicks: { Frame },
	bodies: { Frame },
	head: TextLabel,
	change: TextLabel,
	clock: TextLabel,
	rows: { { name: TextLabel, px: TextLabel, chg: TextLabel, price: number, open: number } },
	crawl: TextLabel,
	nextCandle: number,
	nextFlip: number,
}

local screens: { Screen } = {}
local rng = Random.new()

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

local function text(parent: Instance, t: string, props): TextLabel
	local l = new("TextLabel", { BackgroundTransparency = 1, Text = t, TextScaled = true, Font = Enum.Font.Code,
		TextColor3 = Color3.new(1, 1, 1), Parent = parent })
	for k, v in props do
		(l :: any)[k] = v
	end
	return l
end

local function money(n: number): string
	return string.format("%.2f", n)
end

local function pct(now: number, open: number): string
	local p = (now - open) / open * 100
	return string.format("%s%.2f%%", p >= 0 and "+" or "", p)
end

local function step(price: number): number
	return math.max(0.5, price * (1 + rng:NextNumber(-0.012, 0.0125)))
end

local function drawChart(s: Screen)
	local hi, lo = -math.huge, math.huge
	for _, c in s.candles do
		hi, lo = math.max(hi, c.h), math.min(lo, c.l)
	end
	local span = math.max(hi - lo, 1e-3)
	local function y(v: number): number
		return 0.94 - (v - lo) / span * 0.88
	end
	for i, c in s.candles do
		local color = c.c >= c.o and UP or DOWN
		local xs = 0.03 + (i - 1) / CANDLES * 0.94
		local w, b = s.wicks[i], s.bodies[i]
		w.BackgroundColor3, b.BackgroundColor3 = color, color
		w.Position = UDim2.fromScale(xs + 0.011, y(c.h))
		w.Size = UDim2.new(0, 1, y(c.l) - y(c.h), 0)
		local top, bot = y(math.max(c.o, c.c)), y(math.min(c.o, c.c))
		b.Position = UDim2.fromScale(xs, top)
		b.Size = UDim2.fromScale(0.022, math.max(bot - top, 0.012))
	end
end

local function tick(s: Screen, now: number)
	-- the live candle wiggles every tick; a new one opens every couple of seconds
	local last = s.candles[#s.candles]
	s.price = step(s.price)
	last.c = s.price
	last.h, last.l = math.max(last.h, s.price), math.min(last.l, s.price)
	if now >= s.nextCandle then
		s.nextCandle = now + rng:NextNumber(1.5, 3)
		table.remove(s.candles, 1)
		table.insert(s.candles, { o = s.price, c = s.price, h = s.price, l = s.price })
	end
	local open = s.candles[1].o
	s.head.Text = s.sym .. "  $" .. money(s.price)
	s.change.Text = pct(s.price, open)
	s.change.TextColor3 = s.price >= open and UP or DOWN
	s.clock.Text = os.date("%H:%M:%S") :: string

	if now >= s.nextFlip then
		-- someone alt-tabbed: flip between the chart and the screener
		s.nextFlip = now + rng:NextNumber(10, 30)
		s.chartView.Visible = not s.chartView.Visible
		s.listView.Visible = not s.chartView.Visible
		if s.chartView.Visible then
			s.sym = SYMBOLS[rng:NextInteger(1, #SYMBOLS)]
		end
	end
	if s.chartView.Visible then
		drawChart(s)
	else
		for _, r in s.rows do
			if rng:NextNumber() < 0.5 then
				local old = r.price
				r.price = step(r.price)
				r.px.Text = money(r.price)
				r.px.TextColor3 = r.price >= old and UP or DOWN
				r.chg.Text = pct(r.price, r.open)
				r.chg.TextColor3 = r.price >= r.open and UP or DOWN
			else
				r.px.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end
end

local function build(monitor: BasePart)
	local gui = monitor:WaitForChild("Mirror", 10)
	local bg = gui and gui:FindFirstChildWhichIsA("Frame")
	if not bg then
		return
	end
	local root = new("Frame", { Name = "Idle", Size = UDim2.fromScale(1, 1), BackgroundColor3 = BG, BorderSizePixel = 0,
		ZIndex = 5, Parent = bg })

	-- top bar: symbol + price, change, clock
	local top = new("Frame", { Size = UDim2.fromScale(1, 0.13), BackgroundColor3 = Color3.fromRGB(18, 26, 44),
		BorderSizePixel = 0, ZIndex = 5, Parent = root })
	local head = text(top, "", { Size = UDim2.fromScale(0.5, 0.9), Position = UDim2.fromScale(0.02, 0.05),
		TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, ZIndex = 6 })
	local change = text(top, "", { Size = UDim2.fromScale(0.22, 0.8), Position = UDim2.fromScale(0.52, 0.1), ZIndex = 6 })
	local clock = text(top, "", { Size = UDim2.fromScale(0.22, 0.7), Position = UDim2.fromScale(0.76, 0.15),
		TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 })

	-- candle chart view
	local chartView = new("Frame", { Size = UDim2.fromScale(1, 0.72), Position = UDim2.fromScale(0, 0.14),
		BackgroundTransparency = 1, ZIndex = 5, Parent = root })
	for g = 1, 3 do
		new("Frame", { Size = UDim2.new(0.96, 0, 0, 1), Position = UDim2.fromScale(0.02, g / 4),
			BackgroundColor3 = Color3.fromRGB(30, 40, 60), BorderSizePixel = 0, ZIndex = 5, Parent = chartView })
	end
	local wicks, bodies = {}, {}
	for i = 1, CANDLES do
		wicks[i] = new("Frame", { Size = UDim2.new(0, 1, 0, 0), BorderSizePixel = 0, ZIndex = 6, Parent = chartView })
		bodies[i] = new("Frame", { Size = UDim2.fromScale(0.022, 0), BorderSizePixel = 0, ZIndex = 7, Parent = chartView })
	end

	-- screener view: watchlist rows that flash on every tick
	local listView = new("Frame", { Size = UDim2.fromScale(1, 0.72), Position = UDim2.fromScale(0, 0.14),
		BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = root })
	local rows = {}
	for r = 1, ROWS do
		local y = (r - 1) / ROWS
		local price = rng:NextNumber(3, 400)
		local row = {
			name = text(listView, SYMBOLS[rng:NextInteger(1, #SYMBOLS)], { Size = UDim2.fromScale(0.3, 0.8 / ROWS),
				Position = UDim2.fromScale(0.04, y + 0.02), TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamBold, ZIndex = 6 }),
			px = text(listView, money(price), { Size = UDim2.fromScale(0.3, 0.8 / ROWS), Position = UDim2.fromScale(0.36, y + 0.02),
				TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 }),
			chg = text(listView, "+0.00%", { Size = UDim2.fromScale(0.26, 0.8 / ROWS), Position = UDim2.fromScale(0.7, y + 0.02),
				TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 }),
			price = price,
			open = price,
		}
		table.insert(rows, row)
	end

	-- bottom news crawl
	local bottom = new("Frame", { Size = UDim2.fromScale(1, 0.12), Position = UDim2.fromScale(0, 0.88),
		BackgroundColor3 = Color3.fromRGB(150, 20, 30), BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 5,
		Parent = root })
	local crawl = text(bottom, "BREAKING: " .. NEWS[rng:NextInteger(1, #NEWS)], { Size = UDim2.fromScale(2.5, 0.8),
		Position = UDim2.fromScale(1, 0.1), TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, ZIndex = 6 })

	local price = rng:NextNumber(5, 300)
	local candles = {}
	for i = 1, CANDLES do
		local o = price
		price = step(step(price))
		candles[i] = { o = o, c = price, h = math.max(o, price) * (1 + rng:NextNumber(0, 0.006)),
			l = math.min(o, price) * (1 - rng:NextNumber(0, 0.006)) }
	end

	local now = os.clock()
	table.insert(screens, {
		monitor = monitor,
		root = root,
		trust = bg:FindFirstChild("TrustBack") :: GuiObject?,
		chartView = chartView,
		listView = listView,
		sym = SYMBOLS[rng:NextInteger(1, #SYMBOLS)],
		price = price,
		candles = candles,
		wicks = wicks,
		bodies = bodies,
		head = head,
		change = change,
		clock = clock,
		rows = rows,
		crawl = crawl,
		nextCandle = now + rng:NextNumber(1, 2.5),
		nextFlip = now + rng:NextNumber(8, 30),
	})
	tick(screens[#screens], now)
end

function IdleScreens.init()
	for _, m in CollectionService:GetTagged("DeskScreen") do
		task.spawn(build, m)
	end
	CollectionService:GetInstanceAddedSignal("DeskScreen"):Connect(function(m)
		task.spawn(build, m)
	end)

	local nextTick = 0
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		local slide = 1 - (now * 0.08) % 3.6 -- crawl slides from the right edge off the left
		local doTick = now >= nextTick
		if doTick then
			nextTick = now + 0.25
		end
		for _, s in screens do
			-- hide the terminal while a call is on this desk so the caller + trust bar show through
			local busy = s.trust ~= nil and s.trust.Visible
			s.root.Visible = not busy
			if not busy and (s.monitor.Position - camPos).Magnitude < UPDATE_RANGE then
				s.crawl.Position = UDim2.fromScale(slide, 0.1)
				if doTick then
					tick(s, now)
				end
			end
		end
	end)
end

return IdleScreens
