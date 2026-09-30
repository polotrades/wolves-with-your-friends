-- Files: a file explorer. Sidebar (Desktop, Documents, Photos, Downloads, Recycle Bin), back / up, a path bar,
-- big icons, double-click to open, and Delete / Restore. Documents open in a viewer, notes in Notes, photos in a
-- photo viewer. Running a downloaded .exe is... not a great idea.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local FileSystem = require(Client:WaitForChild("FileSystem"))
local Photo = require(Client:WaitForChild("Photo"))
local NotesApp = require(script.Parent:WaitForChild("NotesApp"))
local Adware = require(script.Parent:WaitForChild("Adware"))

local FilesApp = {}
local win, refs

local function viewText(item)
	local w = Desktop.window("files", item.name, Vector2.new(520, 440))
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(250, 250, 252), BorderSizePixel = 0,
		Parent = w.content })
	local scroll = UI.new("ScrollingFrame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = w.content })
	UI.pad(scroll, 16)
	UI.label(scroll, item.text or "", 15, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
		TextColor3 = Color3.fromRGB(30, 30, 40), TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.RobotoMono })
end

local function viewPhoto(item)
	local w = Desktop.window("files", item.name, Vector2.new(520, 420))
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(12, 12, 14), BorderSizePixel = 0,
		Parent = w.content })
	local holder = UI.new("Frame", { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1, Parent = w.content })
	UI.new("UIAspectRatioConstraint", { AspectRatio = 4 / 3, Parent = holder })
	Photo.render(holder, item.photo)
end

function FilesApp.openItem(item)
	if item.kind == "folder" then
		FilesApp.open(item)
	elseif item.kind == "note" then
		NotesApp.open(item)
	elseif item.kind == "photo" and item.photo then
		viewPhoto(item)
	elseif item.kind == "exe" then
		Desktop.notify("Oops.", item.name .. " was definitely a virus. Run the antivirus!", "☠️")
		Adware.spawn(3)
	else
		viewText(item)
	end
end

local function show(folder)
	if not refs then
		return
	end
	if refs.folder ~= folder then
		table.insert(refs.history, refs.folder)
	end
	refs.folder = folder
	refs.selected = nil
	refs.path.Text = "  " .. FileSystem.path(folder)
	win:setTitle(folder.name .. " - Files")
	for _, c in refs.grid:GetChildren() do
		if c:IsA("GuiButton") then
			c:Destroy()
		end
	end
	for name, b in refs.side do
		b.BackgroundTransparency = name == folder.name and 0 or 1
	end
	local children = folder.children or {}
	refs.empty.Visible = #children == 0
	refs.restore.Visible = folder == FileSystem.bin
	for i, item in children do
		local b = UI.new("TextButton", { Name = item.name, Text = "", AutoButtonColor = false, BackgroundColor3 = UI.os.accent,
			BackgroundTransparency = 1, LayoutOrder = i, Parent = refs.grid })
		UI.corner(b, 4)
		if item.kind == "photo" and item.photo then
			local thumb = UI.new("Frame", { Size = UDim2.fromOffset(64, 48), Position = UDim2.new(0.5, -32, 0, 8),
				BackgroundTransparency = 1, Parent = b })
			Photo.render(thumb, item.photo)
		else
			UI.icon(b, FileSystem.GLYPHS[item.kind] or "📄", FileSystem.COLORS[item.kind] or UI.os.surface3, 48,
				{ Position = UDim2.new(0.5, -24, 0, 6) })
		end
		UI.label(b, item.name, 12, { Size = UDim2.new(1, -4, 0, 32), Position = UDim2.new(0, 2, 0, 60), TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top,
			TextTruncate = Enum.TextTruncate.AtEnd })
		local last = 0
		b.Activated:Connect(function()
			local now = os.clock()
			if now - last < 0.4 then
				FilesApp.openItem(item)
				last = 0
				return
			end
			last = now
			if refs.selected and refs.selected.button.Parent then
				refs.selected.button.BackgroundTransparency = 1
			end
			refs.selected = { item = item, button = b }
			b.BackgroundTransparency = 0.7
			refs.status.Text = string.format("  %s   ·   %s   ·   %s", item.name, item.kind, item.created)
		end)
	end
	refs.status.Text = string.format("  %d items", #children)
end

function FilesApp.open(folder: any?)
	if win and not win.closed then
		win:setMinimized(false)
		if folder then
			show(folder)
		end
		return
	end
	win = Desktop.window("files", "Files", Vector2.new(700, 460))
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	refs = { history = {}, side = {} }
	-- toolbar
	local tools = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = UI.os.title, BorderSizePixel = 0, Parent = c })
	UI.flat(tools, "←", UI.os.surface2, { Size = UDim2.fromOffset(32, 28), Position = UDim2.fromOffset(8, 6), TextSize = 18 }, function()
		local prev = table.remove(refs.history)
		if prev then
			show(prev)
			table.remove(refs.history)
		end
	end)
	UI.flat(tools, "↑", UI.os.surface2, { Size = UDim2.fromOffset(32, 28), Position = UDim2.fromOffset(44, 6), TextSize = 18 }, function()
		if refs.folder.parent then
			show(refs.folder.parent)
		end
	end)
	refs.path = UI.label(tools, "", 13, { Size = UDim2.new(1, -330, 0, 28), Position = UDim2.fromOffset(84, 6),
		BackgroundTransparency = 0, BackgroundColor3 = UI.os.surface2, TextTruncate = Enum.TextTruncate.AtEnd })
	UI.corner(refs.path, 6)
	UI.flat(tools, "＋ Folder", UI.os.surface2, { Size = UDim2.fromOffset(74, 28), Position = UDim2.new(1, -236, 0, 6), TextSize = 13 },
		function()
			if refs.folder ~= FileSystem.bin and refs.folder ~= FileSystem.root then
				local f = FileSystem.newItem("folder", FileSystem.uniqueName(refs.folder, "New folder", ""))
				f.children = {}
				FileSystem.add(refs.folder, f)
				show(refs.folder)
			end
		end)
	refs.restore = UI.flat(tools, "Restore", UI.os.surface2, { Size = UDim2.fromOffset(70, 28), Position = UDim2.new(1, -158, 0, 6),
		TextSize = 13 }, function()
			if refs.selected then
				FileSystem.restore(refs.selected.item, FileSystem.documents)
				show(refs.folder)
			end
		end)
	UI.flat(tools, "🗑 Delete", Color3.fromRGB(170, 50, 50), { Size = UDim2.fromOffset(78, 28), Position = UDim2.new(1, -84, 0, 6),
		TextSize = 13 }, function()
			local sel = refs.selected
			if sel and sel.item.parent ~= FileSystem.root then
				FileSystem.delete(sel.item)
				show(refs.folder)
			end
		end)
	-- sidebar
	local side = UI.new("Frame", { Size = UDim2.new(0, 160, 1, -64), Position = UDim2.fromOffset(0, 40),
		BackgroundColor3 = UI.os.title, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = c })
	UI.pad(side, 6)
	UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = side })
	for i, f in { FileSystem.root, FileSystem.desktop, FileSystem.documents, FileSystem.photos, FileSystem.downloads, FileSystem.bin } do
		local glyph = f == FileSystem.root and "💻" or f == FileSystem.bin and "🗑️" or f == FileSystem.photos and "🖼️"
			or f == FileSystem.downloads and "⬇️" or f == FileSystem.desktop and "🖥️" or "📁"
		local b = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = UI.os.surface3, BackgroundTransparency = 1,
			Text = "  " .. glyph .. "  " .. f.name, Font = UI.body, TextSize = 14, TextColor3 = UI.os.text, AutoButtonColor = false,
			TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, Parent = side })
		UI.corner(b, 4)
		refs.side[f.name] = b
		b.Activated:Connect(function()
			show(f)
		end)
	end
	-- files
	refs.grid = UI.new("ScrollingFrame", { Size = UDim2.new(1, -170, 1, -70), Position = UDim2.fromOffset(166, 44),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = c })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(96, 100), CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.grid })
	refs.empty = UI.label(c, "This folder is empty.", 14, { Size = UDim2.new(1, -170, 0, 20), Position = UDim2.fromOffset(170, 80),
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.os.dim, Visible = false })
	refs.status = UI.label(c, "", 12, { Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -24), BackgroundTransparency = 0,
		BackgroundColor3 = UI.os.title, TextColor3 = UI.os.dim })
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	refs.folder = folder or FileSystem.root
	show(refs.folder)
	refs.history = {}
end

return FilesApp
