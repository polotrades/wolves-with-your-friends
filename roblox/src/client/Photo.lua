-- Camera filters and photo rendering. A photo is a frozen copy of your character (plus a little office backdrop)
-- seen from the desk webcam, so the Files app can show it again later in a ViewportFrame.
local Photo = {}

Photo.FILTERS = { "Normal", "Warm", "Cool", "Noir" }

-- how each filter tints the viewport
function Photo.apply(vp: ViewportFrame, filter: string)
	vp.Ambient = Color3.fromRGB(170, 170, 170)
	vp.LightColor = Color3.fromRGB(255, 255, 255)
	vp.ImageColor3 = Color3.new(1, 1, 1)
	if filter == "Warm" then
		vp.ImageColor3 = Color3.fromRGB(255, 225, 185)
		vp.LightColor = Color3.fromRGB(255, 220, 170)
	elseif filter == "Cool" then
		vp.ImageColor3 = Color3.fromRGB(190, 215, 255)
		vp.LightColor = Color3.fromRGB(200, 225, 255)
	elseif filter == "Noir" then
		vp.ImageColor3 = Color3.fromRGB(215, 215, 215)
		vp.Ambient = Color3.fromRGB(90, 90, 90)
	end
end

-- grayscale every part of a model (Noir)
function Photo.desaturate(model: Instance)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local c = d.Color
			local l = c.R * 0.3 + c.G * 0.59 + c.B * 0.11
			d.Color = Color3.new(l, l, l)
		elseif d:IsA("Decal") or d:IsA("Texture") then
			d.Color3 = Color3.fromRGB(200, 200, 200)
		elseif d:IsA("Clothing") then
			d.Color3 = Color3.fromRGB(170, 170, 170)
		end
	end
end

-- a simple office wall behind you: panels, a window with the city and a plant
function Photo.backdrop(cam: CFrame, parent: Instance)
	local folder = Instance.new("Model")
	folder.Name = "Backdrop"
	local function block(size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?)
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cam * offset
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Parent = folder
		return p
	end
	block(Vector3.new(30, 18, 0.5), CFrame.new(0, 0, -9), Color3.fromRGB(205, 190, 165))
	block(Vector3.new(8, 5, 0.3), CFrame.new(4.5, 2.2, -8.6), Color3.fromRGB(120, 170, 220), Enum.Material.Glass)
	for i = 0, 5 do
		block(Vector3.new(0.7, 1 + (i % 3) * 0.9, 0.2), CFrame.new(1.5 + i * 1.2, 0.3 + (i % 3) * 0.45, -8.4),
			Color3.fromRGB(60, 80, 110))
	end
	block(Vector3.new(8.4, 0.3, 0.4), CFrame.new(4.5, -0.4, -8.5), Color3.fromRGB(60, 50, 45), Enum.Material.Wood)
	block(Vector3.new(1.2, 1.4, 1.2), CFrame.new(-5, -3.2, -7.5), Color3.fromRGB(150, 90, 60))
	local leaf = block(Vector3.new(2.2, 2.4, 2.2), CFrame.new(-5, -1.4, -7.5), Color3.fromRGB(60, 150, 70), Enum.Material.Grass)
	leaf.Shape = Enum.PartType.Ball
	folder.Parent = parent
	return folder
end

-- draws a saved photo into a frame
function Photo.render(parent: GuiObject, photo): ViewportFrame
	local vp = Instance.new("ViewportFrame")
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	vp.BorderSizePixel = 0
	local cam = Instance.new("Camera")
	cam.FieldOfView = 55
	cam.CFrame = photo.cam
	cam.Parent = vp
	vp.CurrentCamera = cam
	local world = Instance.new("WorldModel")
	world.Parent = vp
	photo.model:Clone().Parent = world
	Photo.apply(vp, photo.filter)
	vp.Parent = parent
	return vp
end

return Photo
