-- Pop-up ads: PumpAds campaigns (and suspicious downloads) spray silly ad windows over your own desktop.
-- Close them one by one, or let the antivirus clean them all. Shark Shield Pro blocks them outright.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))

local Adware = {}
local popups = {}

local ADS = {
	{ "🍌 BANANA MOON MINING", "Bananas. On the moon. Buy now before the moon runs out!", Color3.fromRGB(250, 210, 40) },
	{ "🦆 DUCK CORP", "Quack quack quack. (That means BUY in duck.)", Color3.fromRGB(80, 190, 250) },
	{ "🛥️ YACHT FUTURES", "Your future yacht is calling. Pick up!", Color3.fromRGB(40, 120, 220) },
	{ "🍞 TOAST HOLDINGS", "Toast only goes UP. Like toast. From a toaster.", Color3.fromRGB(230, 150, 70) },
	{ "💰 YOU WON!!!", "You are the 1,000,000th visitor! Your prize: this pop-up.", Color3.fromRGB(80, 200, 110) },
	{ "🔥 HOT STOCK ALERT", "A stock is hot. Which one? Click to find out. (Don't.)", Color3.fromRGB(240, 80, 60) },
}

function Adware.count(): number
	local n = 0
	for w in popups do
		if not w.closed then
			n += 1
		end
	end
	return n
end

function Adware.spawn(n: number)
	if State.has("shieldpro") then
		Desktop.notify("Shark Shield Pro", string.format("Blocked %d pop-up ad%s.", n, n == 1 and "" or "s"), "🛡️")
		return
	end
	local rng = Random.new()
	local host = Desktop.host()
	for i = 1, n do
		task.delay((i - 1) * 0.35, function()
			local ad = ADS[rng:NextInteger(1, #ADS)]
			local size = host.AbsoluteSize
			local pos = UDim2.fromOffset(rng:NextInteger(40, math.max(60, size.X - 380)), rng:NextInteger(10, math.max(20, size.Y - 260)))
			local w = Desktop.window("adware", "Special Offer!!!", Vector2.new(320, 210), pos, false)
			popups[w] = true
			w:addCloseHandler(function()
				popups[w] = nil
			end)
			local c = w.content
			UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = ad[3], BorderSizePixel = 0, Parent = c })
			UI.text(c, ad[1], { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 10), TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0.3 })
			UI.label(c, ad[2], 15, { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.fromOffset(10, 56), TextWrapped = true,
				TextColor3 = Color3.fromRGB(20, 20, 30), Font = UI.bold })
			UI.flat(c, "BUY NOW!!!", Color3.fromRGB(220, 30, 40), { Size = UDim2.new(1, -20, 0, 40), Position = UDim2.new(0, 10, 1, -50) },
				function()
					Desktop.notify("Nice try", "The ad multiplied.", "😈")
					Adware.spawn(1)
				end)
		end)
	end
end

function Adware.clearAll(): number
	local n = 0
	for w in popups do
		if not w.closed then
			w:close()
			n += 1
		end
	end
	table.clear(popups)
	return n
end

return Adware
