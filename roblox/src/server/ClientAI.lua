-- AI clients: one Roblox TextGenerator per call, remembering the conversation through ContextToken.
-- Replies come back as JSON { reply, interest_change, hang_up }. If the API fails, canned lines take over
-- so the game still works.
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Clients = require(Shared:WaitForChild("Clients"))
local Deals = require(Shared:WaitForChild("Deals"))

local ClientAI = {}

local SCHEMA = HttpService:JSONEncode({
	type = "object",
	properties = {
		reply = { type = "string" },
		interest_change = { type = "integer", minimum = -20, maximum = 20 },
		hang_up = { type = "boolean" },
	},
	required = { "reply", "interest_change", "hang_up" },
	additionalProperties = false,
})

local function systemPrompt(profile, secrets): string
	local details = {}
	for _, d in Deals.list do
		table.insert(details, string.format("your %s is %s", d.secretLabel, secrets[d.id]))
	end
	return table.concat({
		string.format("You are %s, %s.", Clients.displayName(profile), profile.persona),
		"You are a fictional character in a silly cartoon comedy game. A broker from Wolf & Co. is calling you",
		"to sell you ridiculous, obviously fake investments (like banana farms on the moon).",
		"Stay in character and be funny. Every reply is at most 2 short sentences and under 200 characters.",
		"Keep it family friendly. Never give real financial advice and never mention real companies or people.",
		"Your private, completely made-up details: " .. table.concat(details, "; ") .. ".",
		string.format("Each message starts with your current interest level from 0 to 100. Below %d, you are skeptical", Config.REVEAL_TRUST),
		string.format("and never share any detail. At %d or above, if the broker asks for one of your details, share it", Config.REVEAL_TRUST),
		"and read it out exactly with its dashes.",
		"Raise interest (up to +20) when the broker is funny, confident, flattering or creative. Lower it (down to -20)",
		"when they are rude, boring, repetitive or pushy. Hang up if the broker is very rude or your interest is 0.",
		"If a note says a different broker grabbed the phone, react to that with surprise.",
		"Answer only with the JSON object.",
	}, " ")
end

export type Call = {
	profile: any,
	secrets: { [string]: string },
	trust: number,
	gen: TextGenerator?,
	contextToken: string?,
	pendingNote: string?,
}

function ClientAI.start(call: Call)
	local gen = Instance.new("TextGenerator")
	gen.SystemPrompt = systemPrompt(call.profile, call.secrets)
	gen.Temperature = Config.AI_TEMPERATURE
	gen.Parent = ServerStorage
	call.gen = gen
end

function ClientAI.stop(call: Call)
	if call.gen then
		call.gen:Destroy()
		call.gen = nil
	end
end

local function clampReply(s: string): string
	s = s:gsub("%s+", " ")
	if #s > Config.TTS_MAX_CHARS - 20 then
		s = s:sub(1, Config.TTS_MAX_CHARS - 23) .. "..."
	end
	return s
end

-- Backup lines for when the AI service is unavailable. Big pools, and a call never repeats a line.
local LINES = {
	cold = {
		"Hmm. Who is this again?",
		"How did you get this number?",
		"Is this about my car's warranty? Because I don't have a car.",
		"I'm very busy. I was about to watch paint dry.",
		"You sound like a robot. Are you a robot?",
		"My cousin warned me about people like you.",
		"I'm putting you on speaker so my dog can judge you.",
		"Make it quick, my soup is getting cold.",
		"Wolf and what? Never heard of you.",
		"Okay... you have ten seconds. Go.",
	},
	warm = {
		"Okay, now you've got my attention.",
		"Bananas on the moon? Go on...",
		"Hmm, that's actually not the worst idea I've heard today.",
		"Tell me more, I'm listening!",
		"Wait, is the yacht shaped like a duck or a goose?",
		"My neighbor has one of those. I hate my neighbor. Keep talking.",
		"What's the catch? There's always a catch.",
		"You're funny. I don't trust funny people. But keep going.",
		"Hold on, let me get a pen. Okay, what?",
		"Would The Chairman personally shake my hand?",
	},
	hot = {
		"I love it! What do you need from me?",
		"You're my favorite broker ever!",
		"Take my money! Metaphorically. Well, also literally.",
		"This is the best phone call of my entire life.",
		"I'm telling everyone at bingo about you.",
		"Where do I sign? Can I sign with a crayon?",
		"Okay okay okay, I'm in. What's the next step?",
		"You had me at 'moon bananas'.",
		"My heart is racing. Is that the deal or my heart medicine?",
		"Say the word and I'm a Wolf!",
	},
	greet = {
		"Hello? Who's calling?",
		"Yeah, hello? Speak up, I'm in a tunnel.",
		"Hi there! Is this the pizza place?",
		"Hello-o? This better be important.",
	},
	question = {
		"Great question. I have no idea. Next question.",
		"Why do you want to know? Suspicious...",
		"Hmm, let me think... nope, you tell me.",
		"Is that a trick question? It feels like a trick question.",
	},
	rude = {
		"Excuse me?! I don't have to take this!",
		"Wow. Rude. My grandma is more polite, and she bites.",
		"Say that again and I'm hanging up.",
	},
}

local function pick(call, pool: { string }): string
	call.usedLines = call.usedLines or {}
	local fresh = {}
	for _, l in pool do
		if not call.usedLines[l] then
			table.insert(fresh, l)
		end
	end
	if #fresh == 0 then
		table.clear(call.usedLines)
		fresh = pool
	end
	local line = fresh[math.random(1, #fresh)]
	call.usedLines[line] = true
	return line
end

local function canned(call, text: string)
	local t = text:lower()
	local delta = 3
	if #t > 60 then
		delta += 3
	end
	if t:find("please") or t:find("thank") or t:find("amazing") or t:find("love") or t:find("yacht") or t:find("moon") then
		delta += 4
	end
	local rude = t:find("stupid") or t:find("shut up") or t:find("idiot") or t:find("dumb")
	if rude then
		delta = -15
	end
	local asked
	for _, d in Deals.list do
		if t:find(d.secretLabel:lower()) or (d.id == "account" and t:find("account")) or (d.id == "tradelink" and t:find("pin"))
			or (d.id == "pennystock" and t:find("code")) then
			asked = d
			break
		end
	end
	local newTrust = call.trust + delta
	if asked and not rude and newTrust >= Config.REVEAL_TRUST then
		return { reply = string.format("Oh, fine! My %s is %s. Don't tell my cat.", asked.secretLabel, call.secrets[asked.id]),
			interest_change = delta, hang_up = false }
	elseif asked and not rude then
		return { reply = "Whoa there, I barely know you. Why should I give you that?", interest_change = delta - 3, hang_up = false }
	end
	local pool
	if rude then
		pool = LINES.rude
	elseif #call.transcript <= 2 and (t:find("hello") or t:find("^hi") or t:find("hey")) then
		pool = LINES.greet
	elseif t:find("%?") and math.random() < 0.4 then
		pool = LINES.question
	elseif newTrust < 35 then
		pool = LINES.cold
	elseif newTrust < Config.REVEAL_TRUST then
		pool = LINES.warm
	else
		pool = LINES.hot
	end
	return { reply = pick(call, pool), interest_change = delta, hang_up = newTrust <= 0, offline = true }
end

-- Pull the JSON object out of a reply, even if the model wrapped it in extra words.
local function parse(text: string)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, text)
	if not (ok and type(data) == "table") then
		local inner = text:match("%b{}")
		if inner then
			ok, data = pcall(HttpService.JSONDecode, HttpService, inner)
		end
	end
	if ok and type(data) == "table" and type(data.reply) == "string" then
		return data
	end
	return { reply = text, interest_change = 3, hang_up = false }
end

ClientAI.lastError = nil :: string?
local schemaWorks = true -- flips off if Roblox rejects the JsonSchema option

local function generate(call, prompt: string)
	local request = {
		UserPrompt = prompt,
		ContextToken = call.contextToken,
		MaxTokens = Config.AI_MAX_TOKENS,
	}
	if schemaWorks then
		request.JsonSchema = SCHEMA
	else
		request.UserPrompt = prompt
			.. '\n(Answer ONLY with JSON like {"reply":"...","interest_change":5,"hang_up":false})'
	end
	return pcall(function()
		return (call.gen :: TextGenerator):GenerateTextAsync(request)
	end)
end

-- Returns { reply: string, interest_change: number, hang_up: boolean, offline: boolean? }
function ClientAI.respond(call, speaker: string, text: string)
	local prompt = string.format("[Interest: %d/100] ", call.trust)
	if call.pendingNote then
		prompt ..= "[Note: " .. call.pendingNote .. "] "
		call.pendingNote = nil
	end
	prompt ..= string.format("[%s says]: %s", speaker, text)

	local result
	if call.gen then
		local ok, response = generate(call, prompt)
		if not ok and schemaWorks then
			warn("[ClientAI] request with JsonSchema failed, retrying without it:", response)
			schemaWorks = false
			ok, response = generate(call, prompt)
		end
		if ok and response and response.GeneratedText then
			call.contextToken = response.ContextToken
			result = parse(response.GeneratedText)
			ClientAI.lastError = nil
		else
			ClientAI.lastError = tostring(response)
			warn("[ClientAI] TextGenerator failed, using backup lines:", response)
		end
	end
	result = result or canned(call, speaker == "System" and "hello" or text)
	result.reply = clampReply(tostring(result.reply))
	result.interest_change = math.clamp(tonumber(result.interest_change) or 0, -20, 20)
	result.hang_up = result.hang_up == true
	return result
end

function ClientAI.greet(call: Call)
	return ClientAI.respond(call, "System", "The phone rings and you pick up. Greet the caller in character.")
end

return ClientAI
