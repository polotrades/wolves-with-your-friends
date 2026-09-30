-- Shark Mart: everything you can buy with Personal money. The server checks prices and applies the effects;
-- the Shark Mart app lists these.
local Catalog = {}

export type Item = {
	id: string,
	tab: string, -- upgrades | store | employees
	name: string,
	glyph: string,
	price: number,
	desc: string,
	max: number?, -- how many you can own (default 1)
	pay: number?, -- employees: money earned every Catalog.PAY_EVERY seconds
}

Catalog.PAY_EVERY = 20

Catalog.upgrades = {
	{ id = "access", name = "Account Access", glyph = "🔑", price = 800,
		desc = "Callers grant Remote Access at 50 trust instead of 70." },
	{ id = "extractor", name = "Advanced Extractor", glyph = "🧲", price = 1200,
		desc = "Every verified deal pays 25% more." },
	{ id = "stall", name = "Stall Script", glyph = "⏳", price = 600,
		desc = "Once per call, a caller who is about to hang up gives you one more chance." },
	{ id = "smooth", name = "Smooth Talker", glyph = "🎤", price = 1000,
		desc = "+3 bonus trust every time a caller likes what you said." },
	{ id = "betterscript", name = "Better Script", glyph = "📜", price = 500,
		desc = "Premium lines in the Script app and sharper suggested replies in the Phone." },
	{ id = "vpn", name = "VPN", glyph = "🛰️", price = 900,
		desc = "Remote Access sessions last 50% longer, and a refused request costs no trust." },
}

Catalog.store = {
	{ id = "luckytie", name = "Lucky Tie", glyph = "👔", price = 400,
		desc = "Every call you answer starts with +5 trust." },
	{ id = "shieldpro", name = "Shark Shield Pro", glyph = "🛡️", price = 350,
		desc = "The antivirus blocks pop-up ads before they open." },
	{ id = "goldmouse", name = "Golden Mouse", glyph = "🖱️", price = 250,
		desc = "A gold cursor and taskbar trim. Everyone walking past your monitor will see it." },
	{ id = "wp_goldrush", name = "Wallpaper: Gold Rush", glyph = "🌄", price = 200,
		desc = "A premium wallpaper for the Backgrounds app." },
	{ id = "wp_neon", name = "Wallpaper: Neon Grid", glyph = "🌆", price = 200,
		desc = "A premium wallpaper for the Backgrounds app." },
	{ id = "wp_yacht", name = "Wallpaper: Yacht Life", glyph = "🛥️", price = 300,
		desc = "A premium wallpaper for the Backgrounds app." },
}

Catalog.employees = {
	{ id = "intern", name = "Intern", glyph = "🧑‍💼", price = 300, pay = 10, max = 3,
		desc = "Makes coffee and the occasional sale. Pays $10 every 20 seconds of the workday." },
	{ id = "coldcaller", name = "Cold Caller", glyph = "📞", price = 800, pay = 30, max = 3,
		desc = "Dials all day. Pays $30 every 20 seconds of the workday." },
	{ id = "closer", name = "The Closer", glyph = "🦈", price = 2000, pay = 75, max = 2,
		desc = "Never loses a call. Pays $75 every 20 seconds of the workday." },
}

Catalog.byId = {} :: { [string]: Item }
for tab, list in { upgrades = Catalog.upgrades, store = Catalog.store, employees = Catalog.employees } do
	for _, item in list do
		item.tab = tab
		Catalog.byId[item.id] = item
	end
end

-- employees get pricier with every hire
function Catalog.price(item: Item, owned: number): number
	if item.tab == "employees" then
		return math.floor(item.price * 1.5 ^ owned)
	end
	return item.price
end

return Catalog
