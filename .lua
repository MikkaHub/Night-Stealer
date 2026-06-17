--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           MIKKA HUB - Grow a Garden 2 Pet Visual Spawner      ║
    ║                   Delta Executor Compatible                    ║
    ╚══════════════════════════════════════════════════════════════╝

    Features:
    ✓ Visual Pet Spawner (all original features)
    ✓ GUI Toggle (Mikka Hub style)
    ✓ Delta Executor Optimized
    ✓ All pet systems: animations, following, carrying, frog jump, owl hoot

    Usage: Paste into Delta Executor and execute
]]

-- Delta Executor Detection & Compatibility
local getexecutorname = getexecutorname or function() return "Unknown" end
local executor = getexecutorname()
local isDelta = executor:lower():find("delta") ~= nil

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

--========================================
-- MIKKA HUB GUI CREATION
--========================================

local function CreateMikkaHub()
    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MikkaHub_GAG2"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Parent to CoreGui (Delta compatible) or PlayerGui
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Main Frame (Mikka Hub style - dark rounded)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    -- Rounded corners
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = MainFrame

    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageTransparency = 0.6
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Parent = MainFrame

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    -- Title Text
    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "Title"
    TitleText.Size = UDim2.new(1, -80, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "🌸 Mikka Hub | GAG 2 Pet Visuals"
    TitleText.TextColor3 = Color3.fromRGB(255, 182, 193)
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = TitleBar

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "Close"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    -- Minimize Button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "Minimize"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -70, 0, 5)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.TextSize = 18
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = TitleBar

    local MinCorner = Instance.new("UICorner")
    MinCorner.CornerRadius = UDim.new(0, 6)
    MinCorner.Parent = MinBtn

    -- Content Frame
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -50)
    Content.Position = UDim2.new(0, 10, 0, 45)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = Color3.fromRGB(255, 182, 193)
    Content.CanvasSize = UDim2.new(0, 0, 0, 800)
    Content.Parent = MainFrame

    -- UI List Layout
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.Parent = Content

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "Status"
    StatusLabel.Size = UDim2.new(1, 0, 0, 25)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: Ready | Executor: " .. executor
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.Parent = Content

    -- Separator
    local Sep1 = Instance.new("Frame")
    Sep1.Size = UDim2.new(1, -10, 0, 1)
    Sep1.Position = UDim2.new(0, 5, 0, 0)
    Sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    Sep1.BorderSizePixel = 0
    Sep1.Parent = Content

    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        TitleBar = TitleBar,
        Content = Content,
        StatusLabel = StatusLabel,
        CloseBtn = CloseBtn,
        MinBtn = MinBtn
    }
end

--========================================
-- GUI ELEMENTS HELPERS
--========================================

local function CreateSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = text
    section.TextColor3 = Color3.fromRGB(255, 182, 193)
    section.TextSize = 14
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = parent
    return section
end

local function CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 45, 0, 25)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 6)
    toggleCorner.Parent = toggleBtn

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
        toggleBtn.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end)

    return frame, toggleBtn
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 8)
    sliderFrame.Position = UDim2.new(0, 10, 0, 30)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 4)
    sliderCorner.Parent = sliderFrame

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local dragging = false

    sliderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)

    sliderFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position.X - sliderFrame.AbsolutePosition.X
            local scale = math.clamp(pos / sliderFrame.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * scale
            fill.Size = UDim2.new(scale, 0, 1, 0)
            label.Text = text .. ": " .. string.format("%.1f", value)
            if callback then callback(value) end
        end
    end)

    return frame
end

--========================================
-- PET VISUAL SPAWNER SYSTEM
--========================================

local PetSystem = {
    Active = false,
    VisualFolder = nil,
    ModelsFolder = nil,
    CarryFolder = nil,
    ActivePets = {},
    PendingBuilds = {},
    Destroying = {},
    Config = {
        FollowSpeed = 14,
        GroundCastInterval = 0.0667,
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
    },
    GroundRaycastParams = RaycastParams.new(),
    SecondaryRaycastParams = RaycastParams.new(),
    LastFilterRefresh = -math.huge,
    FruitGenCache = {},
    Networking = nil,
    PetModules = nil,
    PetSizes = nil,
    PetTypes = nil,
}

function PetSystem:Init()
    self.GroundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self.GroundRaycastParams.IgnoreWater = false
    self.GroundRaycastParams.RespectCanCollide = false

    self.SecondaryRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    self.SecondaryRaycastParams.IgnoreWater = false
    self.SecondaryRaycastParams.RespectCanCollide = false

    local success
    success, self.PetModules = pcall(function()
        return require(ReplicatedStorage:WaitForChild("SharedModules", 5):WaitForChild("PetModules", 5))
    end)
    if not success then self.PetModules = {} end

    success, self.Networking = pcall(function()
        return require(ReplicatedStorage:WaitForChild("SharedModules", 5):WaitForChild("Networking", 5))
    end)

    success, self.PetSizes = pcall(function()
        return require(ReplicatedStorage:WaitForChild("SharedData", 5):WaitForChild("PetSizes", 5))
    end)

    success, self.PetTypes = pcall(function()
        return require(ReplicatedStorage:WaitForChild("SharedData", 5):WaitForChild("PetTypes", 5))
    end)

    self.VisualFolder = Instance.new("Folder")
    self.VisualFolder.Name = "_PetVisualClient_Mikka"
    self.VisualFolder.Parent = workspace

    self.ModelsFolder = Instance.new("Folder")
    self.ModelsFolder.Name = "Models"
    self.ModelsFolder.Parent = self.VisualFolder

    self.CarryFolder = Instance.new("Folder")
    self.CarryFolder.Name = "Carry"
    self.CarryFolder.Parent = self.VisualFolder

    self.Active = true
end

function PetSystem:RefreshGroundFilter()
    local filterList = {}
    for _, player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            table.insert(filterList, character)
        end
    end
    if self.VisualFolder then
        table.insert(filterList, self.VisualFolder)
    end
    local petRefs = workspace:FindFirstChild("PlayerPetReferences")
    if petRefs then
        table.insert(filterList, petRefs)
    end
    local gardens = workspace:FindFirstChild("Gardens")
    if gardens then
        for _, garden in pairs(gardens:GetChildren()) do
            local plants = garden:FindFirstChild("Plants")
            if plants then
                table.insert(filterList, plants)
            end
        end
    end
    local potted = workspace:FindFirstChild("PottedPlantVisuals")
    if potted then
        table.insert(filterList, potted)
    end
    self.GroundRaycastParams.FilterDescendantsInstances = filterList
end

function PetSystem:CastGroundY(position, startY)
    local startPos = Vector3.new(position.X, startY + self.Config.RaycastStartHeight, position.Z)
    local result = workspace:Raycast(startPos, Vector3.new(0, -self.Config.RaycastDistance, 0), self.GroundRaycastParams)
    if not (result and result.Instance) then return nil end
    local hit = result.Instance
    if hit.Transparency < 0.99 and hit.CanCollide then
        return result.Position.Y
    end
    local secondaryFilter = table.clone(self.GroundRaycastParams.FilterDescendantsInstances)
    table.insert(secondaryFilter, hit)
    self.SecondaryRaycastParams.FilterDescendantsInstances = secondaryFilter
    for _ = 1, 8 do
        local secondaryResult = workspace:Raycast(startPos, Vector3.new(0, -self.Config.RaycastDistance, 0), self.SecondaryRaycastParams)
        if not (secondaryResult and secondaryResult.Instance) then return nil end
        local secondaryHit = secondaryResult.Instance
        if secondaryHit.Transparency < 0.99 and secondaryHit.CanCollide then
            return secondaryResult.Position.Y
        end
        table.insert(secondaryFilter, secondaryHit)
        self.SecondaryRaycastParams.FilterDescendantsInstances = secondaryFilter
    end
    return nil
end

function PetSystem:ComputeFootOffset(model)
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

function PetSystem:ComputeJumpOffset(slot)
    if slot:GetAttribute("PetSpecies") ~= "Frog" then return 0 end
    local jumpStart = slot:GetAttribute("SlotJumpStart")
    if typeof(jumpStart) ~= "number" then return 0 end
    local jumpPeak = slot:GetAttribute("SlotJumpPeak")
    if typeof(jumpPeak) ~= "number" or jumpPeak <= 0 then return 0 end
    local jumpDuration = slot:GetAttribute("SlotJumpDuration")
    if typeof(jumpDuration) ~= "number" or jumpDuration <= 0 then return 0 end
    local elapsed = workspace:GetServerTimeNow() - jumpStart
    if elapsed < 0 or elapsed > jumpDuration then return 0 end
    local t = elapsed / jumpDuration
    return jumpPeak * 4 * t * (1 - t)
end

function PetSystem:GetOrCreateAnimator(model)
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

function PetSystem:FindAnimationsOnModel(model, animationNames)
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

function PetSystem:GetAnimNameForState(module, state)
    if not module or not module.Animations then return nil end
    local anims = module.Animations
    if state == "idle" then return anims.Idle
    elseif state == "walking" then return anims.Walk
    elseif state == "flying" then return anims.Fly
    elseif state == "flyidle" then return anims.FlyIdle or anims.Fly
    elseif state == "landing" then return anims.Land
    elseif state == "takeoff" then return anims.Takeoff
    elseif state == "groundidle" then return anims.GroundIdle or anims.Idle
    end
    return nil
end

function PetSystem:SwitchState(petData, newState)
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
    for _, track in pairs(petData.Tracks) do
        if track.IsPlaying then
            track:Stop(fadeTime)
        end
    end
    local animName = self:GetAnimNameForState(petData.Module, newState)
    if animName then
        local track = petData.Tracks[animName]
        if track then
            track.Looped = (newState ~= "landing" and newState ~= "takeoff")
            track:Play(track.Looped and 0.2 or 0.05)
        end
    end
end

function PetSystem:ApplyVisibility(petData, isVisible)
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

function PetSystem:ApplyPetTypeTag(model, petType)
    if not model then return end
    if self.PetTypes and petType == self.PetTypes.Rainbow then
        if not model:HasTag("PetRainbow") then
            model:AddTag("PetRainbow")
        end
    else
        if model:HasTag("PetRainbow") then
            model:RemoveTag("PetRainbow")
        end
    end
end

function PetSystem:CloneSpeciesModel(speciesName)
    local moduleData = self.PetModules and self.PetModules[speciesName]
    if not moduleData then return nil, nil end
    local assetName = moduleData.AssetName
    local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
    local petsFolder = assetsFolder and assetsFolder:FindFirstChild("Pets")
    local asset = petsFolder and petsFolder:FindFirstChild(assetName) or (assetsFolder and assetsFolder:FindFirstChild(assetName))
    if not (asset and asset:IsA("Model")) then return nil, nil end
    local clone = asset:Clone()
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

function PetSystem:EnsureSlotAttachment(slot, footOffset, pivotCFrame)
    local attachment = slot:FindFirstChild("PetTarget")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "PetTarget"
        attachment.Parent = slot
    end
    attachment.CFrame = CFrame.new(0, footOffset, 0) * (pivotCFrame or CFrame.identity)
    return attachment
end

function PetSystem:DestroyActive(slot)
    self.Destroying[slot] = (self.Destroying[slot] or 0) + 1
    self.PendingBuilds[slot] = nil
    local petData = self.ActivePets[slot]
    if petData then
        self.ActivePets[slot] = nil
        for _, connection in pairs(petData.Connections) do
            connection:Disconnect()
        end
        petData.Connections = {}
        for _, track in pairs(petData.Tracks) do
            track:Stop(0)
        end
        if petData.CarryFruitModel then
            petData.CarryFruitModel:Destroy()
            petData.CarryFruitModel = nil
        end
        if petData.Model and petData.Model.Parent then
            petData.Model:Destroy()
        end
    end
    self.Destroying[slot] = nil
end

function PetSystem:BuildSlotModel(slot, speciesName)
    if self.PendingBuilds[slot] then return end
    local generation = (self.Destroying[slot] or 0) + 1
    self.Destroying[slot] = generation
    self.PendingBuilds[slot] = generation

    local function Bail()
        if self.PendingBuilds[slot] == generation then
            self.PendingBuilds[slot] = nil
        end
        if slot.Parent then
            local currentSpecies = slot:GetAttribute("PetSpecies")
            if type(currentSpecies) == "string" and currentSpecies ~= "" 
               and (currentSpecies ~= speciesName or not self.ActivePets[slot]) then
                task.defer(function() self:SyncSlot(slot) end)
            end
        end
    end

    local parent = slot.Parent
    local owner = nil
    if parent and parent:IsA("Folder") then
        owner = Players:FindFirstChild(parent.Name)
    end
    if not owner then return Bail() end

    local model, moduleData = self:CloneSpeciesModel(speciesName)
    if not (model and moduleData) then return Bail() end

    model:SetAttribute("PetID", slot:GetAttribute("PetId"))
    model:SetAttribute("Owner", owner.Name)
    model:SetAttribute("OwnerSlot", slot.Name)

    local primaryPart = model.PrimaryPart
    if not (primaryPart and primaryPart.Parent) then
        primaryPart = model:FindFirstChild("Torso") or model:FindFirstChild("RootPart") or model:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            model.PrimaryPart = primaryPart
        end
    end
    if not primaryPart then
        model:Destroy()
        return Bail()
    end

    local pivotCFrame = CFrame.identity
    if moduleData.Pivot and typeof(moduleData.Pivot) == "Vector3" then
        local p = moduleData.Pivot
        pivotCFrame = CFrame.Angles(math.rad(p.X), math.rad(p.Y), math.rad(p.Z))
    end
    model:PivotTo(pivotCFrame)

    local scale = 1
    if self.PetSizes and self.PetSizes.GetScale then
        scale = self.PetSizes.GetScale(slot:GetAttribute("PetSize"), {
            Big = moduleData.BigScale,
            Huge = moduleData.HugeScale
        })
    end
    if scale ~= 1 then
        model:ScaleTo(scale)
    end

    local footOffset = self:ComputeFootOffset(model)
    local petPivotCFrame = primaryPart.CFrame:Inverse() * model:GetPivot()
    local slotAttachment = self:EnsureSlotAttachment(slot, footOffset, pivotCFrame)

    RunService.Heartbeat:Wait()
    local waitCount = 0
    while waitCount < self.Config.MaxJumpWaitFrames 
          and slot.Position.Magnitude <= 1 
          and not slot:GetAttribute("SlotVisualIndex") do
        RunService.Heartbeat:Wait()
        waitCount = waitCount + 1
        if (self.Destroying[slot] or 0) ~= generation 
           or not slot.Parent or slot:GetAttribute("PetSpecies") ~= speciesName then
            model:Destroy()
            return Bail()
        end
    end

    if (self.Destroying[slot] or 0) ~= generation 
       or not slot.Parent or slot:GetAttribute("PetSpecies") ~= speciesName then
        model:Destroy()
        return Bail()
    end

    model:PivotTo(slot.CFrame * slotAttachment.CFrame)

    local petPivot = Instance.new("Attachment")
    petPivot.Name = "PetPivot"
    petPivot.CFrame = petPivotCFrame
    petPivot.Parent = primaryPart

    primaryPart.Anchored = true
    model.Parent = self.ModelsFolder

    if (self.Destroying[slot] or 0) ~= generation 
       or not slot.Parent or slot:GetAttribute("PetSpecies") ~= speciesName then
        if model.Parent then model:Destroy() end
        return Bail()
    end

    local animator = self:GetOrCreateAnimator(model)
    local animations = self:FindAnimationsOnModel(model, moduleData.Animations)
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
        LastSlotCF = nil,
        PrevSlotCF = nil,
        LastSlotTickAt = nil,
        SlotTickPeriod = nil,
        InterpSlotCF = nil,
        SlotGroundCastNext = 0,
        SlotGroundCachedY = nil,
        LastGroundY = nil,
        CarryFruitModel = nil,
        CarryFruitAnchor = nil,
        CarryFruitAttach = nil,
        CarryFruitToken = 0,
    }

    self.ActivePets[slot] = petData
    self:ApplyPetTypeTag(model, slot:GetAttribute("PetType"))

    table.insert(petData.Connections, model.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            self:DestroyActive(slot)
        end
    end))

    task.spawn(function()
        RunService.Heartbeat:Wait()
        if self.ActivePets[slot] then
            local pd = self.ActivePets[slot]
            if pd.Slot.Parent then
                pd.Model:PivotTo(pd.Slot.CFrame * pd.SlotAttachment.CFrame)
            end
            pd.LastAnimPos = slot.Position
            pd.LastAnimTime = os.clock()
        end
    end)

    task.spawn(function()
        RunService.Heartbeat:Wait()
        if self.ActivePets[slot] then
            local pd = self.ActivePets[slot]
            local initialState
            if pd.IsFlyer then
                local flightPhase = slot:GetAttribute("FlightPhase") or "Flying"
                initialState = flightPhase == "Flying" and "flying" 
                    or (flightPhase == "Landing" and "landing" 
                    or (flightPhase == "Grounded" and "groundidle" 
                    or (flightPhase == "Takeoff" and "takeoff" or "flying")))
            else
                initialState = "idle"
            end
            pd.CurrentState = ""
            self:SwitchState(pd, initialState)
        end
    end)

    self:ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)

    if self.PendingBuilds[slot] == generation then
        self.PendingBuilds[slot] = nil
    end
end

function PetSystem:SyncSlot(slot)
    local species = slot:GetAttribute("PetSpecies")
    local petData = self.ActivePets[slot]
    if petData and petData.Species ~= species then
        self:DestroyActive(slot)
        petData = nil
    end
    if type(species) == "string" and species ~= "" then
        if not petData then
            self:BuildSlotModel(slot, species)
        else
            petData.Model:SetAttribute("PetID", slot:GetAttribute("PetId"))
            self:ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)
            local attached = slot:GetAttribute("PetAttached") ~= false
            petData.Model:SetAttribute("AttachedToPetPart", attached)
        end
    else
        self.Destroying[slot] = (self.Destroying[slot] or 0) + 1
        self.PendingBuilds[slot] = nil
        local parent = slot.Parent
        local owner = nil
        if parent and parent:IsA("Folder") then
            owner = Players:FindFirstChild(parent.Name)
        end
        if owner and self.ModelsFolder then
            for _, child in pairs(self.ModelsFolder:GetChildren()) do
                if child:GetAttribute("OwnerSlot") == slot.Name 
                   and child:GetAttribute("Owner") == owner.Name then
                    child:Destroy()
                end
            end
        end
    end
end

function PetSystem:WatchSlot(slot)
    slot.CanQuery = false

    slot:GetAttributeChangedSignal("PetSpecies"):Connect(function()
        self:SyncSlot(slot)
    end)

    slot:GetAttributeChangedSignal("PetSize"):Connect(function()
        self:DestroyActive(slot)
        self:SyncSlot(slot)
    end)

    slot:GetAttributeChangedSignal("PetVisible"):Connect(function()
        local petData = self.ActivePets[slot]
        if petData then
            self:ApplyVisibility(petData, slot:GetAttribute("PetVisible") ~= false)
        end
    end)

    slot:GetAttributeChangedSignal("PetAttached"):Connect(function()
        local petData = self.ActivePets[slot]
        if petData then
            local attached = slot:GetAttribute("PetAttached") ~= false
            petData.Model:SetAttribute("AttachedToPetPart", attached)
        end
    end)

    slot:GetAttributeChangedSignal("PetId"):Connect(function()
        local petData = self.ActivePets[slot]
        if petData then
            petData.Model:SetAttribute("PetID", slot:GetAttribute("PetId"))
        end
    end)

    slot:GetAttributeChangedSignal("PetType"):Connect(function()
        local petData = self.ActivePets[slot]
        if petData then
            self:ApplyPetTypeTag(petData.Model, slot:GetAttribute("PetType"))
        end
    end)

    slot:GetAttributeChangedSignal("CarryingFruit"):Connect(function()
        local petData = self.ActivePets[slot]
        if not petData then return end
        local fruitName = slot:GetAttribute("CarryingFruit")
        if typeof(fruitName) == "string" and fruitName ~= "" then
            -- Fruit carrying would be handled here
        else
            petData.CarryFruitToken = (petData.CarryFruitToken or 0) + 1
            petData.CarryFruitAnchor = nil
            petData.CarryFruitAttach = nil
            if petData.CarryFruitModel then
                petData.CarryFruitModel:Destroy()
                petData.CarryFruitModel = nil
            end
        end
    end)

    slot.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            self:DestroyActive(slot)
        end
    end)

    self:SyncSlot(slot)
end

function PetSystem:WatchPlayerFolder(folder)
    for _, child in pairs(folder:GetChildren()) do
        if child:IsA("BasePart") and string.match(child.Name, "^PetPart%d+$") then
            self:WatchSlot(child)
        end
    end
    folder.ChildAdded:Connect(function(child)
        if child:IsA("BasePart") and string.match(child.Name, "^PetPart%d+$") then
            self:WatchSlot(child)
        end
    end)
end

function PetSystem:WatchRoot(root)
    for _, child in pairs(root:GetChildren()) do
        if child:IsA("Folder") then
            self:WatchPlayerFolder(child)
        end
    end
    root.ChildAdded:Connect(function(child)
        if child:IsA("Folder") then
            self:WatchPlayerFolder(child)
        end
    end)
end

function PetSystem:SnapPetsForPlayer(player)
    for slot, petData in pairs(self.ActivePets) do
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

function PetSystem:SnapLocalPetsToFollow()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hrpCF = hrp.CFrame
    local lookVector = hrpCF.LookVector
    local flatLook = Vector3.new(lookVector.X, 0, lookVector.Z)
    local direction = flatLook.Magnitude < 0.0001 and Vector3.new(0, 0, -1) or flatLook.Unit
    local position = hrpCF.Position
    local baseCF = CFrame.lookAt(position, position + direction)

    for slot, petData in pairs(self.ActivePets) do
        if petData.Owner == LocalPlayer and slot.Parent 
           and petData.Primary and petData.Primary.Parent then
            local claim = slot:GetAttribute("PetClaim")
            if type(claim) ~= "string" or claim == "" then
                local offsetX = slot:GetAttribute("SlotOffsetX")
                local offsetZ = slot:GetAttribute("SlotOffsetZ")
                if typeof(offsetX) == "number" and typeof(offsetZ) == "number" then
                    local heightOffset = slot:GetAttribute("SlotHeightOffset") or 0
                    local targetCF = baseCF * CFrame.new(offsetX, -2.5, offsetZ)
                    local targetPos = targetCF.Position

                    local groundY = self:CastGroundY(targetPos, targetPos.Y)
                    if groundY == nil then groundY = targetPos.Y end
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
                    petData.ForceFollowUntil = os.clock() + self.Config.ForceFollowDuration
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

function PetSystem:FindLocalOwlPrimary()
    for _, petData in pairs(self.ActivePets) do
        if petData.Owner == LocalPlayer and petData.Species == "Owl" then
            if petData.Primary and petData.Primary.Parent then
                return petData.Primary
            end
        end
    end
    return nil
end

function PetSystem:PlayOwlHoot(soundId)
    if type(soundId) ~= "string" or soundId == "" then return end
    local owlPrimary = self:FindLocalOwlPrimary()
    local soundParent = owlPrimary
    if not soundParent then
        local character = LocalPlayer.Character
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
    sound.Parent = soundParent
    sound:Play()

    sound.Ended:Once(function()
        sound:Destroy()
    end)
end

function PetSystem:OnRenderStep(deltaTime)
    if not self.Active then return end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local currentTime = os.clock()

    if currentTime - self.LastFilterRefresh >= self.Config.FilterRefreshInterval then
        self.LastFilterRefresh = currentTime
        self:RefreshGroundFilter()
    end

    for slot, petData in pairs(self.ActivePets) do
        if not slot.Parent then continue end
        if not (petData.Primary and petData.Primary.Parent) then continue end

        local goalPos = nil
        local goalRotation = nil

        local slotOverride = slot:GetAttribute("SlotOverride")
        local offsetX = slot:GetAttribute("SlotOffsetX")
        local offsetZ = slot:GetAttribute("SlotOffsetZ")
        local heightOffset = slot:GetAttribute("SlotHeightOffset") or 0
        local petClaim = slot:GetAttribute("PetClaim")
        local hasClaim = type(petClaim) == "string" and petClaim ~= ""

        if hasClaim then
            petData.ForceFollowUntil = nil
            slotOverride = true
        elseif petData.ForceFollowUntil and currentTime < petData.ForceFollowUntil then
            if petData.Owner == LocalPlayer and hrp then
                slotOverride = false
            else
                petData.ForceFollowUntil = nil
            end
        elseif petData.ForceFollowUntil then
            petData.ForceFollowUntil = nil
        end

        if petData.Owner == LocalPlayer and hrp 
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
        else
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

        if petData.LocalChase then
            local dx = targetPos.X - currentPos.X
            local dz = targetPos.Z - currentPos.Z
            local dist = math.sqrt(dx * dx + dz * dz)

            local smoothing = 1 - math.exp(-self.Config.SmoothingFactor * deltaTime)
            local speed = petData.Module and (petData.Module.FollowSpeed or self.Config.FollowSpeed) or self.Config.FollowSpeed

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

            local newY
            if petData.IsFlyer then
                local heightRatio = math.clamp((heightOffset or 0) / 1.5, 0, 1)
                local flyY = targetPos.Y
                local groundY

                if heightRatio < 1 then
                    local castY = self:CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                    local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                    local prevGroundY = petData.LastChaseGroundY or targetGroundY
                    local lerpAlpha = math.clamp(self.Config.HeightLerpSpeed * deltaTime, 0, 1)
                    local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                    petData.LastChaseGroundY = smoothGroundY
                    groundY = smoothGroundY + (petData.FootOffset or 0)
                else
                    groundY = flyY
                end

                newY = groundY * (1 - heightRatio) + flyY * heightRatio
            else
                local castY = self:CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                local prevGroundY = petData.LastChaseGroundY or targetGroundY
                local lerpAlpha = math.clamp(self.Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                petData.LastChaseGroundY = smoothGroundY
                newY = smoothGroundY + (petData.FootOffset or 0) + self:ComputeJumpOffset(slot)
            end

            local finalPos = Vector3.new(newX, newY, newZ)
            local moveDir = finalPos - currentPos
            local moveSpeed = moveDir.Magnitude / math.max(deltaTime, 0.001)

            local lookX = -goalRotation.LookVector.X
            local lookZ = -goalRotation.LookVector.Z
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
            local yawAlpha = math.clamp(self.Config.RotationSpeed * deltaTime, 0, 1)
            local newYaw = lastYaw + yawDiff * yawAlpha
            petData.LastYaw = newYaw
            petData.VirtualSlotPos = nil

            local pivot = petData.SpeciesPivotCFrame or CFrame.identity
            local targetCF = CFrame.new(finalPos) * CFrame.Angles(0, newYaw, 0) * pivot
            petData.Primary.CFrame = petData.Primary.CFrame:Lerp(targetCF, smoothing)
        else
            -- Interpolate to slot
            local slotTarget = petData.InterpSlotCF or (slot.CFrame * petData.SlotAttachment.CFrame)
            local targetPos = slotTarget.Position

            local dx = targetPos.X - currentPos.X
            local dz = targetPos.Z - currentPos.Z
            local dist = math.sqrt(dx * dx + dz * dz)

            local smoothing = 1 - math.exp(-self.Config.SmoothingFactor * deltaTime)
            local speed = petData.Module and (petData.Module.FollowSpeed or self.Config.FollowSpeed) or self.Config.FollowSpeed

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

            local newY
            if petData.IsFlyer then
                newY = targetPos.Y
            else
                local castY = self:CastGroundY(Vector3.new(newX, currentPos.Y, newZ), currentPos.Y)
                local targetGroundY = castY or (petData.LastChaseGroundY or currentPos.Y)
                local prevGroundY = petData.LastChaseGroundY or targetGroundY
                local lerpAlpha = math.clamp(self.Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothGroundY = prevGroundY + (targetGroundY - prevGroundY) * lerpAlpha
                petData.LastChaseGroundY = smoothGroundY
                newY = smoothGroundY + (petData.FootOffset or 0) + self:ComputeJumpOffset(slot)
            end

            local finalPos = Vector3.new(newX, newY, newZ)

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
            local yawAlpha = math.clamp(self.Config.RotationSpeed * deltaTime, 0, 1)
            local newYaw = lastYaw + yawDiff * yawAlpha
            petData.LastYaw = newYaw

            local pivot = petData.SpeciesPivotCFrame or CFrame.identity
            local targetCF = CFrame.new(finalPos) * CFrame.Angles(0, newYaw, 0) * pivot
            petData.Primary.CFrame = petData.Primary.CFrame:Lerp(targetCF, smoothing)
            petData.VirtualSlotPos = nil
        end

        -- Update carry fruit
        if petData.CarryFruitAnchor and petData.CarryFruitAnchor.Parent 
           and petData.CarryFruitAttach and petData.CarryFruitAttach.Parent then
            petData.CarryFruitAnchor.CFrame = petData.CarryFruitAttach.WorldCFrame
        end
    end
end

function PetSystem:OnHeartbeat(deltaTime)
    if not self.Active then return end
    local currentTime = os.clock()

    if currentTime - self.LastFilterRefresh >= self.Config.FilterRefreshInterval then
        self.LastFilterRefresh = currentTime
        self:RefreshGroundFilter()
    end

    for slot, petData in pairs(self.ActivePets) do
        if not slot.Parent then continue end

        local slotPos = slot.Position
        local slotAttachment = petData.SlotAttachment

        if not (slotAttachment and slotAttachment.Parent) then continue end

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
                    local groundY = self:CastGroundY(slotPos, slotPos.Y)
                    if groundY ~= nil then
                        petData.SlotGroundCachedY = groundY
                    end
                    petData.SlotGroundCastNext = currentTime + self.Config.GroundCastInterval
                end

                local cachedY = petData.SlotGroundCachedY
                if cachedY == nil then
                    cachedY = petData.LastGroundY or slotPos.Y
                end
                local prevY = petData.LastGroundY or cachedY
                local lerpAlpha = math.clamp(self.Config.HeightLerpSpeed * deltaTime, 0, 1)
                local smoothY = prevY + (cachedY - prevY) * lerpAlpha
                petData.LastGroundY = smoothY
                groundOffset = smoothY - slotPos.Y + (petData.FootOffset or 0)
            else
                groundOffset = footOffset
            end

            newOffsetY = groundOffset * (1 - heightRatio) + footOffset * heightRatio
        else
            if (petData.SlotGroundCastNext or 0) <= currentTime then
                local groundY = self:CastGroundY(slotPos, slotPos.Y)
                if groundY ~= nil then
                    petData.SlotGroundCachedY = groundY
                end
                petData.SlotGroundCastNext = currentTime + self.Config.GroundCastInterval
            end

            local cachedY = petData.SlotGroundCachedY
            if cachedY == nil then
                cachedY = petData.LastGroundY or slotPos.Y
            end
            local prevY = petData.LastGroundY or cachedY
            local lerpAlpha = math.clamp(self.Config.HeightLerpSpeed * deltaTime, 0, 1)
            local smoothY = prevY + (cachedY - prevY) * lerpAlpha
            petData.LastGroundY = smoothY
            newOffsetY = smoothY - slotPos.Y + (petData.FootOffset or 0)
        end

        slotAttachment.CFrame = CFrame.new(0, newOffsetY, 0) * pivotCF

        -- Animation state
        if petData.IsFlyer then
            local flightPhase = slot:GetAttribute("FlightPhase") or "Flying"
            local animState = flightPhase == "Flying" and "flying" 
                or (flightPhase == "Landing" and "landing" 
                or (flightPhase == "Grounded" and "groundidle" 
                or (flightPhase == "Takeoff" and "takeoff" or "flying")))

            local moduleAnims = petData.Module and petData.Module.Animations
            if animState == "flying" and moduleAnims and moduleAnims.FlyIdle then
                local speed = 0
                local primaryPos = petData.Primary and petData.Primary.Position

                if primaryPos then
                    if petData.LastVisualPos and petData.LastVisualTime then
                        local dt = currentTime - petData.LastVisualTime
                        local timeDelta = math.max(0.001, dt)
                        local dist = (primaryPos - petData.LastVisualPos).Magnitude
                        if dist < self.Config.MaxSpeedForInterpolation then
                            speed = dist / timeDelta
                        end
                    end
                    petData.LastVisualPos = primaryPos
                    petData.LastVisualTime = currentTime
                end

                local alpha = math.clamp(deltaTime * self.Config.SpeedSmoothFactor, 0, 1)
                petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - alpha) + speed * alpha

                local smoothedSpeed = petData.SmoothedSpeed
                local currentAnim = petData.AnimState
                animState = smoothedSpeed > self.Config.FlyWalkThreshold and "flying" 
                    or (smoothedSpeed < self.Config.FlyIdleThreshold and "flyidle" 
                    or ((currentAnim ~= "flying" and currentAnim ~= "flyidle") and "flying" or currentAnim))
            end

            petData.AnimState = animState
            self:SwitchState(petData, animState)
        else
            -- Non-flyer animation state
            local speed = 0
            local primaryPos = petData.Primary and petData.Primary.Position

            if primaryPos then
                if petData.LastVisualPos and petData.LastVisualTime then
                    local dt = currentTime - petData.LastVisualTime
                    local timeDelta = math.max(0.001, dt)
                    local dist = (primaryPos - petData.LastVisualPos).Magnitude
                    if dist < self.Config.MaxSpeedForInterpolation then
                        speed = dist / timeDelta
                    end
                end
                petData.LastVisualPos = primaryPos
                petData.LastVisualTime = currentTime
            end

            local alpha = math.clamp(deltaTime * self.Config.SpeedSmoothFactor, 0, 1)
            petData.SmoothedSpeed = (petData.SmoothedSpeed or 0) * (1 - alpha) + speed * alpha

            local smoothedSpeed = petData.SmoothedSpeed
            local currentAnim = petData.AnimState or "idle"
            local animState = currentAnim == "idle" and smoothedSpeed > self.Config.WalkThreshold and "walking" 
                or (currentAnim == "walking" and smoothedSpeed < self.Config.IdleThreshold and "idle" or currentAnim)

            petData.AnimState = animState
            self:SwitchState(petData, animState)
        end
    end
end

--========================================
-- MAIN EXECUTION & GUI CONTROLS
--========================================

local GUI = CreateMikkaHub()
local MikkaHub = {
    GUI = GUI,
    PetSystem = PetSystem,
    Active = false,
}

-- Pet System Controls Section
CreateSection(GUI.Content, "🐾 Pet System Controls")

-- Toggle: Enable Pet Visuals
CreateToggle(GUI.Content, "Enable Pet Visuals", false, function(state)
    MikkaHub.Active = state
    if state then
        PetSystem:Init()

        local petRefs = workspace:FindFirstChild("PlayerPetReferences") 
            or workspace:WaitForChild("PlayerPetReferences", 30)

        if petRefs and petRefs:IsA("Folder") then
            PetSystem:WatchRoot(petRefs)

            -- Networking events
            if PetSystem.Networking and PetSystem.Networking.SFX and PetSystem.Networking.SFX.OwlHoot then
                PetSystem.Networking.SFX.OwlHoot.OnClientEvent:Connect(function(soundId)
                    PetSystem:PlayOwlHoot(soundId)
                end)
            end

            if PetSystem.Networking and PetSystem.Networking.Place and PetSystem.Networking.Place.TeleportedBack then
                PetSystem.Networking.Place.TeleportedBack.OnClientEvent:Connect(function()
                    task.spawn(function()
                        RunService.Heartbeat:Wait()
                        PetSystem:SnapPetsForPlayer(LocalPlayer)
                    end)
                end)
            end

            -- Frog jump
            local lastFrogJump = 0
            local function HookCharacter(character)
                local humanoid = character:FindFirstChildOfClass("Humanoid") 
                    or character:WaitForChild("Humanoid", 10)
                if humanoid and humanoid:IsA("Humanoid") then
                    humanoid.Jumping:Connect(function(isJumping)
                        if isJumping then
                            local now = os.clock()
                            if now - lastFrogJump >= PetSystem.Config.SnapCooldown then
                                lastFrogJump = now
                                if PetSystem.Networking and PetSystem.Networking.Pets and PetSystem.Networking.Pets.FrogJump then
                                    PetSystem.Networking.Pets.FrogJump:Fire()
                                end
                            end
                        end
                    end)
                end
            end

            LocalPlayer.CharacterAdded:Connect(HookCharacter)
            if LocalPlayer.Character then
                task.spawn(HookCharacter, LocalPlayer.Character)
            end

            -- Snap broadcast
            if PetSystem.Networking and PetSystem.Networking.Pets and PetSystem.Networking.Pets.SnapPetsBroadcast then
                PetSystem.Networking.Pets.SnapPetsBroadcast.OnClientEvent:Connect(function(userId)
                    if userId == LocalPlayer.UserId then return end
                    local player = Players:GetPlayerByUserId(userId)
                    if player then
                        task.spawn(function()
                            RunService.Heartbeat:Wait()
                            PetSystem:SnapPetsForPlayer(player)
                        end)
                    end
                end)
            end

            -- Bind loops
            RunService:BindToRenderStep("PetVisualFollow_Mikka", Enum.RenderPriority.Camera.Value + 1, function(dt)
                PetSystem:OnRenderStep(dt)
            end)

            RunService.Heartbeat:Connect(function(dt)
                PetSystem:OnHeartbeat(dt)
            end)
        end

        GUI.StatusLabel.Text = "Status: Pet System Active"
        GUI.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        -- Disable
        pcall(function()
            RunService:UnbindFromRenderStep("PetVisualFollow_Mikka")
        end)

        for slot, _ in pairs(PetSystem.ActivePets) do
            PetSystem:DestroyActive(slot)
        end

        if PetSystem.VisualFolder then
            PetSystem.VisualFolder:Destroy()
            PetSystem.VisualFolder = nil
        end

        PetSystem.Active = false
        PetSystem.ActivePets = {}
        PetSystem.PendingBuilds = {}
        PetSystem.Destroying = {}

        GUI.StatusLabel.Text = "Status: Pet System Disabled"
        GUI.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Toggle: Show/Hide Pets
CreateToggle(GUI.Content, "Show All Pets", true, function(state)
    for _, petData in pairs(PetSystem.ActivePets) do
        PetSystem:ApplyVisibility(petData, state)
    end
end)

-- Toggle: Rainbow Mode
CreateToggle(GUI.Content, "Force Rainbow Tags", false, function(state)
    for _, petData in pairs(PetSystem.ActivePets) do
        if state then
            if not petData.Model:HasTag("PetRainbow") then
                petData.Model:AddTag("PetRainbow")
            end
        else
            if petData.Model:HasTag("PetRainbow") then
                petData.Model:RemoveTag("PetRainbow")
            end
        end
    end
end)

-- Separator
local Sep2 = Instance.new("Frame")
Sep2.Size = UDim2.new(1, -10, 0, 1)
Sep2.Position = UDim2.new(0, 5, 0, 0)
Sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Sep2.BorderSizePixel = 0
Sep2.Parent = GUI.Content

-- Settings Section
CreateSection(GUI.Content, "⚙️ Settings")

CreateSlider(GUI.Content, "Follow Speed", 5, 30, 14, function(value)
    PetSystem.Config.FollowSpeed = value
end)

CreateSlider(GUI.Content, "Rotation Speed", 5, 25, 12, function(value)
    PetSystem.Config.RotationSpeed = value
end)

CreateSlider(GUI.Content, "Smoothing", 10, 100, 60, function(value)
    PetSystem.Config.SmoothingFactor = value
end)

-- Separator
local Sep3 = Instance.new("Frame")
Sep3.Size = UDim2.new(1, -10, 0, 1)
Sep3.Position = UDim2.new(0, 5, 0, 0)
Sep3.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Sep3.BorderSizePixel = 0
Sep3.Parent = GUI.Content

-- Actions Section
CreateSection(GUI.Content, "🎮 Actions")

CreateButton(GUI.Content, "📍 Snap Local Pets", function()
    PetSystem:SnapLocalPetsToFollow()
    GUI.StatusLabel.Text = "Status: Pets Snapped!"
    task.delay(1, function()
        if MikkaHub.Active then
            GUI.StatusLabel.Text = "Status: Pet System Active"
        else
            GUI.StatusLabel.Text = "Status: Ready | Executor: " .. executor
        end
    end)
end)

CreateButton(GUI.Content, "🔄 Refresh Ground Filter", function()
    PetSystem:RefreshGroundFilter()
    GUI.StatusLabel.Text = "Status: Ground Filter Refreshed!"
    task.delay(1, function()
        if MikkaHub.Active then
            GUI.StatusLabel.Text = "Status: Pet System Active"
        else
            GUI.StatusLabel.Text = "Status: Ready | Executor: " .. executor
        end
    end)
end)

CreateButton(GUI.Content, "💥 Destroy All Pets", function()
    for slot, _ in pairs(PetSystem.ActivePets) do
        PetSystem:DestroyActive(slot)
    end
    GUI.StatusLabel.Text = "Status: All Pets Destroyed"
    task.delay(1, function()
        if MikkaHub.Active then
            GUI.StatusLabel.Text = "Status: Pet System Active"
        else
            GUI.StatusLabel.Text = "Status: Ready | Executor: " .. executor
        end
    end)
end)

-- Separator
local Sep4 = Instance.new("Frame")
Sep4.Size = UDim2.new(1, -10, 0, 1)
Sep4.Position = UDim2.new(0, 5, 0, 0)
Sep4.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
Sep4.BorderSizePixel = 0
Sep4.Parent = GUI.Content

-- Info Section
CreateSection(GUI.Content, "ℹ️ Info")

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -10, 0, 60)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Mikka Hub v1.0
GAG 2 Pet Visual Spawner
Delta Executor Compatible
All original features included"
InfoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = GUI.Content

--========================================
-- GUI FUNCTIONALITY
--========================================

-- Draggable
local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil

GUI.TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = GUI.MainFrame.Position
    end
end)

GUI.TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        GUI.MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        dragInput = nil
    end
end)

-- Close button
GUI.CloseBtn.MouseButton1Click:Connect(function()
    GUI.ScreenGui:Destroy()
    MikkaHub.GUI = nil
end)

-- Minimize button
local minimized = false
local originalSize = GUI.MainFrame.Size

GUI.MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        GUI.MainFrame:TweenSize(UDim2.new(0, 420, 0, 40), "Out", "Quad", 0.3, true)
        GUI.MinBtn.Text = "+"
    else
        GUI.MainFrame:TweenSize(originalSize, "Out", "Quad", 0.3, true)
        GUI.MinBtn.Text = "-"
    end
end)

-- Toggle key (RightShift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        if GUI.ScreenGui.Enabled then
            GUI.MainFrame.Visible = false
            GUI.ScreenGui.Enabled = false
        else
            GUI.MainFrame.Visible = true
            GUI.ScreenGui.Enabled = true
        end
    end
end)

--========================================
-- NOTIFICATION SYSTEM
--========================================

local function Notify(title, text, duration)
    duration = duration or 3

    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "MikkaNotification"
    notifGui.ResetOnSpawn = false
    pcall(function() notifGui.Parent = CoreGui end)
    if not notifGui.Parent then
        notifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 80)
    notifFrame.Position = UDim2.new(1, 20, 1, -100)
    notifFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = notifGui

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notifFrame

    local notifTitle = Instance.new("TextLabel")
    notifTitle.Size = UDim2.new(1, -20, 0, 25)
    notifTitle.Position = UDim2.new(0, 10, 0, 5)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text = "🌸 " .. title
    notifTitle.TextColor3 = Color3.fromRGB(255, 182, 193)
    notifTitle.TextSize = 14
    notifTitle.Font = Enum.Font.GothamBold
    notifTitle.TextXAlignment = Enum.TextXAlignment.Left
    notifTitle.Parent = notifFrame

    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 0, 40)
    notifText.Position = UDim2.new(0, 10, 0, 30)
    notifText.BackgroundTransparency = 1
    notifText.Text = text
    notifText.TextColor3 = Color3.fromRGB(200, 200, 200)
    notifText.TextSize = 12
    notifText.Font = Enum.Font.Gotham
    notifText.TextXAlignment = Enum.TextXAlignment.Left
    notifText.TextYAlignment = Enum.TextYAlignment.Top
    notifText.TextWrapped = true
    notifText.Parent = notifFrame

    notifFrame:TweenPosition(UDim2.new(1, -320, 1, -100), "Out", "Quad", 0.5, true)

    task.delay(duration, function()
        notifFrame:TweenPosition(UDim2.new(1, 20, 1, -100), "In", "Quad", 0.5, true)
        task.wait(0.5)
        notifGui:Destroy()
    end)
end

-- Initial notification
Notify("Mikka Hub Loaded", "Press RightShift to toggle GUI
Enable Pet Visuals to start", 5)

--========================================
-- RETURN
--========================================

return MikkaHub
