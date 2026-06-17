--[[
    Visual Pet Spawner - Grow a Garden 2
    All features from original PetVisualClient system

    Features:
    - Pet model cloning from ReplicatedStorage (never workspace)
    - Animation system (idle, walk, fly, flyidle, landing, takeoff, groundidle)
    - Ground raycasting with dynamic filter refresh
    - Pet following with offset positioning
    - Fruit/Plant carrying system
    - Frog jump physics
    - Owl hoot SFX
    - Rainbow pet tagging
    - Size scaling (Big/Huge)
    - Visibility toggling
    - Smooth interpolation for remote pets
    - Slot-based attachment architecture
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Module references (adjust paths as needed)
local PetModules = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("PetModules"))
local Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))
local PetSizes = require(ReplicatedStorage:WaitForChild("SharedData"):WaitForChild("PetSizes"))
local PetTypes = require(ReplicatedStorage:WaitForChild("SharedData"):WaitForChild("PetTypes"))

-- Asset references
local AssetsFolder = ReplicatedStorage:WaitForChild("Assets")
local PetsFolder = AssetsFolder:WaitForChild("Pets")
local FruitsFolder = AssetsFolder:WaitForChild("Fruits")
local PlantsFolder = AssetsFolder:WaitForChild("Plants")

-- Plant generation modules for fruit carrying
local PlantGenModules = ReplicatedStorage:FindFirstChild("PlantGenerationModules")
local FruitGenFolder = PlantGenModules and PlantGenModules:FindFirstChild("Fruits")
local PlantGenFolder = PlantGenModules and PlantGenModules:FindFirstChild("Plants")

--========================================
-- CONFIGURATION
--========================================
local Config = {
    StartOrder = 6,
    FollowSpeed = 14,
    GroundCastInterval = 0.0667, -- ~15Hz
    FilterRefreshInterval = 1.0,
    MaxJumpWaitFrames = 60,
    MaxFruitInitWait = 600,
    RaycastDistance = 600,
    RaycastStartHeight = 200,
    SmoothingFactor = 60,
    RotationSpeed = 12,
    HeightLerpSpeed = 18,
    SpeedSmoothFactor = 6,
    WalkThreshold = 2,
    IdleThreshold = 0.6,
    FlyWalkThreshold = 2,
    FlyIdleThreshold = 0.6,
    SnapCooldown = 0.2,
    ForceFollowDuration = 0.4,
    MaxSpeedForInterpolation = 50,
}

--========================================
-- STATE TABLES
--========================================
local ActivePets = {}      -- [slot] = petData
local PendingBuilds = {}   -- [slot] = generation number
local Destroying = {}      -- [slot] = generation number
local FruitGenCache = {}   -- [fruitName] = {Module=..., IsPlant=...}
local FruitAssetCache = {} -- [fruitName] = asset
local PlantAssetCache = {} -- [plantName] = asset

-- Raycast params
local GroundRaycastParams = RaycastParams.new()
GroundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
GroundRaycastParams.IgnoreWater = false
GroundRaycastParams.RespectCanCollide = false

local SecondaryRaycastParams = RaycastParams.new()
SecondaryRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
SecondaryRaycastParams.IgnoreWater = false
SecondaryRaycastParams.RespectCanCollide = false

-- Timing
local LastFilterRefresh = -math.huge
local LastFrogJumpTime = 0
local OwlSound = nil

-- Folders (created in Init)
local VisualFolder = nil
local ModelsFolder = nil
local CarryFolder = nil

--========================================
-- UTILITY FUNCTIONS
--========================================

-- Apply or remove Rainbow tag based on pet type
local function ApplyPetTypeTag(model, petType)
    if not model then return end
    if petType == PetTypes.Rainbow then
        if not model:HasTag("PetRainbow") then
            model:AddTag("PetRainbow")
        end
    else
        if model:HasTag("PetRainbow") then
            model:RemoveTag("PetRainbow")
        end
    end
end

-- Refresh ground raycast filter to exclude dynamic objects
local function RefreshGroundFilter()
    local filterList = {}

    -- Exclude all player characters
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            table.insert(filterList, character)
        end
    end

    -- Exclude pet visual folder
    if VisualFolder then
        table.insert(filterList, VisualFolder)
    end

    -- Exclude player pet references
    local petRefs = workspace:FindFirstChild("PlayerPetReferences")
    if petRefs then
        table.insert(filterList, petRefs)
    end

    -- Exclude gardens and plants
    local gardens = workspace:FindFirstChild("Gardens")
    if gardens then
        for _, garden in pairs(gardens:GetChildren()) do
            local plants = garden:FindFirstChild("Plants")
            if plants then
                table.insert(filterList, plants)
            end
        end
    end

    -- Exclude potted plants
    local potted = workspace:FindFirstChild("PottedPlantVisuals")
    if potted then
        table.insert(filterList, potted)
    end

    GroundRaycastParams.FilterDescendantsInstances = filterList
end

-- Cast ray to find ground Y at position
local function CastGroundY(position, startY)
    local startPos = Vector3.new(position.X, startY + Config.RaycastStartHeight, position.Z)
    local result = workspace:Raycast(startPos, Vector3.new(0, -Config.RaycastDistance, 0), GroundRaycastParams)

    if not (result and result.Instance) then
        return nil
    end

    local hit = result.Instance
    if hit.Transparency < 0.99 and hit.CanCollide then
        return result.Position.Y
    end

    -- Secondary raycast through transparent parts
    local secondaryFilter = table.clone(GroundRaycastParams.FilterDescendantsInstances)
    table.insert(secondaryFilter, hit)
    SecondaryRaycastParams.FilterDescendantsInstances = secondaryFilter

    for _ = 1, 8 do
        local secondaryResult = workspace:Raycast(startPos, Vector3.new(0, -Config.RaycastDistance, 0), SecondaryRaycastParams)
        if not (secondaryResult and secondaryResult.Instance) then
            return nil
        end

        local secondaryHit = secondaryResult.Instance
        if secondaryHit.Transparency < 0.99 and secondaryHit.CanCollide then
            return secondaryResult.Position.Y
        end

        table.insert(secondaryFilter, secondaryHit)
        SecondaryRaycastParams.FilterDescendantsInstances = secondaryFilter
    end

    return nil
end

-- Compute jump offset for Frog pets
local function ComputeJumpOffset(slot)
    if slot:GetAttribute("PetSpecies") ~= "Frog" then
        return 0
    end

    local jumpStart = slot:GetAttribute("SlotJumpStart")
    if typeof(jumpStart) ~= "number" then return 0 end

    local jumpPeak = slot:GetAttribute("SlotJumpPeak")
    if typeof(jumpPeak) ~= "number" or jumpPeak <= 0 then return 0 end

    local jumpDuration = slot:GetAttribute("SlotJumpDuration")
    if typeof(jumpDuration) ~= "number" or jumpDuration <= 0 then return 0 end

    local elapsed = workspace:GetServerTimeNow() - jumpStart
    if elapsed < 0 or elapsed > jumpDuration then
        return 0
    end

    local t = elapsed / jumpDuration
    return jumpPeak * 4 * t * (1 - t)
end

-- Compute foot offset from model parts
local function ComputeFootOffset(model)
    local pivotY = model:GetPivot().Position.Y
    local lowestY = math.huge

    for _, descendant in pairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Transparency < 1 then
            local cf = descendant.CFrame
            local size = descendant.Size
            local halfX, halfY, halfZ = size.X * 0.5, size.Y * 0.5, size.Z * 0.5

            for xSign = -1, 1, 2 do
                for ySign = -1, 1, 2 do
                    local corner = cf * Vector3.new(xSign * halfX, ySign * halfY, -halfZ)
                    lowestY = math.min(lowestY, corner.Y)

                    local corner2 = cf * Vector3.new(xSign * halfX, ySign * halfY, halfZ)
                    lowestY = math.min(lowestY, corner2.Y)
                end
            end
        end
    end

    return lowestY == math.huge and 0 or pivotY - lowestY
end

-- Get or create AnimationController and Animator
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

-- Find animations on model
local function FindAnimationsOnModel(model, animationNames)
    local animations = {}
    local animFolder = model:FindFirstChild("Animations")

    if animationNames then
        local foundNames = {}
        for _, name in pairs(animationNames) do
            if type(name) == "string" and name ~= "" and not foundNames[name] then
                foundNames[name] = true
                local anim = animFolder and animFolder:FindFirstChild(name) or model:FindFirstChild(name)
                if anim and anim:IsA("Animation") then
                    animations[name] = anim
                end
            end
        end
    else
        if animFolder then
            for _, child in pairs(animFolder:GetChildren()) do
                if child:IsA("Animation") then
                    animations[child.Name] = child
                end
            end
        end
        for _, child in pairs(model:GetChildren()) do
            if child:IsA("Animation") then
                animations[child.Name] = child
            end
        end
    end

    return animations
end

-- Get animation name for state
local function GetAnimNameForState(module, state)
    if not module or not module.Animations then return nil end

    local anims = module.Animations
    if state == "idle" then
        return anims.Idle
    elseif state == "walking" then
        return anims.Walk
    elseif state == "flying" then
        return anims.Fly
    elseif state == "flyidle" then
        return anims.FlyIdle or anims.Fly
    elseif state == "landing" then
        return anims.Land
    elseif state == "takeoff" then
        return anims.Takeoff
    elseif state == "groundidle" then
        return anims.GroundIdle or anims.Idle
    end
    return nil
end

-- Switch animation state
local function SwitchState(petData, newState)
    if newState == "takeoff" then
        local anims = petData.Module and petData.Module.Animations
        if anims and not anims.Takeoff then
            newState = "flying"
        end
    end

    if petData.CurrentState == newState then return end

    local oldState = petData.CurrentState
    petData.CurrentState = newState

    local fadeTime = (oldState == "landing" or oldState == "takeoff") and 0.05 or 0.2

    -- Stop all current tracks
    for _, track in pairs(petData.Tracks) do
        if track.IsPlaying then
            track:Stop(fadeTime)
        end
    end

    -- Start new track
    local animName = GetAnimNameForState(petData.Module, newState)
    if animName then
        local track = petData.Tracks[animName]
        if track then
            track.Looped = (newState ~= "landing" and newState ~= "takeoff")
            track:Play(track.Looped and 0.2 or 0.05)
        end
    end
end

-- Apply visibility to model
local function ApplyVisibility(petData, isVisible)
    local transparency = isVisible and 0 or 1
    for _, descendant in pairs(petData.Model:GetDescendants()) do
        if descendant ~= petData.Model.PrimaryPart then
            if descendant:IsA("BasePart") then
                descendant.Transparency = transparency
            elseif descendant:IsA("Decal") then
                descendant.Transparency = transparency
            end
        end
    end
end

--========================================
-- MODEL CLONING
--========================================

-- Clone pet species model from ReplicatedStorage (NEVER from workspace)
local function CloneSpeciesModel(speciesName)
    local moduleData = PetModules[speciesName]
    if not moduleData then
        return nil, nil
    end

    local assetName = moduleData.AssetName
    local asset = PetsFolder:FindFirstChild(assetName) or AssetsFolder:FindFirstChild(assetName)

    if not (asset and asset:IsA("Model")) then
        return nil, nil
    end

    local clone = asset:Clone()

    -- Configure all parts for physics
    for _, descendant in pairs(clone:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = true
            descendant.Massless = true
        end
    end

    return clone, moduleData
end

-- Ensure PetTarget attachment exists on slot
local function EnsureSlotAttachment(slot, footOffset, pivotCFrame)
    local attachment = slot:FindFirstChild("PetTarget")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "PetTarget"
        attachment.Parent = slot
    end

    attachment.CFrame = CFrame.new(0, footOffset, 0) * (pivotCFrame or CFrame.identity)
    return attachment
end

--========================================
-- DESTRUCTION
--========================================

-- Destroy active pet for slot
local function DestroyActive(slot)
    Destroying[slot] = (Destroying[slot] or 0) + 1
    PendingBuilds[slot] = nil

    local petData = ActivePets[slot]
    if petData then
        ActivePets[slot] = nil

        -- Disconnect all connections
        for _, connection in pairs(petData.Connections) do
            connection:Disconnect()
        end
        petData.Connections = {}

        -- Stop all animations
        for _, track in pairs(petData.Tracks) do
            track:Stop(0)
        end

        -- Destroy carry fruit
        if petData.CarryFruitModel then
            petData.CarryFruitModel:Destroy()
            petData.CarryFruitModel = nil
        end

        -- Destroy model
        if petData.Model and petData.Model.Parent then
            petData.Model:Destroy()
        end
    end

    Destroying[slot] = nil
end

--========================================
-- BUILD SLOT MODEL
--========================================

local function BuildSlotModel(slot, speciesName)
    if PendingBuilds[slot] then return end

    local generation = (Destroying[slot] or 0) + 1
    Destroying[slot] = generation
    PendingBuilds[slot] = generation

    -- Bail function for cleanup
    local function Bail()
        if PendingBuilds[slot] == generation then
            PendingBuilds[slot] = nil
        end

        if slot.Parent then
            local currentSpecies = slot:GetAttribute("PetSpecies")
            if type(currentSpecies) == "string" and currentSpecies ~= "" 
               and (currentSpecies ~= speciesName or not ActivePets[slot]) then
                task.defer(SyncSlot, slot)
            end
        end
    end

    -- Get owner player
    local parent = slot.Parent
    local owner = nil
    if parent and parent:IsA("Folder") then
        owner = Players:FindFirstChild(parent.Name)
    end

    if not owner then
        return Bail()
    end

    -- Clone model
    local model, moduleData = CloneSpeciesModel(speciesName)
    if not (model and moduleData) then
        return Bail()
    end

    -- Set attributes
    model:SetAttribute("PetID", slot:GetAttribute("PetId"))
    model:SetAttribute("Owner", owner.Name)
    model:SetAttribute("OwnerSlot", slot.Name)

    -- Find primary part
    local primaryPart = model.PrimaryPart
    if not (primaryPart and primaryPart.Parent) then
        primaryPart = model:FindFirstChild("Torso") 
            or model:FindFirstChild("RootPart") 
            or model:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            model.PrimaryPart = primaryPart
        end
    end

    if not primaryPart then
        model:Destroy()
        return Bail()
    end

    -- Compute pivot CFrame
    local pivotCFrame = CFrame.identity
    if moduleData.Pivot and typeof(moduleData.Pivot) == "Vector3" then
        local p = moduleData.Pivot
        pivotCFrame = CFrame.Angles(math.rad(p.X), math.rad(p.Y), math.rad(p.Z))
    end
    model:PivotTo(pivotCFrame)

    -- Scale model
    local scale = PetSizes.GetScale(slot:GetAttribute("PetSize"), {
        Big = moduleData.BigScale,
        Huge = moduleData.HugeScale
    })
    if scale ~= 1 then
        model:ScaleTo(scale)
    end

    -- Compute foot offset and create attachments
    local footOffset = ComputeFootOffset(model)
    local petPivotCFrame = primaryPart.CFrame:Inverse() * model:GetPivot()
    local slotAttachment = EnsureSlotAttachment(slot, footOffset, pivotCFrame)

    -- Wait for slot to initialize
    RunService.Heartbeat:Wait()
    local waitCount = 0
    while waitCount < Config.MaxJumpWaitFrames 
          and slot.Position.Magnitude <= 1 
          and not slot:GetAttribute("SlotVisualIndex") do
        RunService.Heartbeat:Wait()
        waitCount = waitCount + 1

        if (Destroying[slot] or 0) ~= generation 
           or not slot.Parent 
           or slot:GetAttribute("PetSpecies") ~= speciesName then
            model:Destroy()
            return Bail()
        end
    end

    if (Destroying[slot] or 0) ~= generation 
       or not slot.Parent 
       or slot:GetAttribute("PetSpecies") ~= speciesName then
        model:Destroy()
        return Bail()
    end

    -- Position model
    model:PivotTo(slot.CFrame * slotAttachment.CFrame)

    -- Create pet pivot attachment
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = petPivotCFrame
    petPivot.Parent = primaryPart

    primaryPart.Anchored = true
    model.Parent = ModelsFolder

    -- Verify still valid
    if (Destroying[slot] or 0) ~= generation 
       or not slot.Parent 
       or slot:GetAttribute("PetSpecies") ~= speciesName then
        if model.Parent then
            model:Destroy()
        end
        return Bail()
    end

    -- Setup animator
    local animator = GetOrCreateAnimator(model)
    local animations = FindAnimationsOnModel(model, moduleData.Animations)
    local tracks = {}

    for animName, animation in pairs(animations) do
        local success, track = pcall(function()
            return animator:LoadAnimation(animation)
        end)
        if success and track then
            track.Looped = true
            track.Priority = Enum.AnimationPriority.Movement
            tracks[animName] = track
        end
    end

    -- Create pet data
    local petData = {
        Owner = owner,
        Slot = slot,
        Species = speciesName,
        Module = moduleData,
        Model = model,
        Primary = primaryPart,
        Animator = animator,
        Tracks = tracks,
        CurrentState = "",
        SlotAttachment = slotAttachment,
        PetAttachment = petPivot,
        FootOffset = footOffset,
        SpeciesPivotCFrame = pivotCFrame,
        Generation = generation,
        Connections = {},
        LastAnimPos = slot.Position,
        LastAnimTime = os.clock(),
        AnimState = "idle",
        IsFlyer = moduleData.IsFlying == true,
        -- Following state
        LocalGoalPos = nil,
        LocalGoalRotation = nil,
        LocalChase = false,
        LastYaw = nil,
        LastChaseGroundY = nil,
        LastLocalGroundY = nil,
        LastVisualPos = nil,
        LastVisualTime = nil,
        SmoothedSpeed = 0,
        LastGoalChangeTime = nil,
        LastTrackedGoalXZ = nil,
        ForceFollowUntil = nil,
        VirtualSlotPos = nil,
        -- Slot interpolation
        LastSlotCF = nil,
        PrevSlotCF = nil,
        LastSlotTickAt = nil,
        SlotTickPeriod = nil,
        InterpSlotCF = nil,
        -- Ground caching
        SlotGroundCastNext = 0,
        SlotGroundCachedY = nil,
        LastGroundY = nil,
        -- Fruit carrying
        CarryFruitModel = nil,
        CarryFruitAnchor = nil,
        CarryFruitAttach = nil,
        CarryFruitToken = 0,
    }

    ActivePets[slot] = petData

    -- Apply pet type tag
    ApplyPetTypeTag(model, slot:GetAttribute("PetType"))

    -- Ancestry changed connection
    table.insert(petData.Connections, model.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            DestroyActive(slot)
        end
    end))

    -- Initial positioning
    task.spawn(function()
        RunService.Heartbeat:Wait()
        if ActivePets[slot] then
            local pd = ActivePets[slot]
            if pd.Slot.Parent then
                local targetCF = pd.Slot.CFrame * pd.SlotAttachment.CFrame
                pd.Model:PivotTo(targetCF)
            end
            pd.LastAnimPos = slot.Position
            pd.LastAnimTime = os.clock()
        end
    end)

    -- Initial animation state
    task.spawn(function()
        RunService.Heartbeat:Wait()
        if ActivePets[slot] then
            local pd = ActivePets[slot]
            local initialState
            if pd.IsFlyer then
                local flightPhase = slot:GetAttribute("FlightPhase") or "Flying"
                if flightPhase == "Flying" then
                    initialState = "flying"
                elseif flightPhase == "Landing" then
                    initialState = "landing"
                elseif flightPhase == "Grounded" then
                    initialState = "groundidle"
                elseif flightPhase == "Takeoff" then
                    initialState = "takeoff"
                else
                    initialState = "flying"
                end
            else
                initialState = "idle"
            end
            pd.CurrentState = ""
            SwitchState(pd, initialState)
        end
    end)

    -- Apply visibility
    ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)

    if PendingBuilds[slot] == generation then
        PendingBuilds[slot] = nil
    end
end

--========================================
-- SYNC SLOT
--========================================

function SyncSlot(slot)
    local species = slot:GetAttribute("PetSpecies")
    local petData = ActivePets[slot]

    -- Species changed, destroy and rebuild
    if petData and petData.Species ~= species then
        DestroyActive(slot)
        petData = nil
    end

    if type(species) == "string" and species ~= "" then
        if not petData then
            BuildSlotModel(slot, species)
        else
            -- Update existing
            petData.Model:SetAttribute("PetID", slot:GetAttribute("PetId"))
            ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)
            local attached = slot:GetAttribute("PetAttached") ~= false
            petData.Model:SetAttribute("AttachedToPetPart", attached)
        end
    else
        -- No pet, clean up any existing models for this slot
        Destroying[slot] = (Destroying[slot] or 0) + 1
        PendingBuilds[slot] = nil

        local parent = slot.Parent
        local owner = nil
        if parent and parent:IsA("Folder") then
            owner = Players:FindFirstChild(parent.Name)
        end

        if owner and ModelsFolder then
            for _, child in pairs(ModelsFolder:GetChildren()) do
                if child:GetAttribute("OwnerSlot") == slot.Name 
                   and child:GetAttribute("Owner") == owner.Name then
                    child:Destroy()
                end
            end
        end
    end
end

--========================================
-- FRUIT/PLANT CARRYING
--========================================

-- Get fruit generation module
local function GetCarryFruitGenModule(fruitName)
    if FruitGenCache[fruitName] == nil then
        local folder = nil
        if FruitGenFolder and FruitGenFolder:FindFirstChild(fruitName) then
            folder = FruitGenFolder
        elseif PlantGenFolder and PlantGenFolder:FindFirstChild(fruitName) then
            folder = PlantGenFolder
        end

        if folder then
            local module = folder:FindFirstChild(fruitName)
            local success, result = pcall(require, module)
            if success and result then
                FruitGenCache[fruitName] = {
                    Module = result,
                    IsPlant = folder == PlantGenFolder
                }
                return FruitGenCache[fruitName]
            else
                FruitGenCache[fruitName] = false
                return false
            end
        else
            FruitGenCache[fruitName] = false
            return false
        end
    else
        return FruitGenCache[fruitName]
    end
end

-- Get fruit/plant asset
local function GetCarryFruitAsset(fruitName)
    local fruit = FruitsFolder and FruitsFolder:FindFirstChild(fruitName)
    if fruit then
        return fruit, false
    end

    local plant = PlantsFolder and PlantsFolder:FindFirstChild(fruitName)
    if plant then
        return plant, true
    end

    return nil, false
end

-- Attach carry fruit to pet
local function AttachCarryFruit(petData, fruitName, seed, size, _, mutation)
    -- Clean up existing
    if petData.CarryFruitModel then
        petData.CarryFruitModel:Destroy()
        petData.CarryFruitModel = nil
    end

    if not (petData.Primary and petData.Primary.Parent) then
        return
    end

    local fruitPos = petData.Primary:FindFirstChild("FruitPosition")
    if not (fruitPos and fruitPos:IsA("Attachment")) then
        return
    end

    local asset, isPlant = GetCarryFruitAsset(fruitName)
    if not asset then return end

    local genModule = GetCarryFruitGenModule(fruitName)
    if not genModule then return end

    petData.CarryFruitToken = (petData.CarryFruitToken or 0) + 1
    local token = petData.CarryFruitToken
    local fruitModel = asset:Clone()

    -- Configure parts
    for _, descendant in pairs(fruitModel:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.Massless = true
            descendant.Anchored = false
        end
    end

    fruitModel.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.Massless = true
            descendant.Anchored = false
        end
    end)

    if mutation and mutation ~= "" then
        fruitModel:SetAttribute("Mutation", mutation)
    end

    -- Initialize fruit/plant
    local initSuccess = false
    if isPlant then
        local initPlant = genModule.Module.InitPlant
        if type(initPlant) == "function" then
            initSuccess = pcall(initPlant, fruitModel, seed, size, os.time())
        end
    else
        local initFruit = genModule.Module.InitFruit
        if type(initFruit) == "function" then
            initSuccess = pcall(initFruit, fruitModel, seed, size)
        end
    end

    if not initSuccess then
        fruitModel:Destroy()
        return
    end

    -- Position and parent
    fruitModel:PivotTo(CFrame.new(0, -5000, 0))
    fruitModel.Parent = CarryFolder

    -- Wait for initialization
    task.spawn(function()
        local waitCount = 0
        while fruitModel and fruitModel.Parent 
              and not fruitModel:HasTag("InitializationComplete") do
            task.wait()
            waitCount = waitCount + 1
            if waitCount > Config.MaxFruitInitWait then
                break
            end
        end

        if petData.CarryFruitToken == token and fruitModel.Parent then
            -- Position at fruit attachment
            fruitModel:PivotTo(fruitPos.WorldCFrame)

            -- Create anchor part
            local anchor = Instance.new("Part")
            anchor.Name = "CarryAnchor"
            anchor.Size = Vector3.new(0.01, 0.01, 0.01)
            anchor.Transparency = 1
            anchor.CanCollide = false
            anchor.CanQuery = false
            anchor.CanTouch = false
            anchor.Massless = true
            anchor.Anchored = true
            anchor.CFrame = fruitPos.WorldCFrame
            anchor.Parent = fruitModel

            fruitModel.PrimaryPart = anchor

            -- Configure all parts and weld
            for _, descendant in pairs(fruitModel:GetDescendants()) do
                if descendant:IsA("BasePart") and descendant ~= anchor then
                    descendant.Anchored = false
                    descendant.CanCollide = false
                    descendant.CanQuery = false
                    descendant.CanTouch = false
                    descendant.Massless = true
                end
            end

            for _, descendant in pairs(fruitModel:GetDescendants()) do
                if descendant:IsA("BasePart") and descendant ~= anchor then
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = anchor
                    weld.Part1 = descendant
                    weld.Parent = descendant
                end
            end

            petData.CarryFruitModel = fruitModel
            petData.CarryFruitAnchor = anchor
            petData.CarryFruitAttach = fruitPos
        else
            fruitModel:Destroy()
        end
    end)
end

--========================================
-- SLOT WATCHING
--========================================

local function WatchSlot(slot)
    slot.CanQuery = false

    -- Pet species changed
    slot:GetAttributeChangedSignal("PetSpecies"):Connect(function()
        SyncSlot(slot)
    end)

    -- Pet size changed (rebuild)
    slot:GetAttributeChangedSignal("PetSize"):Connect(function()
        DestroyActive(slot)
        SyncSlot(slot)
    end)

    -- Visibility changed
    slot:GetAttributeChangedSignal("PetVisible"):Connect(function()
        local petData = ActivePets[slot]
        if petData then
            ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)
        end
    end)

    -- Attached state changed
    slot:GetAttributeChangedSignal("PetAttached"):Connect(function()
        local petData = ActivePets[slot]
        if petData then
            local attached = slot:GetAttribute("PetAttached") ~= false
            petData.Model:SetAttribute("AttachedToPetPart", attached)
        end
    end)

    -- Pet ID changed
    slot:GetAttributeChangedSignal("PetId"):Connect(function()
        local petData = ActivePets[slot]
        if petData then
            petData.Model:SetAttribute("PetID", slot:GetAttribute("PetId"))
        end
    end)

    -- Pet type changed (Rainbow, etc.)
    slot:GetAttributeChangedSignal("PetType"):Connect(function()
        local petData = ActivePets[slot]
        if petData then
            ApplyPetTypeTag(petData.Model, slot:GetAttribute("PetType"))
        end
    end)

    -- Carrying fruit changed
    slot:GetAttributeChangedSignal("CarryingFruit"):Connect(function()
        local petData = ActivePets[slot]
        if not petData then return end

        local fruitName = slot:GetAttribute("CarryingFruit")
        if typeof(fruitName) == "string" and fruitName ~= "" then
            AttachCarryFruit(
                petData,
                fruitName,
                slot:GetAttribute("CarryingFruitSeed") or 0,
                slot:GetAttribute("CarryingFruitSize") or 1,
                slot:GetAttribute("CarryingFruitOvertimeGrowth") or 1,
                slot:GetAttribute("CarryingFruitMutation") or ""
            )
        else
            -- Clear fruit
            petData.CarryFruitToken = (petData.CarryFruitToken or 0) + 1
            petData.CarryFruitAnchor = nil
            petData.CarryFruitAttach = nil
            if petData.CarryFruitModel then
                petData.CarryFruitModel:Destroy()
                petData.CarryFruitModel = nil
            end
        end
    end)

    -- Slot removed
    slot.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            DestroyActive(slot)
        end
    end)

    -- Initial sync
    SyncSlot(slot)
end

-- Watch all slots in a player folder
local function WatchPlayerFolder(folder)
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("BasePart") and string.match(child.Name, "^PetPart%d+$") then
            WatchSlot(child)
        end
    end

    folder.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and string.match(child.Name, "^PetPart%d+$") then
            WatchSlot(child)
        end
    end)
end

-- Watch root folder (PlayerPetReferences)
local function WatchRoot(root)
    for _, child in pairs(root:GetChildren()) do
        if child:IsA("Folder") then
            WatchPlayerFolder(child)
        end
    end

    root.ChildAdded:Connect(function(child)
        if child:IsA("Folder") then
            WatchPlayerFolder(child)
        end
    end)
end

--========================================
-- SNAPPING
--========================================

-- Snap all pets for a player (instant reposition)
local function SnapPetsForPlayer(player)
    for slot, petData in pairs(ActivePets) do
        if petData.Owner == player and slot.Parent then
            local claim = slot:GetAttribute("PetClaim")
            if type(claim) ~= "string" or claim == "" then
                petData.Model:PivotTo(slot.CFrame * petData.SlotAttachment.CFrame)
                petData.LastAnimPos = slot.Position
                petData.LastAnimTime = os.clock()
                petData.LastVisualPos = petData.Primary and petData.Primary.Position
                petData.LastVisualTime = os.clock()
                petData.SmoothedSpeed = 0
                petData.LastGoalChangeTime = nil
                petData.LastTrackedGoalXZ = nil
            end
        end
    end
end

-- Snap local pets to follow positions
local function SnapLocalPetsToFollow()
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if not hrp then return end

    local hrpCF = hrp.CFrame
    local lookVector = hrpCF.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    local direction = flatLook.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or flatLook.Unit
    local position = hrpCF.Position
    local baseCF = CFrame.lookAt(position, position + direction)

    for slot, petData in pairs(ActivePets) do
        if petData.Owner == localPlayer and slot.Parent 
           and petData.Primary and petData.Primary.Parent then
            local claim = slot:GetAttribute("PetClaim")
            if type(claim) ~= "string" or claim == "" then
                local offsetX = slot:GetAttribute("SlotOffsetX")
                local offsetZ = slot:GetAttribute("SlotOffsetZ")

                if typeof(offsetX) == "number" and typeof(offsetZ) == "number" then
                    local heightOffset = slot:GetAttribute("SlotHeightOffset") or 0
                    local targetCF = baseCF * CFrame.new(offsetX, -2.5, offsetZ)
                    local targetPos = targetCF.Position

                    local groundY = CastGroundY(targetPos, targetPos.Y)
                    if groundY == nil then
                        groundY = targetPos.Y
                    end
                    petData.LastLocalGroundY = groundY

                    local finalY
                    if petData.IsFlyer then
                        finalY = groundY + (petData.FootOffset or 0) + heightOffset
                    else
                        finalY = groundY + (petData.FootOffset or 0)
                    end

                    local finalPos = Vector3.new(targetPos.X, finalY, targetPos.Z)
                    local rotation = targetCF - targetCF.Position
                    local yaw = math.atan2(-rotation.LookVector.X, -rotation.LookVector.Z)
                    local pivot = petData.SpeciesPivotCFrame or CFrame.identity

                    petData.Primary.CFrame = CFrame.new(finalPos) * CFrame.Angles(0, yaw, 0) * pivot
                    petData.LocalGoalPos = finalPos
                    petData.LocalGoalRotation = rotation
                    petData.LastYaw = yaw
                    petData.LocalChase = true
                    petData.VirtualSlotPos = nil
                    petData.ForceFollowUntil = os.clock() + Config.ForceFollowDuration
                    petData.LastVisualPos = finalPos
                    petData.LastVisualTime = os.clock()
                    petData.SmoothedSpeed = 0
                    petData.LastGoalChangeTime = nil
                    petData.LastTrackedGoalXZ = nil
                    petData.AnimState = "idle"
                end
            end
        end
    end
end

--========================================
-- OWL HOOT
--========================================

local function FindLocalOwlPrimary()
    local localPlayer = Players.LocalPlayer
    for _, petData in pairs(ActivePets) do
        if petData.Owner == localPlayer and petData.Species == "Owl" then
            if petData.Primary and petData.Primary.Parent then
                return petData.Primary
            end
        end
    end
    return nil
end

local function PlayOwlHoot(soundId)
    if type(soundId) ~= "string" or soundId == "" then return end

    if OwlSound and OwlSound.Parent and OwlSound.IsPlaying then
        return
    end

    local owlPrimary = FindLocalOwlPrimary()
    local soundParent = owlPrimary

    if not soundParent then
        local character = Players.LocalPlayer.Character
        if character then
            soundParent = character:FindFirstChild("HumanoidRootPart")
        end
    end

    if not soundParent then return end

    local sound = Instance.new("Sound")
    sound.Name = "OwlHoot"
    sound.SoundId = soundId
    sound.Volume = 4.5
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 10
    sound.RollOffMaxDistance = 400

    local sfxGroup = SoundService:FindFirstChild("SFXGroup")
    if sfxGroup and sfxGroup:IsA("SoundGroup") then
        sound.SoundGroup = sfxGroup
    end

    sound.Parent = soundParent
    OwlSound = sound
    sound:Play()

    sound.Ended:Once(function()
        if OwlSound == sound then
            OwlSound = nil
        end
        sound:Destroy()
    end)
end

--========================================
-- RENDER STEP - PET FOLLOWING
--========================================

local function OnRenderStep(deltaTime)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local currentTime = os.clock()

    -- Refresh ground filter periodically
    if currentTime - LastFilterRefresh >= Config.FilterRefreshInterval then
        LastFilterRefresh = currentTime
        RefreshGroundFilter()
    end

    for slot, petData in pairs(ActivePets) do
        if not slot.Parent then continue end
        if not (petData.Primary and petData.Primary.Parent) then continue end

        local goalPos = nil
        local goalRotation = nil
        local isLocalChase = false

        local slotOverride = slot:GetAttribute("SlotOverride")
        local offsetX = slot:GetAttribute("SlotOffsetX")
        local offsetZ = slot:GetAttribute("SlotOffsetZ")
        local heightOffset = slot:GetAttribute("SlotHeightOffset") or 0
        local petClaim = slot:GetAttribute("PetClaim")
        local hasClaim = type(petClaim) == "string" and petClaim ~= ""

        -- Handle claim/force follow logic
        if hasClaim then
            petData.ForceFollowUntil = nil
            slotOverride = true
        elseif petData.ForceFollowUntil and currentTime < petData.ForceFollowUntil then
            if petData.Owner == localPlayer and hrp then
                slotOverride = false
            else
                petData.ForceFollowUntil = nil
            end
        elseif petData.ForceFollowUntil then
            petData.ForceFollowUntil = nil
        end

        -- Local player pet following
        if petData.Owner == localPlayer and hrp 
           and slotOverride ~= true 
           and typeof(offsetX) == "number" 
           and typeof(offsetZ) == "number" then

            local hrpCF = hrp.CFrame
            local lookVector = hrpCF.LookVector
            local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
            local direction = flatLook.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or flatLook.Unit
            local position = hrpCF.Position
            local baseCF = CFrame.lookAt(position, position + direction)
            local targetCF = baseCF * CFrame.new(offsetX, -2.5, offsetZ)
            local targetPos = targetCF.Position

            local groundY
            if petData.IsFlyer then
                groundY = targetPos.Y + heightOffset
            else
                groundY = targetPos.Y
            end

            local finalPos = Vector3.new(targetPos.X, groundY, targetPos.Z)
            local rotation = targetCF - targetCF.Position

            petData.LocalGoalPos = finalPos
            petData.LocalGoalRotation = rotation
            petData.LocalChase = true

            local xzPos = Vector3.new(finalPos.X, 0, finalPos.Z)
            if petData.LastTrackedGoalXZ and (xzPos - petData.LastTrackedGoalXZ).Magnitude > 0.005 then
                petData.LastGoalChangeTime = currentTime
            end
            petData.LastTrackedGoalXZ = xzPos

            goalPos = finalPos
            goalRotation = rotation
            isLocalChase = true
        else
            -- Remote pet - interpolate slot position
            local slotCF = slot.CFrame

            if slotCF ~= petData.LastSlotCF then
                if petData.LastSlotTickAt then
                    local delta = currentTime - petData.LastSlotTickAt
                    if petData.SlotTickPeriod then
                        petData.SlotTickPeriod = petData.SlotTickPeriod * 0.7 + math.clamp(delta, 0.01, 0.2) * 0.3
                    else
                        petData.SlotTickPeriod = math.clamp(delta, 0.01, 0.2)
                    end
                end
                petData.PrevSlotCF = petData.LastSlotCF or slotCF
                petData.LastSlotCF = slotCF
                petData.LastSlotTickAt = currentTime
                petData.LastGoalChangeTime = currentTime
            end

            if petData.PrevSlotCF and petData.LastSlotTickAt then
                local period = petData.SlotTickPeriod or 0.0333
                local t = math.clamp((currentTime - petData.LastSlotTickAt) / period, 0, 1)
                slotCF = petData.PrevSlotCF:Lerp(slotCF, t)
            end

            goalPos = (slotCF * petData.SlotAttachment.CFrame).Position
            petData.InterpSlotCF = slotCF
            petData.LocalChase = false
        end

        -- Movement logic
        local currentPos = petData.Primary.CFrame.Position
        local targetPos = goalPos
        local targetRot = goalRotation

        if petData.LocalChase then
            -- Chase local goal
            local dx = targetPos.X - currentPos.X
            local dz = targetPos.Z - currentPos.Z
            local distSq = dx * dx + dz * dz
            local dist = math.sqrt(distSq)

            local smoothing = 1 - math.exp(-Config.SmoothingFactor * deltaTime)
            local speed = petData.Module and (petData.Module.FollowSpeed or Config.FollowSpeed) or Config.FollowSpeed

            -- Adjust for humanoid walk speed
            if petData.Owner then
                local ownerChar = petData.Owner.Character
                if ownerChar then
                    local humanoid = ownerChar:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        speed = speed * math.max(1, humanoid.WalkSpeed / 16)
                    end
                end
            end

            local maxMove = speed * deltaTime
            local newX, newZ

            if dist <= 0.05 or dist <= maxMove then
                newX = targetPos.X
                newZ = targetPos.Z
            else
                local moveDist = maxMove / math.max(smoothing, 0.001)
                newX = currentPos.X + (dx / dist) * moveDist
                newZ = currentPos.Z + (dz / dist) * moveDist
            end

            -- Height calculation
            local newY
            if petData.IsFlyer then
                local heightRatio = math.clamp((heightOffset or 0) / 1.5, 0, 1)
                local flyY = targetPos.Y
                local groundY

                if heightRatio < 1 then
                    local castY = CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                    local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                    local prevGroundY = petData.LastChaseGroundY or targetGroundY
                    local lerpAlpha = math.clamp(Config.HeightLerpSpeed * deltaTime, 0, 1)
                    local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                    petData.LastChaseGroundY = smoothGroundY
                    groundY = smoothGroundY + (petData.FootOffset or 0)
                else
                    groundY = flyY
                end

                newY = groundY * (1 - heightRatio) + flyY * heightRatio
            else
                local castY = CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                local prevGroundY = petData.LastChaseGroundY or targetGroundY
                local lerpAlpha = math.clamp(Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                petData.LastChaseGroundY = smoothGroundY
                newY = smoothGroundY + (petData.FootOffset or 0) + ComputeJumpOffset(slot)
            end

            local finalPos = Vector3.new(newX, newY, newZ)
            local moveDir = finalPos - currentPos
            local moveSpeed = moveDir.Magnitude / math.max(deltaTime, 0.001)

            -- Rotation
            local lookX = -targetRot.LookVector.X
            local lookZ = -targetRot.LookVector.Z
            local targetYaw = math.atan2(lookX, lookZ)

            if moveSpeed > 0.5 then
                local moveDirFlat = Vector3.new(moveDir.X, 0, moveDir.Z)
                if moveDirFlat.Magnitude > 0.0001 then
                    local unit = moveDirFlat.Unit
                    targetYaw = math.atan2(-unit.X, -unit.Z)
                end
            end

            local lastYaw = petData.LastYaw or targetYaw
            local yawDiff = (targetYaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
            local yawAlpha = math.clamp(Config.RotationSpeed * deltaTime, 0, 1)
            local newYaw = lastYaw + yawDiff * yawAlpha
            petData.LastYaw = newYaw
            petData.VirtualSlotPos = nil

            local pivot = petData.SpeciesPivotCFrame or CFrame.identity
            local targetCF = CFrame.new(finalPos) * CFrame.Angles(0, newYaw, 0) * pivot
            petData.Primary.CFrame = petData.Primary.CFrame:Lerp(targetCF, smoothing)
        else
            -- Interpolate to slot position
            local slotTarget = petData.InterpSlotCF or (slot.CFrame * petData.SlotAttachment.CFrame)
            local targetPos = slotTarget.Position

            local dx = targetPos.X - currentPos.X
            local dz = targetPos.Z - currentPos.Z
            local distSq = dx * dx + dz * dz
            local dist = math.sqrt(distSq)

            local smoothing = 1 - math.exp(-Config.SmoothingFactor * deltaTime)
            local speed = petData.Module and (petData.Module.FollowSpeed or Config.FollowSpeed) or Config.FollowSpeed

            if petData.Owner then
                local ownerChar = petData.Owner.Character
                if ownerChar then
                    local humanoid = ownerChar:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        speed = speed * math.max(1, humanoid.WalkSpeed / 16)
                    end
                end
            end

            local maxMove = speed * deltaTime
            local newX, newZ, isMoving

            if dist > 0.05 and maxMove < dist then
                local moveDist = maxMove / math.max(smoothing, 0.001)
                newX = currentPos.X + (dx / dist) * moveDist
                newZ = currentPos.Z + (dz / dist) * moveDist
                isMoving = true
            else
                newX = targetPos.X
                newZ = targetPos.Z
                isMoving = false
            end

            -- Height
            local newY
            if petData.IsFlyer then
                newY = targetPos.Y
            else
                local castY = CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                local prevGroundY = petData.LastChaseGroundY or targetGroundY
                local lerpAlpha = math.clamp(Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                petData.LastChaseGroundY = smoothGroundY
                newY = smoothGroundY + (petData.FootOffset or 0) + ComputeJumpOffset(slot)
            end

            local finalPos = Vector3.new(newX, newY, newZ)

            -- Rotation from slot look vector
            local slotLook = (petData.InterpSlotCF or slot.CFrame).LookVector
            local targetYaw = math.atan2(-slotLook.X, -slotLook.Z)

            local moveDir = finalPos - currentPos
            if isMoving and moveDir.Magnitude / math.max(deltaTime, 0.001) > 0.5 then
                local moveDirFlat = Vector3.new(moveDir.X, 0, moveDir.Z)
                if moveDirFlat.Magnitude > 0.0001 then
                    local unit = moveDirFlat.Unit
                    targetYaw = math.atan2(-unit.X, -unit.Z)
                end
            end

            local lastYaw = petData.LastYaw or targetYaw
            local yawDiff = (targetYaw - lastYaw + math.pi) % (2 * math.pi) - math.pi
            local yawAlpha = math.clamp(Config.RotationSpeed * deltaTime, 0, 1)
            local newYaw = lastYaw + yawDiff * yawAlpha
            petData.LastYaw = newYaw

            local pivot = petData.SpeciesPivotCFrame or CFrame.identity
            local targetCF = CFrame.new(finalPos) * CFrame.Angles(0, newYaw, 0) * pivot
            petData.Primary.CFrame = petData.Primary.CFrame:Lerp(targetCF, smoothing)
            petData.VirtualSlotPos = nil
        end

        -- Update carry fruit position
        if petData.CarryFruitAnchor and petData.CarryFruitAnchor.Parent 
           and petData.CarryFruitAttach and petData.CarryFruitAttach.Parent then
            petData.CarryFruitAnchor.CFrame = petData.CarryFruitAttach.WorldCFrame
        end
    end
end

--========================================
-- HEARTBEAT - ANIMATION STATE
--========================================

local function OnHeartbeat(deltaTime)
    local currentTime = os.clock()

    -- Refresh ground filter
    if currentTime - LastFilterRefresh >= Config.FilterRefreshInterval then
        LastFilterRefresh = currentTime
        RefreshGroundFilter()
    end

    for slot, petData in pairs(ActivePets) do
        if not slot.Parent then continue end

        local slotPos = slot.Position
        local slotAttachment = petData.SlotAttachment

        if not (slotAttachment and slotAttachment.Parent) then continue end

        -- Update slot attachment height
        local pivotCF = petData.SpeciesPivotCFrame or CFrame.identity
        local newOffsetY

        if petData.IsFlyer then
            local heightRatio = math.clamp((slot:GetAttribute("SlotHeightOffset") or 0) / 1.5, 0, 1)
            local footOffset = petData.FootOffset or 0
            local isPerched = slot:GetAttribute("Perched") == true
            local isTakeoff = slot:GetAttribute("FlightPhase") == "Takeoff"

            local groundOffset
            if heightRatio < 1 and not (isPerched or isTakeoff) then
                if (petData.SlotGroundCastNext or 0) <= currentTime then
                    local groundY = CastGroundY(slotPos, slotPos.Y)
                    if groundY ~= nil then
                        petData.SlotGroundCachedY = groundY
                    end
                    petData.SlotGroundCastNext = currentTime + Config.GroundCastInterval
                end

                local cachedY = petData.SlotGroundCachedY
                if cachedY == nil then
                    cachedY = petData.LastGroundY or slotPos.Y
                end
                local prevY = petData.LastGroundY or cachedY
                local lerpAlpha = math.clamp(Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothY = prevY + (cachedY - prevY) * lerpAlpha
                petData.LastGroundY = smoothY
                groundOffset = smoothY - slotPos.Y + (petData.FootOffset or 0)
            else
                groundOffset = footOffset
            end

            newOffsetY = groundOffset * (1 - heightRatio) + footOffset * heightRatio
        else
            -- Non-flyer ground tracking
            if (petData.SlotGroundCastNext or 0) <= currentTime then
                local groundY = CastGroundY(slotPos, slotPos.Y)
                if groundY ~= nil then
                    petData.SlotGroundCachedY = groundY
                end
                petData.SlotGroundCastNext = currentTime + Config.GroundCastInterval
            end

            local cachedY = petData.SlotGroundCachedY
            if cachedY == nil then
                cachedY = petData.LastGroundY or slotPos.Y
            end
            local prevY = petData.LastGroundY or cachedY
            local lerpAlpha = math.clamp(Config.HeightLerpSpeed * deltaTime, 0, 1)
            local smoothY = prevY + (cachedY - prevY) * lerpAlpha
            petData.LastGroundY = smoothY
            newOffsetY = smoothY - slotPos.Y + (petData.FootOffset or 0)
        end

        slotAttachment.CFrame = CFrame.new(0, newOffsetY, 0) * pivotCF

        -- Animation state management
        if petData.IsFlyer then
            local flightPhase = slot:GetAttribute("FlightPhase") or "Flying"
            local animState = flightPhase == "Flying" and "flying" 
                or (flightPhase == "Landing" and "landing" 
                or (flightPhase == "Grounded" and "groundidle" 
                or (flightPhase == "Takeoff" and "takeoff" or "flying")))

            local moduleAnims = petData.Module and petData.Module.Animations
            if animState == "flying" and moduleAnims and moduleAnims.FlyIdle then
                local currentTime = os.clock()
                local speed = 0
                local primaryPos = petData.Primary and petData.Primary.Position

                if primaryPos then
                    if petData.LastVisualPos and petData.LastVisualTime then
                        local dt = currentTime - petData.LastVisualTime
                        local timeDelta = math.max(0.001, dt)
                        local dist = (primaryPos - petData.LastVisualPos).Magnitude
                        if dist < Config.MaxSpeedForInterpolation then
                            speed = dist / timeDelta
                        end
                    end
                    petData.LastVisualPos = primaryPos
                    petData.LastVisualTime = currentTime
                end

                local alpha = math.clamp(deltaTime * Config.SpeedSmoothFactor, 0, 1)
                petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - alpha) + speed * alpha

                local smoothedSpeed = petData.SmoothedSpeed
                local currentAnim = petData.AnimState
                animState = smoothedSpeed > Config.FlyWalkThreshold and "flying" 
                    or (smoothedSpeed < Config.FlyIdleThreshold and "flyidle" 
                    or ((currentAnim ~= "flying" and currentAnim ~= "flyidle") and "flying" or currentAnim))
            end

            petData.AnimState = animState
            SwitchState(petData, animState)
        else
            -- Non-flyer animation state
            local currentTime = os.clock()
            local speed = 0
            local primaryPos = petData.Primary and petData.Primary.Position

            if primaryPos then
                if petData.LastVisualPos and petData.LastVisualTime then
                    local dt = currentTime - petData.LastVisualTime
                    local timeDelta = math.max(0.001, dt)
                    local dist = (primaryPos - petData.LastVisualPos).Magnitude
                    if dist < Config.MaxSpeedForInterpolation then
                        speed = dist / timeDelta
                    end
                end
                petData.LastVisualPos = primaryPos
                petData.LastVisualTime = currentTime
            end

            local alpha = math.clamp(deltaTime * Config.SpeedSmoothFactor, 0, 1)
            petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - alpha) + speed * alpha

            local smoothedSpeed = petData.SmoothedSpeed
            local currentAnim = petData.AnimState or "idle"
            local animState = currentAnim == "idle" and smoothedSpeed > Config.WalkThreshold and "walking" 
                or (currentAnim == "walking" and smoothedSpeed < Config.IdleThreshold and "idle" or currentAnim)

            petData.AnimState = animState
            SwitchState(petData, animState)
        end
    end
end

--========================================
-- PUBLIC API
--========================================

local PetVisualClient = {
    StartOrder = Config.StartOrder
}

-- Snap pets for a specific player (instant reposition)
function PetVisualClient:SnapPetsForPlayer(player)
    SnapPetsForPlayer(player)
end

-- Snap local pets to follow player
function PetVisualClient:SnapLocalPetsToFollow()
    SnapLocalPetsToFollow()
end

-- Initialize (called once)
function PetVisualClient:Init()
    -- Create folders
    VisualFolder = Instance.new("Folder")
    VisualFolder.Name = "_PetVisualClient"
    VisualFolder.Parent = workspace

    ModelsFolder = Instance.new("Folder")
    ModelsFolder.Name = "Models"
    ModelsFolder.Parent = VisualFolder

    CarryFolder = Instance.new("Folder")
    CarryFolder.Name = "Carry"
    CarryFolder.Parent = VisualFolder
end

-- Start (called after Init)
function PetVisualClient:Start()
    -- Watch PlayerPetReferences
    local petRefs = workspace:FindFirstChild("PlayerPetReferences") 
        or workspace:WaitForChild("PlayerPetReferences", 30)

    if petRefs and petRefs:IsA("Folder") then
        WatchRoot(petRefs)

        -- Networking events
        if Networking and Networking.SFX and Networking.SFX.OwlHoot then
            Networking.SFX.OwlHoot.OnClientEvent:Connect(PlayOwlHoot)
        end

        if Networking and Networking.Place and Networking.Place.TeleportedBack then
            Networking.Place.TeleportedBack.OnClientEvent:Connect(function()
                task.spawn(function()
                    RunService.Heartbeat:Wait()
                    self:SnapPetsForPlayer(Players.LocalPlayer)
                end)
            end)
        end

        -- Frog jump handling
        local function HookCharacter(character)
            local humanoid = character:FindFirstChildOfClass("Humanoid") 
                or character:WaitForChild("Humanoid", 10)

            if humanoid and humanoid:IsA("Humanoid") then
                humanoid.Jumping:Connect(function(isJumping)
                    if isJumping then
                        local now = os.clock()
                        if now - LastFrogJumpTime >= Config.SnapCooldown then
                            LastFrogJumpTime = now
                            if Networking and Networking.Pets and Networking.Pets.FrogJump then
                                Networking.Pets.FrogJump:Fire()
                            end
                        end
                    end
                end)
            end
        end

        Players.LocalPlayer.CharacterAdded:Connect(HookCharacter)
        if Players.LocalPlayer.Character then
            task.spawn(HookCharacter, Players.LocalPlayer.Character)
        end

        -- Snap pets broadcast from other players
        if Networking and Networking.Pets and Networking.Pets.SnapPetsBroadcast then
            Networking.Pets.SnapPetsBroadcast.OnClientEvent:Connect(function(userId)
                if userId == Players.LocalPlayer.UserId then
                    return
                end

                local player = Players:GetPlayerByUserId(userId)
                if player then
                    task.spawn(function()
                        RunService.Heartbeat:Wait()
                        self:SnapPetsForPlayer(player)
                    end)
                end
            end)
        end

        -- Bind render step for smooth following
        RunService:BindToRenderStep("PetVisualFollow", Enum.RenderPriority.Camera.Value + 1, OnRenderStep)

        -- Heartbeat for animation states and ground tracking
        RunService.Heartbeat:Connect(OnHeartbeat)
    end
end

return PetVisualClient
