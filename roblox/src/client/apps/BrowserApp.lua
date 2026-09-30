-- Browser: a pretend web browser with back / forward / refresh, an address bar and a handful of fictional sites:
-- a search engine, floor-100 news, a live market board, an encyclopedia, cat pictures and a link to Shark Mart.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))

local BrowserApp = {
	go = nil :: any,
	open = nil :: any,
}
local win, refs

local HOME = "howl.search"
local DARK = Color3.fromRGB(30, 30, 40)

type Site = { title: string, keys: string, draw: (ScrollingFrame) -> () }
local SITES: { [string]: Site } = {}

local function h1(p: Instance, text: string, color: Color3?, order: number)
	return UI.label(p, text, 26, { Font = UI.bold, TextColor3 = color or DARK, LayoutOrder = order, TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y })
end

local function para(p: Instance, text: string, order: number, color: Color3?)
	return UI.label(p, text, 15, { TextColor3 = color or Color3.fromRGB(60, 60, 75), LayoutOrder = order, TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
end

local function link(p: Instance, text: string, url: string, order: number)
	local b = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Font = UI.body, TextSize = 15,
		TextColor3 = Color3.fromRGB(30, 90, 220), Text = text, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order,
		Parent = p })
	b.Activated:Connect(function()
		BrowserApp.go(url)
	end)
	return b
end

SITES["howl.search"] = { title = "Howl Search", keys = "search home", draw = function(p)
	UI.text(p, "Howl", { Size = UDim2.new(1, 0, 0, 70), TextColor3 = Color3.fromRGB(70, 110, 230), LayoutOrder = 1 })
	local box = UI.new("TextBox", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(240, 242, 248),
		TextColor3 = DARK, PlaceholderText = "🔍  Search the web (try: moon, cats, news)", Font = UI.body, TextSize = 16,
		ClearTextOnFocus = false, Text = "", LayoutOrder = 2, Parent = p })
	UI.corner(box, 20)
	box.FocusLost:Connect(function(enter)
		if enter and box.Text ~= "" then
			BrowserApp.go("howl.search/?q=" .. box.Text)
		end
	end)
	para(p, "Popular sites", 3, Color3.fromRGB(120, 120, 130))
	local order = 4
	for url, s in SITES do
		if url ~= HOME then
			link(p, "›  " .. s.title .. "   (" .. url .. ")", url, order)
			order += 1
		end
	end
end }

SITES["floor100.news"] = { title = "The Floor 100 Times", keys = "news headlines times", draw = function(p)
	h1(p, "THE FLOOR 100 TIMES", Color3.fromRGB(20, 20, 20), 1)
	para(p, "All the news that fits, and some that doesn't.", 2, Color3.fromRGB(120, 120, 130))
	local stories = {
		{ "Banana Moon Mining up 400% on rumors of a banana on the moon", "Analysts remain unsure whether the moon has bananas, or whether it has ever been asked." },
		{ "Duck Corp CEO says 'quack' on earnings call, stock soars", "Investors called it 'the most honest earnings call in years'." },
		{ "Fish tank on floor 100 outperforms three hedge funds", "The goldfish declined to comment." },
		{ "Local man buys high, sells low, calls it a strategy", "'It's called being early,' he explained. It is not called that." },
		{ "Golden Toilet Index hits all-time high", "Experts say the market is 'flush' with optimism." },
	}
	for i, s in stories do
		UI.label(p, s[1], 18, { Font = UI.bold, TextColor3 = DARK, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 2 + i * 2 })
		para(p, s[2], 3 + i * 2)
	end
end }

SITES["stonks.market"] = { title = "Stonks Market Board", keys = "stocks market prices ticker", draw = function(p)
	h1(p, "📈 Stonks Market Board", Color3.fromRGB(20, 120, 60), 1)
	para(p, "Prices refresh every time you press ⟳. Past performance is a coin toss.", 2)
	local rng = Random.new()
	for i, sym in { "BMM", "DUCK", "YACHT", "TOAST", "WOLF", "MOON", "PUMP", "GOLD", "LAMBO", "FOMO" } do
		local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(244, 246, 250)
			or Color3.new(1, 1, 1), BorderSizePixel = 0, LayoutOrder = 2 + i, Parent = p })
		local chg = rng:NextNumber(-12, 18)
		UI.label(row, "  " .. sym, 15, { Size = UDim2.new(0.4, 0, 1, 0), Font = UI.bold, TextColor3 = DARK })
		UI.label(row, string.format("$%.2f", rng:NextNumber(0.5, 420)), 15, { Size = UDim2.new(0.3, 0, 1, 0),
			Position = UDim2.fromScale(0.4, 0), TextColor3 = DARK })
		UI.label(row, string.format("%s%.2f%%  ", chg >= 0 and "+" or "", chg), 15, { Size = UDim2.new(0.3, 0, 1, 0),
			Position = UDim2.fromScale(0.7, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = UI.bold,
			TextColor3 = chg >= 0 and Color3.fromRGB(20, 150, 70) or Color3.fromRGB(210, 40, 50) })
	end
end }

SITES["wolfpedia.org"] = { title = "WolfPedia", keys = "wiki encyclopedia banana moon wolf firm", draw = function(p)
	h1(p, "WolfPedia: Banana Moon Mining Co.", DARK, 1)
	para(p, "From WolfPedia, the encyclopedia anyone can make up.", 2, Color3.fromRGB(120, 120, 130))
	para(p, "Banana Moon Mining Co. (ticker: BMM) is a company that plans to mine bananas on the moon. As of today it has mined"
		.. " zero bananas, which the company describes as 'a strong start'.", 3)
	para(p, "History: founded in a garage, then a slightly bigger garage. Its logo is a banana wearing a space helmet.", 4)
	h1(p, "Wolf & Co.", DARK, 5)
	para(p, "Wolf & Co. is a brokerage on floor 100 of a very tall tower. Employees make phone calls, close deals, and try to hit"
		.. " a daily target set by The Chairman. Nobody has seen The Chairman's feet.", 6)
end }

SITES["cats.daily"] = { title = "Cute Cats Daily", keys = "cats cute pets animals", draw = function(p)
	h1(p, "🐱 Cute Cats Daily", Color3.fromRGB(230, 90, 150), 1)
	para(p, "Scientifically proven to lower stress by 40% during a boss review.", 2)
	local grid = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 230), BackgroundTransparency = 1, LayoutOrder = 3, Parent = p })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(110, 110), CellPadding = UDim2.fromOffset(8, 8), Parent = grid })
	for _, cat in { "😺", "😸", "😹", "😻", "😼", "🙀", "😽", "🐈" } do
		local f = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 235, 245), Parent = grid })
		UI.corner(f, 10)
		UI.text(f, cat, { Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15) })
	end
end }

SITES["sharkmart.shop"] = { title = "Shark Mart Online", keys = "shop store upgrades buy shark mart", draw = function(p)
	h1(p, "🦈 Shark Mart Online", Color3.fromRGB(0, 150, 140), 1)
	para(p, "Upgrades, wallpapers, employees and the Bank. Everything a broker needs.", 2)
	UI.flat(p, "Open Shark Mart", Color3.fromRGB(0, 150, 140), { Size = UDim2.fromOffset(200, 40), LayoutOrder = 3 }, function()
		Desktop.openApp("sharkmart")
	end)
end }

local function searchPage(p: ScrollingFrame, q: string)
	h1(p, "Results for “" .. q .. "”", DARK, 1)
	local order = 2
	local lq = q:lower()
	for url, s in SITES do
		if url ~= HOME and (s.keys:find(lq, 1, true) or s.title:lower():find(lq, 1, true) or url:find(lq, 1, true)) then
			link(p, s.title, url, order)
			para(p, url, order + 1, Color3.fromRGB(30, 130, 60))
			order += 2
		end
	end
	if order == 2 then
		para(p, "No results. Even the internet doesn't know. Try: moon, news, cats, stocks.", 2)
	end
end

local function render(url: string)
	local p = refs.page
	for _, c in p:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	p.CanvasPosition = Vector2.zero
	refs.address.Text = url
	local site = SITES[url]
	local q = url:match("^howl%.search/%?q=(.+)$")
	if q then
		searchPage(p, q)
		win:setTitle("Search - Browser")
	elseif site then
		site.draw(p)
		win:setTitle(site.title .. " - Browser")
	else
		h1(p, "This site can't be reached", DARK, 1)
		para(p, url .. " took too long to respond. Probably out to lunch.", 2)
		link(p, "Go to Howl Search", HOME, 3)
		win:setTitle("Not found - Browser")
	end
end

function BrowserApp.go(url: string)
	if not refs then
		BrowserApp.open()
	end
	url = url:gsub("^https?://", ""):gsub("^www%.", ""):gsub("/$", "")
	if url == "" then
		url = HOME
	end
	-- bare words become a search
	if not url:find("%.") then
		url = "howl.search/?q=" .. url
	end
	while #refs.history > refs.index do
		table.remove(refs.history)
	end
	table.insert(refs.history, url)
	refs.index = #refs.history
	render(url)
end

function BrowserApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	win = Desktop.window("browser", "Browser", Vector2.new(760, 520))
	local c = win.content
	refs = { history = {}, index = 0 }
	local bar = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = UI.os.title, BorderSizePixel = 0, Parent = c })
	local function nav(x: number, glyph: string, fn)
		local b = UI.new("TextButton", { Size = UDim2.fromOffset(32, 30), Position = UDim2.fromOffset(x, 6), Text = glyph,
			Font = UI.body, TextSize = 18, TextColor3 = UI.os.text, BackgroundColor3 = UI.os.surface2, AutoButtonColor = true,
			Parent = bar })
		UI.corner(b, 15)
		b.Activated:Connect(fn)
	end
	nav(8, "←", function()
		if refs.index > 1 then
			refs.index -= 1
			render(refs.history[refs.index])
		end
	end)
	nav(44, "→", function()
		if refs.index < #refs.history then
			refs.index += 1
			render(refs.history[refs.index])
		end
	end)
	nav(80, "⟳", function()
		render(refs.history[refs.index] or HOME)
	end)
	nav(116, "⌂", function()
		BrowserApp.go(HOME)
	end)
	refs.address = UI.new("TextBox", { Size = UDim2.new(1, -168, 0, 30), Position = UDim2.fromOffset(156, 6),
		BackgroundColor3 = UI.os.surface2, TextColor3 = UI.os.text, Font = UI.body, TextSize = 14, ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = bar })
	UI.corner(refs.address, 15)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = refs.address })
	refs.address.FocusLost:Connect(function(enter)
		if enter then
			BrowserApp.go(refs.address.Text)
		end
	end)
	refs.page = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -42), Position = UDim2.fromOffset(0, 42),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarImageColor3 = Color3.fromRGB(150, 150, 160), Parent = c })
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 40), PaddingTop = UDim.new(0, 20),
		PaddingBottom = UDim.new(0, 20), Parent = refs.page })
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.page })
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	BrowserApp.go(HOME)
end

return BrowserApp
