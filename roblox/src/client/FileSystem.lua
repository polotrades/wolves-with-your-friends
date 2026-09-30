-- The desk computer's files: folders, text documents, notes (editable), photos from the Camera app and a few
-- silly downloads. Lives on the client for the whole session.
local FileSystem = {}

export type Item = {
	name: string,
	kind: string, -- folder | doc | note | photo | exe
	text: string?,
	children: { Item }?,
	parent: Item?,
	photo: any?, -- { model: Model, cam: CFrame, filter: string }
	created: string,
}

local listeners: { () -> () } = {}

local function now(): string
	return os.date("%H:%M") :: string
end

local function folder(name: string): Item
	return { name = name, kind = "folder", children = {}, created = now() }
end

FileSystem.root = folder("This PC")

local function put(parent: Item, item: Item): Item
	item.parent = parent
	table.insert(parent.children :: { Item }, item)
	return item
end

FileSystem.desktop = put(FileSystem.root, folder("Desktop"))
FileSystem.documents = put(FileSystem.root, folder("Documents"))
FileSystem.photos = put(FileSystem.root, folder("Photos"))
FileSystem.downloads = put(FileSystem.root, folder("Downloads"))
FileSystem.bin = put(FileSystem.root, folder("Recycle Bin"))

local function doc(parent: Item, name: string, text: string, kind: string?)
	put(parent, { name = name, kind = kind or "doc", text = text, created = "9:00" })
end

doc(FileSystem.desktop, "README - New Hires.txt", table.concat({
	"WELCOME TO FLOOR 100!",
	"",
	"1. A desk rings: it glows yellow. Run over and press E to answer.",
	"2. Talk to the caller (mic or typing). Make them laugh. Make them trust you.",
	"3. Above 60 trust they share details. Type them into the deal apps and press Verify.",
	"4. Every deal pays you AND the firm. The firm must hit the daily target before the boss review.",
	"5. Spend your Personal money in Shark Mart.",
	"",
	"Nobody reads this file. If you did: you're promoted. (Not really.)",
}, "\n"))
doc(FileSystem.documents, "Employee Handbook.txt", table.concat({
	"WOLF & CO. EMPLOYEE HANDBOOK (ABRIDGED)",
	"",
	"Rule 1: Always answer the phone.",
	"Rule 2: Never let the phone ring more than 15 seconds. It jumps to another desk and it is embarrassing.",
	"Rule 3: The Chairman's golden stapler is off limits.",
	"Rule 4: The fish tank is not a snack bar.",
	"Rule 5: Soda only on the trading floor. The juice bar is on the roof.",
	"Rule 6: If you miss the daily target, you are ALL fired. Nothing personal.",
}, "\n"))
doc(FileSystem.documents, "Quota Memo.txt", table.concat({
	"MEMO - FROM THE CHAIRMAN",
	"",
	"The target goes up every day. That's how targets work.",
	"Hit it together and everyone gets a bonus. Miss it and the boss review gets... loud.",
	"Tip: the Bank tab in Shark Mart lets you deposit Personal money into the firm.",
}, "\n"))
doc(FileSystem.documents, "Caller Cheat Sheet.txt", table.concat({
	"WHO'S ON THE LINE?",
	"",
	"Grandpa - loves toy trains and polite people. Be patient.",
	"Celebrity - needs VIP treatment. Compliment the movies.",
	"Billionaire - only respects confidence. Don't blink.",
	"Conspiracy Guy - whisper. The pigeons are listening.",
	"Gym Bro - talk in gains.",
	"Retired Spy - say the password. There is no password.",
	"",
	"Trust bar: HOSTILE < 15 < SKEPTICAL < 40 < CURIOUS < 65 < HOOKED",
}, "\n"))
doc(FileSystem.documents, "Lunch Orders.txt", "Tuesday: 14 cheeseburgers, 1 salad (nobody knows who ordered the salad).\n"
	.. "Wednesday: pizza with pineapple. The debate continues.\nThursday: tacos. Obviously.")
doc(FileSystem.downloads, "BananaMoon_Prospectus.pdf", table.concat({
	"BANANA MOON MINING CO. - INVESTOR PROSPECTUS",
	"",
	"Q: Is there a banana on the moon?",
	"A: Not yet.",
	"",
	"Q: Then what are we mining?",
	"A: Potential.",
}, "\n"))
doc(FileSystem.downloads, "definitely_not_a_virus.exe", "", "exe")
doc(FileSystem.downloads, "free_yacht_generator.exe", "", "exe")

function FileSystem.onChange(fn: () -> ())
	table.insert(listeners, fn)
end

local function emit()
	for _, fn in listeners do
		task.spawn(fn)
	end
end

function FileSystem.add(parent: Item, item: Item): Item
	put(parent, item)
	emit()
	return item
end

function FileSystem.newItem(kind: string, name: string, text: string?): Item
	return { name = name, kind = kind, text = text, created = now() }
end

function FileSystem.detach(item: Item)
	local p = item.parent
	if p and p.children then
		local i = table.find(p.children, item)
		if i then
			table.remove(p.children, i)
		end
	end
	item.parent = nil
end

-- Delete: moves to the Recycle Bin, or removes for good from inside the bin
function FileSystem.delete(item: Item)
	local inBin = item.parent == FileSystem.bin
	FileSystem.detach(item)
	if not inBin then
		put(FileSystem.bin, item)
	elseif item.photo and item.photo.model then
		item.photo.model:Destroy()
	end
	emit()
end

function FileSystem.restore(item: Item, to: Item)
	FileSystem.detach(item)
	put(to, item)
	emit()
end

function FileSystem.rename(item: Item, name: string)
	item.name = name
	emit()
end

function FileSystem.touched()
	emit()
end

-- a name that isn't taken yet in a folder ("Note 3.txt")
function FileSystem.uniqueName(parent: Item, base: string, ext: string): string
	local taken = {}
	for _, c in parent.children or {} do
		taken[c.name] = true
	end
	local n = 1
	local name = base .. " " .. n .. ext
	while taken[name] do
		n += 1
		name = base .. " " .. n .. ext
	end
	return name
end

function FileSystem.path(item: Item): string
	local parts = {}
	local cur: Item? = item
	while cur do
		table.insert(parts, 1, cur.name)
		cur = cur.parent
	end
	return table.concat(parts, "  ›  ")
end

FileSystem.GLYPHS = { folder = "📁", doc = "📄", note = "📝", photo = "🖼️", exe = "⚙️" }
FileSystem.COLORS = {
	folder = Color3.fromRGB(240, 190, 60),
	doc = Color3.fromRGB(90, 150, 230),
	note = Color3.fromRGB(250, 210, 80),
	photo = Color3.fromRGB(80, 190, 150),
	exe = Color3.fromRGB(150, 150, 165),
}

return FileSystem
