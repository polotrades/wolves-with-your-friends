-- One place that lists every RemoteEvent. The server creates them; clients wait for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Status", -- server -> all: { state, timeLeft, day, team, quota }
	"Money", -- server -> player: { personal }
	"Toast", -- server -> player/all: text popups
	"CallOpen", -- server -> player: a call is now on your screen
	"CallUpdate", -- server -> player: new transcript line / trust / waiting state
	"CallClosed", -- server -> player: call ended (reason)
	"Say", -- player -> server: something the player said (voice transcript or typed)
	"HangUp", -- player -> server
	"LeaveDesk", -- player -> server
	"Verify", -- player -> server: (dealId, value)
	"VerifyResult", -- server -> player: (dealId, ok, message, payout)
	"Meeting", -- server -> all: meeting phases
	"Vote", -- player -> server: quote index
	"Report", -- server -> all: final statement
	"Spawn", -- player -> server: leave the main menu (with the chosen look) and spawn into the tower
	"Ring", -- server -> all: (deskId, position, ringing) for the HUD arrow
	"Chairman", -- server -> all: The Chairman's announcements
	"DeskOpen", -- server -> player: you sat at a computer with no call on it (deskId)
	"DeskState", -- player -> server: a compact copy of your Shark OS desktop, drawn on your monitor for passers-by
	"Buy", -- player -> server: Shark Mart item id
	"Owned", -- server -> player: { [id] = count }
	"Bank", -- player -> server: deposit this much Personal money into the firm
	"RequestAccess", -- player -> server: ask the caller for remote access to their computer
	"RemoteAccess", -- server -> player: { state = "granted" | "denied" | "ended", name, seconds }
	"PumpAds", -- player -> server: (stockIndex, budget) launch an ad campaign
	"PumpResult", -- server -> player: { started?, stock, spent, returned }
	"Casino", -- player -> server: (action, amount?, choice?) wallet | deposit | cashout | updown | slots
	"CasinoResult", -- server -> player: { wallet, game?, win?, bet?, up?, reels?, error?, note? }
	"Grab", -- player -> server: ask to pick up a part (network ownership)
	"Drop", -- player -> server: let go / throw (part, velocity)
	"Interact", -- player -> server: (kind, target) eat / pour / print / etc.
	"Fx", -- server -> all: (kind, cframe) spawn a shared effect (puddle, splash, print)
	"Floor", -- player -> server: travel between "office" and "roof"
	"Music", -- server -> all: (on, assetId) DJ music toggle for client ambience
}

local Net = {}

local folder: Folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	for _, n in NAMES do
		if not folder:FindFirstChild(n) then
			local e = Instance.new("RemoteEvent")
			e.Name = n
			e.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
end

for _, n in NAMES do
	Net[n] = folder:WaitForChild(n)
end

return Net
