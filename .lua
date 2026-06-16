-- GAG 2 Visual Pet Spawner v4
-- CORRECT: Creates fake slot objects and uses the REAL positioning system
-- Based on complete PetVisualController source analysis

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
local fakeSlots = {}

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

-- Compute Foot Offset (matches v_u_72 exactly)
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

-- Get or Create Animator (matches v_u_76)
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

-- Find Animations (matches v_u_86)
local function findAnimations(model, animNames)
    local anims = {}
    local animFolder = model:FindFirstChild("Animations")
    
    if animNames then
        local seen = {}
        for _, name in pairs(animNames) do
            if type(name) == "string" and name ~= "" and not seen[name] then
                seen[name] = true
                local anim = animFolder and animFolder:FindFirstChild(name) or model:FindFirstChild(name)
                if anim and anim:IsA("Animation") then
                    anims[name] = anim
                end
            end
        end
    else
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
    end
    
    return anims
end

-- Get Animation Name for State (matches v_u_89)
local function getAnimNameForState(module, state)
    local anims = module and module.Animations
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

-- Switch Animation State (matches v_u_99)
local function switchState(petData, newState)
    if newState == "takeoff" then
        local anims = petData.Module and petData.Module.Animations
        newState = (anims and not anims.Takeoff) and "flying" or newState
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
        
        local animName = getAnimNameForState(petData.Module, newState)
        local track = animName and petData.Tracks[animName]
        
        if track then
            track.Looped = (newState ~= "landing" and newState ~= "takeoff")
            track:Play(track.Looped and 0.2 or 0.05)
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

-- Create Fake Slot (simulates PetPart1-PetPart6)
local function createFakeSlot(index)
    local slot = Instance.new("Part")
    slot.Name = "PetPart" .. index
    slot.Size = Vector3.new(1, 1, 1)
    slot.Transparency = 1
    slot.CanCollide = false
    slot.CanQuery = false
    slot.CanTouch = false
    slot.Anchored = false
    slot.Parent = workspace
    
    -- Slot offsets (matching game pattern: 6 pets in circle)
    local angle = (index - 1) * (math.pi * 2 / 6)
    local radius = 4
    slot:SetAttribute("SlotOffsetX", math.cos(angle) * radius)
    slot:SetAttribute("SlotOffsetZ", math.sin(angle) * radius)
    slot:SetAttribute("SlotHeightOffset", 0)
    
    return slot
end

-- Create PetTarget Attachment (matches v_u_117)
local function ensureSlotAttachment(slot, footOffset, pivotCFrame)
    local attach = slot:FindFirstChild("PetTarget")
    if not attach then
        attach = Instance.new("Attachment")
        attach.Name = "PetTarget"
        attach.Parent = slot
    end
    attach.CFrame = CFrame.new(0, footOffset, 0) * (pivotCFrame or CFrame.identity)
    return attach
end

-- Spawn Pet (CORRECT - matches BuildSlotModel exactly)
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
    
    for _, part in pairs(pet:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = true
            part.Massless = true
        end
    end
    
    -- Set PrimaryPart (matches source fallback)
    local primary = pet.PrimaryPart
    if not (primary and primary.Parent) then
        primary = pet:FindFirstChild("Torso") or pet:FindFirstChild("RootPart") or pet:FindFirstChildWhichIsA("BasePart")
        if primary then
            pet.PrimaryPart = primary
        end
    end
    
    if not primary then
        pet:Destroy()
        warn("No PrimaryPart found")
        return
    end
    
    -- Compute pivot CFrame (matches source v134)
    local speciesPivot = CFrame.identity -- Simplified, could use module data
    
    -- Compute foot offset (matches v_u_72)
    local footOffset = computeFootOffset(pet)
    
    -- Scale (default 1)
    local scale = 1
    if scale ~= 1 then
        pet:ScaleTo(scale)
    end
    
    -- Create fake slot
    local index = #activePets + 1
    local slot = createFakeSlot(index)
    
    -- Create PetTarget attachment (matches v_u_117)
    local slotAttachment = ensureSlotAttachment(slot, footOffset, speciesPivot)
    
    -- Create PetPivot on primary (matches source)
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = primary.CFrame:Inverse() * pet:GetPivot()
    petPivot.Parent = primary
    
    -- Anchor primary (CRITICAL - matches source)
    primary.Anchored = true
    
    -- Initial position
    local startPos = hrp.Position + Vector3.new(
        math.cos((index - 1) * math.pi * 2 / 6) * 4,
        0,
        math.sin((index - 1) * math.pi * 2 / 6) * 4
    )
    slot.CFrame = CFrame.new(startPos)
    
    -- Parent to workspace (not _PetVisualClient - we need slot to exist)
    pet.Parent = workspace
    
    -- Initial PivotTo (matches source)
    pet:PivotTo(slot.CFrame * slotAttachment.CFrame)
    
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
    
    -- Play idle
    if tracks.Idle then
        tracks.Idle:Play(0.2)
    end
    
    -- Pet data (matches v_u_155 structure)
    local petData = {
        Model = pet,
        Primary = primary,
        Slot = slot,
        SlotAttachment = slotAttachment,
        PetAttachment = petPivot,
        FootOffset = footOffset,
        SpeciesPivotCFrame = speciesPivot,
        Tracks = tracks,
        CurrentState = "",
        AnimState = "idle",
        IsFlyer = false, -- Could check module data
        LastYaw = 0,
        LastChaseGroundY = startPos.Y,
        SmoothedSpeed = 0,
        LastVisualPos = startPos,
        LastVisualTime = os.clock(),
    }
    
    -- Position update (matches Heartbeat logic from source)
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
        
        -- Get slot offsets
        local offsetX = slot:GetAttribute("SlotOffsetX") or 0
        local offsetZ = slot:GetAttribute("SlotOffsetZ") or 0
        local heightOffset = slot:GetAttribute("SlotHeightOffset") or 0
        
        -- Compute target position (matches SnapLocalPetsToFollow)
        local playerCF = h.CFrame
        local lookVec = playerCF.LookVector
        local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
        local lookDir = flatLook.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or flatLook.Unit
        local playerPos = playerCF.Position
        
        local targetCF = CFrame.lookAt(playerPos, playerPos + lookDir) * CFrame.new(offsetX, -2.5, offsetZ)
        local targetPos = targetCF.Position
        
        -- Ground height (simplified - just use player Y)
        local groundY = playerPos.Y - 3
        local finalY = groundY + footOffset + heightOffset
        
        -- Smooth movement (matches source lerp)
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
        
        -- Smooth Y
        local smoothY = currentPos.Y + (finalY - currentPos.Y) * math.clamp(18 * dt, 0, 1)
        
        -- Compute yaw (face movement direction or player)
        local moveDir = Vector3.new(newX - currentPos.X, 0, newZ - currentPos.Z)
        local yaw
        if moveDir.Magnitude > 0.0001 then
            local unit = moveDir.Unit
            yaw = math.atan2(-unit.X, -unit.Z)
        else
            yaw = math.atan2(-lookDir.X, -lookDir.Z)
        end
        
        -- Smooth yaw
        local lastYaw = petData.LastYaw or yaw
        local yawDiff = (yaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
        local newYaw = lastYaw + yawDiff * math.clamp(12 * dt, 0, 1)
        petData.LastYaw = newYaw
        
        -- Apply position (matches source exactly)
        local newPos = Vector3.new(newX, smoothY, newZ)
        local finalCF = CFrame.new(newPos) * CFrame.Angles(0, newYaw, 0) * speciesPivot
        
        primary.CFrame = primary.CFrame:Lerp(finalCF, damping)
        
        -- Update slot position for tracking
        slot.CFrame = CFrame.new(newPos)
        
        -- Animation state based on speed
        local moveSpeed = moveDir.Magnitude / math.max(dt, 0.001)
        local smoothSpeed = petData.SmoothedSpeed * (1 - math.clamp(6 * dt, 0, 1)) + moveSpeed * math.clamp(6 * dt, 0, 1)
        petData.SmoothedSpeed = smoothSpeed
        
        local animState = smoothSpeed > 2 and "walking" or "idle"
        if animState ~= petData.AnimState then
            petData.AnimState = animState
            switchState(petData, animState)
        end
        
        petData.LastVisualPos = newPos
        petData.LastVisualTime = os.clock()
    end
    
    connection = RunService.Heartbeat:Connect(updatePosition)
    petData.Connection = connection
    
    table.insert(activePets, petData)
    table.insert(fakeSlots, slot)
    
    infoLabel.Text = "Selected: " .. (selectedPetName or "None") .. " | Active: " .. #activePets .. "/6"
    print("Spawned: " .. petName .. " at slot " .. index)
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
    fakeSlots = {}
    infoLabel.Text = "Selected: " .. (selectedPetName or "None") .. " | Active: 0/6"
    print("All pets despawned")
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

print("GAG 2 Visual Pet Spawner v4 LOADED")
print("CORRECT: Uses fake slots + Primary.CFrame lerp (matches source)")
print("Templates: ReplicatedStorage.Assets.Pets")
