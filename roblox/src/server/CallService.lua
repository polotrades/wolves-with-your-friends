-- Calls: a random desk computer rings, a player runs over and answers it, talks to an AI client,
-- types the client's details into a deal app, and gets paid. Unanswered calls jump to another desk.
-- Coworkers can walk up and Take Over a call.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Clients = require(Shared:WaitForChild("Clients"))
local Deals = require(Shared:WaitForChild("Deals"))
local Net = require(Shared:WaitForChild("Net"))
local ClientAI = require(script.Parent:WaitForChild("ClientAI"))
local Economy = require(script.Parent:WaitForChild("Economy"))
local NPCGuide = require(script.Parent:WaitForChild("NPCGuide"))

local CallService = {}

local desks = {}
local activeCalls: { [Player]: any } = {}
local running = false
local quotes = {} -- lines players said today, for Deal Replay
local lastSay: { [Player]: number } = {}
local rng = Random.new()

local function mood(trust: number): string
	if trust < 15 then
		return "HOSTILE"
	elseif trust < 40 then
		return "SKEPTICAL"
	elseif trust < 65 then
		return "CURIOUS"
	end
	return "HOOKED"
end

local function filter(player: Player, text: string): string?
	local ok, result = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	return ok and result or nil
end

-- yellow outline around the desk and its chair while it rings (Highlights are created on demand:
-- Roblox only draws a limited number at once)
local function setOutline(desk, on: boolean)
	for _, h in desk.outlines or {} do
		h:Destroy()
	end
	desk.outlines = {}
	if not on then
		return
	end
	for _, target in { desk.model, desk.chair } do
		if target then
			local h = Instance.new("Highlight")
			h.FillTransparency = 0.85
			h.FillColor = Color3.fromRGB(255, 210, 40)
			h.OutlineColor = Color3.fromRGB(255, 210, 40)
			h.DepthMode = Enum.HighlightDepthMode.Occluded
			h.Adornee = target
			h.Parent = desk.model
			table.insert(desk.outlines, h)
		end
	end
end

local function setRinging(desk, on: boolean)
	if not on and desk.ringTag.Enabled then
		NPCGuide.announce(desk, false)
	end
	setOutline(desk, on)
	desk.ringTag.Enabled = on
	desk.incoming.Visible = on
	desk.monitor:SetAttribute("Ringing", on)
	desk.answer.Enabled = on
	desk.use.Enabled = not on and desk.state ~= "active"
	local sound = desk.monitor:FindFirstChild("Ring") :: Sound?
	if sound then
		if on then
			sound:Play()
		else
			sound:Stop()
		end
	end
end

local function updateMirror(desk)
	local m = desk.mirror
	local call = desk.call
	if not call then
		m.Caller.Text = ""
		m.Line.Text = ""
		m.TrustBack.Visible = false
		return
	end
	m.Caller.Text = Clients.displayName(call.profile)
	m.TrustBack.Visible = true
	m.TrustBack.Trust.Size = UDim2.fromScale(math.clamp(call.trust / 100, 0.02, 1), 1)
	local last = call.transcript[#call.transcript]
	m.Line.Text = last and (last.name .. ": " .. last.text) or ""
end

local function publicCall(call)
	local p = call.profile
	return {
		desk = call.desk.id,
		name = Clients.displayName(p),
		kind = p.kind,
		color = p.color,
		voice = p.voice,
		pitch = p.pitch,
		speed = p.speed,
		trust = call.trust,
		mood = mood(call.trust),
		transcript = call.transcript,
		claimed = call.claimed,
	}
end

local function sendUpdate(call, extra)
	local payload = { trust = call.trust, mood = mood(call.trust), waiting = call.busy }
	for k, v in extra or {} do
		payload[k] = v
	end
	Net.CallUpdate:FireClient(call.operator, payload)
end

local function addLine(call, who: string, name: string, text: string)
	local line = { who = who, name = name, text = text }
	table.insert(call.transcript, line)
	sendUpdate(call, { line = line })
	updateMirror(call.desk)
end

local function idleDesks(except)
	local out = {}
	for _, d in desks do
		if d.state == "idle" and d ~= except then
			table.insert(out, d)
		end
	end
	return out
end

local function ringAt(desk, pending)
	desk.state = "ringing"
	desk.pending = pending
	setRinging(desk, true)
	NPCGuide.announce(desk)
	task.spawn(function() -- seconds left on the ring pill
		local ends = os.clock() + Config.RING_TIMEOUT
		while desk.state == "ringing" and desk.pending == pending do
			desk.ringTag.Frame.Count.Text = math.max(0, math.ceil(ends - os.clock())) .. "s"
			task.wait(0.25)
		end
	end)
	task.delay(Config.RING_TIMEOUT, function()
		if desk.state ~= "ringing" or desk.pending ~= pending then
			return
		end
		setRinging(desk, false)
		desk.state = "idle"
		desk.pending = nil
		pending.jumps += 1
		if running and pending.jumps < Config.RING_MAX_JUMPS then
			local free = idleDesks(desk)
			if #free > 0 then
				ringAt(free[rng:NextInteger(1, #free)], pending)
			end
		end
	end)
end

local function busyCount(): number
	local n = 0
	for _, d in desks do
		if d.state ~= "idle" then
			n += 1
		end
	end
	return n
end

local function spawnCall()
	local free = idleDesks()
	if #free == 0 then
		return
	end
	local secrets = {}
	for _, d in Deals.list do
		secrets[d.id] = Deals.generate(d.pattern, rng)
	end
	ringAt(free[rng:NextInteger(1, #free)], { profile = Clients.random(rng), secrets = secrets, jumps = 0 })
end

local function seat(player: Player, desk)
	local char = player.Character
	if char then
		char:PivotTo(desk.seatCFrame)
	end
end

function CallService.endCall(call, reason: string)
	if call.closed then
		return
	end
	call.closed = true
	activeCalls[call.operator] = nil
	ClientAI.stop(call)
	local desk = call.desk
	desk.state = "idle"
	desk.call = nil
	desk.takeover.Enabled = false
	desk.use.Enabled = true
	updateMirror(desk)
	if call.operator.Parent then
		Net.CallClosed:FireClient(call.operator, { reason = reason })
	end
end

function CallService.answer(player: Player, desk)
	if desk.state ~= "ringing" or activeCalls[player] or not running then
		return
	end
	local pending = desk.pending
	setRinging(desk, false)
	desk.pending = nil
	local call = {
		profile = pending.profile,
		secrets = pending.secrets,
		trust = Config.START_TRUST,
		operator = player,
		desk = desk,
		transcript = {},
		claimed = {},
		busy = true,
		closed = false,
		warnedOffline = false,
		usedLines = {},
	}
	desk.state = "active"
	desk.call = call
	desk.takeover.Enabled = true
	desk.use.Enabled = false
	activeCalls[player] = call
	ClientAI.start(call)
	Economy.countCall(player)
	seat(player, desk)
	Net.CallOpen:FireClient(player, publicCall(call))
	updateMirror(desk)
	task.spawn(function()
		local res = ClientAI.greet(call)
		if call.closed then
			return
		end
		call.busy = false
		addLine(call, "client", call.profile.name, res.reply)
	end)
end

function CallService.takeover(player: Player, desk)
	local call = desk.call
	if desk.state ~= "active" or not call or activeCalls[player] or call.operator == player then
		return
	end
	local old = call.operator
	activeCalls[old] = nil
	Net.CallClosed:FireClient(old, { reason = "taken", by = player.DisplayName })
	Net.Toast:FireClient(old, player.DisplayName .. " took over your call!")
	local oldChar = old.Character
	if oldChar then
		oldChar:PivotTo(oldChar:GetPivot() * CFrame.new(0, 0, 6)) -- scooted out of the chair
	end
	call.operator = player
	call.pendingNote = string.format("A different broker named %s just grabbed the phone from %s mid-call.",
		player.DisplayName, old.DisplayName)
	activeCalls[player] = call
	seat(player, desk)
	Net.CallOpen:FireClient(player, publicCall(call))
end

local function onSay(player: Player, text: any)
	if type(text) ~= "string" then
		return
	end
	text = text:sub(1, 280)
	if text:gsub("%s", "") == "" then
		return
	end
	local now = os.clock()
	if lastSay[player] and now - lastSay[player] < 0.6 then
		return
	end
	lastSay[player] = now
	local call = activeCalls[player]
	if not call or call.busy then
		return
	end
	call.busy = true
	local clean = filter(player, text)
	if not clean or call.closed then
		call.busy = false
		return
	end
	addLine(call, "player", player.DisplayName, clean)
	table.insert(quotes, { name = player.DisplayName, text = clean, client = call.profile.name })
	local res = ClientAI.respond(call, player.DisplayName, clean)
	if call.closed then
		return
	end
	if res.offline and not call.warnedOffline then
		call.warnedOffline = true
		Net.Toast:FireClient(player, "AI clients offline - using backup lines. Check Output for [ClientAI].")
	end
	call.trust = math.clamp(call.trust + res.interest_change, 0, 100)
	call.busy = false
	addLine(call, "client", call.profile.name, res.reply)
	if res.hang_up then
		task.delay(2.5, function()
			CallService.endCall(call, "hung up")
		end)
	end
end

local function onVerify(player: Player, dealId: any, value: any)
	if type(dealId) ~= "string" or type(value) ~= "string" then
		return
	end
	local call = activeCalls[player]
	local deal = Deals.byId[dealId]
	if not call or not deal then
		Net.VerifyResult:FireClient(player, dealId, false, "No client on the line.")
		return
	end
	if call.claimed[dealId] then
		Net.VerifyResult:FireClient(player, dealId, false, "Already closed with this client.")
		return
	end
	if Deals.normalize(value) == Deals.normalize(call.secrets[dealId]) then
		call.claimed[dealId] = true
		Economy.add(player, deal.payout)
		Net.VerifyResult:FireClient(player, dealId, true, string.format("Deal closed - $%d earned.", deal.payout), deal.payout)
	else
		Net.VerifyResult:FireClient(player, dealId, false, "Verification failed. Wrong code.")
	end
end

function CallService.init(office)
	desks = office.desks
	for _, desk in desks do
		if Config.RING_SOUND_ID ~= "" then
			local s = Instance.new("Sound")
			s.Name = "Ring"
			s.SoundId = Config.RING_SOUND_ID
			s.Looped = true
			s.RollOffMaxDistance = 140
			s.Parent = desk.monitor
		end
		desk.answer.Triggered:Connect(function(player)
			CallService.answer(player, desk)
		end)
		desk.takeover.Triggered:Connect(function(player)
			CallService.takeover(player, desk)
		end)
		-- any computer works: sit down and use the apps even when nothing is ringing
		desk.use.Triggered:Connect(function(player)
			if desk.state == "idle" and not activeCalls[player] then
				seat(player, desk)
				Net.DeskOpen:FireClient(player, desk.id)
			end
		end)
	end
	Net.Say.OnServerEvent:Connect(onSay)
	Net.Verify.OnServerEvent:Connect(onVerify)
	Net.HangUp.OnServerEvent:Connect(function(player)
		local call = activeCalls[player]
		if call then
			CallService.endCall(call, "you hung up")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local call = activeCalls[player]
		if call then
			CallService.endCall(call, "left")
		end
		lastSay[player] = nil
	end)
end

function CallService.startDay()
	running = true
	table.clear(quotes)
	task.spawn(function()
		task.wait(2)
		while running do
			if busyCount() < math.min(#Players:GetPlayers() + 1, #desks) then
				spawnCall()
			end
			task.wait(rng:NextNumber(Config.RING_GAP_MIN, Config.RING_GAP_MAX))
		end
	end)
end

function CallService.stopAll()
	running = false
	for _, call in activeCalls do
		CallService.endCall(call, "end of day")
	end
	for _, d in desks do
		if d.state == "ringing" then
			setRinging(d, false)
		end
		d.state = "idle"
		d.pending = nil
		d.takeover.Enabled = false
	end
end

function CallService.takeQuotes()
	local q = quotes
	quotes = {}
	return q
end

return CallService
