-- The piano keyboard UI. Opens when you press Play Piano on the grand piano. Click keys or use the home row to
-- play; each press animates the key and asks the server to play the note at the piano so everyone hears it.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(script.Parent:WaitForChild("UI"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Piano = {}
local player = Players.LocalPlayer
local gui, pianoPart, keyByCode = nil, nil, {}

-- 12 notes: C C# D D# E F F# G G# A A# B (black keys are the sharps)
local WHITE = { { 1, "C", Enum.KeyCode.A }, { 3, "D", Enum.KeyCode.S }, { 5, "E", Enum.KeyCode.D },
	{ 6, "F", Enum.KeyCode.F }, { 8, "G", Enum.KeyCode.G }, { 10, "A", Enum.KeyCode.H }, { 12, "B", Enum.KeyCode.J } }
local BLACK = { { 2, "C#", 0 }, { 4, "D#", 1 }, { 7, "F#", 3 }, { 9, "G#", 4 }, { 11, "A#", 5 } }

local function hit(noteIndex: number, keyFrame: GuiObject, down: Color3, up: Color3)
	if pianoPart then
		Net.Piano:FireServer(noteIndex, pianoPart.Position)
	end
	keyFrame.BackgroundColor3 = down
	task.delay(0.12, function()
		if keyFrame.Parent then
			keyFrame.BackgroundColor3 = up
		end
	end)
end

local function close()
	if gui then
		gui:Destroy()
		gui = nil
	end
	keyByCode = {}
	pianoPart = nil
end

local function open(part: BasePart)
	if gui then
		close()
	end
	pianoPart = part
	gui = UI.new("ScreenGui", { Name = "Piano", ResetOnSpawn = false, DisplayOrder = 7, Parent = player:WaitForChild("PlayerGui") })
	local panel = UI.new("Frame", { Size = UDim2.fromOffset(560, 180), AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -20), BackgroundColor3 = Color3.fromRGB(20, 16, 14), Parent = gui })
	UI.corner(panel, 10)
	UI.new("UIStroke", { Color = Color3.fromRGB(200, 160, 60), Thickness = 2, Parent = panel })
	UI.label(panel, "🎹 Grand Piano  ·  click keys or A S D F G H J", 13, { Size = UDim2.new(1, -20, 0, 20),
		Position = UDim2.fromOffset(12, 6), TextColor3 = UI.os.dim })
	UI.flat(panel, "✕", UI.os.surface3, { Size = UDim2.fromOffset(28, 24), Position = UDim2.new(1, -36, 0, 6) }, close)
	local board = UI.new("Frame", { Size = UDim2.new(1, -24, 1, -44), Position = UDim2.fromOffset(12, 34),
		BackgroundTransparency = 1, Parent = panel })
	local whiteW = 1 / #WHITE
	for i, w in WHITE do
		local key = UI.new("TextButton", { Size = UDim2.new(whiteW, -3, 1, 0), Position = UDim2.fromScale((i - 1) * whiteW, 0),
			BackgroundColor3 = Color3.fromRGB(245, 245, 240), Text = w[2], Font = UI.bold, TextSize = 14,
			TextColor3 = Color3.fromRGB(60, 60, 70), TextYAlignment = Enum.TextYAlignment.Bottom, AutoButtonColor = false,
			Parent = board })
		UI.corner(key, 4)
		key.Activated:Connect(function()
			hit(w[1], key, Color3.fromRGB(200, 200, 190), Color3.fromRGB(245, 245, 240))
		end)
		keyByCode[w[3]] = { note = w[1], frame = key, down = Color3.fromRGB(200, 200, 190), up = Color3.fromRGB(245, 245, 240) }
	end
	for _, b in BLACK do
		local key = UI.new("TextButton", { Size = UDim2.new(whiteW * 0.6, 0, 0.62, 0),
			Position = UDim2.fromScale((b[3] + 1) * whiteW - whiteW * 0.3, 0), BackgroundColor3 = Color3.fromRGB(20, 20, 24),
			Text = "", AutoButtonColor = false, ZIndex = 3, Parent = board })
		UI.corner(key, 4)
		key.Activated:Connect(function()
			hit(b[1], key, Color3.fromRGB(80, 80, 90), Color3.fromRGB(20, 20, 24))
		end)
	end
end

function Piano.init()
	Net.Piano.OnClientEvent:Connect(function(part)
		if typeof(part) == "Instance" and part:IsA("BasePart") then
			open(part)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not gui then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape then
			close()
			return
		end
		local k = keyByCode[input.KeyCode]
		if k then
			hit(k.note, k.frame, k.down, k.up)
		end
	end)
end

return Piano
