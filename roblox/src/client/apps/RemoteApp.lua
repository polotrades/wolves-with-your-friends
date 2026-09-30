-- Remote Access: the connection to the caller's computer. Press Request Access in the Phone; if the caller trusts
-- you enough they click Allow and a timed session opens here. (Driving their desktop comes in the next update:
-- HANDOFF step 2.)
local Client = script.Parent.Parent
local UI = require(Client:WaitForChild("UI"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))

local RemoteApp = {}
local win, refs
local log: { string } = {}

local function addLog(text: string)
	table.insert(log, os.date("%H:%M:%S") .. "  " .. text)
	if #log > 30 then
		table.remove(log, 1)
	end
	if refs then
		refs.log.Text = table.concat(log, "\n")
	end
end

local function render()
	if not refs then
		return
	end
	local a = State.access
	refs.idle.Visible = a == nil
	refs.live.Visible = a ~= nil
	if a then
		refs.who.Text = "Connected to " .. a.name .. "'s PC"
	end
	local need = State.has("access") and 50 or 70
	refs.need.Text = string.format("Callers click Allow at %d+ trust%s.", need, State.has("access") and " (Account Access)" or "")
end

function RemoteApp.open()
	if win and not win.closed then
		win:setMinimized(false)
		render()
		return
	end
	win = Desktop.window("remote", "Remote Access", Vector2.new(520, 440))
	local c = win.content
	UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = UI.os.surface, BorderSizePixel = 0, Parent = c })
	refs = {}
	refs.idle = UI.new("Frame", { Size = UDim2.new(1, 0, 1, -130), BackgroundTransparency = 1, Parent = c })
	UI.text(refs.idle, "🖥️", { Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0.5, -32, 0, 30) })
	UI.label(refs.idle, "Not connected", 20, { Position = UDim2.fromOffset(0, 104), Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Center })
	UI.label(refs.idle, "Win the caller's trust, then press  🖥️ Request Access  in the Phone.", 14, { Position = UDim2.fromOffset(20, 136),
		Size = UDim2.new(1, -40, 0, 40), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = UI.os.dim })
	refs.need = UI.label(refs.idle, "", 13, { Position = UDim2.fromOffset(0, 180), TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = UI.colors.yellow })

	refs.live = UI.new("Frame", { Size = UDim2.new(1, 0, 1, -130), BackgroundTransparency = 1, Visible = false, Parent = c })
	local screen = UI.new("Frame", { Size = UDim2.new(1, -24, 1, -60), Position = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(20, 70, 140), Parent = refs.live })
	UI.corner(screen, 6)
	UI.new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(60, 140, 220), Color3.fromRGB(20, 50, 110)),
		Parent = screen })
	for i, app in { { "🏦", "Bank" }, { "✉️", "Email" }, { "📁", "Files" }, { "🪙", "Crypto" } } do
		local tile = UI.new("Frame", { Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(12 + (i - 1) * 80, 12),
			BackgroundTransparency = 1, Parent = screen })
		UI.icon(tile, app[1], Color3.fromRGB(240, 240, 250), 40, { Position = UDim2.new(0.5, -20, 0, 0) })
		UI.label(tile, app[2], 12, { Position = UDim2.fromOffset(0, 44), TextXAlignment = Enum.TextXAlignment.Center })
	end
	refs.who = UI.label(screen, "", 15, { Position = UDim2.new(0, 12, 1, -52), Font = UI.bold })
	UI.label(screen, "Their desktop is live. Hands-on control arrives in the next update.", 12, {
		Position = UDim2.new(0, 12, 1, -30), TextColor3 = Color3.fromRGB(210, 225, 255) })
	refs.timer = UI.label(refs.live, "", 16, { Size = UDim2.new(0.6, 0, 0, 36), Position = UDim2.new(0, 12, 1, -42), Font = UI.bold,
		TextColor3 = UI.colors.yellow })
	UI.flat(refs.live, "Disconnect", Color3.fromRGB(200, 50, 60), { Size = UDim2.fromOffset(120, 34), Position = UDim2.new(1, -132, 1, -40) },
		function()
			RemoteApp.ended("You disconnected.")
		end)

	refs.log = UI.label(c, table.concat(log, "\n"), 12, { Size = UDim2.new(1, -24, 0, 110), Position = UDim2.new(0, 12, 1, -120),
		BackgroundTransparency = 0, BackgroundColor3 = UI.os.title, Font = Enum.Font.RobotoMono, TextColor3 = Color3.fromRGB(120, 220, 140),
		TextYAlignment = Enum.TextYAlignment.Bottom, TextWrapped = true, ClipsDescendants = true })
	UI.corner(refs.log, 6)
	win:addCloseHandler(function()
		refs = nil
		win = nil
	end)
	render()
	task.spawn(function()
		while refs do
			local a = State.access
			if a then
				local left = a.ends - os.clock()
				refs.timer.Text = string.format("⏱ Session: %ds left", math.max(0, math.ceil(left)))
			end
			task.wait(0.2)
		end
	end)
end

-- the server's answer to Request Access
function RemoteApp.event(e)
	if e.state == "granted" then
		State.access = { name = e.name, ends = os.clock() + (e.seconds or 60) }
		addLog("ACCESS GRANTED by " .. e.name .. " (" .. (e.seconds or 60) .. "s)")
		Desktop.notify("Remote Access", e.name .. " clicked Allow!", "🖥️")
		RemoteApp.open()
		local token = State.access
		task.delay(e.seconds or 60, function()
			if State.access == token then
				RemoteApp.ended("Session timed out.")
			end
		end)
	elseif e.state == "denied" then
		addLog("Request refused (needs " .. tostring(e.need) .. " trust)")
		Desktop.notify("Remote Access", "The caller refused. Build more trust first.", "🚫")
	elseif e.state == "ended" then
		if State.access then
			RemoteApp.ended("Caller hung up.")
		end
	end
	State.emit()
	render()
end

function RemoteApp.ended(reason: string)
	if not State.access then
		return
	end
	State.access = nil
	addLog("Session closed: " .. reason)
	State.emit()
	render()
end

return RemoteApp
