-- Wolf Casino (the Shark OS minigame): a wallet you fill from Personal money, Up or Down (1.9x) and Stock Slots.
-- All results are rolled here. In-game money only (never Robux); wins go back to the wallet and cashing out
-- returns them to Personal money WITHOUT counting toward the firm's target.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Casino = {}

local wallets: { [Player]: number } = {}
local lastPlay: { [Player]: number } = {}
local rng = Random.new()

local BETS = { [10] = true, [50] = true, [100] = true, [250] = true }
local DEPOSITS = { [100] = true, [500] = true }
-- reel symbols and weights (out of 100)
local SYMBOLS = { { "🍌", 30, 3 }, { "🦆", 25, 4 }, { "🛥️", 20, 6 }, { "💰", 15, 10 }, { "🐺", 10, 20 } }
local PAIR_PAYS = 1.3

local function roll(): string
	local n = rng:NextInteger(1, 100)
	for _, s in SYMBOLS do
		n -= s[2]
		if n <= 0 then
			return s[1]
		end
	end
	return SYMBOLS[1][1]
end

local function reply(player: Player, t)
	t.wallet = wallets[player] or 0
	Net.CasinoResult:FireClient(player, t)
end

local function bet(player: Player, amount: any): number?
	if type(amount) ~= "number" or not BETS[amount] then
		return nil
	end
	local now = os.clock()
	if lastPlay[player] and now - lastPlay[player] < 0.8 then
		return nil
	end
	if (wallets[player] or 0) < amount then
		reply(player, { error = "Not enough in your casino wallet. Deposit first." })
		return nil
	end
	lastPlay[player] = now
	wallets[player] -= amount
	return amount
end

local function onCasino(player: Player, action: any, a: any, b: any)
	if action == "wallet" then
		reply(player, {})
	elseif action == "deposit" then
		if type(a) == "number" and DEPOSITS[a] and Economy.spend(player, a, "Wolf Casino deposit") then
			wallets[player] = (wallets[player] or 0) + a
			reply(player, { note = "Deposited " .. a .. ". Good luck!" })
		else
			reply(player, { error = "Not enough Personal money to deposit that." })
		end
	elseif action == "cashout" then
		local w = wallets[player] or 0
		if w <= 0 then
			reply(player, { error = "Your casino wallet is empty." })
			return
		end
		wallets[player] = 0
		Economy.add(player, w, false, "Wolf Casino cash out")
		reply(player, { note = "Cashed out $" .. w .. " to Personal." })
	elseif action == "updown" then
		local amount = bet(player, a)
		if not amount or (b ~= "up" and b ~= "down") then
			return
		end
		local up = rng:NextNumber() < 0.5
		local win = ((b == "up") == up) and math.floor(amount * 1.9) or 0
		wallets[player] += win
		reply(player, { game = "updown", up = up, bet = amount, win = win })
	elseif action == "slots" then
		local amount = bet(player, a)
		if not amount then
			return
		end
		local reels = { roll(), roll(), roll() }
		local win = 0
		if reels[1] == reels[2] and reels[2] == reels[3] then
			for _, s in SYMBOLS do
				if s[1] == reels[1] then
					win = amount * s[3]
				end
			end
		elseif reels[1] == reels[2] or reels[2] == reels[3] or reels[1] == reels[3] then
			win = math.floor(amount * PAIR_PAYS)
		end
		wallets[player] += win
		reply(player, { game = "slots", reels = reels, bet = amount, win = win })
	end
end

-- a new run wipes Personal money, and the casino wallets with it
function Casino.resetRun()
	table.clear(wallets)
	for _, p in Players:GetPlayers() do
		reply(p, {})
	end
end

function Casino.init()
	Net.Casino.OnServerEvent:Connect(onCasino)
	Players.PlayerRemoving:Connect(function(p)
		wallets[p] = nil
		lastPlay[p] = nil
	end)
end

return Casino
