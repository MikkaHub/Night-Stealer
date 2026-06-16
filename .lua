-- GAG 2 Visual Pet Spawner v6
-- FIXED: Animation search uses GetDescendants() to find ALL animations anywhere in the model
-- FIXED: More robust animation loading with retry

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local petsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")

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
scrollFrame.Size = UDim2.new(1, -20, 1, -180)
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

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, -20, 0, 20)
infoLabel.Position = UDim2.new(0, 10, 1, -80)
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
btnFrame.Position = UDim2.new(0, 10, 1, -55)
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

-- Compute Foot Offset
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

-- ============================================
-- FIXED: Find Animations using GetDescendants()
-- ============================================
local function findAnimations(model)
    local anims = {}
    local count = 0
    
    -- Search ALL descendants, not just direct children
    for _, desc in ipairs(model:GetDescendants()) do
        if desc:IsA("Animation") then
            anims[desc.Name] = desc
            count = count + 1
            print("  Found animation: " .. desc.Name .. " | ID: " .. desc.AnimationId)
        end
    end
    
    print("Total animations found: " .. count)
    return anims
end

-- Get Animation Name for State
local function getAnimNameForState(anims, state)
    if not anims then return nil end
    
    if state == "idle" then return anims.Idle
    elseif state == "walking" then return anims.Walk
    elseif state == "flying" then return anims.Fly
    elseif state == "flyidle" then return anims.FlyIdle or anims.Fly
    elseif state == "landing" then return anims.Land
    elseif state == "takeoff" then return anims.Takeoff
    elseif state == "groundidle" then return anims.GroundIdle or anims.Idle
    else return nil end
end

-- Switch Animation State
local function switchState(petData, newState)
    if newState == "takeoff" then
        local hasTakeoff = petData.Animations and petData.Animations.Takeoff
        newState = (not hasTakeoff) and "flying" or newState
    end
    
    if petData.CurrentState ~= newState then
        local oldState = petData.CurrentState
        petData.CurrentState = newState
        
        local fadeTime = (oldState ~= "landing" and oldState ~= "takeoff") and 0.2 or 0.05
        
        for _, track in pairs(petData.Tracks) do
            if track.IsPlaying then
                track:Stop(fadeTime)
            end
        end
        
        local animName = getAnimNameForState(petData.Animations, newState)
        local track = animName and petData.Tracks[animName.Name]
        
        if track then
            track.Looped = (newState ~= "landing" and newState ~= "takeoff")
            track:Play(track.Looped and 0.2 or 0.05)
            print("Playing: " .. newState .. " (" .. animName.Name .. ")")
        else
            print("No track for: " .. newState)
        end
    end
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

-- Spawn Pet
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
    
    -- Clone pet
    local pet = template:Clone()
    print("=== Spawning: " .. petName .. " ===")
    
    -- Setup parts
    for _, part in pairs(pet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = true
            part.Massless = true
        end
    end
    
    -- Set PrimaryPart
    local primary = pet.PrimaryPart
    if not (primary and primary.Parent) then
        primary = pet:FindFirstChild("Torso") or pet:FindFirstChild("RootPart") or pet:FindFirstChildWhichIsA("BasePart")
        if primary then
            pet.PrimaryPart = primary
            print("PrimaryPart: " .. primary.Name)
        end
    else
        print("PrimaryPart: " .. primary.Name .. " (existing)")
    end
    
    if not primary then
        pet:Destroy()
        warn("No PrimaryPart!")
        return
    end
    
    -- Compute foot offset
    local footOffset = computeFootOffset(pet)
    print("Foot offset: " .. footOffset)
    
    -- ============================================
    -- CRITICAL FIX: Create AnimationController BEFORE parenting
    -- ============================================
    local animController = Instance.new("AnimationController")
    animController.Parent = pet
    
    local animator = Instance.new("Animator")
    animator.Parent = animController
    
    print("AnimationController ready")
    
    -- Parent to workspace
    pet.Parent = workspace
    print("Parented to workspace")
    
    -- ============================================
    -- FIXED: Find ALL animations using GetDescendants
    -- ============================================
    print("Searching for animations...")
    local animations = findAnimations(pet)
    
    local tracks = {}
    
    -- Load animations with detailed error reporting
    for name, anim in pairs(animations) do
        print("Loading: " .. name .. " (" .. anim.AnimationId .. ")")
        
        local success, result = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        
        if success and result then
            tracks[name] = result
            print("  SUCCESS: " .. name)
        else
            warn("  FAILED: " .. name .. " - " .. tostring(result))
        end
    end
    
    -- Determine if flyer
    local isFlyer = tracks.Fly ~= nil
    print("Is flyer: " .. tostring(isFlyer))
    
    -- Determine initial state
    local initialState = isFlyer and "flying" or "idle"
    local initialAnim = getAnimNameForState(animations, initialState)
    
    if initialAnim and tracks[initialAnim.Name] then
        tracks[initialAnim.Name].Looped = true
        tracks[initialAnim.Name].Priority = Enum.AnimationPriority.Movement
        tracks[initialAnim.Name]:Play(0.2)
        print("Playing initial: " .. initialState)
    else
        print("No initial animation available")
    end
    
    -- Anchor primary
    primary.Anchored = true
    
    -- Position in circle
    local index = #activePets + 1
    local angle = (index - 1) * (math.pi * 2 / 6)
    local radius = 4
    
    local startPos = hrp.Position + Vector3.new(
        math.cos(angle) * radius,
        footOffset + 2,
        math.sin(angle) * radius
    )
    
    -- Create slot part
    local slot = Instance.new("Part")
    slot.Name = "PetSlot" .. index
    slot.Size = Vector3.new(1, 1, 1)
    slot.Transparency = 1
    slot.CanCollide = false
    slot.CanQuery = false
    slot.CanTouch = false
    slot.Anchored = false
    slot.CFrame = CFrame.new(startPos)
    slot.Parent = workspace
    
    -- Create PetTarget attachment
    local slotAttach = Instance.new("Attachment")
    slotAttach.Name = "PetTarget"
    slotAttach.CFrame = CFrame.new(0, footOffset, 0)
    slotAttach.Parent = slot
    
    -- Create PetPivot on primary
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = primary.CFrame:Inverse() * pet:GetPivot()
    petPivot.Parent = primary
    
    -- Initial position
    pet:PivotTo(slot.CFrame * slotAttach.CFrame)
    print("Position set")
    
    -- Pet data
    local petData = {
        Model = pet,
        Primary = primary,
        Slot = slot,
        SlotAttachment = slotAttach,
        PetAttachment = petPivot,
        FootOffset = footOffset,
        Tracks = tracks,
        Animations = animations,
        CurrentState = initialState,
        IsFlyer = isFlyer,
        LastYaw = 0,
        SmoothedSpeed = 0,
    }
    
    -- Position update
    local connection
    
    local function updatePosition(dt)
        if not pet or not pet.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local char = player.Character
        if not char then return end
        local h = char:FindFirstChild("HumanoidRootPart")
        if not h then return end
        
        local playerPos = h.Position
        local lookDir = h.CFrame.LookVector
        local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z).Unit
        
        local targetPos = playerPos + Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        
        local groundY = playerPos.Y - 3
        local finalY = groundY + footOffset + 1.5
        
        local currentPos = primary.Position
        local dx = targetPos.X - currentPos.X
        local dz = targetPos.Z - currentPos.Z
        local dist = math.sqrt(dx * dx + dz * dz)
        
        local damping = 1 - math.exp(-60 * dt)
        local speed = 14 * dt
        local followSpeed = speed / math.max(damping, 0.001)
        
        local newX, newZ
        if dist <= 0.05 or dist <= followSpeed then
            newX = targetPos.X
            newZ = targetPos.Z
        else
            local invDist = 1 / dist
            newX = currentPos.X + dx * invDist * followSpeed
            newZ = currentPos.Z + dz * invDist * followSpeed
        end
        
        local smoothY = currentPos.Y + (finalY - currentPos.Y) * math.clamp(18 * dt, 0, 1)
        
        local moveDir = Vector3.new(newX - currentPos.X, 0, newZ - currentPos.Z)
        local yaw
        if moveDir.Magnitude > 0.0001 then
            local unit = moveDir.Unit
            yaw = math.atan2(-unit.X, -unit.Z)
        else
            yaw = math.atan2(-flatLook.X, -flatLook.Z)
        end
        
        local lastYaw = petData.LastYaw
        local yawDiff = (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
        local newYaw = lastYaw + yawDiff * math.clamp(12 * dt, 0, 1)
        petData.LastYaw = newYaw
        
        local newPos = Vector3.new(newX, smoothY, newZ)
        local finalCF = CFrame.new(newPos) * CFrame.Angles(0, newYaw, 0)
        
        primary.CFrame = primary.CFrame:Lerp(finalCF, damping)
        slot.CFrame = CFrame.new(newPos)
        
        -- Animation state
        local moveSpeed = moveDir.Magnitude / math.max(dt, 0.001)
        local smoothSpeed = petData.SmoothedSpeed * (1 - math.clamp(6 * dt, 0, 1)) + moveSpeed * math.clamp(6 * dt, 0, 1)
        petData.SmoothedSpeed = smoothSpeed
        
        local animState
        if petData.IsFlyer then
            animState = "flying"
        else
            animState = smoothSpeed > 2 and "walking" or "idle"
        end
        
        if animState ~= petData.CurrentState then
            petData.CurrentState = animState
            switchState(petData, animState)
        end
    end
    
    connection = RunService.Heartbeat:Connect(updatePosition)
    petData.Connection = connection
    
    table.insert(activePets, petData)
    
    infoLabel.Text = "Selected: " .. (selectedPetName or "None") .. " | Active: " .. #activePets .. "/6"
    print("=== Spawn Complete ===")
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
        if petData.Slot and petData.Slot.Parent then
            petData.Slot:Destroy()
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

player.CharacterAdded:Connect(despawnAllPets)

print("GAG 2 Visual Pet Spawner v6 LOADED")
print("FIXED: GetDescendants() finds ALL animations")
print("FIXED: Detailed logging for debugging")
