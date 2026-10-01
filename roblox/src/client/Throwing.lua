-- First-person grab and throw. Look at a nearby grabbable prop and press E (or tap the on-screen Grab button) to
-- pick it up; it floats in front of you. Press the throw key (Q, or the Throw button) to hurl it where you're
-- looking; press E again to set it down gently. Charge a throw by holding Q.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local UI = require(script.Parent:WaitForChild("UI"))
local Gestures = require(script.Parent:WaitForChild("Gestures"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local Throwing = {
	gui = nil :: ScreenGui?,
	goal = nil :: Attachment?,
	a0 = nil :: Attachment?,
	grabBtn = nil :: GuiButton?,
	throwBtn = nil :: GuiButton?,
}

local player = Players.LocalPlayer
local held: BasePart? = nil
local hold: AlignPosition?
local spin: AlignOrientation?
local reach = 3.2 -- studs in front of the camera
local charge = 0
local charging = false
local GRAB_DIST = 18
local enabled = false

local function camera(): Camera
	return Workspace.CurrentCamera
end

-- the grabbable prop under the crosshair (or closest to the camera ray), within reach
local function target(): BasePart?
	local cam = camera()
	if not cam then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	local result = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * GRAB_DIST, params)
	if not result then
		return nil
	end
	local part = result.Instance
	local model = part:FindFirstAncestorOfClass("Model")
	if model and CollectionService:HasTag(model, "Grabbable") then
		return model.PrimaryPart or part
	elseif CollectionService:HasTag(part, "Grabbable") then
		return part
	end
	return nil
end

local function pickUp(part: BasePart)
	if held then
		return
	end
	held = part
	Net.Grab:FireServer(part)
	-- a target attachment in the world the part is pulled toward (updated each frame)
	local goal = Instance.new("Attachment")
	goal.Name = "ThrowGoal"
	goal.WorldCFrame = part.CFrame
	goal.Parent = Workspace.Terrain
	local a0 = Instance.new("Attachment")
	a0.Parent = part
	local h = Instance.new("AlignPosition")
	h.Attachment0 = a0
	h.Attachment1 = goal
	h.MaxForce = 90000
	h.Responsiveness = 60
	h.Parent = part
	local o = Instance.new("AlignOrientation")
	o.Attachment0 = a0
	o.Attachment1 = goal
	o.MaxTorque = 40000
	o.Responsiveness = 40
	o.Parent = part
	hold, spin = h, o
	Throwing.goal = goal
	Throwing.a0 = a0
end

local function clearConstraints()
	if hold then
		hold:Destroy()
	end
	if spin then
		spin:Destroy()
	end
	if Throwing.goal then
		Throwing.goal:Destroy()
	end
	if Throwing.a0 then
		Throwing.a0:Destroy()
	end
	hold, spin = nil, nil
end

local function release(throwPower: number)
	local part = held
	if not part then
		return
	end
	clearConstraints()
	local cam = camera()
	local velocity = Vector3.zero
	if throwPower > 0 and cam then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local base = hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		velocity = cam.CFrame.LookVector * (45 + throwPower * 95) + Vector3.new(0, 12 + throwPower * 10, 0) + base
	end
	Net.Drop:FireServer(part, velocity)
	Gestures.setGrab(false)
	held = nil
end

function Throwing.setEnabled(on: boolean)
	enabled = on
	if not on and held then
		release(0)
	end
	if Throwing.gui then
		Throwing.gui.Enabled = on
	end
end

function Throwing.init()
	local gui = UI.new("ScreenGui", { Name = "Throwing", ResetOnSpawn = false, DisplayOrder = 3, Enabled = false,
		Parent = player:WaitForChild("PlayerGui") })
	Throwing.gui = gui
	-- crosshair hint
	local hint = UI.new("TextLabel", { Name = "Hint", Size = UDim2.fromOffset(360, 28), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.56, 0), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.4, Font = UI.bold, TextSize = 16, Parent = gui })
	-- charge meter
	local meterBack = UI.new("Frame", { Size = UDim2.fromOffset(160, 8), AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.6, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 0.4,
		BorderSizePixel = 0, Visible = false, Parent = gui })
	UI.corner(meterBack, 4)
	local meter = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.colors.yellow, BorderSizePixel = 0,
		Parent = meterBack })
	UI.corner(meter, 4)
	-- touch buttons (phones)
	if UserInputService.TouchEnabled then
		local grabBtn = UI.button(gui, "GRAB", UI.colors.blue, { Size = UDim2.fromOffset(90, 60),
			Position = UDim2.new(1, -210, 1, -150), AnchorPoint = Vector2.new(0, 1) }, function()
				Throwing.toggleGrab()
			end)
		local throwBtn = UI.button(gui, "THROW", UI.colors.orange, { Size = UDim2.fromOffset(90, 60),
			Position = UDim2.new(1, -110, 1, -150), AnchorPoint = Vector2.new(0, 1) }, function()
				if held then
					release(1)
				end
			end)
		Throwing.grabBtn, Throwing.throwBtn = grabBtn, throwBtn
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.E then
			Throwing.toggleGrab()
		elseif input.KeyCode == Enum.KeyCode.Q and held then
			charging = true
			charge = 0
		end
	end)
	UserInputService.InputEnded:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.Q and charging then
			charging = false
			meterBack.Visible = false
			if held then
				release(math.clamp(0.35 + charge, 0.35, 1))
			end
			charge = 0
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not enabled then
			return
		end
		local cam = camera()
		if held and hold and cam and held.Parent then
			if charging then
				charge = math.min(1, charge + dt * 1.1)
				meterBack.Visible = true
				meter.Size = UDim2.fromScale(charge, 1)
			end
			local goal = Throwing.goal :: Attachment
			goal.WorldCFrame = cam.CFrame * CFrame.new(0, -0.4, -reach) * CFrame.Angles(0, os.clock() % (math.pi * 2), 0)
			hint.Text = charging and "Release Q to THROW" or "[Q] throw   ·   [E] drop"
		elseif held then
			held = nil
		else
			local t = target()
			hint.Text = t and ("[E] pick up  " .. (t.Parent and t.Parent.Name or t.Name)) or ""
			meterBack.Visible = false
		end
	end)
end

function Throwing.toggleGrab()
	if held then
		release(0)
	else
		local t = target()
		if t then
			pickUp(t)
		end
	end
end

return Throwing
