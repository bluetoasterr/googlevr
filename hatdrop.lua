local ps = game:GetService("RunService").PostSimulation
local input = game:GetService("UserInputService")
local Player = game.Players.LocalPlayer
local options = getgenv().options or {}

local function createpart(size, name,h)
	local Part = Instance.new("Part")
	if h and options and options.outlinesEnabled then 
		local SelectionBox = Instance.new("SelectionBox")
		SelectionBox.Adornee = Part
		SelectionBox.LineThickness = 0.05
		SelectionBox.Parent = Part
	end
	Part.Parent = workspace
	local char = game.Players.LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		Part.CFrame = char.HumanoidRootPart.CFrame
	else
		Part.CFrame = CFrame.new(0,0,0)
	end
	Part.Size = size
	Part.Transparency = 1
	Part.CanCollide = false
	Part.Anchored = true
	Part.Name = name
	return Part
end

local lefthandpart = createpart(Vector3.new(2,1,1), "moveRH",true)
local righthandpart = createpart(Vector3.new(2,1,1), "moveRH",true)
local headpart = createpart(Vector3.new(1,1,1), "moveH",false)
local lefttoypart = createpart(Vector3.new(1,1,1), "LToy",true)
local righttoypart =  createpart(Vector3.new(1,1,1), "RToy",true)
local thirdperson = false
local lefttoyenable = false
local righttoyenable = false
local lfirst = true
local rfirst = true
local ltoypos = CFrame.new(1.15,0,0) * CFrame.Angles(0,math.rad(180),0)
local rtoypos = CFrame.new(1.15,0,0) * CFrame.Angles(0,math.rad(0),0)

local parts = {
    left=lefthandpart,
    right=righthandpart,
    headhats=headpart,
    leftToy=lefttoypart,
    rightToy=righttoypart,
}

function _isnetworkowner(Part)
	return Part.ReceiveAge == 0
end

function filterMeshID(id)
	return (string.find(id,'assetdelivery')~=nil and string.match(string.sub(id,37,#id),"%d+")) or string.match(id,"%d+")
end

function findMeshID(id)
    for i,v in pairs(getgenv().headhats or {}) do
        if i=="meshid:"..id then return true,"headhats" end
    end
    if getgenv().right=="meshid:"..id then return true,"right" end
    if getgenv().left=="meshid:"..id then return true,"left" end
    if options.leftToy and options.leftToy=="meshid:"..id then return true,"leftToy" end
    if options.rightToy and options.rightToy=="meshid:"..id then return true,"rightToy" end
    return false
end

function findHatName(id)
    for i,v in pairs(getgenv().headhats or {}) do
        if i==id then return true,"headhats" end
    end
    if getgenv().right==id then return true,"right" end
    if getgenv().left==id then return true,"left" end
    if options.leftToy and options.leftToy==id then return true,"leftToy" end
    if options.rightToy and options.rightToy==id then return true,"rightToy" end
    return false
end

function Align(Part1,Part0,cf,isflingpart) 
    local up = isflingpart
    local velocity = Vector3.new(20,20,20)
    local con;con=ps:Connect(function()
        if up~=nil then up=not up end
        if not Part1:IsDescendantOf(workspace) then con:Disconnect() return end
        if not _isnetworkowner(Part1) then return end
        Part1.CanCollide=false
        Part1.CFrame=Part0.CFrame*cf
        Part1.Velocity = velocity
    end)

    return {SetVelocity = function(self,v) velocity=v end,SetCFrame = function(self,v) cf=v end,}
end

function NewHatdropCallback(Character, callback)
    local block = false
    local character = Character
    
    game.Players.LocalPlayer.Character = nil
    game.Players.LocalPlayer.Character = character
    wait(game.Players.RespawnTime + 0.05)
    
    if character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead,false)
    end
    
    for i, v in pairs(character:GetChildren()) do
        if v.Name == "Torso" or v.Name == "UpperTorso" then
            v:Destroy()
        end
    end
    
    if character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart:Destroy()
    end
    
    for i,v in pairs(character:GetChildren()) do
        if v:IsA("Accessory") then
            sethiddenproperty(v,"BackendAccoutrementState", 0)
        end
    end
    
    if block == true then 
        for i,v in pairs(character:GetDescendants()) do
            if v:IsA("SpecialMesh") then
                v:Destroy()
            end
        end
    end
    
    for i,v in pairs(character:GetChildren()) do
        if v:IsA("BasePart") and v.Name ~= "Head" then
            v:Destroy()
        end
    end
    
    if character:FindFirstChild("Head") then
        character.Head:remove()
    end
    
    wait(0.1)
    
    local foundmeshids = {}
    local allhats = {}
    
    for i,v in pairs(character:GetChildren()) do
        if not v:IsA"Accessory" then continue end
        if not v:FindFirstChild("Handle") then continue end
        local mesh = v.Handle:FindFirstChildOfClass("SpecialMesh")
        if not mesh then continue end
        
        local is,d = findMeshID(filterMeshID(mesh.MeshId))
        if foundmeshids["meshid:"..filterMeshID(mesh.MeshId)] then 
            is = false 
        else 
            foundmeshids["meshid:"..filterMeshID(mesh.MeshId)] = true 
        end
	
        if is then
            table.insert(allhats,{v,d,"meshid:"..filterMeshID(mesh.MeshId)})
        else
            local is,d = findHatName(v.Name)
            if not is then continue end
            table.insert(allhats,{v,d,v.Name})
        end
    end
    
    callback(allhats)
end

local cam = workspace.CurrentCamera
cam.CameraType = "Scriptable"
cam.HeadScale = (options and options.headscale) or 1

game:GetService("StarterGui"):SetCore("VREnableControllerModels", false)

local rightarmalign = nil

getgenv().con5 = input.UserCFrameChanged:connect(function(part,move)
    cam.CameraType = "Scriptable"
	cam.HeadScale = (options and options.headscale) or 1
    if part == Enum.UserCFrame.Head then
        headpart.CFrame = cam.CFrame*(CFrame.new(move.p*(cam.HeadScale-1))*move)
    elseif part == Enum.UserCFrame.LeftHand then
        local leftOffset = (options and options.lefthandrotoffset) or Vector3.new(0,0,0)
        lefthandpart.CFrame = cam.CFrame*(CFrame.new(move.p*(cam.HeadScale-1))*move*CFrame.Angles(math.rad(leftOffset.X),math.rad(leftOffset.Y),math.rad(leftOffset.Z)))
        if lefttoyenable then
            lefttoypart.CFrame = lefthandpart.CFrame * ltoypos
        end
    elseif part == Enum.UserCFrame.RightHand then
        local rightOffset = (options and options.righthandrotoffset) or Vector3.new(0,0,0)
        righthandpart.CFrame = cam.CFrame*(CFrame.new(move.p*(cam.HeadScale-1))*move*CFrame.Angles(math.rad(rightOffset.X),math.rad(rightOffset.Y),math.rad(rightOffset.Z)))
        if righttoyenable then
            righttoypart.CFrame = righthandpart.CFrame * rtoypos
        end
    end
end)

getgenv().con4 = input.InputBegan:connect(function(key)
	if options and options.thirdPersonButtonToggle and key.KeyCode == options.thirdPersonButtonToggle then
		thirdperson = not thirdperson
	end
	if key.KeyCode == Enum.KeyCode.ButtonR1 then
		R1down = true
	end
    if options and options.leftToyBind and key.KeyCode == options.leftToyBind then
		if not lfirst then
			ltoypos = lefttoypart.CFrame:ToObjectSpace(lefthandpart.CFrame):Inverse()
		end
		lfirst = false
        lefttoyenable = not lefttoyenable
    end
	if options and options.rightToyBind and key.KeyCode == options.rightToyBind then
		if not rfirst then
			rtoypos = righttoypart.CFrame:ToObjectSpace(righthandpart.CFrame):Inverse()
		end
		rfirst = false
        righttoyenable = not righttoyenable
    end
    if key.KeyCode == Enum.KeyCode.ButtonR2 and rightarmalign~=nil then
        R2down = true
    end
end)

getgenv().con3 = input.InputEnded:connect(function(key)
	if key.KeyCode == Enum.KeyCode.ButtonR1 then
		R1down = false
	end
    if key.KeyCode == Enum.KeyCode.ButtonR2 and rightarmalign~=nil then
        R2down = false
    end
end)

local negitive = true
getgenv().con2 = game:GetService("RunService").RenderStepped:connect(function()
	if R1down and options then
		local rightOffset = options.righthandrotoffset or Vector3.new(0,0,0)
		local controllerOffset = options.controllerRotationOffset or Vector3.new(0,0,0)
		cam.CFrame = cam.CFrame:Lerp(cam.CoordinateFrame + (righthandpart.CFrame * CFrame.Angles(math.rad(rightOffset.X),math.rad(rightOffset.Y),math.rad(rightOffset.Z)):Inverse() * CFrame.Angles(math.rad(controllerOffset.X),math.rad(controllerOffset.Y),math.rad(controllerOffset.Z))).LookVector * cam.HeadScale/2, 0.5)
	end
    if R2down and rightarmalign then
        negitive=not negitive
        rightarmalign:SetVelocity(Vector3.new(0,0,-99999999))
        local rightOffset = (options and options.righthandrotoffset) or Vector3.new(0,0,0)
        rightarmalign:SetCFrame(CFrame.Angles(math.rad(rightOffset.X),math.rad(rightOffset.Y),math.rad(rightOffset.Z)):Inverse()*CFrame.new(0,0,8*(negitive and -1 or 1)))
    elseif rightarmalign then
        rightarmalign:SetVelocity(Vector3.new(0.1,0.1,0.1))
        rightarmalign:SetCFrame(CFrame.new(0,0,0))
    end
end)

NewHatdropCallback(Player.Character, function(allhats)
    for i,v in pairs(allhats) do
        if not v[1]:FindFirstChild("Handle") then continue end
        if v[2]=="headhats" then 
            local transparency = 1
            if options and options.HeadHatTransparency then
                transparency = options.HeadHatTransparency
            end
            v[1].Handle.Transparency = transparency
        end

        local align = Align(v[1].Handle,parts[v[2]],((v[2]=="headhats")and (getgenv()[v[2]] and getgenv()[v[2]][(v[3])])) or CFrame.identity)
        if v[2]=="right" then
            rightarmalign = align
        end
    end
end)

getgenv().conn = Player.CharacterAdded:Connect(function(Character)
    wait(0.5)
    NewHatdropCallback(Character, function(allhats)
        for i,v in pairs(allhats) do
            if not v[1]:FindFirstChild("Handle") then continue end
            if v[2]=="headhats" then 
                local transparency = 1
                if options and options.HeadHatTransparency then
                    transparency = options.HeadHatTransparency
                end
                v[1].Handle.Transparency = transparency
            end

            local align = Align(v[1].Handle,parts[v[2]],((v[2]=="headhats")and (getgenv()[v[2]] and getgenv()[v[2]][(v[3])])) or CFrame.identity)
            if v[2]=="right" then
                rightarmalign = align
            end
        end
    end)
end)
