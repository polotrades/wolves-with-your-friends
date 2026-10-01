-- Office suspicion: a floor-wide meter (0-100) that rises when calls go badly (a caller gets suspicious or hangs
-- up) and when the floor descends into chaos (lots of thrown things). It drifts down slowly when things are calm,
-- and closing deals buys a little goodwill. At 100 the floor gets raided (RaidService), set up in GameLoop.
local Suspicion = {}

local value = 0
local onFull: (() -> ())? = nil
local fired = false

function Suspicion.get(): number
	return math.floor(value)
end

function Suspicion.set(n: number)
	value = math.clamp(n, 0, 100)
end

function Suspicion.add(amount: number)
	if fired then
		return
	end
	value = math.clamp(value + amount, 0, 100)
	if value >= 100 and onFull then
		fired = true
		local fn = onFull
		task.spawn(fn)
	end
end

function Suspicion.decay(dt: number)
	if value > 0 then
		value = math.max(0, value - dt * 0.6) -- about 0.6/sec when calm
	end
end

function Suspicion.reset()
	value = 0
	fired = false
end

function Suspicion.onFull(fn: () -> ())
	onFull = fn
end

return Suspicion
