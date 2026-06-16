-- GAG 2 Visual Pet Spawner v2
-- Matches PetVisualController mechanics from source
-- Templates: ReplicatedStorage.Assets.Pets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local petsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")
local visualClient = workspace:WaitForChild("_PetVisualClient")

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VisualPetSpawner"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 480)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -240)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

-- Title
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Visual Pet Spawner"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Search
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 50)
searchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
searchBox.Text = ""
searchBox.PlaceholderText = "Search pets..."
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
searchBox.TextSize = 14
searchBox.Font = Enum.Font.Gotham
searchBox.Parent = mainFrame

Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)

-- Pet List
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -210)
scrollFrame.Position = UDim2.new(0, 10, 0, 90)
scrollFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 6)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

-- Settings
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(1, -20, 0, 60)
settingsFrame.Position = UDim2.new(0, 10, 1, -150)
settingsFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
settingsFrame.BorderSizePixel = 0
settingsFrame.Parent = mainFrame

Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0, 6)

local scaleLabel = Instance.new("TextLabel")
scaleLabel.Size = UDim2.new(0.3, 0, 0, 25)
scaleLabel.Position = UDim2.new(0, 8, 0, 5)
scaleLabel.BackgroundTransparency = 1
scaleLabel.Text = "Scale:"
scaleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
scaleLabel.TextSize = 12
scaleLabel.Font = Enum.Font.Gotham
scaleLabel.TextXAlignment = Enum.TextXAlignment.Left
scaleLabel.Parent = settingsFrame

local scaleBox = Instance.new("TextBox")
scaleBox.Size = UDim2.new(0.6, -10, 0, 22)
scaleBox.Position = UDim2.new(0.35, 0, 0, 5)
scaleBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
scaleBox.Text = "1"
scaleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleBox.TextSize = 12
scaleBox.Font = Enum.Font.Gotham
scaleBox.Parent = settingsFrame

Instance.new("UICorner", scaleBox).CornerRadius = UDim.new(0, 4)

local offsetLabel = Instance.new("TextLabel")
offsetLabel.Size = UDim2.new(0.3, 0, 0, 25)
offsetLabel.Position = UDim2.new(0, 8, 0, 32)
offsetLabel.BackgroundTransparency = 1
offsetLabel.Text = "Height:"
offsetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
offsetLabel.TextSize = 12
offsetLabel.Font = Enum.Font.Gotham
offsetLabel.TextXAlignment = Enum.TextXAlignment.Left
offsetLabel.Parent = settingsFrame

local offsetBox = Instance.new("TextBox")
offsetBox.Size = UDim2.new(0.6, -10, 0, 22)
offsetBox.Position = UDim2.new(0.35, 0, 0, 32)
offsetBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
offsetBox.Text = "0"
offsetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
offsetBox.TextSize = 12
offsetBox.Font = Enum.Font.Gotham
offsetBox.Parent = settingsFrame

Instance.new("UICorner", offsetBox).CornerRadius = UDim.new(0, 4)

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 20)
infoLabel.Position = UDim2.new(0, 10, 1, -85)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Selected: None | Active: 0/6"
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Parent = mainFrame

-- Buttons
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(1, -20, 0, 35)
btnFrame.Position = UDim2.new(0, 10, 1, -60)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = mainFrame

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(0.48, -4, 1, 0)
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
spawnBtn.Text = "Spawn"
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.TextSize = 14
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.Parent = btnFrame

Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)

local despawnBtn = Instance.new("TextButton")
despawnBtn.Size = UDim2.new(0.48, -4, 1, 0)
despawnBtn.Position = UDim2.new(0.52, 0, 0, 0)
despawnBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
despawnBtn.Text = "Despawn All"
despawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
despawnBtn.TextSize = 14
despawnBtn.Font = Enum.Font.GothamBold
despawnBtn.Parent = btnFrame

Instance.new("UICorner", despawnBtn).CornerRadius = UDim.new(0, 6)

-- Open Button
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 130, 0, 40)
openBtn.Position = UDim2.new(0, 15, 0, 15)
openBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
openBtn.Text = "Pet Spawner"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextSize = 14
openBtn.Font = Enum.Font.GothamBold
openBtn.Visible = false
openBtn.Parent = screenGui

Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)

-- State
local selectedPetName = nil
local activePets = {}
local maxPets = 6

-- Dragging
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Compute Foot Offset (matches source v_u_72)
local function computeFootOffset(model)
    local pivotY = model:GetPivot().Position.Y
    local lowest = math.huge
    
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local cf = part.CFrame
            local size = part.Size
            local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
            
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    local cornerY = (cf * Vector3.new(x * hx, y * hy, -hz)).Y
                    if cornerY < lowest then lowest = cornerY end
                    cornerY = (cf * Vector3.new(x * hx, y * hy, hz)).Y
                    if cornerY < lowest then lowest = cornerY end
                end
            end
        end
    end
    
    return lowest == math.huge and 0 or pivotY - lowest
end

-- Get or Create Animator (matches source v_u_76)
local function getOrCreateAnimator(model)
    local animController = model:FindFirstChildOfClass("AnimationController")
    if not animController then
        animController = Instance.new("AnimationController")
        animController.Parent = model
    end
    local animator = animController:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = animController
    end
    return animator
end

-- Find Animations (matches source v_u_86)
local function findAnimations(model)
    local anims = {}
    local animFolder = model:FindFirstChild("Animations")
    
    if animFolder then
        for _, child in pairs(animFolder:GetChildren()) do
            if child:IsA("Animation") then
                anims[child.Name] = child
            end
        end
    end
    
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Animation") then
            anims[child.Name] = child
        end
    end
    
    return anims
end

-- Populate List
local petButtons = {}

local function updateList(filter)
    for _, btn in ipairs(petButtons) do btn:Destroy() end
    petButtons = {}
    
    for _, pet in ipairs(petsFolder:GetChildren()) do
        if pet:IsA("Model") and (not filter or string.find(string.lower(pet.Name), string.lower(filter))) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 32)
            btn.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
            btn.Text = pet.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 13
            btn.Font = Enum.Font.Gotham
            btn.Parent = scrollFrame
            
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                selectedPetName = pet.Name
                infoLabel.Text = "Selected: " .. pet.Name .. " | Active: " .. #activePets .. "/6"
                for _, b in ipairs(petButtons) do b.BackgroundColor3 = Color3.fromRGB(65, 65, 65) end
                btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
            end)
            
            table.insert(petButtons, btn)
        end
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

updateList()

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateList(searchBox.Text)
end)

-- Spawn Pet (matches source mechanics)
local function spawnVisualPet(petName)
    if #activePets >= maxPets then
        warn("Max pets reached (6/6)")
        return
    end
    
    local template = petsFolder:FindFirstChild(petName)
    if not template then 
        warn("Pet not found: " .. petName) 
        return 
    end
    
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Clone and setup (matches v_u_111)
    local pet = template:Clone()
    
    -- Setup parts (matches source)
    for _, part in pairs(pet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = true
            part.Massless = true
        end
    end
    
    -- Set PrimaryPart (matches source fallback logic)
    local primary = pet.PrimaryPart
    if not (primary and primary.Parent) then
        primary = pet:FindFirstChild("RootPart") or pet:FindFirstChild("Torso") or pet:FindFirstChildWhichIsA("BasePart")
        if primary then
            pet.PrimaryPart = primary
        end
    end
    
    if not primary then
        pet:Destroy()
        warn("No PrimaryPart found for " .. petName)
        return
    end
    
    -- Apply scale
    local scale = tonumber(scaleBox.Text) or 1
    if scale ~= 1 then
        pet:ScaleTo(scale)
    end
    
    -- Compute foot offset (matches v_u_72)
    local footOffset = computeFootOffset(pet)
    
    -- Create pivot attachment (matches v_u_117)
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.Parent = primary
    
    -- Position in circle around player
    local index = #activePets + 1
    local angle = (index - 1) * (math.pi * 2 / 6)
    local radius = 4
    
    -- Parent to visual client (matches source)
    pet.Parent = visualClient
    
    -- Setup animations
    local animator = getOrCreateAnimator(pet)
    local animations = findAnimations(pet)
    local tracks = {}
    
    for name, anim in pairs(animations) do
        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if success and track then
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Movement
            tracks[name] = track
        end
    end
    
    -- Play idle animation if available
    if tracks.Idle then
        tracks.Idle:Play(0.2)
    elseif tracks.idle then
        tracks.idle:Play(0.2)
    end
    
    -- Position tracking
    local startTime = tick()
    local connection
    
    local function updatePosition()
        if not pet or not pet.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local char = player.Character
        if not char then return end
        local h = char:FindFirstChild("HumanoidRootPart")
        if not h then return end
        
        local time = tick() - startTime
        local floatY = math.sin(time * 2 + index) * 0.3
        local heightOffset = tonumber(offsetBox.Text) or 0
        
        -- Position in circle with foot offset applied
        local targetPos = h.Position + Vector3.new(
            math.cos(angle) * radius,
            footOffset + heightOffset + floatY,
            math.sin(angle) * radius
        )
        
        -- Smoothly interpolate
        local currentPos = primary.Position
        local newPos = currentPos:Lerp(targetPos, 0.1)
        
        primary.CFrame = CFrame.new(newPos) * CFrame.Angles(0, math.atan2(
            h.Position.X - newPos.X,
            h.Position.Z - newPos.Z
        ) + math.pi, 0)
    end
    
    connection = RunService.Heartbeat:Connect(updatePosition)
    
    table.insert(activePets, {
        Model = pet,
        Connection = connection,
        Name = petName,
        Primary = primary,
        Tracks = tracks
    })
    
    infoLabel.Text = "Selected: " .. (selectedPetName or "None") .. " | Active: " .. #activePets .. "/6"
end

-- Despawn All
local function despawnAllPets()
    for _, petData in ipairs(activePets) do
        if petData.Connection then petData.Connection:Disconnect() end
        if petData.Tracks then
            for _, track in pairs(petData.Tracks) do
                if track.IsPlaying then track:Stop(0) end
            end
        end
        if petData.Model and petData.Model.Parent then
            petData.Model:Destroy()
        end
    end
    activePets = {}
    infoLabel.Text = "Selected: " .. (selectedPetName or "None") .. " | Active: 0/6"
end

-- Events
spawnBtn.MouseButton1Click:Connect(function()
    if selectedPetName then 
        spawnVisualPet(selectedPetName) 
    else 
        warn("Select a pet first!") 
    end
end)

despawnBtn.MouseButton1Click:Connect(despawnAllPets)

closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
    openBtn.Visible = true
end)

openBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = true
    openBtn.Visible = false
end)

-- Cleanup
player.CharacterAdded:Connect(despawnAllPets)

print("GAG 2 Visual Pet Spawner v2 Loaded!")
print("Source: ReplicatedStorage.Assets.Pets")
print("Visual Client: workspace._PetVisualClient")
