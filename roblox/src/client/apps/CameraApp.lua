-- Camera: a live self-view from the desk webcam (a copy of your character in a ViewportFrame, posed every frame),
-- with Normal / Warm / Cool / Noir filters. SNAP saves the shot to Files › Photos.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local FileSystem = require(Client:WaitForChild("FileSystem"))
local Photo = require(Client:WaitForChild("Photo"))

local CameraApp = {}
local player = Players.LocalPlayer
local win, refs

-- where the desk webcam sits (top of this desk's monitor), looking at the chair
local function webcam(): CFrame?
	local floor = Workspace:FindFirstChild("Floor100")
	local desk = State.deskId and floor and floor:FindFirstChild("Desk" .. State.deskId)
	local monitor = desk and desk:FindFirstChild("Monitor") :: BasePart?
	local char = player.Character
	local head = char and char:FindFirstChild("Head") :: BasePart?
	if monitor then
		local pos = monitor.Position + monitor.CFrame.UpVector * (monitor.Size.Y / 2 + 0.2) + monitor.CFrame.LookVector * 0.15
		local target = head and head.Position - Vector3.new(0, 0.6, 0) or (pos + monitor.CFrame.LookVector * 5)
		return CFrame.lookAt(pos, target)
	elseif head then
		return CFrame.lookAt(head.Position + head.CFrame.LookVector * 4, head.Position)
	end
	return nil
end

-- copy the character into the viewport and pair each copied part with the real one
local function rebuild()
	if refs.clone then
		refs.clone:Destroy()
		refs.clone = nil
	end
	if refs.backdrop then
		refs.backdrop:Destroy()
		refs.backdrop = nil
	end
	refs.pairs = {}
	local char = player.Character
	local cam = webcam()
	if not char or not cam then
		refs.hint.Text = "No camera found. Sit at a desk first."
		return
	end
	refs.hint.Text = ""
	char.Archivable = true
	local ok, copy = pcall(function()
		return char:Clone()
	end)
	if not ok or not copy then
		refs.hint.Text = "Camera error."
		return
	end
	for _, d in copy:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("JointInstance") or d:IsA("Constraint") or d:IsA("Sound") or d:IsA("ProximityPrompt") or d:IsA("BillboardGui") then
			d:Destroy()
		end
	end
	-- pair parts by their path inside the model ("Head", "Hat.Handle", ...)
	local function rel(inst: Instance, root: Instance): string
		local parts = {}
		local cur: Instance? = inst
		while cur and cur ~= root do
			table.insert(parts, 1, cur.Name)
			cur = cur.Parent
		end
		return table.concat(parts, ".")
	end
	local byPath = {}
	for _, d in copy:GetDescendants() do
		if d:IsA("BasePart") then
			byPath[rel(d, copy)] = d
		end
	end
	for _, s in char:GetDescendants() do
		if s:IsA("BasePart") then
			local d = byPath[rel(s, char)]
			if d then
				d.Anchored = true
				d.LocalTransparencyModifier = 0
				table.insert(refs.pairs, { s, d })
			end
		end
	end
	if refs.filter == "Noir" then
		Photo.desaturate(copy)
	end
	copy.Parent = refs.world
	refs.clone = copy
	refs.backdrop = Photo.backdrop(cam, refs.world)
	if refs.filter == "Noir" then
		Photo.desaturate(refs.backdrop)
	end
	Photo.apply(refs.vp, refs.filter)
	refs.camera.CFrame = cam
end

local function snap()
	if not refs.clone then
		return
	end
	local shot = Instance.new("Model")
	shot.Name = "Photo"
	refs.clone:Clone().Parent = shot
	if refs.backdrop then
		refs.backdrop:Clone().Parent = shot
	end
	local name = FileSystem.uniqueName(FileSystem.photos, "Selfie", ".png")
	local item = FileSystem.newItem("photo", name)
	item.photo = { model = shot, cam = refs.camera.CFrame, filter = refs.filter }
	FileSystem.add(FileSystem.photos, item)
	-- shutter flash
	refs.flash.BackgroundTransparency = 0
	TweenService:Create(refs.flash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	Desktop.notify("Camera", "Saved to Files › Photos › " .. name, "📸")
end

function CameraApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	win = Desktop.window("camera", "Camera", Vector2.new(560, 500), nil, false)
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 10, 12), BorderSizePixel = 0, Parent = c })
	refs = { filter = "Normal", pairs = {}, filterButtons = {} }
	local view = UI.new("Frame", { Size = UDim2.new(1, -20, 1, -110), Position = UDim2.fromOffset(10, 10), BackgroundTransparency = 1,
		Parent = c })
	refs.vp = UI.new("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 30, 35), Parent = view })
	UI.corner(refs.vp, 8)
	refs.camera = UI.new("Camera", { FieldOfView = 55, Parent = refs.vp })
	refs.vp.CurrentCamera = refs.camera
	refs.world = UI.new("WorldModel", { Parent = refs.vp })
	refs.flash = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1,
		ZIndex = 5, Parent = view })
	UI.label(view, "● LIVE", 13, { Size = UDim2.fromOffset(80, 20), Position = UDim2.fromOffset(10, 8), Font = UI.bold,
		TextColor3 = UI.colors.red, ZIndex = 4 })
	refs.hint = UI.label(view, "", 15, { Position = UDim2.new(0, 0, 0.5, -10), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	-- filters
	for i, f in Photo.FILTERS do
		refs.filterButtons[f] = UI.flat(c, f, UI.os.surface2, { Size = UDim2.new(0.18, -6, 0, 34),
			Position = UDim2.new((i - 1) * 0.18, 10, 1, -92), TextSize = 14 }, function()
				refs.filter = f
				for name, b in refs.filterButtons do
					b.BackgroundColor3 = name == f and UI.os.accent or UI.os.surface2
				end
				rebuild()
			end)
	end
	refs.filterButtons.Normal.BackgroundColor3 = UI.os.accent
	local shutter = UI.flat(c, "📸 SNAP", Color3.fromRGB(220, 50, 60), { Size = UDim2.new(0.28, -10, 0, 34),
		Position = UDim2.new(0.72, 0, 1, -92), TextSize = 16 }, snap)
	shutter.TextColor3 = Color3.new(1, 1, 1)
	UI.label(c, "Your desk webcam. Snaps are saved to Files › Photos.", 12, { Position = UDim2.new(0, 10, 1, -48),
		TextColor3 = UI.os.dim })
	rebuild()
	refs.conn = RunService.RenderStepped:Connect(function()
		for _, p in refs.pairs do
			p[2].CFrame = p[1].CFrame
		end
		local cam = webcam()
		if cam then
			refs.camera.CFrame = cam
		end
	end)
	win:addCloseHandler(function()
		refs.conn:Disconnect()
		refs = nil
		win = nil
	end)
end

return CameraApp
