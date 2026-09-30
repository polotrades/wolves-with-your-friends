-- Notes: quick notes saved as files in Documents. Handy for writing down what a caller told you.
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local FileSystem = require(Client:WaitForChild("FileSystem"))

local NotesApp = {}
local win, refs

local function notes()
	local out = {}
	for _, item in FileSystem.documents.children or {} do
		if item.kind == "note" then
			table.insert(out, item)
		end
	end
	return out
end

local function select(item)
	if not refs then
		return
	end
	refs.current = item
	refs.title.Text = item and item.name or ""
	refs.editor.Text = item and (item.text or "") or ""
	refs.editor.TextEditable = item ~= nil
	refs.editor.PlaceholderText = item and "Start typing..." or "Make a new note with +"
	for _, b in refs.list:GetChildren() do
		if b:IsA("GuiButton") then
			b.BackgroundTransparency = (item and b.Name == item.name) and 0 or 1
		end
	end
end

local function refreshList()
	if not refs then
		return
	end
	for _, b in refs.list:GetChildren() do
		if b:IsA("GuiButton") then
			b:Destroy()
		end
	end
	for i, item in notes() do
		local b = UI.new("TextButton", { Name = item.name, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = UI.os.surface3,
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = refs.list })
		UI.corner(b, 6)
		UI.label(b, item.name:gsub("%.txt$", ""), 14, { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -16, 0, 18),
			Font = UI.bold, TextTruncate = Enum.TextTruncate.AtEnd })
		UI.label(b, ((item.text or ""):gsub("\n", " ")):sub(1, 40), 12, { Position = UDim2.fromOffset(10, 22),
			Size = UDim2.new(1, -16, 0, 16), TextColor3 = UI.os.dim, TextTruncate = Enum.TextTruncate.AtEnd })
		b.Activated:Connect(function()
			select(item)
		end)
	end
	select(refs.current)
end

local function newNote(text: string?)
	local item = FileSystem.newItem("note", FileSystem.uniqueName(FileSystem.documents, "Note", ".txt"), text or "")
	FileSystem.add(FileSystem.documents, item)
	refs.current = item
	refreshList()
end

function NotesApp.open(item: any?)
	if not (win and not win.closed) then
		win = Desktop.window("notes", "Notes", Vector2.new(560, 420))
		local c = win.content
		UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(34, 32, 28), BorderSizePixel = 0, Parent = c })
		refs = {}
		local side = UI.new("Frame", { Size = UDim2.new(0, 180, 1, 0), BackgroundColor3 = Color3.fromRGB(28, 26, 22),
			BorderSizePixel = 0, Parent = c })
		UI.flat(side, "＋ New note", Color3.fromRGB(200, 150, 30), { Size = UDim2.new(1, -16, 0, 32), Position = UDim2.fromOffset(8, 8) },
			function()
				newNote()
			end)
		refs.list = UI.new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -52), Position = UDim2.fromOffset(4, 48),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = side })
		UI.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.list })
		refs.title = UI.label(c, "", 16, { Size = UDim2.new(1, -330, 0, 26), Position = UDim2.fromOffset(192, 8), Font = UI.bold,
			TextTruncate = Enum.TextTruncate.AtEnd })
		UI.flat(c, "Caller", UI.os.surface3, { Size = UDim2.fromOffset(62, 26), Position = UDim2.new(1, -140, 0, 8), TextSize = 13 },
			function()
				-- drop the current caller's name into the note
				if refs.current and State.call then
					refs.editor.Text ..= (refs.editor.Text == "" and "" or "\n") .. State.call.name .. " (" .. State.call.kind .. "): "
				end
			end)
		UI.flat(c, "🗑", UI.os.surface3, { Size = UDim2.fromOffset(62, 26), Position = UDim2.new(1, -72, 0, 8) }, function()
			if refs.current then
				FileSystem.delete(refs.current)
				refs.current = nil
				refreshList()
			end
		end)
		refs.editor = UI.new("TextBox", { Size = UDim2.new(1, -200, 1, -52), Position = UDim2.fromOffset(192, 42),
			BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(245, 235, 200), PlaceholderColor3 = UI.os.dim, Font = UI.body,
			TextSize = 16, MultiLine = true, TextWrapped = true, ClearTextOnFocus = false, Text = "",
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = c })
		refs.editor:GetPropertyChangedSignal("Text"):Connect(function()
			if refs and refs.current and refs.current.text ~= refs.editor.Text then
				refs.current.text = refs.editor.Text
			end
		end)
		refs.editor.FocusLost:Connect(function()
			FileSystem.touched()
			refreshList()
		end)
		win:addCloseHandler(function()
			refs = nil
			win = nil
		end)
		if #notes() == 0 then
			newNote("Call notes\n\n")
		end
		refs.current = notes()[1]
	else
		win:setMinimized(false)
	end
	if item then
		refs.current = item
	end
	refreshList()
end

return NotesApp
