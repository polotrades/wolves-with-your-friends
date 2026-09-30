-- Backgrounds: pick a desktop wallpaper. Premium ones are locked until you buy them in Shark Mart's Store.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local Wallpapers = require(Client:WaitForChild("Wallpapers"))

local BackgroundsApp = {}
local win, grid

local function refresh()
	if not grid then
		return
	end
	for _, c in grid:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	for i, w in Wallpapers.list do
		local locked = w.premium ~= nil and not State.has(w.premium)
		local b = UI.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = UI.os.surface2, LayoutOrder = i,
			Parent = grid })
		UI.corner(b, 8)
		if Desktop.wallpaper() == w.id then
			UI.new("UIStroke", { Color = UI.os.accent, Thickness = 3, Parent = b })
		end
		local thumb = UI.new("Frame", { Size = UDim2.new(1, -12, 0, 92), Position = UDim2.fromOffset(6, 6), Parent = b })
		UI.corner(thumb, 6)
		Wallpapers.draw(thumb, w.id)
		UI.label(b, w.name, 13, { Size = UDim2.new(1, -12, 0, 20), Position = UDim2.fromOffset(8, 102), Font = UI.bold })
		if locked then
			local lock = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
				Parent = thumb })
			lock.ZIndex = 10
			UI.text(lock, "🔒 Shark Mart", { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 0.5, -12), ZIndex = 11 })
		end
		b.Activated:Connect(function()
			if locked then
				Desktop.notify("Locked wallpaper", "Buy " .. w.name .. " in Shark Mart › Store.", "🔒")
				Desktop.openApp("sharkmart")
				return
			end
			Desktop.setWallpaper(w.id)
			refresh()
		end)
	end
end

function BackgroundsApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		refresh()
		return
	end
	win = Desktop.window("backgrounds", "Backgrounds", Vector2.new(600, 470))
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = win.content })
	UI.label(win.content, "   Choose your background", 16, { Size = UDim2.new(1, 0, 0, 36), Font = UI.bold })
	grid = UI.new("ScrollingFrame", { Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 38), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = win.content })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(180, 128), CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	win:addCloseHandler(function()
		win, grid = nil, nil
	end)
	refresh()
end

-- redraw when a premium wallpaper gets unlocked
local lastKey = ""
State.onChange(function()
	local key = ""
	for _, w in Wallpapers.list do
		key ..= (w.premium and State.has(w.premium)) and "1" or "0"
	end
	if key ~= lastKey then
		lastKey = key
		if grid then
			refresh()
		end
	end
end)

return BackgroundsApp
