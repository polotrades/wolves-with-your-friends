-- PumpAds: pay for a loud ad campaign about a silly penny stock. After 20 seconds the server pays back somewhere
-- between a flop and a moonshot (into Personal AND the firm). Side effect: pop-up ads everywhere, including
-- your own computer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local Adware = require(script.Parent:WaitForChild("Adware"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local PumpAdsApp = {}
local STOCKS = { { "BMM", "Banana Moon Mining", "🍌" }, { "DUCK", "Duck Corp", "🦆" }, { "YACHT", "Yacht Futures", "🛥️" },
	{ "TOAST", "Toast Holdings", "🍞" } }
local SLOGANS = { "TO THE MOON!", "Buy before your neighbor does!", "Number go up. Trust us." }
local BUDGETS = { 100, 250, 500 }
local DURATION = 20

local win, refs
local running = nil :: { ends: number, stock: string }?

local function highlight(group: { GuiButton }, pick: number)
	for i, b in group do
		b.BackgroundColor3 = i == pick and Color3.fromRGB(230, 60, 140) or UI.os.surface2
	end
end

function PumpAdsApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	win = Desktop.window("pumpads", "PumpAds", Vector2.new(480, 470))
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	UI.pad(c, 14)
	refs = { stock = 1, slogan = 1, budget = 1 }
	UI.label(c, "📢 PumpAds · Ad Campaign Studio", 18, { Font = UI.bold })
	UI.label(c, "1. Pick a stock", 13, { Position = UDim2.fromOffset(0, 32), TextColor3 = UI.os.dim, Font = UI.bold })
	local stocks = {}
	for i, s in STOCKS do
		local b = UI.flat(c, s[3] .. " " .. s[1], UI.os.surface2, { Size = UDim2.new(0.25, -6, 0, 40),
			Position = UDim2.new((i - 1) * 0.25, 0, 0, 54), TextSize = 14 }, function()
				refs.stock = i
				highlight(stocks, i)
			end)
		stocks[i] = b
	end
	UI.label(c, "2. Pick a slogan", 13, { Position = UDim2.fromOffset(0, 104), TextColor3 = UI.os.dim, Font = UI.bold })
	local slogans = {}
	for i, s in SLOGANS do
		slogans[i] = UI.flat(c, "“" .. s .. "”", UI.os.surface2, { Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromOffset(0, 126 + (i - 1) * 34), TextSize = 13 }, function()
				refs.slogan = i
				highlight(slogans, i)
			end)
	end
	UI.label(c, "3. Budget (from Personal money)", 13, { Position = UDim2.fromOffset(0, 232), TextColor3 = UI.os.dim, Font = UI.bold })
	local budgets = {}
	for i, amount in BUDGETS do
		budgets[i] = UI.flat(c, UI.money(amount), UI.os.surface2, { Size = UDim2.new(1 / 3, -6, 0, 36),
			Position = UDim2.new((i - 1) / 3, 0, 0, 254) }, function()
				refs.budget = i
				highlight(budgets, i)
			end)
	end
	highlight(stocks, 1)
	highlight(slogans, 1)
	highlight(budgets, 1)
	refs.status = UI.label(c, "Returns land in 20 seconds. Could flop, could moon.", 13, { Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 300), TextWrapped = true, TextColor3 = UI.os.dim })
	local barBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 1, -64), BackgroundColor3 = UI.os.surface3,
		BorderSizePixel = 0, Parent = c })
	UI.corner(barBack, 4)
	refs.bar = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(230, 60, 140), BorderSizePixel = 0,
		Parent = barBack })
	UI.corner(refs.bar, 4)
	refs.launch = UI.flat(c, "🚀 Launch campaign", Color3.fromRGB(230, 60, 140), { Size = UDim2.new(1, 0, 0, 44),
		Position = UDim2.new(0, 0, 1, -48) }, function()
			if running then
				return
			end
			local budget = BUDGETS[refs.budget]
			if State.personal < budget then
				refs.status.Text = "Not enough Personal money for that budget."
				refs.status.TextColor3 = UI.colors.red
				return
			end
			Net.PumpAds:FireServer(refs.stock, budget)
		end)
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	task.spawn(function()
		while refs do
			if running then
				local left = running.ends - os.clock()
				refs.bar.Size = UDim2.fromScale(math.clamp(1 - left / DURATION, 0, 1), 1)
				refs.launch.Text = string.format("Campaign live: %ds", math.max(0, math.ceil(left)))
			else
				refs.launch.Text = "🚀 Launch campaign"
			end
			task.wait(0.2)
		end
	end)
end

-- server accepted the campaign (result == nil) or paid it out
function PumpAdsApp.result(r)
	if r.started then
		running = { ends = os.clock() + DURATION, stock = r.stock }
		if refs then
			refs.status.Text = string.format("“%s” is running for $%s. Ads are going out everywhere...", SLOGANS[refs.slogan], r.stock)
			refs.status.TextColor3 = UI.os.text
		end
		task.delay(2, function()
			Adware.spawn(2)
		end)
		return
	end
	running = nil
	local profit = r.returned - r.spent
	local msg = string.format("$%s campaign returned %s (%s%s)", r.stock, UI.money(r.returned), profit >= 0 and "+" or "-",
		UI.money(math.abs(profit)))
	Desktop.notify("PumpAds", msg, profit >= 0 and "📈" or "📉")
	if refs then
		refs.status.Text = msg
		refs.status.TextColor3 = profit >= 0 and UI.colors.green or UI.colors.red
		refs.bar.Size = UDim2.fromScale(0, 1)
	end
end

return PumpAdsApp
