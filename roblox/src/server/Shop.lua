-- Shark Mart on the server: buying upgrades / store items / employees with Personal money, the Bank (deposit into
-- the firm), employees earning money during the workday, and PumpAds campaigns. Everything resets with the run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Economy = require(script.Parent:WaitForChild("Economy"))

local Shop = {}

local owned: { [Player]: { [string]: number } } = {}
local campaigns: { [Player]: boolean } = {}
local working = false
local rng = Random.new()

local PUMP_STOCKS = { "BMM", "DUCK", "YACHT", "TOAST" }
local PUMP_BUDGETS = { [100] = true, [250] = true, [500] = true }
local PUMP_SECONDS = 20

local function send(player: Player)
	Net.Owned:FireClient(player, owned[player] or {})
end

function Shop.count(player: Player, id: string): number
	local o = owned[player]
	return o and o[id] or 0
end

function Shop.has(player: Player, id: string): boolean
	return Shop.count(player, id) > 0
end

local function onBuy(player: Player, id: any)
	if type(id) ~= "string" then
		return
	end
	local item = Catalog.byId[id]
	if not item then
		return
	end
	local have = Shop.count(player, id)
	if have >= (item.max or 1) then
		Net.Toast:FireClient(player, "You already have the most " .. item.name .. " you can get.")
		send(player)
		return
	end
	local price = Catalog.price(item, have)
	if not Economy.spend(player, price, "Bought " .. item.name) then
		Net.Toast:FireClient(player, "Not enough Personal money for " .. item.name .. ".")
		send(player)
		return
	end
	owned[player] = owned[player] or {}
	owned[player][id] = have + 1
	send(player)
	Net.Toast:FireClient(player, (item.tab == "employees" and "Hired: " or "Bought: ") .. item.name)
end

local function onBank(player: Player, amount: any)
	if type(amount) ~= "number" or amount ~= amount then
		return
	end
	amount = math.floor(amount)
	if Economy.deposit(player, amount) then
		Net.Toast:FireClient(player, string.format("Deposited $%d into the firm.", amount))
	end
end

-- PumpAds: pay a budget, wait, get paid back between 0.3x and 2.4x (a bit better than break-even on average)
local function onPump(player: Player, stock: any, budget: any)
	if type(stock) ~= "number" or not PUMP_STOCKS[stock] or type(budget) ~= "number" or not PUMP_BUDGETS[budget] then
		return
	end
	if campaigns[player] then
		Net.Toast:FireClient(player, "A PumpAds campaign is already running.")
		return
	end
	local sym = PUMP_STOCKS[stock]
	if not Economy.spend(player, budget, "PumpAds campaign: " .. sym) then
		Net.Toast:FireClient(player, "Not enough Personal money for that budget.")
		return
	end
	campaigns[player] = true
	Net.PumpResult:FireClient(player, { started = true, stock = sym, spent = budget })
	task.delay(PUMP_SECONDS, function()
		campaigns[player] = nil
		if not player.Parent then
			return
		end
		local mult = rng:NextNumber() < 0.45 and rng:NextNumber(0.3, 0.9) or rng:NextNumber(1.1, 2.4)
		local returned = math.floor(budget * mult)
		Economy.add(player, returned, true, "PumpAds return: " .. sym)
		Net.PumpResult:FireClient(player, { stock = sym, spent = budget, returned = returned })
	end)
end

function Shop.setWorking(on: boolean)
	working = on
end

function Shop.resetRun()
	table.clear(owned)
	for _, p in Players:GetPlayers() do
		send(p)
	end
end

function Shop.init()
	Net.Buy.OnServerEvent:Connect(onBuy)
	Net.Bank.OnServerEvent:Connect(onBank)
	Net.PumpAds.OnServerEvent:Connect(onPump)
	Players.PlayerAdded:Connect(function(p)
		task.wait(2)
		send(p)
	end)
	Players.PlayerRemoving:Connect(function(p)
		owned[p] = nil
		campaigns[p] = nil
	end)
	-- employees earn while the workday runs
	task.spawn(function()
		while true do
			task.wait(Catalog.PAY_EVERY)
			if working then
				for player, o in owned do
					local total = 0
					for _, item in Catalog.employees do
						total += (o[item.id] or 0) * (item.pay or 0)
					end
					if total > 0 and player.Parent then
						Economy.add(player, total, true, "Employee earnings")
					end
				end
			end
		end
	end)
end

return Shop
