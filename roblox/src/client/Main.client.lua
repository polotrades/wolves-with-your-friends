-- Client entry point: main menu, HUD, Shark OS (desktop + apps) and voice, then routes server events to them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Deals = require(Shared:WaitForChild("Deals"))

local Client = script.Parent
local Hud = require(Client:WaitForChild("Hud"))
local Desktop = require(Client:WaitForChild("Desktop"))
local State = require(Client:WaitForChild("State"))
local Voice = require(Client:WaitForChild("Voice"))
local Meeting = require(Client:WaitForChild("Meeting"))
local City = require(Client:WaitForChild("City"))
local Decor = require(Client:WaitForChild("Decor"))
local IdleScreens = require(Client:WaitForChild("IdleScreens"))
local OfficeBoards = require(Client:WaitForChild("OfficeBoards"))
local DeskMirror = require(Client:WaitForChild("DeskMirror"))
local Menu = require(Client:WaitForChild("Menu"))
local Apps = Client:WaitForChild("apps")
local PhoneApp = require(Apps:WaitForChild("PhoneApp"))
local DealApp = require(Apps:WaitForChild("DealApp"))
local ScriptApp = require(Apps:WaitForChild("ScriptApp"))
local FilesApp = require(Apps:WaitForChild("FilesApp"))
local NotesApp = require(Apps:WaitForChild("NotesApp"))
local BrowserApp = require(Apps:WaitForChild("BrowserApp"))
local SharkMartApp = require(Apps:WaitForChild("SharkMartApp"))
local CameraApp = require(Apps:WaitForChild("CameraApp"))
local RemoteApp = require(Apps:WaitForChild("RemoteApp"))
local BackgroundsApp = require(Apps:WaitForChild("BackgroundsApp"))
local AntivirusApp = require(Apps:WaitForChild("AntivirusApp"))
local PumpAdsApp = require(Apps:WaitForChild("PumpAdsApp"))
local CasinoApp = require(Apps:WaitForChild("CasinoApp"))

Hud.init()
Desktop.init()
Voice.init()
Meeting.init()
City.init()
Decor.init()
IdleScreens.init()
OfficeBoards.init()

-- main menu first; the HUD appears once you spawn onto floor 100
Menu.onSpawn = function()
	Hud.setVisible(true)
end
Menu.show()

-- ---------------------------------------------------------------- apps (pinned = on the taskbar)
local function app(id, name, glyph, color, open, order, pinned)
	Desktop.registerApp({ id = id, name = name, glyph = glyph, color = color, open = open, order = order, pinned = pinned })
end
app("files", "Files", "📁", Color3.fromRGB(240, 190, 60), function()
	FilesApp.open()
end, 1, true)
app("browser", "Browser", "🌐", Color3.fromRGB(60, 140, 240), BrowserApp.open, 2, true)
app("phone", "Phone", "📞", Color3.fromRGB(40, 170, 80), PhoneApp.open, 3, true)
app("script", "Script", "📜", Color3.fromRGB(40, 110, 230), ScriptApp.open, 4, true)
app("notes", "Notes", "📝", Color3.fromRGB(250, 200, 60), function()
	NotesApp.open()
end, 5, true)
app("sharkmart", "Shark Mart", "🦈", Color3.fromRGB(0, 160, 150), function()
	SharkMartApp.open()
end, 6, true)
app("camera", "Camera", "📷", Color3.fromRGB(90, 90, 110), CameraApp.open, 7, true)
app("remote", "Remote Access", "🖥️", Color3.fromRGB(0, 110, 210), RemoteApp.open, 8, true)
for i, d in Deals.list do
	app(d.id, d.app, d.id == "card" and "💳" or "$", d.color, function()
		DealApp.open(d.id)
	end, 10 + i, false)
end
app("pumpads", "PumpAds", "📢", Color3.fromRGB(230, 60, 140), PumpAdsApp.open, 20, false)
app("casino", "Wolf Casino", "🎰", Color3.fromRGB(200, 150, 30), CasinoApp.open, 21, false)
app("antivirus", "Shark Shield", "🛡️", Color3.fromRGB(40, 170, 110), AntivirusApp.open, 22, false)
app("backgrounds", "Backgrounds", "🖼️", Color3.fromRGB(150, 90, 220), BackgroundsApp.open, 23, false)
Desktop.openFile = FilesApp.openItem
DeskMirror.init()

Desktop.onLeave = function()
	if PhoneApp.call then
		Net.HangUp:FireServer()
	end
	Desktop.close()
end

-- ---------------------------------------------------------------- server events
Net.Status.OnClientEvent:Connect(function(s)
	Hud.setStatus(s)
	Desktop.setStatus(s)
	OfficeBoards.update(s)
end)
Net.Money.OnClientEvent:Connect(function(m)
	local before = State.personal
	Hud.setPersonal(m.personal)
	Desktop.setPersonal(m.personal)
	if m.note and m.personal ~= before then
		State.log(m.note, m.personal - before)
	end
	SharkMartApp.refresh()
	CasinoApp.refresh()
	State.emit()
end)
Net.Owned.OnClientEvent:Connect(function(owned)
	State.owned = owned
	SharkMartApp.refresh()
	State.emit()
end)
Net.Toast.OnClientEvent:Connect(function(text)
	Hud.toast(text)
	if Desktop.isOpen() then
		Desktop.notify("Wolf & Co.", text, "📣")
	end
end)

Net.CallOpen.OnClientEvent:Connect(function(call)
	Desktop.open(call.desk)
	table.clear(State.claimed)
	for id in call.claimed or {} do
		State.claimed[id] = true
	end
	DealApp.resetAll()
	PhoneApp.setCall(call)
	DealApp.open("account")
end)
Net.DeskOpen.OnClientEvent:Connect(function(deskId)
	Desktop.open(deskId)
	PhoneApp.reset()
	State.emit()
end)
Net.CallUpdate.OnClientEvent:Connect(PhoneApp.update)
Net.CallClosed.OnClientEvent:Connect(function(info)
	PhoneApp.closed(info.reason == "taken" and ("taken over by " .. tostring(info.by)) or info.reason)
	RemoteApp.ended("Call ended.")
	if info.reason == "taken" or info.reason == "end of day" then
		Desktop.close()
	end
end)
Net.VerifyResult.OnClientEvent:Connect(DealApp.result)
Net.RemoteAccess.OnClientEvent:Connect(function(e)
	RemoteApp.event(e)
	PhoneApp.refreshAccess()
end)
Net.PumpResult.OnClientEvent:Connect(PumpAdsApp.result)
Net.CasinoResult.OnClientEvent:Connect(CasinoApp.result)

Net.Meeting.OnClientEvent:Connect(function(m)
	Desktop.close()
	Meeting.show(m)
end)
Net.Report.OnClientEvent:Connect(Meeting.report)
