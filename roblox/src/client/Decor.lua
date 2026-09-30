-- Client-side office life: scrolls every LED stock ticker (parts tagged "Ticker").
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Decor = {}

function Decor.init()
	local tapes: { TextLabel } = {}
	local function add(p: Instance)
		local g = p:FindFirstChildWhichIsA("SurfaceGui")
		local tape = g and g:FindFirstChild("Tape") :: TextLabel?
		if tape then
			table.insert(tapes, tape)
		end
	end
	for _, p in CollectionService:GetTagged("Ticker") do
		add(p)
	end
	CollectionService:GetInstanceAddedSignal("Ticker"):Connect(function(p)
		task.wait(0.5)
		add(p)
	end)
	RunService.RenderStepped:Connect(function()
		-- the tape holds the text twice, so sliding it by half its width loops seamlessly
		local x = -((os.clock() * 0.03) % 2)
		for _, tape in tapes do
			tape.Position = UDim2.fromScale(x, 0)
		end
	end)
end

return Decor
