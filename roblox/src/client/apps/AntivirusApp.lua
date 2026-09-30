-- Shark Shield: a pretend antivirus. Scan finds pop-up ads, shady downloads and a few harmless jokes;
-- Clean closes the ads and moves the bad files to the Recycle Bin.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local FileSystem = require(Client:WaitForChild("FileSystem"))
local Adware = require(script.Parent:WaitForChild("Adware"))

local AntivirusApp = {}
local win
local SCAN_NAMES = { "System32-ish", "Desktop", "Documents", "Downloads", "Photos", "Browser cookies", "Coffee machine",
	"The fish tank", "Chairman's golden stapler", "Registry of Registries" }
local JOKES = { "tracking.cookie (chocolate chip, harmless)", "suspicion.log (you're fine... for now)",
	"banana.dll (it's just a banana)" }

local GREEN = Color3.fromRGB(40, 190, 110)

function AntivirusApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	win = Desktop.window("antivirus", "Shark Shield", Vector2.new(460, 440))
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	UI.pad(c, 16)
	local shield = UI.text(c, "🛡️", { Size = UDim2.fromOffset(70, 70) })
	local headline = UI.label(c, "You're protected", 22, { Size = UDim2.new(1, -86, 0, 28), Position = UDim2.fromOffset(86, 6),
		Font = UI.bold, TextColor3 = GREEN })
	local sub = UI.label(c, State.has("shieldpro") and "Shark Shield PRO · real-time pop-up blocking ON"
		or "Free edition · upgrade to Pro in Shark Mart", 13, { Size = UDim2.new(1, -86, 0, 18), Position = UDim2.fromOffset(86, 40),
		TextColor3 = UI.os.dim })
	local barBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 8), Position = UDim2.fromOffset(0, 90), BackgroundColor3 = UI.os.surface3,
		BorderSizePixel = 0, Parent = c })
	UI.corner(barBack, 4)
	local bar = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.os.accent, BorderSizePixel = 0, Parent = barBack })
	UI.corner(bar, 4)
	local scanning = UI.label(c, "", 13, { Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 104), TextColor3 = UI.os.dim })
	local list = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -190), Position = UDim2.fromOffset(0, 128),
		BackgroundColor3 = UI.os.title, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = c })
	UI.corner(list, 6)
	UI.pad(list, 8)
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	local busy = false
	local found = {}
	local clean
	local scan = UI.flat(c, "Quick scan", UI.os.accent, { Size = UDim2.new(0.5, -4, 0, 44), Position = UDim2.new(0, 0, 1, -48) })
	clean = UI.flat(c, "Clean threats", UI.os.surface3, { Size = UDim2.new(0.5, -4, 0, 44), Position = UDim2.new(0.5, 4, 1, -48) })
	local function row(text: string, color: Color3)
		UI.label(list, text, 13, { TextColor3 = color, LayoutOrder = #list:GetChildren(), TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y })
	end
	scan.Activated:Connect(function()
		if busy then
			return
		end
		busy = true
		for _, l in list:GetChildren() do
			if l:IsA("TextLabel") then
				l:Destroy()
			end
		end
		found = {}
		headline.Text, headline.TextColor3 = "Scanning...", UI.os.text
		for i, name in SCAN_NAMES do
			if not win or win.closed then
				return
			end
			scanning.Text = "Scanning: " .. name
			bar.Size = UDim2.fromScale(i / #SCAN_NAMES, 1)
			task.wait(0.25)
		end
		local ads = Adware.count()
		if ads > 0 then
			table.insert(found, "ads")
			row(string.format("⚠️  %d pop-up ad window%s (Adware.PumpAds)", ads, ads == 1 and "" or "s"), UI.colors.orange)
		end
		for _, item in FileSystem.downloads.children or {} do
			if item.kind == "exe" then
				table.insert(found, item)
				row("⚠️  " .. item.name .. " (Trojan.TotallyLegit)", UI.colors.red)
			end
		end
		row("ℹ️  " .. JOKES[math.random(#JOKES)], UI.os.dim)
		scanning.Text = "Scan complete."
		if #found == 0 then
			headline.Text, headline.TextColor3 = "No threats found", GREEN
			shield.Text = "🛡️"
		else
			headline.Text, headline.TextColor3 = #found .. " threat" .. (#found == 1 and "" or "s") .. " found", UI.colors.red
			shield.Text = "⚠️"
			clean.BackgroundColor3 = UI.colors.red
		end
		busy = false
	end)
	clean.Activated:Connect(function()
		if busy or #found == 0 then
			return
		end
		local ads = Adware.clearAll()
		local files = 0
		for _, f in found do
			if type(f) == "table" and f.parent then
				FileSystem.delete(f)
				files += 1
			end
		end
		found = {}
		row(string.format("✅  Closed %d ad%s, quarantined %d file%s.", ads, ads == 1 and "" or "s", files, files == 1 and "" or "s"),
			GREEN)
		headline.Text, headline.TextColor3 = "You're protected", GREEN
		shield.Text = "🛡️"
		clean.BackgroundColor3 = UI.os.surface3
		sub.Text = sub.Text
	end)
	win:addCloseHandler(function()
		win = nil
	end)
end

return AntivirusApp
