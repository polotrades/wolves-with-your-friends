-- Client-side game state the desktop and its apps read: the round status, money, the current call, what you own
-- in Shark Mart, and a bank log. Anything can listen with State.onChange.
local State = {
	status = nil :: any, -- { state, timeLeft, day, team, quota, haul }
	personal = 0,
	call = nil :: any, -- the public call table from the server, or nil
	claimed = {} :: { [string]: boolean }, -- deals closed on the current call
	owned = {} :: { [string]: number }, -- Shark Mart id -> count
	access = nil :: any, -- remote access session { name, ends } or nil
	transactions = {} :: { { text: string, amount: number, time: string } },
	deskId = nil :: number?,
}

local listeners: { () -> () } = {}

function State.onChange(fn: () -> ())
	table.insert(listeners, fn)
end

function State.emit()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function State.has(id: string): boolean
	return (State.owned[id] or 0) > 0
end

function State.log(text: string, amount: number)
	table.insert(State.transactions, 1, { text = text, amount = amount, time = os.date("%H:%M") :: string })
	if #State.transactions > 40 then
		table.remove(State.transactions)
	end
end

return State
