-- Shark Mart: spend Personal money. Tabs: Upgrades (call perks), Store (items and wallpapers),
-- Employees (they earn money during the workday) and Bank (your balance, deposits to the firm, history).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local SharkMartApp = {}
local TABS = { { "upgrades", "⬆️ Upgrades" }, { "store", "🛍️ Store" }, { "employees", "👥 Employees" }, { "bank", "🏦 Bank" } }
local ACCENT = Color3.fromRGB(0, 150, 140)

local win, refs

local function clear()
	for _, c in refs.page:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

local function itemCard(item, order: number)
	local owned = State.owned[item.id] or 0
	local max = item.max or 1
	local price = Catalog.price(item, owned)
	local card = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 76), BackgroundColor3 = UI.os.surface2, LayoutOrder = order,
		Parent = refs.page })
	UI.corner(card, 8)
	UI.icon(card, item.glyph, ACCENT, 48, { Position = UDim2.fromOffset(12, 14) })
	UI.label(card, item.name .. (max > 1 and string.format("  (%d/%d)", owned, max) or ""), 16, {
		Size = UDim2.new(1, -200, 0, 20), Position = UDim2.fromOffset(72, 10), Font = UI.bold })
	UI.label(card, item.desc, 13, { Size = UDim2.new(1, -200, 0, 40), Position = UDim2.fromOffset(72, 32), TextWrapped = true,
		TextColor3 = UI.os.dim, TextYAlignment = Enum.TextYAlignment.Top })
	local maxed = owned >= max
	local afford = State.personal >= price
	local b = UI.flat(card, maxed and (max > 1 and "Maxed" or "Owned ✓") or UI.money(price),
		maxed and UI.os.surface3 or (afford and ACCENT or Color3.fromRGB(90, 70, 70)),
		{ Size = UDim2.fromOffset(104, 38), Position = UDim2.new(1, -116, 0.5, -19), TextSize = 15 })
	b.Activated:Connect(function()
		if maxed then
			return
		end
		if not afford then
			Desktop.notify("Shark Mart", "Not enough Personal money for " .. item.name .. ".", "💸")
			return
		end
		b.Text = "..."
		Net.Buy:FireServer(item.id)
	end)
end

local function bankPage()
	local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromRGB(20, 60, 70), LayoutOrder = 1,
		Parent = refs.page })
	UI.corner(head, 10)
	UI.new("UIGradient", { Rotation = 20, Color = ColorSequence.new(Color3.fromRGB(0, 140, 130), Color3.fromRGB(20, 50, 90)), Parent = head })
	UI.label(head, "PERSONAL BALANCE", 12, { Position = UDim2.fromOffset(16, 12), Font = UI.bold, TextColor3 = Color3.fromRGB(200, 240, 235) })
	UI.label(head, UI.money(State.personal), 34, { Size = UDim2.new(1, -32, 0, 40), Position = UDim2.fromOffset(16, 32), Font = UI.bold })
	local s = State.status
	UI.label(head, s and string.format("Firm today: %s / %s", UI.money(s.team), UI.money(s.quota)) or "", 13, {
		Position = UDim2.fromOffset(16, 78), TextColor3 = Color3.fromRGB(200, 240, 235) })
	local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, LayoutOrder = 2, Parent = refs.page })
	UI.label(row, "Deposit into the firm (counts toward today's target):", 13, { TextColor3 = UI.os.dim })
	for i, amount in { 100, 500, 0 } do
		UI.flat(row, amount == 0 and "Everything" or UI.money(amount), ACCENT, { Size = UDim2.new(1 / 3, -6, 0, 36),
			Position = UDim2.new((i - 1) / 3, 0, 0, 24) }, function()
				local a = amount == 0 and State.personal or amount
				if a <= 0 or State.personal < a then
					Desktop.notify("Bank", "Not enough Personal money.", "💸")
					return
				end
				Net.Bank:FireServer(a)
			end)
	end
	UI.label(refs.page, "History", 15, { Font = UI.bold, LayoutOrder = 3 })
	if #State.transactions == 0 then
		UI.label(refs.page, "No transactions yet. Close a deal!", 13, { TextColor3 = UI.os.dim, LayoutOrder = 4 })
	end
	for i, t in State.transactions do
		local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = UI.os.surface2, LayoutOrder = 4 + i,
			Parent = refs.page })
		UI.corner(r, 6)
		UI.label(r, "  " .. t.time .. "   " .. t.text, 13, { Size = UDim2.new(1, -110, 1, 0) })
		UI.label(r, (t.amount >= 0 and "+" or "-") .. UI.money(math.abs(t.amount)) .. "  ", 13, { Size = UDim2.new(0, 100, 1, 0),
			Position = UDim2.new(1, -100, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, Font = UI.bold,
			TextColor3 = t.amount >= 0 and UI.colors.green or UI.colors.red })
	end
end

local function show(tab: string)
	if not refs then
		return
	end
	refs.tab = tab
	for id, b in refs.tabs do
		b.BackgroundColor3 = id == tab and ACCENT or UI.os.surface2
	end
	refs.balance.Text = "💰 " .. UI.money(State.personal)
	clear()
	if tab == "bank" then
		bankPage()
		return
	end
	for i, item in (Catalog :: any)[tab] do
		itemCard(item, i)
	end
end

function SharkMartApp.open(tab: string?)
	if win and not win.closed then
		win:setMinimized(false)
		show(tab or refs.tab)
		return
	end
	win = Desktop.window("sharkmart", "Shark Mart", Vector2.new(620, 520))
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	refs = { tabs = {} }
	local head = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 92), BackgroundColor3 = UI.os.title, BorderSizePixel = 0, Parent = c })
	UI.label(head, "🦈 SHARK MART", 20, { Size = UDim2.new(0.6, 0, 0, 30), Position = UDim2.fromOffset(16, 8), Font = UI.bold,
		TextColor3 = Color3.fromRGB(120, 230, 215) })
	refs.balance = UI.label(head, "", 16, { Size = UDim2.new(0.4, -16, 0, 30), Position = UDim2.new(0.6, 0, 0, 8), Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = UI.colors.green })
	for i, t in TABS do
		refs.tabs[t[1]] = UI.flat(head, t[2], UI.os.surface2, { Size = UDim2.new(0.25, -10, 0, 34),
			Position = UDim2.new((i - 1) * 0.25, 8, 0, 48), TextSize = 14 }, function()
				show(t[1])
			end)
	end
	refs.page = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -92), Position = UDim2.fromOffset(0, 92), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = c })
	UI.pad(refs.page, 12)
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.page })
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	show(tab or "upgrades")
end

-- money or ownership changed: redraw the page
function SharkMartApp.refresh()
	if refs then
		show(refs.tab)
	end
end

return SharkMartApp
