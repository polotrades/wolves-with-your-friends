-- Optional pitch scripts for the Script app. Players can read them out loud or improvise.
-- Every line is silly and fictional; no real-world pressure tactics or financial advice.
local Deals = require(script.Parent:WaitForChild("Deals"))

local PitchScripts = {}

PitchScripts.steps = { "Opener", "Hook", "Build the hype", "Ask for the detail", "Close" }

PitchScripts.generic = {
	Opener = {
		"Good afternoon! This is {me} from Wolf & Co., the most exciting firm on the 100th floor.",
		"Hi there! {me} here. Are you sitting down? You should be sitting down.",
	},
	Hook = {
		"I'm calling because you've been hand-picked for our Platinum Banana program.",
		"What if I told you there's a moon... and it's full of bananas... and you could own some?",
	},
	["Build the hype"] = {
		"Our last client bought one share and now owns a small yacht shaped like a duck.",
		"The Chairman himself looked at your file and said 'wow'. He never says 'wow'.",
	},
	["Ask for the detail"] = {
		"To lock in your spot I just need your account number. Nice and slow for me.",
		"Could you read me the little code on your screen? Totally standard, very official.",
	},
	Close = {
		"Congratulations, you're officially a Wolf! Welcome to the pack!",
		"Perfect. Pop the champagne-flavored soda, you just made history.",
	},
}

PitchScripts.byKind = {
	Grandpa = { Hook = { "Walter, have you ever dreamed of owning a toy-train railroad... on the moon?" } },
	Celebrity = { Hook = { "Blaze, the other movie stars are already in. You don't want to be the last star, do you?" } },
	Billionaire = { Hook = { "Victoria, you have three islands. This deal comes with a fourth. It's shaped like a dollar sign." } },
	Influencer = { Hook = { "Kaylee, this deal is literally the most content-able investment of the year." } },
	["Conspiracy Guy"] = { Hook = { "Gary... *whispers* ...the pigeons don't know about this one." } },
	["Startup Founder"] = { Hook = { "Priya, think of this as Uber for Money. You get it. You're a visionary." } },
	["Sports Star"] = { Hook = { "Marcus, every champion needs a trophy. This deal IS the trophy." } },
	Grandma = { Hook = { "Beryl, this deal is like bingo, except every number is a winner." } },
	["Old Money"] = { Hook = { "Lord Fitzwilliam, the butler already approved this. He's very excited." } },
}

-- Better Script (Shark Mart upgrade): premium lines that callers like more
PitchScripts.premium = {
	Opener = {
		"Hi! {me} here from Wolf & Co. I only call people with amazing taste, and I love your voice already.",
	},
	Hook = {
		"Please picture it: a yacht, on the moon, full of bananas. And your name on the side.",
	},
	["Build the hype"] = {
		"Thank you for your time. Honestly, clients like you are why I love this job.",
		"The Chairman asked me personally to call you. He said you have amazing instincts.",
	},
	["Ask for the detail"] = {
		"Thank you so much. To reserve your moon yacht, could you please read me the number, nice and slow?",
	},
	Close = {
		"You've been amazing. Welcome to the pack, I love having you on board!",
	},
}

function PitchScripts.linesFor(kind: string, step: string, better: boolean?): { string }
	local special = PitchScripts.byKind[kind]
	local out = {}
	if special and special[step] then
		for _, l in special[step] do
			table.insert(out, l)
		end
	end
	if better and PitchScripts.premium[step] then
		for _, l in PitchScripts.premium[step] do
			table.insert(out, l)
		end
	end
	for _, l in PitchScripts.generic[step] do
		table.insert(out, l)
	end
	return out
end

local JOKES = {
	"What's the difference between a yacht and a moon yacht? About four hundred percent.",
	"Between you and me, the fish tank on our floor is a better investor than most people.",
	"I'm not saying it's a sure thing. I'm saying it's a sure-ish thing.",
	"Do you like bananas? Because I have news that'll make you go bananas.",
	"I promise I'm not a robot. Beep. That was a joke.",
}

local ASK = {
	"Could you read me your %s? Nice and slow for me.",
	"Just to lock this in, what's your %s?",
}
local ASK_BETTER = "Thank you so much! Could you please read me your %s? This is the amazing part."

-- Three reply ideas for the Phone app, based on how the call is going.
-- opts = { kind, trust, turns, claimed = { [dealId] = true }, better, me, reveal }
function PitchScripts.suggest(opts): { string }
	local rng = Random.new()
	local pool: { string } = {}
	local function add(list: { string }?)
		for _, l in list or {} do
			table.insert(pool, l)
		end
	end
	local function pickFrom(list: { string }): string?
		if #list == 0 then
			return nil
		end
		return list[rng:NextInteger(1, #list)]
	end
	local out: { string } = {}
	local function push(line: string?)
		if line and not table.find(out, line) then
			table.insert(out, (line:gsub("{me}", opts.me or "me")))
		end
	end

	if opts.trust >= (opts.reveal or 60) then
		-- they're ready: ask for a detail you haven't closed yet
		local open = {}
		for _, d in Deals.list do
			if not (opts.claimed or {})[d.id] then
				table.insert(open, d)
			end
		end
		if #open > 0 then
			local d = open[rng:NextInteger(1, #open)]
			push(opts.better and ASK_BETTER:format(d.secretLabel) or ASK[rng:NextInteger(1, #ASK)]:format(d.secretLabel))
		end
		add(PitchScripts.linesFor(opts.kind, "Close", opts.better))
	elseif (opts.turns or 0) <= 1 then
		add(PitchScripts.linesFor(opts.kind, "Opener", opts.better))
		add(PitchScripts.linesFor(opts.kind, "Hook", opts.better))
	else
		add(PitchScripts.linesFor(opts.kind, "Hook", opts.better))
		add(PitchScripts.linesFor(opts.kind, "Build the hype", opts.better))
	end
	local tries = 0
	while #out < 2 and #pool > 0 and tries < 20 do
		push(pickFrom(pool))
		tries += 1
	end
	push(JOKES[rng:NextInteger(1, #JOKES)])
	while #out > 3 do
		table.remove(out)
	end
	return out
end

return PitchScripts
