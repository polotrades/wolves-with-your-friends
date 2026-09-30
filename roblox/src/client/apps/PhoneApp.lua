-- Phone app: the call. Caller card (cartoon avatar, name, a personality line, trust bar with number + label),
-- chat bubbles, 3 suggested replies, a type box, and Request Access / Hang Up / speaker / mic.
-- With no call at this desk it says so and points you at the ringing desks.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local Voice = require(Client:WaitForChild("Voice"))
local State = require(Client:WaitForChild("State"))
local Avatar = require(Client:WaitForChild("Avatar"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Config = require(Shared:WaitForChild("Config"))
local PitchScripts = require(Shared:WaitForChild("PitchScripts"))

local PhoneApp = { call = nil :: any }

local MOOD_COLORS = {
	HOSTILE = UI.colors.red,
	SKEPTICAL = UI.colors.orange,
	CURIOUS = UI.colors.yellow,
	HOOKED = UI.colors.green,
}

local win, refs
local turns = 0

local function addBubble(line)
	if not refs then
		return
	end
	refs.empty.Visible = false
	local mine = line.who == "player"
	local system = line.name == "SYSTEM"
	local holder = UI.new("Frame", { Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, LayoutOrder = #refs.list:GetChildren(), Parent = refs.list })
	if system then
		UI.label(holder, line.text, 13, { TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.os.dim, TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y })
	else
		local bubble = UI.new("Frame", {
			Size = UDim2.new(0.8, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			Position = mine and UDim2.fromScale(0.2, 0) or UDim2.fromScale(0, 0),
			BackgroundColor3 = mine and Color3.fromRGB(0, 110, 210) or UI.os.surface3, Parent = holder,
		})
		UI.corner(bubble, 12)
		UI.pad(bubble, 8)
		UI.new("UIListLayout", { Parent = bubble })
		UI.label(bubble, line.name, 12, { Font = UI.bold,
			TextXAlignment = mine and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
			TextColor3 = mine and Color3.fromRGB(200, 230, 255) or Color3.fromRGB(160, 200, 255) })
		UI.label(bubble, line.text, 15, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
			TextXAlignment = mine and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left })
	end
	task.defer(function()
		if refs then
			refs.list.CanvasPosition = Vector2.new(0, 1e6)
		end
	end)
end

local function setTrust(trust: number, mood: string)
	if not refs then
		return
	end
	local color = MOOD_COLORS[mood] or UI.colors.green
	refs.trustNum.Text = tostring(trust)
	refs.trustNum.TextColor3 = color
	refs.mood.Text = mood
	refs.mood.TextColor3 = color
	refs.bar.Size = UDim2.fromScale(math.clamp(trust / 100, 0.01, 1), 1)
	refs.bar.BackgroundColor3 = color
	refs.access.BackgroundColor3 = State.access and Color3.fromRGB(90, 90, 100) or Color3.fromRGB(0, 110, 210)
end

local function send(text: string)
	if PhoneApp.call and refs and text:gsub("%s", "") ~= "" and not refs.waiting.Visible then
		Net.Say:FireServer(text)
	end
end

local function refreshSuggestions()
	if not refs then
		return
	end
	for _, b in refs.suggest:GetChildren() do
		if b:IsA("GuiButton") then
			b:Destroy()
		end
	end
	local call = PhoneApp.call
	refs.suggestLabel.Visible = call ~= nil
	if not call then
		return
	end
	local ideas = PitchScripts.suggest({
		kind = call.kind,
		trust = call.trust,
		turns = turns,
		claimed = State.claimed,
		better = State.has("betterscript"),
		me = Players.LocalPlayer.DisplayName,
		reveal = Config.REVEAL_TRUST,
	})
	for i, line in ideas do
		local b = UI.new("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = UI.os.surface2, AutoButtonColor = true,
			Font = UI.body, TextSize = 13, TextColor3 = UI.os.text, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = "  💬  " .. line, LayoutOrder = i, Parent = refs.suggest })
		UI.corner(b, 15)
		b.Activated:Connect(function()
			send(line)
		end)
	end
end

local function buildCard(call)
	local card = refs.card
	for _, c in card:GetChildren() do
		if not c:IsA("UICorner") and not c:IsA("UIGradient") then
			c:Destroy()
		end
	end
	local look = call.look or { trait = "", skin = Color3.fromRGB(240, 195, 160), hair = Color3.fromRGB(80, 60, 40), style = "short" }
	local face = UI.new("Frame", { Size = UDim2.fromOffset(92, 92), Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
		Parent = card })
	refs.mouth = Avatar.draw(face, look, call.color)
	UI.label(card, call.name, 17, { Size = UDim2.new(1, -120, 0, 22), Position = UDim2.fromOffset(114, 12), Font = UI.bold,
		TextTruncate = Enum.TextTruncate.AtEnd })
	UI.label(card, call.kind, 13, { Size = UDim2.new(1, -120, 0, 18), Position = UDim2.fromOffset(114, 34),
		TextColor3 = UI.os.dim })
	UI.label(card, "“" .. look.trait .. "”", 13, { Size = UDim2.new(1, -120, 0, 34), Position = UDim2.fromOffset(114, 52),
		Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(255, 220, 140), TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top })
	-- trust bar: number + label
	UI.label(card, "TRUST", 11, { Size = UDim2.fromOffset(60, 16), Position = UDim2.fromOffset(12, 112), Font = UI.bold,
		TextColor3 = UI.os.dim })
	refs.trustNum = UI.label(card, "0", 20, { Size = UDim2.fromOffset(46, 24), Position = UDim2.fromOffset(12, 126), Font = UI.bold })
	refs.mood = UI.label(card, "", 13, { Size = UDim2.fromOffset(120, 18), Position = UDim2.new(1, -132, 0, 112), Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Right })
	local back = UI.new("Frame", { Size = UDim2.new(1, -76, 0, 10), Position = UDim2.fromOffset(62, 134),
		BackgroundColor3 = Color3.fromRGB(25, 25, 30), BorderSizePixel = 0, Parent = card })
	UI.corner(back, 5)
	refs.bar = UI.new("Frame", { Size = UDim2.fromScale(0.25, 1), BorderSizePixel = 0, Parent = back })
	UI.corner(refs.bar, 5)
	local tick = UI.new("Frame", { Size = UDim2.new(0, 2, 1, 6), Position = UDim2.new(Config.REVEAL_TRUST / 100, -1, 0, -3),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = back })
	tick.ZIndex = 3
	refs.waiting = UI.label(card, "● ● ●  thinking", 12, { Size = UDim2.fromOffset(120, 16), Position = UDim2.new(1, -132, 0, 12),
		TextColor3 = UI.colors.yellow, TextXAlignment = Enum.TextXAlignment.Right, Visible = false, Font = UI.bold })
end

local function build()
	win = Desktop.window("phone", "Phone", Vector2.new(420, 640), UDim2.new(1, -440, 0, 8), false)
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	UI.pad(c, 10)
	refs = {}
	refs.card = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 156), BackgroundColor3 = Color3.fromRGB(30, 34, 48), Parent = c })
	UI.corner(refs.card, 10)
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(46, 60, 96), Color3.fromRGB(26, 28, 40)),
		Parent = refs.card })
	-- placeholders until a call arrives
	refs.waiting = UI.label(refs.card, "", 12, { Visible = false })
	refs.trustNum, refs.mood = UI.label(refs.card, "", 12), UI.label(refs.card, "", 12)
	refs.bar = UI.new("Frame", { Parent = refs.card, Visible = false })

	refs.list = UI.new("ScrollingFrame", { Size = UDim2.new(1, 0, 1, -380), Position = UDim2.fromOffset(0, 164),
		BackgroundColor3 = UI.os.title, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 5, BorderSizePixel = 0, Parent = c })
	UI.corner(refs.list, 8)
	UI.pad(refs.list, 8)
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.list })

	refs.empty = UI.new("Frame", { Size = UDim2.new(1, 0, 1, -380), Position = UDim2.fromOffset(0, 164), BackgroundTransparency = 1,
		ZIndex = 5, Parent = c })
	UI.text(refs.empty, "📵", { Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0.5, -32, 0.18, 0), ZIndex = 5 })
	UI.label(refs.empty, "No call at this desk.", 18, { Position = UDim2.new(0, 0, 0.18, 74), Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5 })
	UI.label(refs.empty, "Find a RINGING desk.", 15, { Position = UDim2.new(0, 0, 0.18, 100), TextColor3 = UI.colors.yellow,
		TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 5, Font = UI.bold })

	refs.suggestLabel = UI.label(c, "SUGGESTED REPLIES", 11, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -210),
		TextColor3 = UI.os.dim, Font = UI.bold, Visible = false })
	refs.suggest = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 102), Position = UDim2.new(0, 0, 1, -192),
		BackgroundTransparency = 1, Parent = c })
	UI.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = refs.suggest })

	refs.micStatus = UI.label(c, "", 12, { Size = UDim2.new(1, 0, 0, 16), Position = UDim2.new(0, 0, 1, -140),
		TextColor3 = UI.colors.yellow, Font = UI.bold })
	refs.input = UI.new("TextBox", { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 1, -122),
		BackgroundColor3 = UI.os.surface2, TextColor3 = UI.os.text, PlaceholderText = "Talk (mic) or type here, Enter to send",
		PlaceholderColor3 = UI.os.dim, Font = UI.body, TextSize = 15, ClearTextOnFocus = false, Text = "",
		TextXAlignment = Enum.TextXAlignment.Left, Parent = c })
	UI.corner(refs.input, 18)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0, 14), Parent = refs.input })
	refs.input.FocusLost:Connect(function(enter)
		if enter then
			send(refs.input.Text)
			refs.input.Text = ""
		end
	end)

	refs.access = UI.flat(c, "🖥️ Request Access", Color3.fromRGB(0, 110, 210), { Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 1, -80) }, function()
			if PhoneApp.call and not State.access and not refs.waiting.Visible then
				Net.RequestAccess:FireServer()
			end
		end)
	UI.flat(c, "📞 Hang Up", Color3.fromRGB(210, 40, 50), { Size = UDim2.new(0.5, -4, 0, 40), Position = UDim2.new(0, 0, 1, -40) },
		function()
			if PhoneApp.call then
				Net.HangUp:FireServer()
			end
		end)
	refs.speaker = UI.flat(c, "🔊", UI.os.surface3, { Size = UDim2.new(0.25, -4, 0, 40), Position = UDim2.new(0.5, 4, 1, -40),
		TextSize = 20 }, function()
			Voice.speakerOn = not Voice.speakerOn
			if not Voice.speakerOn then
				Voice.stop()
			end
			refs.speaker.Text = Voice.speakerOn and "🔊" or "🔇"
		end)
	refs.mic = UI.flat(c, "🎙️", UI.os.surface3, { Size = UDim2.new(0.25, -4, 0, 40), Position = UDim2.new(0.75, 4, 1, -40),
		TextSize = 20 }, function()
			local on = Voice.setMic(not Voice.micOn)
			refs.mic.BackgroundColor3 = on and UI.colors.red or UI.os.surface3
		end)

	-- mouth flaps and the dots pulse while the caller talks or thinks
	refs.conn = RunService.RenderStepped:Connect(function()
		refs.micStatus.Text = PhoneApp.call and Voice.micStatus() or ""
		local t = os.clock()
		if refs.mouth and refs.mouth.Parent then
			local talking = Voice.isSpeaking()
			refs.mouth.Size = UDim2.fromScale(0.28, talking and (0.06 + 0.1 * math.abs(math.sin(t * 14))) or 0.06)
		end
		if refs.waiting.Visible then
			refs.waiting.TextTransparency = 0.4 * math.abs(math.sin(t * 4))
		end
	end)
	win:addCloseHandler(function()
		if refs and refs.conn then
			refs.conn:Disconnect()
		end
		refs = nil
		win = nil
	end)
end

-- open (or bring back) the Phone window; shows the current call or the "no call" screen
function PhoneApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		return
	end
	build()
	local call = PhoneApp.call
	if call then
		refs.empty.Visible = false
		buildCard(call)
		setTrust(call.trust, call.mood)
		for _, line in call.transcript do
			addBubble(line)
		end
		refs.waiting.Visible = call.waiting == true
	end
	refreshSuggestions()
end

-- a call was put through to you (answered or taken over)
function PhoneApp.setCall(call)
	PhoneApp.call = call
	State.call = call
	State.access = nil
	turns = 0
	for _, line in call.transcript do
		if line.who == "player" then
			turns += 1
		end
	end
	if win and not win.closed then
		win:close()
	end
	PhoneApp.open()
	Voice.onTranscript = send
	State.emit()
end

function PhoneApp.update(u)
	local call = PhoneApp.call
	if not call then
		return
	end
	call.trust, call.mood, call.waiting = u.trust, u.mood, u.waiting
	if u.line then
		table.insert(call.transcript, u.line)
		if u.line.who == "player" then
			turns += 1
		elseif u.line.who == "client" then
			Voice.speak(u.line.text, call.voice, call.pitch, call.speed)
		end
	end
	if refs then
		setTrust(u.trust, u.mood)
		refs.waiting.Visible = u.waiting == true
		if u.line then
			addBubble(u.line)
			if u.line.who == "client" then
				refreshSuggestions()
			end
		end
	end
	State.emit()
end

function PhoneApp.closed(reason: string)
	PhoneApp.call = nil
	State.call = nil
	State.access = nil
	table.clear(State.claimed)
	Voice.stop()
	Voice.setMic(false)
	if refs then
		refs.waiting.Visible = false
		addBubble({ who = "client", name = "SYSTEM", text = "Call ended: " .. reason })
		refs.mic.BackgroundColor3 = UI.os.surface3
		refreshSuggestions()
	end
	State.emit()
end

function PhoneApp.refreshAccess()
	if refs and PhoneApp.call then
		setTrust(PhoneApp.call.trust, PhoneApp.call.mood)
	end
end

function PhoneApp.setInput(text: string)
	if refs then
		refs.input.Text = text
	end
end

-- clears the chat when you sit down at a new desk with no call
function PhoneApp.reset()
	if win and not win.closed and not PhoneApp.call then
		win:close()
	end
end

return PhoneApp
