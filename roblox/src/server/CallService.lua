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
local Shop = require(script.Parent:WaitForChild("Shop"))

local CallService = {}

local desks = {}
local activeCalls: { [Player]: any } = {}
local running = false
local quotes = {} -- lines players said today, for Deal Replay
local lastSay: { [Player]: number } = {}
local usingDesk: { [Player]: any } = {} -- the desk whose computer each player is sitting at
local lastDeskState: { [Player]: number } = {}
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
	local look = Clients.look(p)
	return {
		look = look,
		access = call.access == true,
		desk = call.desk.id,
		name = Clients.displayName(p),
		kind = p.kind,
		color = p.color,
		voice = p.voice,
		pitch = p.pitch,
		speed = p.speed,
		trust = call.trust,
		mood = mood(call.trust),
		suspicion = call.suspicion or 0,
		notes = call.notes or {},
		ctype = p.type or "normal",
		transcript = call.transcript,
		claimed = call.claimed,
	}
end

local function sendUpdate(call, extra)
	local payload = { trust = call.trust, mood = mood(call.trust), waiting = call.busy,
		suspicion = call.suspicion or 0, notes = call.notes }
	for k, v in extra or {} do
		payload[k] = v
	end
	Net.CallUpdate:FireClient(call.operator, payload)
end

-- auto-notes: if a client line reads out one of their secrets, jot it down for the operator
local function noteSecrets(call, text: string)
	call.notes = call.notes or {}
	local norm = Deals.normalize(text)
	for _, d in Deals.list do
		local secret = call.secrets[d.id]
		if secret and norm:find(Deals.normalize(secret), 1, true) and not call.noted[d.id] then
			call.noted[d.id] = true
			table.insert(call.notes, string.format("%s: %s", d.secretLabel, secret))
		end
	end
end

local function addLine(call, who: string, name: string, text: string)
	local line = { who = who, name = name, text = text }
	table.insert(call.transcript, line)
	if who == "client" then
		noteSecrets(call, text)
		-- bystanders standing near the desk hear the caller too
		Net.CallSpeak:FireAllClients(call.desk.id, call.desk.monitor.Position, text, call.profile.voice,
			call.profile.pitch, call.profile.speed, call.operator)
	end
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

-- the monitor mirror: which desk a player is at, and a copy of their desktop for passers-by
local function leaveDesk(player: Player)
	local desk = usingDesk[player]
	if desk then
		usingDesk[player] = nil
		desk.monitor:SetAttribute("DeskState", nil)
		desk.monitor:SetAttribute("DeskUser", nil)
	end
end

local function seat(player: Player, desk)
	leaveDesk(player)
	for other, d in usingDesk do
		if d == desk and other ~= player then
			leaveDesk(other)
		end
	end
	usingDesk[player] = desk
	desk.monitor:SetAttribute("DeskUser", player.DisplayName)
	local char = player.Character
	if char then
		char:PivotTo(desk.seatCFrame)
	end
end

local function onDeskState(player: Player, state: any)
	local desk = usingDesk[player]
	if not desk or type(state) ~= "string" or #state > 2000 then
		return
	end
	local now = os.clock()
	if lastDeskState[player] and now - lastDeskState[player] < 0.15 then
		return
	end
	lastDeskState[player] = now
	desk.monitor:SetAttribute("DeskState", state)
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
		if call.access then
			Net.RemoteAccess:FireClient(call.operator, { state = "ended" })
		end
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
		trust = Config.START_TRUST + (Shop.has(player, "luckytie") and 5 or 0),
		operator = player,
		desk = desk,
		transcript = {},
		claimed = {},
		busy = true,
		closed = false,
		warnedOffline = false,
		usedLines = {},
		suspicion = 0,
		notes = {},
		noted = {},
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
	leaveDesk(old)
	if call.access then
		call.access = false
		Net.RemoteAccess:FireClient(old, { state = "ended" })
	end
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
	-- suspicion: rude or repetitive lines raise it; paranoid callers twice as fast; a smooth talker calms it
	local lower = clean:lower()
	local rude = lower:find("stupid") or lower:find("shut up") or lower:find("idiot") or lower:find("dumb")
	local repeated = call.lastPlayerLine == lower
	call.lastPlayerLine = lower
	local susp = 0
	if rude then
		susp += 22
	end
	if repeated then
		susp += 12
	end
	if call.profile.type == "paranoid" then
		susp = susp * 2 + 4
	elseif call.profile.type == "trusting" then
		susp = susp * 0.5
	end
	if Shop.has(player, "smooth") then
		susp -= 3
	end
	call.suspicion = math.clamp((call.suspicion or 0) + susp - 2, 0, 100)
	local res = ClientAI.respond(call, player.DisplayName, clean)
	if call.closed then
		return
	end
	if res.offline and not call.warnedOffline then
		call.warnedOffline = true
		Net.Toast:FireClient(player, "AI clients offline - using backup lines. Check Output for [ClientAI].")
	end
	local change = res.interest_change
	if change > 0 and Shop.has(player, "smooth") then
		change += 3 -- Smooth Talker
	end
	call.trust = math.clamp(call.trust + change, 0, 100)
	call.busy = false
	if call.suspicion >= 100 and not (Shop.has(player, "stall") and not call.stalled) then
		addLine(call, "client", call.profile.name, "You know what? This feels like a SCAM. I'm hanging up!")
		task.delay(2, function()
			CallService.endCall(call, "caller got suspicious")
		end)
		return
	end
	addLine(call, "client", call.profile.name, res.reply)
	if res.hang_up and Shop.has(player, "stall") and not call.stalled then
		-- Stall Script: one more chance per call
		call.stalled = true
		res.hang_up = false
		call.trust = math.max(call.trust, 12)
		addLine(call, "client", call.profile.name, "...Wait. Fine. You get ONE more chance. Make it good.")
	end
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
		local payout = deal.payout
		if Shop.has(player, "extractor") then
			payout = math.floor(payout * 1.25) -- Advanced Extractor
		end
		Economy.add(player, payout, true, deal.app .. " deal")
		Net.VerifyResult:FireClient(player, dealId, true, string.format("Deal closed - $%d earned.", payout), payout)
	else
		Net.VerifyResult:FireClient(player, dealId, false, "Verification failed. Wrong code.")
	end
end

-- Request Access: the broker asks the caller to click "Allow" on a remote-access box. Callers who trust you enough
-- say yes (the full remote desktop is HANDOFF step 2).
local GRANT_LINES = {
	"Okay... I clicked the little 'Allow' button. Is my screen supposed to blink like that?",
	"Fine, fine, I clicked it. Don't look at my desktop, it's messy.",
	"Allowed! Ooh, my mouse is moving by itself. Spooky!",
}
local REFUSE_LINES = {
	"Access to MY computer? Absolutely not. We just met!",
	"Whoa, whoa. My nephew said never to click those. Earn it first.",
	"Hmm, no. That sounds like something a robot would ask.",
}

local function onRequestAccess(player: Player)
	local call = activeCalls[player]
	if not call or call.busy or call.access or call.closed then
		return
	end
	local need = Shop.has(player, "access") and 50 or 70
	call.busy = true
	addLine(call, "player", player.DisplayName,
		"Could you click 'Allow' on the little box that just popped up? It's just so I can set everything up for you.")
	task.wait(1.2)
	if call.closed or call.operator ~= player then
		return
	end
	call.busy = false
	local name = Clients.displayName(call.profile)
	if call.trust >= need then
		call.access = true
		addLine(call, "client", call.profile.name, GRANT_LINES[rng:NextInteger(1, #GRANT_LINES)])
		Net.RemoteAccess:FireClient(player, { state = "granted", name = name, seconds = Shop.has(player, "vpn") and 90 or 60 })
	else
		if not Shop.has(player, "vpn") then
			call.trust = math.max(0, call.trust - 8)
		end
		addLine(call, "client", call.profile.name, REFUSE_LINES[rng:NextInteger(1, #REFUSE_LINES)])
		Net.RemoteAccess:FireClient(player, { state = "denied", need = need })
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
	Net.RequestAccess.OnServerEvent:Connect(onRequestAccess)
	Net.DeskState.OnServerEvent:Connect(onDeskState)
	Net.LeaveDesk.OnServerEvent:Connect(leaveDesk)
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
		lastDeskState[player] = nil
		leaveDesk(player)
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
