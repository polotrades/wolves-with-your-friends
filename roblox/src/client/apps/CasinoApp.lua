-- Wolf Casino: the Shark OS minigame. Deposit Personal money into a casino wallet, then play Up or Down (guess the
-- next candle) or Stock Slots. Every result is decided on the server. Cash out moves the wallet back to Personal.
-- Uses only in-game money (never Robux) and winnings never count toward the firm's target.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local CasinoApp = { wallet = 0 }
local GOLD = Color3.fromRGB(230, 180, 40)
local FELT = Color3.fromRGB(16, 70, 45)
local BETS = { 10, 50, 100, 250 }
local SYMBOLS = { "🍌", "🦆", "🛥️", "💰", "🐺" }

local win, refs

local function setWallet()
	if refs then
		refs.wallet.Text = "WALLET " .. UI.money(CasinoApp.wallet)
		refs.personal.Text = "Personal " .. UI.money(State.personal)
	end
end

local function message(text: string, color: Color3?)
	if refs then
		refs.msg.Text = text
		refs.msg.TextColor3 = color or UI.os.text
	end
end

local function page(name: string)
	refs.game = name
	refs.updown.Visible = name == "updown"
	refs.slots.Visible = name == "slots"
	refs.tabUp.BackgroundColor3 = name == "updown" and GOLD or UI.os.surface2
	refs.tabSlots.BackgroundColor3 = name == "slots" and GOLD or UI.os.surface2
end

-- a little chart for Up or Down: previous candles plus the one that's about to be revealed
local function drawCandles(history: { boolean })
	for _, c in refs.chart:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local y = 0.5
	for i, up in history do
		local h = 0.12
		local top = up and (y - h) or y
		local f = UI.new("Frame", { Size = UDim2.fromScale(0.05, h), Position = UDim2.fromScale(0.04 + (i - 1) * 0.075, top),
			BackgroundColor3 = up and Color3.fromRGB(40, 230, 110) or Color3.fromRGB(255, 70, 80), BorderSizePixel = 0,
			Parent = refs.chart })
		UI.corner(f, 2)
		y = up and (y - h) or (y + h)
		y = math.clamp(y, 0.2, 0.8)
	end
end

local function build()
	win = Desktop.window("casino", "Wolf Casino", Vector2.new(480, 520), nil, false)
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = FELT, BorderSizePixel = 0, Parent = c })
	UI.pad(c, 12)
	refs = { bet = 1, history = {} }
	UI.label(c, "🎰 WOLF CASINO", 20, { Size = UDim2.new(0.6, 0, 0, 26), Font = UI.bold, TextColor3 = GOLD })
	refs.wallet = UI.label(c, "", 16, { Size = UDim2.new(0.4, 0, 0, 22), Position = UDim2.new(0.6, 0, 0, 0), Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Right })
	refs.personal = UI.label(c, "", 12, { Size = UDim2.new(0.4, 0, 0, 16), Position = UDim2.new(0.6, 0, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(190, 230, 200) })
	-- wallet: deposit / cash out
	local row = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 44), BackgroundTransparency = 1, Parent = c })
	for i, amount in { 100, 500 } do
		UI.flat(row, "Deposit " .. UI.money(amount), Color3.fromRGB(30, 120, 80), { Size = UDim2.new(1 / 3, -6, 1, 0),
			Position = UDim2.new((i - 1) / 3, 0, 0, 0), TextSize = 13 }, function()
				if State.personal < amount then
					message("Not enough Personal money to deposit that.", UI.colors.red)
					return
				end
				Net.Casino:FireServer("deposit", amount)
			end)
	end
	UI.flat(row, "Cash out", GOLD, { Size = UDim2.new(1 / 3, -6, 1, 0), Position = UDim2.new(2 / 3, 0, 0, 0), TextSize = 13,
		TextColor3 = Color3.fromRGB(40, 30, 0) }, function()
			Net.Casino:FireServer("cashout")
		end)
	-- game tabs
	refs.tabUp = UI.flat(c, "📈 Up or Down", UI.os.surface2, { Size = UDim2.new(0.5, -4, 0, 30), Position = UDim2.fromOffset(0, 88),
		TextSize = 14 }, function()
			page("updown")
		end)
	refs.tabSlots = UI.flat(c, "🎰 Stock Slots", UI.os.surface2, { Size = UDim2.new(0.5, -4, 0, 30),
		Position = UDim2.new(0.5, 4, 0, 88), TextSize = 14 }, function()
			page("slots")
		end)
	-- Up or Down
	refs.updown = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 220), Position = UDim2.fromOffset(0, 126), BackgroundTransparency = 1,
		Parent = c })
	refs.chart = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = Color3.fromRGB(8, 20, 16), Parent = refs.updown })
	UI.corner(refs.chart, 8)
	UI.label(refs.updown, "Will the next candle go up or down? Pays 1.9×", 13, { Position = UDim2.fromOffset(0, 154),
		TextColor3 = Color3.fromRGB(190, 230, 200) })
	UI.flat(refs.updown, "▲ UP", Color3.fromRGB(30, 170, 90), { Size = UDim2.new(0.5, -4, 0, 40), Position = UDim2.fromOffset(0, 178) },
		function()
			Net.Casino:FireServer("updown", BETS[refs.bet], "up")
		end)
	UI.flat(refs.updown, "▼ DOWN", Color3.fromRGB(200, 50, 60), { Size = UDim2.new(0.5, -4, 0, 40),
		Position = UDim2.new(0.5, 4, 0, 178) }, function()
			Net.Casino:FireServer("updown", BETS[refs.bet], "down")
		end)
	-- Slots
	refs.slots = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 220), Position = UDim2.fromOffset(0, 126), BackgroundTransparency = 1,
		Visible = false, Parent = c })
	refs.reels = {}
	for i = 1, 3 do
		local r = UI.new("Frame", { Size = UDim2.new(1 / 3, -8, 0, 120), Position = UDim2.new((i - 1) / 3, 4, 0, 0),
			BackgroundColor3 = Color3.fromRGB(250, 245, 230), Parent = refs.slots })
		UI.corner(r, 10)
		UI.new("UIStroke", { Color = GOLD, Thickness = 3, Parent = r })
		refs.reels[i] = UI.text(r, SYMBOLS[i], { Size = UDim2.fromScale(0.7, 0.7), Position = UDim2.fromScale(0.15, 0.15) })
	end
	UI.label(refs.slots, "3× 🐺 20×  ·  3× 💰 10×  ·  3× 🛥️ 6×  ·  3× 🦆 4×  ·  3× 🍌 3×  ·  any pair 1.3×", 12, {
		Position = UDim2.fromOffset(0, 126), TextWrapped = true, Size = UDim2.new(1, 0, 0, 32), TextColor3 = Color3.fromRGB(190, 230, 200) })
	UI.flat(refs.slots, "PULL", GOLD, { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 172),
		TextColor3 = Color3.fromRGB(40, 30, 0), TextSize = 20 }, function()
			if refs.spinning then
				return
			end
			Net.Casino:FireServer("slots", BETS[refs.bet])
		end)
	-- bet size
	UI.label(c, "BET", 12, { Size = UDim2.fromOffset(40, 30), Position = UDim2.new(0, 0, 1, -82), Font = UI.bold,
		TextColor3 = Color3.fromRGB(190, 230, 200) })
	refs.betButtons = {}
	for i, amount in BETS do
		refs.betButtons[i] = UI.flat(c, UI.money(amount), UI.os.surface2, { Size = UDim2.new(0.25, -12, 0, 30),
			Position = UDim2.new((i - 1) * 0.25, 40 - (i - 1) * 10, 1, -82), TextSize = 14 }, function()
				refs.bet = i
				for j, b in refs.betButtons do
					b.BackgroundColor3 = j == i and GOLD or UI.os.surface2
				end
			end)
	end
	refs.betButtons[1].BackgroundColor3 = GOLD
	refs.msg = UI.label(c, "Deposit Personal money to play. Only in-game cash, never Robux.", 14, { Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -44), TextWrapped = true, Font = UI.bold, TextXAlignment = Enum.TextXAlignment.Center })
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	page("updown")
	for _ = 1, 8 do
		table.insert(refs.history, math.random() < 0.5)
	end
	drawCandles(refs.history)
	setWallet()
end

function CasinoApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	build()
	Net.Casino:FireServer("wallet")
end

function CasinoApp.result(r)
	CasinoApp.wallet = r.wallet or CasinoApp.wallet
	if not refs then
		return
	end
	if r.error then
		message(r.error, UI.colors.red)
		setWallet()
		return
	end
	if r.game == "updown" then
		table.insert(refs.history, r.up)
		if #refs.history > 12 then
			table.remove(refs.history, 1)
		end
		drawCandles(refs.history)
		if r.win > 0 then
			message(string.format("%s! You win %s.", r.up and "UP" or "DOWN", UI.money(r.win)), UI.colors.green)
			UI.sound("success", 0.5)
		else
			message(string.format("%s. You lose %s.", r.up and "UP" or "DOWN", UI.money(r.bet)), UI.colors.red)
			UI.sound("error", 0.4)
		end
		setWallet()
	elseif r.game == "slots" then
		refs.spinning = true
		message("Spinning...", UI.os.text)
		-- spin each reel, stopping left to right on the server's result
		for i, reel in refs.reels do
			task.spawn(function()
				local stopAt = os.clock() + 0.6 + i * 0.35
				while os.clock() < stopAt and refs do
					reel.Text = SYMBOLS[math.random(#SYMBOLS)]
					task.wait(0.06)
				end
				reel.Text = r.reels[i]
				local s = Instance.new("UIScale")
				s.Scale = 1.25
				s.Parent = reel
				TweenService:Create(s, TweenInfo.new(0.15), { Scale = 1 }):Play()
			end)
		end
		task.delay(0.6 + 3 * 0.35 + 0.1, function()
			if not refs then
				return
			end
			refs.spinning = false
			if r.win > 0 then
				message("WIN " .. UI.money(r.win) .. "!", UI.colors.green)
				UI.sound("success", 0.6)
			else
				message("No luck. Lost " .. UI.money(r.bet) .. ".", UI.colors.red)
				UI.sound("error", 0.4)
			end
			setWallet()
		end)
	else
		if r.note then
			message(r.note, UI.colors.green)
		end
		setWallet()
	end
end

function CasinoApp.refresh()
	setWallet()
end

return CasinoApp
