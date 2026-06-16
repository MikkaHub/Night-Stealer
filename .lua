-- ============================================
-- GAG 2 VISUAL PET SPAWNER - DELTA COMPATIBLE
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- DELTA FIX: Wait for PlayerGui properly
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    warn("PlayerGui not found! Retrying...")
    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")
    PlayerGui = LocalPlayer.PlayerGui
end

-- Exact same requires from the file
local PetModules = require(ReplicatedStorage.SharedModules.PetModules)
local PetSizes = require(ReplicatedStorage.SharedData.PetSizes)
local PetTypes = require(ReplicatedStorage.SharedData.PetTypes)

-- ============================================
-- EXACT FUNCTIONS FROM UPLOADED FILE
-- ============================================

local function ApplyPetTypeTag(model, petType)
    if model then
        if petType == PetTypes.Rainbow then
            if not model:HasTag("PetRainbow") then
                model:AddTag("PetRainbow")
                return
            end
        elseif model:HasTag("PetRainbow") then
            model:RemoveTag("PetRainbow")
        end
    end
end

local function CloneSpeciesModel(species)
    local module = PetModules[species]
    if not module then
        return nil, nil
    end
    
    local assets = ReplicatedStorage:FindFirstChild("Assets")
    local petsFolder = assets and assets:FindFirstChild("Pets")
    local asset = petsFolder and petsFolder:FindFirstChild(module.AssetName) or assets:FindFirstChild(module.AssetName)
    
    if not (asset and asset:IsA("Model")) then
        return nil, nil
    end
    
    local clone = asset:Clone()
    for _, part in pairs(clone:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = true
            part.Massless = true
        end
    end
    
    return clone, module
end

local function ComputeFootOffset(model)
    local pivotY = model:GetPivot().Position.Y
    local lowest = math.huge
    
    for _, part in pairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part.Transparency < 1 then
            local size = part.Size
            local cf = part.CFrame
            local halfX = size.X * 0.5
            local halfY = size.Y * 0.5
            local halfZ = size.Z * 0.5
            
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    local cornerX = x * halfX
                    local cornerY = y * halfY
                    local cornerZneg = -1 * halfZ
                    local cornerY1 = (cf * Vector3.new(cornerX, cornerY, cornerZneg)).Y
                    if cornerY1 >= lowest then
                        cornerY1 = lowest
                    end
                    local cornerZpos = 1 * halfZ
                    lowest = (cf * Vector3.new(cornerX, cornerY, cornerZpos)).Y
                    if lowest >= cornerY1 then
                        lowest = cornerY1
                    end
                end
            end
        end
    end
    
    return lowest == math.huge and 0 or pivotY - lowest
end

local function GetOrCreateAnimator(model)
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

local function FindAnimationsOnModel(model, animList)
    local found = {}
    local animFolder = model:FindFirstChild("Animations")
    
    if animList then
        local seen = {}
        for _, name in pairs(animList) do
            if type(name) == "string" and (name ~= "" and not seen[name]) then
                seen[name] = true
                local anim = animFolder and animFolder:FindFirstChild(name) or model:FindFirstChild(name)
                if anim and anim:IsA("Animation") then
                    found[name] = anim
                end
            end
        end
        return found
    else
        if animFolder then
            for _, child in pairs(animFolder:GetChildren()) do
                if child:IsA("Animation") then
                    found[child.Name] = child
                end
            end
        end
        for _, child in pairs(model:GetChildren()) do
            if child:IsA("Animation") then
                found[child.Name] = child
            end
        end
        return found
    end
end

local function GetAnimNameForState(module, state)
    if module then
        module = module.Animations
    end
    if module then
        if state == "idle" then
            return module.Idle
        elseif state == "walking" then
            return module.Walk
        elseif state == "flying" then
            return module.Fly
        elseif state == "flyidle" then
            return module.FlyIdle or module.Fly
        elseif state == "landing" then
            return module.Land
        elseif state == "takeoff" then
            return module.Takeoff
        elseif state == "groundidle" then
            return module.GroundIdle or module.Idle
        else
            return nil
        end
    else
        return nil
    end
end

local function SwitchState(petData, newState)
    if newState == "takeoff" then
        local anims = petData.Module
        if anims then
            anims = petData.Module.Animations
        end
        newState = anims and not anims.Takeoff and "flying" or newState
    end
    
    if petData.CurrentState ~= newState then
        local oldState = petData.CurrentState
        petData.CurrentState = newState
        
        local fadeTime
        if oldState == "landing" then
            fadeTime = false
        else
            fadeTime = oldState ~= "takeoff"
        end
        local stopFade = fadeTime and 0.2 or 0.05
        
        for _, track in pairs(petData.Tracks) do
            if track.IsPlaying then
                track:Stop(stopFade)
            end
        end
        
        local animName = GetAnimNameForState(petData.Module, newState)
        if animName then
            animName = petData.Tracks[animName]
        end
        if animName then
            local looped
            if newState == "landing" then
                looped = false
            else
                looped = newState ~= "takeoff"
            end
            animName.Looped = looped
            animName:Play(animName.Looped and 0.2 or 0.05)
        end
    end
end

local function ApplyVisibility(petData, visible)
    local transparency = visible and 0 or 1
    for _, desc in pairs(petData.Model:GetDescendants()) do
        if desc ~= petData.Model.PrimaryPart then
            if desc:IsA("BasePart") then
                desc.Transparency = transparency
            elseif desc:IsA("Decal") then
                desc.Transparency = transparency
            end
        end
    end
end

-- ============================================
-- SPAWNER LOGIC
-- ============================================

local SpawnedPets = {}
local SpawnerFolder = nil
local SpawnerGUI = nil
local RenderConnection = nil
local spawnerFrame = nil

local RaycastParams_Ground = RaycastParams.new()
RaycastParams_Ground.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams_Ground.IgnoreWater = false
RaycastParams_Ground.RespectCanCollide = false

local function CastGroundY(position, startY)
    local origin = Vector3.new(position.X, startY + 200, position.Z)
    local result = workspace:Raycast(origin, Vector3.new(0, -600, 0), RaycastParams_Ground)
    if result and result.Instance then
        local hit = result.Instance
        if hit.Transparency < 0.99 and hit.CanCollide then
            return result.Position.Y
        end
    end
    return startY
end

local function BuildVisualPet(species, position, petType, size)
    local model, module = CloneSpeciesModel(species)
    if not (model and module) then
        warn("Failed to clone:", species)
        return nil
    end
    
    model:SetAttribute("PetID", "Visual_" .. tostring(os.clock()))
    model:SetAttribute("Owner", LocalPlayer.Name)
    model:SetAttribute("OwnerSlot", "VisualSlot")
    model:SetAttribute("PetVisual", true)
    
    local primary = model.PrimaryPart
    local fallback = not (primary and primary.Parent) and (
        model:FindFirstChild("Torso") or 
        (model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart"))
    )
    if fallback then
        model.PrimaryPart = fallback
    end
    primary = model.PrimaryPart
    
    if not primary then
        model:Destroy()
        warn("No primary part for:", species)
        return nil
    end
    
    local pivotCF
    if module then
        local pivot = module.Pivot
        if typeof(pivot) == "Vector3" then
            pivotCF = CFrame.Angles(
                math.rad(pivot.X),
                math.rad(pivot.Y),
                math.rad(pivot.Z)
            )
        else
            pivotCF = CFrame.identity
        end
    else
        pivotCF = CFrame.identity
    end
    model:PivotTo(pivotCF)
    
    local scale = PetSizes.GetScale(size or "Normal", {
        Big = module.BigScale,
        Huge = module.HugeScale
    })
    if scale ~= 1 then
        model:ScaleTo(scale)
    end
    
    local footOffset = ComputeFootOffset(model)
    
    local petPivotCF = primary.CFrame:Inverse() * model:GetPivot()
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = petPivotCF
    petPivot.Parent = primary
    
    if position then
        model:PivotTo(CFrame.new(position) * pivotCF)
    end
    
    if not SpawnerFolder then
        SpawnerFolder = Instance.new("Folder")
        SpawnerFolder.Name = "_VisualPetSpawner"
        SpawnerFolder.Parent = workspace
    end
    model.Parent = SpawnerFolder
    
    local animator = GetOrCreateAnimator(model)
    local anims = FindAnimationsOnModel(model, module.Animations)
    
    local tracks = {}
    for name, anim in pairs(anims) do
        local success, track = pcall(function()
            return animator:LoadAnimation(anim)
        end)
        if success and track then
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Movement
            tracks[name] = track
        end
    end
    
    local petData = {
        Owner = LocalPlayer,
        Slot = nil,
        Species = species,
        Module = module,
        Model = model,
        Primary = primary,
        Animator = animator,
        Tracks = tracks,
        CurrentState = "",
        PetAttachment = petPivot,
        FootOffset = footOffset,
        SpeciesPivotCFrame = pivotCF,
        Connections = {},
        LastAnimPos = position or Vector3.new(),
        LastAnimTime = os.clock(),
        AnimState = "idle",
        IsFlyer = module.IsFlying == true,
        LastYaw = 0,
        LastChaseGroundY = nil,
        SmoothedSpeed = 0,
        LastVisualPos = nil,
        LastVisualTime = nil,
    }
    
    ApplyPetTypeTag(model, petType)
    
    local conn = model.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            DestroyVisualPet(petData)
        end
    end)
    table.insert(petData.Connections, conn)
    
    local initialState
    if petData.IsFlyer then
        initialState = "flying"
    else
        initialState = "idle"
    end
    petData.CurrentState = ""
    SwitchState(petData, initialState)
    
    ApplyVisibility(petData, true)
    
    table.insert(SpawnedPets, petData)
    print("✅ Spawned:", species)
    return petData
end

function DestroyVisualPet(petData)
    for _, conn in pairs(petData.Connections) do
        conn:Disconnect()
    end
    petData.Connections = {}
    
    for _, track in pairs(petData.Tracks) do
        track:Stop(0)
    end
    
    if petData.Model and petData.Model.Parent then
        petData.Model:Destroy()
    end
    
    for i, p in ipairs(SpawnedPets) do
        if p == petData then
            table.remove(SpawnedPets, i)
            break
        end
    end
end

function DestroyAllVisualPets()
    for i = #SpawnedPets, 1, -1 do
        DestroyVisualPet(SpawnedPets[i])
    end
    print("All visual pets despawned")
end

-- ============================================
-- FOLLOW LOGIC (exact from file)
-- ============================================

local function UpdatePetFollow(petData, dt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local primary = petData.Primary
    if not (primary and primary.Parent) then return end
    
    local hrpCF = hrp.CFrame
    local lookVector = hrpCF.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    local direction = flatLook.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or flatLook.Unit
    
    local hrpPos = hrpCF.Position
    local followCF = CFrame.lookAt(hrpPos, hrpPos + direction) * CFrame.new(3, -2.5, 3)
    local goalPos = followCF.Position
    
    local groundY = CastGroundY(goalPos, goalPos.Y)
    if groundY == nil then
        groundY = goalPos.Y
    end
    petData.LastChaseGroundY = groundY
    
    local finalY
    if petData.IsFlyer then
        local heightOffset = 0
        local heightFactor = math.clamp(heightOffset / 1.5, 0, 1)
        if heightFactor < 1 then
            finalY = groundY + petData.FootOffset
        else
            finalY = goalPos.Y + petData.FootOffset
        end
        finalY = finalY * (1 - heightFactor) + (goalPos.Y + petData.FootOffset) * heightFactor
    else
        finalY = groundY + petData.FootOffset
    end
    
    local targetXZ = Vector3.new(goalPos.X, finalY, goalPos.Z)
    local currentPos = primary.CFrame.Position
    
    local dx = targetXZ.X - currentPos.X
    local dz = targetXZ.Z - currentPos.Z
    local distSq = dx * dx + dz * dz
    local distance = math.sqrt(distSq)
    
    local expFactor = -60 * dt
    local lerpAlpha = 1 - math.exp(expFactor)
    local speed = petData.Module and (petData.Module.FollowSpeed or 14) or 14
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        speed = speed * math.max(1, humanoid.WalkSpeed / 16)
    end
    
    local moveDist = speed * dt
    local newX, newZ
    
    if distance <= 0.05 or distance <= moveDist then
        newX = targetXZ.X
        newZ = targetXZ.Z
    else
        local invDist = 1 / distance
        local step = moveDist / math.max(lerpAlpha, 0.001)
        newX = currentPos.X + dx * invDist * step
        newZ = currentPos.Z + dz * invDist * step
    end
    
    local goalRotation = followCF - followCF.Position
    local negLookX = -goalRotation.LookVector.X
    local negLookZ = -goalRotation.LookVector.Z
    local targetYaw = math.atan2(negLookX, negLookZ)
    
    local lastYaw = petData.LastYaw or targetYaw
    local yawDiff = (targetYaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
    local yawLerp = 12 * dt
    local newYaw = lastYaw + yawDiff * math.clamp(yawLerp, 0, 1)
    petData.LastYaw = newYaw
    
    local finalCF = CFrame.new(Vector3.new(newX, finalY, newZ)) 
        * CFrame.Angles(0, newYaw, 0) 
        * (petData.SpeciesPivotCFrame or CFrame.identity)
    
    primary.CFrame = primary.CFrame:Lerp(finalCF, lerpAlpha)
    
    local now = os.clock()
    local speedCalc = 0
    if petData.LastVisualPos and petData.LastVisualTime then
        local timeDelta = math.max(0.001, now - petData.LastVisualTime)
        local moved = (primary.Position - petData.LastVisualPos).Magnitude
        if moved < 50 then
            speedCalc = moved / timeDelta
        end
    end
    petData.LastVisualPos = primary.Position
    petData.LastVisualTime = now
    
    local speedLerp = dt * 6
    petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - math.clamp(speedLerp, 0, 1)) 
        + speedCalc * math.clamp(speedLerp, 0, 1)
    
    local smoothed = petData.SmoothedSpeed
    local currentAnim = petData.AnimState or "idle"
    
    if petData.IsFlyer then
        local flightPhase = "Flying"
        local animState = flightPhase == "Flying" and "flying" or "flyidle"
        local moduleAnims = petData.Module and petData.Module.Animations
        
        if animState == "flying" and (moduleAnims and moduleAnims.FlyIdle) then
            animState = smoothed > 2 and "flying" or (smoothed < 0.6 and "flyidle" 
                or (currentAnim ~= "flying" and currentAnim ~= "flyidle" and "flying" or currentAnim))
        end
        petData.AnimState = animState
        SwitchState(petData, animState)
    else
        local newAnim = currentAnim == "idle" and smoothed > 2 and "walking" 
            or (currentAnim == "walking" and smoothed < 0.6 and "idle" or currentAnim)
        petData.AnimState = newAnim
        SwitchState(petData, newAnim)
    end
end

-- ============================================
-- DELTA-COMPATIBLE GUI
-- ============================================

local function CreateSpawnerGUI()
    if SpawnerGUI then
        pcall(function() SpawnerGUI:Destroy() end)
    end
    
    -- DELTA FIX: Use PlayerGui with proper waiting
    local guiParent = PlayerGui
    
    -- DELTA FIX: Some executors need gethui() or CoreGui
    if not guiParent then
        local success, hui = pcall(function()
            return gethui and gethui() or game:GetService("CoreGui")
        end)
        if success and hui then
            guiParent = hui
        end
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VisualPetSpawner_" .. tostring(math.random(1000, 9999))
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = guiParent
    
    -- DELTA FIX: Ensure it's actually parented
    if not screenGui.Parent then
        warn("Failed to parent ScreenGui! Trying alternate method...")
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 320, 0, 450)
    frame.Position = UDim2.new(0.5, -160, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Visible = true  -- DELTA FIX: Start VISIBLE for testing
    frame.Active = true
    frame.Draggable = true  -- DELTA FIX: Make draggable
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "🐾 GAG 2 Visual Pet Spawner"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name = "PetList"
    scroll.Size = UDim2.new(1, -10, 1, -100)
    scroll.Position = UDim2.new(0, 5, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = frame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = scroll
    
    -- Pet type selector
    local typeFrame = Instance.new("Frame")
    typeFrame.Size = UDim2.new(1, -10, 0, 30)
    typeFrame.BackgroundTransparency = 1
    typeFrame.Parent = scroll
    
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0.4, 0, 1, 0)
    typeLabel.Text = "Pet Type:"
    typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextSize = 14
    typeLabel.Parent = typeFrame
    
    local typeDropdown = Instance.new("TextButton")
    typeDropdown.Size = UDim2.new(0.55, 0, 1, 0)
    typeDropdown.Position = UDim2.new(0.45, 0, 0, 0)
    typeDropdown.Text = "Normal"
    typeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    typeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    typeDropdown.Font = Enum.Font.GothamBold
    typeDropdown.TextSize = 14
    typeDropdown.Parent = typeFrame
    
    Instance.new("UICorner", typeDropdown).CornerRadius = UDim.new(0, 6)
    
    local selectedType = "Normal"
    local typeOptions = {"Normal", "Rainbow", "Golden", "Shiny"}
    local typeIndex = 1
    
    typeDropdown.MouseButton1Click:Connect(function()
        typeIndex = typeIndex % #typeOptions + 1
        selectedType = typeOptions[typeIndex]
        typeDropdown.Text = selectedType
    end)
    
    -- Size selector
    local sizeFrame = Instance.new("Frame")
    sizeFrame.Size = UDim2.new(1, -10, 0, 30)
    sizeFrame.BackgroundTransparency = 1
    sizeFrame.Parent = scroll
    
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0.4, 0, 1, 0)
    sizeLabel.Text = "Size:"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 14
    sizeLabel.Parent = sizeFrame
    
    local sizeDropdown = Instance.new("TextButton")
    sizeDropdown.Size = UDim2.new(0.55, 0, 1, 0)
    sizeDropdown.Position = UDim2.new(0.45, 0, 0, 0)
    sizeDropdown.Text = "Normal"
    sizeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sizeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeDropdown.Font = Enum.Font.GothamBold
    sizeDropdown.TextSize = 14
    sizeDropdown.Parent = sizeFrame
    
    Instance.new("UICorner", sizeDropdown).CornerRadius = UDim.new(0, 6)
    
    local selectedSize = "Normal"
    local sizeOptions = {"Normal", "Big", "Huge"}
    local sizeIndex = 1
    
    sizeDropdown.MouseButton1Click:Connect(function()
        sizeIndex = sizeIndex % #sizeOptions + 1
        selectedSize = sizeOptions[sizeIndex]
        sizeDropdown.Text = selectedSize
    end)
    
    -- Separator
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(1, -10, 0, 2)
    sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sep.BorderSizePixel = 0
    sep.Parent = scroll
    
    -- Pet buttons
    for species, module in pairs(PetModules) do
        local btn = Instance.new("TextButton")
        btn.Name = species .. "Btn"
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.Text = "  " .. species
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Parent = scroll
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local pos = hrp and (hrp.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))) or Vector3.new(0, 10, 0)
            
            local petTypeVal = selectedType == "Rainbow" and PetTypes.Rainbow or nil
            
            BuildVisualPet(species, pos, petTypeVal, selectedSize)
        end)
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0.4, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.3, 0, 1, -42)
    closeBtn.Text = "Close"
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = frame
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)
    
    -- Count label
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(1, 0, 0, 20)
    countLabel.Position = UDim2.new(0, 0, 1, -62)
    countLabel.Text = "Spawned: 0"
    countLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    countLabel.BackgroundTransparency = 1
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 12
    countLabel.Parent = frame
    
    -- Update count
    task.spawn(function()
        while screenGui and screenGui.Parent do
            countLabel.Text = "Spawned: " .. #SpawnedPets
            task.wait(0.5)
        end
    end)
    
    -- DELTA FIX: Notification that it's open
    print("✅ GUI Created! It should be visible on screen.")
    print("If not visible, try pressing P again or check if Delta is blocking GUIs.")
    
    SpawnerGUI = screenGui
    return frame
end

-- ============================================
-- INPUT & RENDER
-- ============================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        if not spawnerFrame or not spawnerFrame.Parent then
            spawnerFrame = CreateSpawnerGUI()
        else
            spawnerFrame.Visible = not spawnerFrame.Visible
        end
    elseif input.KeyCode == Enum.KeyCode.Delete then
        DestroyAllVisualPets()
    end
end)

-- RenderStepped follow
RenderConnection = RunService:BindToRenderStep("VisualPetFollow", Enum.RenderPriority.Camera.Value + 1, function(dt)
    local filterList = {}
    for _, player in pairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            table.insert(filterList, char)
        end
    end
    if SpawnerFolder then
        table.insert(filterList, SpawnerFolder)
    end
    RaycastParams_Ground.FilterDescendantsInstances = filterList
    
    for _, petData in ipairs(SpawnedPets) do
        if petData.Model and petData.Model.Parent then
            UpdatePetFollow(petData, dt)
        end
    end
end)

-- ============================================
-- AUTO-OPEN GUI ON LOAD (DELTA FIX)
-- ============================================

task.spawn(function()
    -- Wait for character to load
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    task.wait(1)
    
    -- Auto-open GUI so you know it loaded
    if not spawnerFrame or not spawnerFrame.Parent then
        spawnerFrame = CreateSpawnerGUI()
    end
end)

print("✅ GAG 2 Visual Pet Spawner loaded!")
print("GUI should auto-open. If not, press P.")
print("Press Delete to remove all pets")
