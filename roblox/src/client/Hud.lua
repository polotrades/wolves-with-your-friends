-- On-foot HUD: a small, clean panel in the top-right with white text, plus toast popups.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UI = require(script.Parent:WaitForChild("UI"))

local Hud = {}
local gui, title, team, bar, timer, personal, toastHolder

local function line(parent: Instance, order: number, size: number): TextLabel
	local l = UI.text(parent, "", { Size = UDim2.new(1, 0, 0, size), LayoutOrder = order, Font = UI.bold,
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.7 })
	UI.new("UITextSizeConstraint", { MaxTextSize = size, Parent = l })
	return l
end

function Hud.init()
	gui = UI.new("ScreenGui", { Name = "Hud", ResetOnSpawn = false, DisplayOrder = 2, Enabled = false,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui") })
	local panel = UI.new("Frame", { Size = UDim2.fromOffset(210, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, -222, 0, 10), BackgroundColor3 = Color3.fromRGB(10, 10, 16), BackgroundTransparency = 0.45,
		Parent = gui })
	UI.corner(panel, 10)
	UI.pad(panel, 8)
	UI.new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	title = line(panel, 1, 16)
	team = line(panel, 2, 14)
	local barBack = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 4), LayoutOrder = 3, BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.75, Parent = panel })
	bar = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = barBack })
	timer = line(panel, 4, 14)
	personal = line(panel, 5, 14)
	personal.Text = "Personal $0"
	title.Text = "WOLF & CO."
	toastHolder = UI.new("Frame", { Size = UDim2.new(0.4, 0, 0, 200), Position = UDim2.fromScale(0.3, 0.1),
		BackgroundTransparency = 1, Parent = gui })
	UI.new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = toastHolder })
end

function Hud.setVisible(on: boolean)
	gui.Enabled = on
end

function Hud.setStatus(s)
	if s.state == "WAITING" then
		title.Text = "NEW RUN"
		timer.Text = "Day 1 starts in " .. UI.clock(s.timeLeft)
	elseif s.state == "DAY" then
		title.Text = "DAY " .. s.day .. "  ·  FLOOR 100"
		timer.Text = "Boss meeting in " .. UI.clock(s.timeLeft)
	else
		title.Text = s.state == "MEETING" and "BOSS MEETING" or "EVERYONE'S FIRED"
		timer.Text = UI.clock(s.timeLeft)
	end
	team.Text = string.format("Firm %s / %s", UI.money(s.team), UI.money(s.quota))
	bar.Size = UDim2.fromScale(math.clamp(s.team / math.max(s.quota, 1), 0, 1), 1)
	bar.BackgroundColor3 = s.team >= s.quota and UI.colors.green or Color3.new(1, 1, 1)
end

function Hud.setPersonal(n: number)
	personal.Text = "Personal " .. UI.money(n)
end

function Hud.toast(text: string)
	local f = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Color3.fromRGB(10, 10, 16),
		BackgroundTransparency = 0.3, Parent = toastHolder })
	UI.corner(f, 10)
	local l = UI.text(f, text, { Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), Font = UI.bold })
	task.delay(3.5, function()
		TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.45)
		f:Destroy()
	end)
end

return Hud
