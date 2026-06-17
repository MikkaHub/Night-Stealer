-- ============================================
-- GAG 2 VISUAL PET SPAWNER - DELTA COMPATIBLE
-- EXACT LOGIC FROM UPLOADED FILE
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then
    repeat task.wait() until LocalPlayer:FindFirstChild("PlayerGui")
    PlayerGui = LocalPlayer.PlayerGui
end

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

local function EnsureSlotAttachment(slotPart, footOffset, pivotCF)
    local attachment = slotPart:FindFirstChild("PetTarget")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "PetTarget"
        attachment.Parent = slotPart
    end
    local cf = pivotCF or CFrame.identity
    attachment.CFrame = CFrame.new(0, footOffset, 0) * cf
    return attachment
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
-- SPAWNER STATE
-- ============================================

local SpawnedPets = {}
local SpawnerFolder = nil
local SpawnerGUI = nil
local spawnerFrame = nil

-- ============================================
-- RAYCAST (exact from file)
-- ============================================

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

-- ============================================
-- BuildVisualPet (EXACT BuildSlotModel logic)
-- ============================================

local function BuildVisualPet(species, position, petType, size)
    local model, module = CloneSpeciesModel(species)
    if not (model and module) then
        warn("Failed to clone:", species)
        return nil
    end
    
    -- Attributes (exact from file)
    model:SetAttribute("PetID", "Visual_" .. tostring(os.clock()))
    model:SetAttribute("Owner", LocalPlayer.Name)
    model:SetAttribute("OwnerSlot", "VisualSlot")
    model:SetAttribute("PetVisual", true)
    
    -- Primary part (exact from file)
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
    
    -- Pivot CFrame (exact from file)
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
    
    -- Scale (exact from file)
    local scale = PetSizes.GetScale(size or "Normal", {
        Big = module.BigScale,
        Huge = module.HugeScale
    })
    if scale ~= 1 then
        model:ScaleTo(scale)
    end
    
    -- Foot offset (exact from file)
    local footOffset = ComputeFootOffset(model)
    
    -- PetPivot attachment (exact from file line ~147)
    local petPivotCF = primary.CFrame:Inverse() * model:GetPivot()
    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = petPivotCF
    petPivot.Parent = primary
    
    -- ============================================
    -- CREATE VISUAL SLOT (mimics PetPart from file)
    -- ============================================
    local visualSlot = Instance.new("Part")
    visualSlot.Name = "PetPart1"
    visualSlot.Size = Vector3.new(1, 1, 1)
    visualSlot.Transparency = 1
    visualSlot.CanCollide = false
    visualSlot.CanQuery = false
    visualSlot.Anchored = true
    visualSlot.Massless = true
    
    -- Slot offsets (like real pets have)
    visualSlot:SetAttribute("SlotOffsetX", 3)
    visualSlot:SetAttribute("SlotOffsetZ", 3)
    visualSlot:SetAttribute("SlotHeightOffset", 0)
    
    -- FIX: Get ground Y first, then position slot there
    local spawnPos = position or Vector3.new(0, 10, 0)
    local groundY = CastGroundY(spawnPos, spawnPos.Y)
    if groundY then
        spawnPos = Vector3.new(spawnPos.X, groundY, spawnPos.Z)
    end
    visualSlot.CFrame = CFrame.new(spawnPos)
    
    -- EnsureSlotAttachment (EXACT from file line 117)
    local slotAttachment = EnsureSlotAttachment(visualSlot, footOffset, pivotCF)
    
    -- Parent slot
    if not SpawnerFolder then
        SpawnerFolder = Instance.new("Folder")
        SpawnerFolder.Name = "_VisualPetSpawner"
        SpawnerFolder.Parent = workspace
    end
    visualSlot.Parent = SpawnerFolder
    
    -- Position model at slot * attachment (EXACT from file line ~150)
    model:PivotTo(visualSlot.CFrame * slotAttachment.CFrame)
    
    -- Anchor primary (EXACT from file line ~152)
    primary.Anchored = true
    
    -- Parent model
    local modelsFolder = SpawnerFolder:FindFirstChild("Models")
    if not modelsFolder then
        modelsFolder = Instance.new("Folder")
        modelsFolder.Name = "Models"
        modelsFolder.Parent = SpawnerFolder
    end
    model.Parent = modelsFolder
    
    -- Animator (EXACT from file)
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
    
    -- ============================================
    -- Pet data (MATCHES file's structure EXACTLY)
    -- ============================================
    local petData = {
        Owner = LocalPlayer,
        Slot = visualSlot,
        Species = species,
        Module = module,
        Model = model,
        Primary = primary,
        Animator = animator,
        Tracks = tracks,
        CurrentState = "",
        SlotAttachment = slotAttachment,
        PetAttachment = petPivot,
        FootOffset = footOffset,
        SpeciesPivotCFrame = pivotCF,
        Connections = {},
        LastAnimPos = visualSlot.Position,
        LastAnimTime = os.clock(),
        AnimState = "idle",
        IsFlyer = module.IsFlying == true,
        LastYaw = 0,
        LastChaseGroundY = nil,
        SmoothedSpeed = 0,
        LastVisualPos = nil,
        LastVisualTime = nil,
        -- Slot interpolation (from file)
        LastSlotCF = nil,
        PrevSlotCF = nil,
        LastSlotTickAt = nil,
        SlotTickPeriod = nil,
        -- Ground casting (from file)
        SlotGroundCastNext = 0,
        SlotGroundCachedY = nil,
        LastGroundY = nil,
        -- Local chase (from file's RenderStep)
        LocalGoalPos = nil,
        LocalGoalRotation = nil,
        LocalChase = false,
        LastTrackedGoalXZ = nil,
        LastGoalChangeTime = nil,
        ForceFollowUntil = nil,
        VirtualSlotPos = nil,
    }
    
    ApplyPetTypeTag(model, petType)
    
    -- Cleanup connections
    local conn1 = model.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            DestroyVisualPet(petData)
        end
    end)
    table.insert(petData.Connections, conn1)
    
    local conn2 = visualSlot.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            DestroyVisualPet(petData)
        end
    end)
    table.insert(petData.Connections, conn2)
    
    -- FIX: Initial animation state for flyers
    local initialState
    if petData.IsFlyer then
        -- Check FlightPhase attribute or default to flying
        local flightPhase = visualSlot:GetAttribute("FlightPhase") or "Flying"
        initialState = flightPhase == "Flying" and "flying" or 
                      (flightPhase == "Landing" and "landing" or 
                      (flightPhase == "Grounded" and "groundidle" or 
                      (flightPhase == "Takeoff" and "takeoff" or "flying")))
    else
        initialState = "idle"
    end
    petData.CurrentState = ""
    SwitchState(petData, initialState)
    
    ApplyVisibility(petData, true)
    
    table.insert(SpawnedPets, petData)
    print("✅ Spawned:", species, "| Flyer:", petData.IsFlyer, "| Initial:", initialState)
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
    
    if petData.Slot and petData.Slot.Parent then
        petData.Slot:Destroy()
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
-- EXACT PET FOLLOW FROM FILE (RenderStepped)
-- ============================================

local function UpdatePetFollow(petData, dt)
    local character = LocalPlayer.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local primary = petData.Primary
    if not (primary and primary.Parent) then return end
    
    local slot = petData.Slot
    if not (slot and slot.Parent) then return end
    
    -- ============================================
    -- EXACT LOGIC FROM FILE'S RenderStepped
    -- ============================================
    
    local v288 = nil
    local v289 = slot:GetAttribute("SlotOverride")
    local v290 = slot:GetAttribute("SlotOffsetX")
    local v291 = slot:GetAttribute("SlotOffsetZ")
    local v292 = slot:GetAttribute("SlotHeightOffset") or 0
    local v293 = slot:GetAttribute("PetClaim")
    local v294
    if type(v293) == "string" then
        v294 = v293 ~= ""
    else
        v294 = false
    end
    
    if v294 then
        petData.ForceFollowUntil = nil
        v289 = true
    elseif petData.ForceFollowUntil and os.clock() < petData.ForceFollowUntil then
        if petData.Owner == LocalPlayer and hrp then
            v289 = false
        else
            petData.ForceFollowUntil = nil
        end
    elseif petData.ForceFollowUntil then
        petData.ForceFollowUntil = nil
    end
    
    -- ============================================
    -- LOCAL CHASE (when owner is local player)
    -- EXACT from file lines 295-311
    -- ============================================
    if petData.Owner == LocalPlayer and (hrp and (v289 ~= true and (typeof(v290) == "number" and typeof(v291) == "number"))) then
        local v295 = hrp.CFrame
        local v296 = v295.LookVector
        local v297 = v296.X
        local v298 = v296.Z
        local v299 = Vector3.new(v297, 0, v298)
        local v300 = v299.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or v299.Unit
        local v301 = v295.Position
        local v302 = CFrame.lookAt(v301, v301 + v300) * CFrame.new(v290, -2.5, v291)
        local v303 = v302.Position
        local v304
        if petData.IsFlyer then
            v304 = v303.Y + v292
        else
            v304 = v303.Y
        end
        local v305 = v303.X
        local v306 = v303.Z
        local v307 = Vector3.new(v305, v304, v306)
        local v308 = v302 - v302.Position
        petData.LocalGoalPos = v307
        petData.LocalGoalRotation = v308
        petData.LocalChase = true
        
        local v309 = v307.X
        local v310 = v307.Z
        local v311 = Vector3.new(v309, 0, v310)
        if petData.LastTrackedGoalXZ and (v311 - petData.LastTrackedGoalXZ).Magnitude > 0.005 then
            petData.LastGoalChangeTime = os.clock()
        end
        petData.LastTrackedGoalXZ = v311
    else
        -- ============================================
        -- SLOT INTERPOLATION (exact from file)
        -- ============================================
        local v312 = slot.CFrame
        if v312 ~= petData.LastSlotCF then
            local v313 = os.clock()
            if petData.LastSlotTickAt then
                local v314 = v313 - petData.LastSlotTickAt
                if petData.SlotTickPeriod then
                    petData.SlotTickPeriod = petData.SlotTickPeriod * 0.7 + math.clamp(v314, 0.01, 0.2) * 0.3
                else
                    petData.SlotTickPeriod = math.clamp(v314, 0.01, 0.2)
                end
            end
            petData.PrevSlotCF = petData.LastSlotCF or v312
            petData.LastSlotCF = v312
            petData.LastSlotTickAt = v313
            petData.LastGoalChangeTime = v313
        end
        
        if petData.PrevSlotCF and petData.LastSlotTickAt then
            local v315 = petData.SlotTickPeriod or 0.03333333333333333
            local v316 = (os.clock() - petData.LastSlotTickAt) / v315
            local v317 = math.clamp(v316, 0, 1)
            v312 = petData.PrevSlotCF:Lerp(v312, v317)
        end
        
        v288 = v312 * petData.SlotAttachment.CFrame
        petData.InterpSlotCF = v312
        petData.LocalChase = false
    end
    
    -- ============================================
    -- LOCAL CHASE MOVEMENT (exact from file)
    -- ============================================
    if petData.LocalChase then
        local v318 = petData.LocalGoalPos
        local v319 = petData.LocalGoalRotation
        local v320 = primary.CFrame.Position
        local v321 = v318.X - v320.X
        local v322 = v318.Z - v320.Z
        local v323 = v321 * v321 + v322 * v322
        local v324 = math.sqrt(v323)
        local v325 = -60 * dt
        local v326 = 1 - math.exp(v325)
        local v327 = petData.Module and (petData.Module.FollowSpeed or 14) or 14
        
        local v328 = petData.Owner
        if v328 then
            local v329 = v328.Character
            if v329 then
                v329 = v329:FindFirstChildOfClass("Humanoid")
            end
            if v329 then
                local v330 = v329.WalkSpeed / 16
                v327 = v327 * math.max(1, v330)
            end
        end
        
        local v331 = v327 * dt
        local v332, v333
        
        if v324 <= 0.05 or v324 <= v331 then
            v332 = v318.X
            v333 = v318.Z
        else
            local v334 = 1 / v324
            local v335 = v331 / math.max(v326, 0.001)
            v332 = v320.X + v321 * v334 * v335
            v333 = v320.Z + v322 * v334 * v335
        end
        
        local v336
        if petData.IsFlyer then
            local v337 = (slot:GetAttribute("SlotHeightOffset") or 0) / 1.5
            local v338 = math.clamp(v337, 0, 1)
            local v339 = v318.Y
            local v340
            if v338 < 1 then
                local v341 = v320.Y
                local v342 = CastGroundY(Vector3.new(v332, v341, v333), v320.Y) or (petData.LastChaseGroundY or v320.Y)
                local v343 = petData.LastChaseGroundY or v342
                local v344 = 18 * dt
                local v345 = math.clamp(v344, 0, 1)
                local v346 = v343 + (v342 - v343) * v345
                petData.LastChaseGroundY = v346
                v340 = v346 + (petData.FootOffset or 0)
            else
                v340 = v339
            end
            v336 = v340 * (1 - v338) + v339 * v338
        else
            local v347 = v320.Y
            local v348 = CastGroundY(Vector3.new(v332, v347, v333), v320.Y) or (petData.LastChaseGroundY or v320.Y)
            local v349 = petData.LastChaseGroundY or v348
            local v350 = 18 * dt
            local v351 = math.clamp(v350, 0, 1)
            local v352 = v349 + (v348 - v349) * v351
            petData.LastChaseGroundY = v352
            v336 = v352 + (petData.FootOffset or 0)
        end
        
        local v353 = Vector3.new(v332, v336, v333)
        local v354 = v353 - v320
        local v355 = v354.Magnitude / math.max(dt, 0.001)
        local v356 = -v319.LookVector.X
        local v357 = -v319.LookVector.Z
        local v358 = math.atan2(v356, v357)
        
        if v355 > 0.5 then
            local v359 = v354.X
            local v360 = v354.Z
            local v361 = Vector3.new(v359, 0, v360)
            if v361.Magnitude > 0.0001 then
                local v362 = v361.Unit
                local v363 = -v362.X
                local v364 = -v362.Z
                v358 = math.atan2(v363, v364)
            end
        end
        
        local v365 = petData.LastYaw or v358
        local v366 = (v358 - v365 + math.pi) % (2 * math.pi) - math.pi
        local v367 = 12 * dt
        local v368 = v365 + v366 * math.clamp(v367, 0, 1)
        petData.LastYaw = v368
        petData.VirtualSlotPos = nil
        
        local v369 = petData.SpeciesPivotCFrame or CFrame.identity
        local v370 = CFrame.new(v353) * CFrame.Angles(0, v368, 0) * v369
        primary.CFrame = primary.CFrame:Lerp(v370, v326)
        
    else
        -- ============================================
        -- SLOT FOLLOW (exact from file)
        -- ============================================
        local v371 = primary.CFrame.Position
        local v372 = v288.Position
        local v373 = v372.X - v371.X
        local v374 = v372.Z - v371.Z
        local v375 = v373 * v373 + v374 * v374
        local v376 = math.sqrt(v375)
        local v377 = -60 * dt
        local v378 = 1 - math.exp(v377)
        local v379 = petData.Module and (petData.Module.FollowSpeed or 14) or 14
        
        local v380 = petData.Owner
        if v380 then
            local v381 = v380.Character
            if v381 then
                v381 = v381:FindFirstChildOfClass("Humanoid")
            end
            if v381 then
                local v382 = v381.WalkSpeed / 16
                v379 = v379 * math.max(1, v382)
            end
        end
        
        local v383 = v379 * dt
        local v384, v385, v386
        
        if v376 > 0.05 and v383 < v376 then
            local v387 = 1 / v376
            local v388 = v383 / math.max(v378, 0.001)
            v384 = v371.X + v373 * v387 * v388
            v385 = v371.Z + v374 * v387 * v388
            v386 = true
        else
            v384 = v372.X
            v385 = v372.Z
            v386 = false
        end
        
        local v389
        if petData.IsFlyer then
            v389 = v372.Y
        else
            local v390 = v371.Y
            local v391 = CastGroundY(Vector3.new(v384, v390, v385), v371.Y) or (petData.LastChaseGroundY or v371.Y)
            local v392 = petData.LastChaseGroundY or v391
            local v393 = 18 * dt
            local v394 = math.clamp(v393, 0, 1)
            local v395 = v392 + (v391 - v392) * v394
            petData.LastChaseGroundY = v395
            v389 = v395 + (petData.FootOffset or 0)
        end
        
        local v396 = Vector3.new(v384, v389, v385)
        local v397 = (petData.InterpSlotCF or v288).LookVector
        local v398 = -v397.X
        local v399 = -v397.Z
        local v400 = math.atan2(v398, v399)
        local v401 = v396 - v371
        
        if v386 and v401.Magnitude / math.max(dt, 0.001) > 0.5 then
            local v402 = v401.X
            local v403 = v401.Z
            local v404 = Vector3.new(v402, 0, v403)
            if v404.Magnitude > 0.0001 then
                local v405 = v404.Unit
                local v406 = -v405.X
                local v407 = -v405.Z
                v400 = math.atan2(v406, v407)
            end
        end
        
        local v408 = petData.LastYaw or v400
        local v409 = (v400 - v408 + math.pi) % (2 * math.pi) - math.pi
        local v410 = 12 * dt
        local v411 = v408 + v409 * math.clamp(v410, 0, 1)
        petData.LastYaw = v411
        
        local v412 = petData.SpeciesPivotCFrame or CFrame.identity
        local v413 = CFrame.new(v396) * CFrame.Angles(0, v411, 0) * v412
        primary.CFrame = primary.CFrame:Lerp(v413, v378)
        petData.VirtualSlotPos = nil
    end
end

-- ============================================
-- EXACT ANIMATION STATE FROM FILE (Heartbeat)
-- FIX: Added flyer animation logic
-- ============================================

local function UpdatePetAnimation(petData, dt)
    local slot = petData.Slot
    if not (slot and slot.Parent) then return end
    
    local primary = petData.Primary
    if not (primary and primary.Parent) then return end
    
    -- Slot attachment ground update (exact from file)
    local slotPos = slot.Position
    local now = os.clock()
    
    -- ============================================
    -- FLYER SLOT ATTACHMENT (exact from file lines 418-434)
    -- ============================================
    local v419 = petData.SlotAttachment
    if v419 and v419.Parent then
        local v420 = petData.SpeciesPivotCFrame or CFrame.identity
        local v421
        
        if petData.IsFlyer then
            local v422 = (slot:GetAttribute("SlotHeightOffset") or 0) / 1.5
            local v423 = math.clamp(v422, 0, 1)
            local v424 = petData.FootOffset or 0
            local v425 = slot:GetAttribute("Perched") == true
            local v426 = slot:GetAttribute("FlightPhase") == "Takeoff"
            local v427
            
            if v423 < 1 and not (v425 or v426) then
                local v428 = os.clock()
                if (petData.SlotGroundCastNext or 0) <= v428 then
                    local v429 = CastGroundY(slotPos, slotPos.Y)
                    if v429 ~= nil then
                        petData.SlotGroundCachedY = v429
                    end
                    petData.SlotGroundCastNext = v428 + 0.06666666666666667
                end
                
                local v430 = petData.SlotGroundCachedY
                if v430 == nil then
                    v430 = petData.LastGroundY or slotPos.Y
                end
                local v431 = petData.LastGroundY or v430
                local v432 = 18 * dt
                local v433 = math.clamp(v432, 0, 1)
                local v434 = v431 + (v430 - v431) * v433
                petData.LastGroundY = v434
                v427 = v434 - slotPos.Y + (petData.FootOffset or 0)
            else
                v427 = v424
            end
            
            v421 = v427 * (1 - v423) + v424 * v423
        else
            -- Ground pet slot attachment (exact from file)
            local v435 = os.clock()
            if (petData.SlotGroundCastNext or 0) <= v435 then
                local v436 = CastGroundY(slotPos, slotPos.Y)
                if v436 ~= nil then
                    petData.SlotGroundCachedY = v436
                end
                petData.SlotGroundCastNext = v435 + 0.06666666666666667
            end
            
            local v437 = petData.SlotGroundCachedY
            if v437 == nil then
                v437 = petData.LastGroundY or slotPos.Y
            end
            local v438 = petData.LastGroundY or v437
            local v439 = 18 * dt
            local v440 = math.clamp(v439, 0, 1)
            local v441 = v438 + (v437 - v438) * v440
            petData.LastGroundY = v441
            v421 = v441 - slotPos.Y + (petData.FootOffset or 0)
        end
        
        v419.CFrame = CFrame.new(0, v421, 0) * v420
    end
    
    -- ============================================
    -- ANIMATION STATE (EXACT from file's Heartbeat)
    -- FIX: Added complete flyer logic
    -- ============================================
    if petData.IsFlyer then
        -- ============================================
        -- FLYER ANIMATION (exact from file lines 442-454)
        -- ============================================
        local v442 = slot:GetAttribute("FlightPhase") or "Flying"
        local v443 = v442 == "Flying" and "flying" or 
                    (v442 == "Landing" and "landing" or 
                    (v442 == "Grounded" and "groundidle" or 
                    (v442 == "Takeoff" and "takeoff" or "flying")))
        
        local v444 = petData.Module
        if v444 then
            v444 = petData.Module.Animations
        end
        
        -- FlyIdle speed-based switching (exact from file)
        if v443 == "flying" and (v444 and v444.FlyIdle) then
            local v445 = os.clock()
            local v446 = 0
            
            local v447 = petData.Primary
            if v447 then
                v447 = petData.Primary.Position
            end
            
            if v447 then
                if petData.LastVisualPos and petData.LastVisualTime then
                    local v448 = v445 - petData.LastVisualTime
                    local v449 = math.max(0.001, v448)
                    local v450 = (v447 - petData.LastVisualPos).Magnitude
                    if v450 < 50 then
                        v446 = v450 / v449
                    end
                end
                petData.LastVisualPos = v447
                petData.LastVisualTime = v445
            end
            
            local v451 = dt * 6
            local v452 = math.clamp(v451, 0, 1)
            petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - v452) + v446 * v452
            
            local v453 = petData.SmoothedSpeed
            local v454 = petData.AnimState
            v443 = v453 > 2 and "flying" or 
                   (v453 < 0.6 and "flyidle" or 
                   (v454 ~= "flying" and v454 ~= "flyidle" and "flying" or v454))
        end
        
        petData.AnimState = v443
        SwitchState(petData, v443)
        
    else
        -- ============================================
        -- GROUND PET ANIMATION (exact from file lines 455-465)
        -- ============================================
        local v455 = os.clock()
        local v456 = 0
        
        local v457 = petData.Primary
        if v457 then
            v457 = petData.Primary.Position
        end
        
        if v457 then
            if petData.LastVisualPos and petData.LastVisualTime then
                local v458 = v455 - petData.LastVisualTime
                local v459 = math.max(0.001, v458)
                local v460 = (v457 - petData.LastVisualPos).Magnitude
                if v460 < 50 then
                    v456 = v460 / v459
                end
            end
            petData.LastVisualPos = v457
            petData.LastVisualTime = v455
        end
        
        local v461 = dt * 6
        local v462 = math.clamp(v461, 0, 1)
        petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - v462) + v456 * v462
        
        local v463 = petData.SmoothedSpeed
        local v464 = petData.AnimState or "idle"
        local v465 = v464 == "idle" and v463 > 2 and "walking" or 
                      (v464 == "walking" and v463 < 0.6 and "idle" or v464)
        petData.AnimState = v465
        SwitchState(petData, v465)
    end
end

-- ============================================
-- DELTA GUI WITH DELETE PER PET
-- ============================================

local function CreateSpawnerGUI()
    if SpawnerGUI then
        pcall(function() SpawnerGUI:Destroy() end)
    end
    
    local guiParent = PlayerGui
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
    
    if not screenGui.Parent then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 340, 0, 480)
    frame.Position = UDim2.new(0.5, -170, 0.5, -240)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Visible = true
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "🐾 GAG 2 Visual Pet Spawner"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Parent = frame
    
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
    
    -- Tab buttons
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, -10, 0, 30)
    tabFrame.Position = UDim2.new(0, 5, 0, 47)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = frame
    
    local spawnTab = Instance.new("TextButton")
    spawnTab.Size = UDim2.new(0.48, 0, 1, 0)
    spawnTab.Text = "Spawn"
    spawnTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
    spawnTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    spawnTab.Font = Enum.Font.GothamBold
    spawnTab.TextSize = 14
    spawnTab.Parent = tabFrame
    
    Instance.new("UICorner", spawnTab).CornerRadius = UDim.new(0, 6)
    
    local manageTab = Instance.new("TextButton")
    manageTab.Size = UDim2.new(0.48, 0, 1, 0)
    manageTab.Position = UDim2.new(0.52, 0, 0, 0)
    manageTab.Text = "Manage (" .. #SpawnedPets .. ")"
    manageTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    manageTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    manageTab.Font = Enum.Font.GothamBold
    manageTab.TextSize = 14
    manageTab.Parent = tabFrame
    
    Instance.new("UICorner", manageTab).CornerRadius = UDim.new(0, 6)
    
    -- Content frames
    local spawnFrame = Instance.new("Frame")
    spawnFrame.Size = UDim2.new(1, -10, 1, -130)
    spawnFrame.Position = UDim2.new(0, 5, 0, 80)
    spawnFrame.BackgroundTransparency = 1
    spawnFrame.Visible = true
    spawnFrame.Parent = frame
    
    local manageFrame = Instance.new("Frame")
    manageFrame.Size = UDim2.new(1, -10, 1, -130)
    manageFrame.Position = UDim2.new(0, 5, 0, 80)
    manageFrame.BackgroundTransparency = 1
    manageFrame.Visible = false
    manageFrame.Parent = frame
    
    -- Tab switching
    spawnTab.MouseButton1Click:Connect(function()
        spawnFrame.Visible = true
        manageFrame.Visible = false
        spawnTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        manageTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    manageTab.MouseButton1Click:Connect(function()
        spawnFrame.Visible = false
        manageFrame.Visible = true
        spawnTab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        manageTab.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
        refreshManageList()
    end)
    
    -- ============================================
    -- SPAWN TAB
    -- ============================================
    
    local spawnScroll = Instance.new("ScrollingFrame")
    spawnScroll.Size = UDim2.new(1, 0, 1, 0)
    spawnScroll.BackgroundTransparency = 1
    spawnScroll.ScrollBarThickness = 6
    spawnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    spawnScroll.Parent = spawnFrame
    
    Instance.new("UIListLayout", spawnScroll).Padding = UDim.new(0, 4)
    
    -- Type selector
    local typeFrame = Instance.new("Frame")
    typeFrame.Size = UDim2.new(1, 0, 0, 28)
    typeFrame.BackgroundTransparency = 1
    typeFrame.Parent = spawnScroll
    
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(0.35, 0, 1, 0)
    typeLabel.Text = "Type:"
    typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextSize = 13
    typeLabel.Parent = typeFrame
    
    local typeDropdown = Instance.new("TextButton")
    typeDropdown.Size = UDim2.new(0.6, 0, 1, 0)
    typeDropdown.Position = UDim2.new(0.4, 0, 0, 0)
    typeDropdown.Text = "Normal"
    typeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    typeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    typeDropdown.Font = Enum.Font.GothamBold
    typeDropdown.TextSize = 13
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
    sizeFrame.Size = UDim2.new(1, 0, 0, 28)
    sizeFrame.BackgroundTransparency = 1
    sizeFrame.Parent = spawnScroll
    
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0.35, 0, 1, 0)
    sizeLabel.Text = "Size:"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 13
    sizeLabel.Parent = sizeFrame
    
    local sizeDropdown = Instance.new("TextButton")
    sizeDropdown.Size = UDim2.new(0.6, 0, 1, 0)
    sizeDropdown.Position = UDim2.new(0.4, 0, 0, 0)
    sizeDropdown.Text = "Normal"
    sizeDropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sizeDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    sizeDropdown.Font = Enum.Font.GothamBold
    sizeDropdown.TextSize = 13
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
    sep.Size = UDim2.new(1, 0, 0, 2)
    sep.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    sep.BorderSizePixel = 0
    sep.Parent = spawnScroll
    
    -- Pet spawn buttons
    for species, module in pairs(PetModules) do
        local btn = Instance.new("TextButton")
        btn.Name = species .. "Btn"
        btn.Size = UDim2.new(1, -5, 0, 30)
        btn.Text = "  📌 " .. species .. (module.IsFlying and " 🦅" or "")
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.Parent = spawnScroll
        
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local pos = hrp and hrp.Position or Vector3.new(0, 10, 0)
            
            local petTypeVal = selectedType == "Rainbow" and PetTypes.Rainbow or nil
            
            BuildVisualPet(species, pos, petTypeVal, selectedSize)
            manageTab.Text = "Manage (" .. #SpawnedPets .. ")"
        end)
    end
    
    -- ============================================
    -- MANAGE TAB (Delete individual pets)
    -- ============================================
    
    local manageScroll = Instance.new("ScrollingFrame")
    manageScroll.Name = "ManageScroll"
    manageScroll.Size = UDim2.new(1, 0, 1, 0)
    manageScroll.BackgroundTransparency = 1
    manageScroll.ScrollBarThickness = 6
    manageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    manageScroll.Parent = manageFrame
    
    Instance.new("UIListLayout", manageScroll).Padding = UDim.new(0, 4)
    
    local function refreshManageList()
        for _, child in pairs(manageScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        if #SpawnedPets == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.Text = "No pets spawned"
            empty.TextColor3 = Color3.fromRGB(150, 150, 150)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 14
            empty.Parent = manageScroll
            return
        end
        
        for i, petData in ipairs(SpawnedPets) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -5, 0, 32)
            row.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            row.Parent = manageScroll
            
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
            nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
            nameLabel.Text = petData.Species .. (petData.IsFlyer and " 🦅" or "")
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 13
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = row
            
            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0.4, 0, 0.8, 0)
            delBtn.Position = UDim2.new(0.58, 0, 0.1, 0)
            delBtn.Text = "❌ Delete"
            delBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 12
            delBtn.Parent = row
            
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            
            delBtn.MouseButton1Click:Connect(function()
                DestroyVisualPet(petData)
                manageTab.Text = "Manage (" .. #SpawnedPets .. ")"
                refreshManageList()
            end)
        end
    end
    
    -- ============================================
    -- CLOSE & DELETE ALL
    -- ============================================
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0.28, 0, 0, 30)
    closeBtn.Position = UDim2.new(0.02, 0, 1, -36)
    closeBtn.Text = "Close"
    closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = frame
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    
    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)
    
    local deleteAllBtn = Instance.new("TextButton")
    deleteAllBtn.Size = UDim2.new(0.38, 0, 0, 30)
    deleteAllBtn.Position = UDim2.new(0.32, 0, 1, -36)
    deleteAllBtn.Text = "Delete All"
    deleteAllBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    deleteAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteAllBtn.Font = Enum.Font.GothamBold
    deleteAllBtn.TextSize = 14
    deleteAllBtn.Parent = frame
    
    Instance.new("UICorner", deleteAllBtn).CornerRadius = UDim.new(0, 6)
    
    deleteAllBtn.MouseButton1Click:Connect(function()
        DestroyAllVisualPets()
        manageTab.Text = "Manage (0)"
        refreshManageList()
    end)
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "CountLabel"
    countLabel.Size = UDim2.new(0.28, 0, 0, 30)
    countLabel.Position = UDim2.new(0.72, 0, 1, -36)
    countLabel.Text = "0 pets"
    countLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    countLabel.BackgroundTransparency = 1
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 12
    countLabel.Parent = frame
    
    task.spawn(function()
        while screenGui and screenGui.Parent do
            countLabel.Text = #SpawnedPets .. " pets"
            manageTab.Text = "Manage (" .. #SpawnedPets .. ")"
            task.wait(0.5)
        end
    end)
    
    SpawnerGUI = screenGui
    return frame
end

-- ============================================
-- INPUT
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

-- ============================================
-- RENDER & HEARTBEAT (EXACT from file)
-- ============================================

RunService:BindToRenderStep("VisualPetFollow", Enum.RenderPriority.Camera.Value + 1, function(dt)
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

RunService.Heartbeat:Connect(function(dt)
    for _, petData in ipairs(SpawnedPets) do
        if petData.Slot and petData.Slot.Parent then
            UpdatePetAnimation(petData, dt)
        end
    end
end)

-- ============================================
-- AUTO-OPEN
-- ============================================

task.spawn(function()
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    task.wait(1)
    
    if not spawnerFrame or not spawnerFrame.Parent then
        spawnerFrame = CreateSpawnerGUI()
    end
end)

print("✅ GAG 2 Visual Pet Spawner loaded!")
print("Press P for GUI | Spawn tab to spawn | Manage tab to delete individual pets")
print("Press Delete to remove all pets")
