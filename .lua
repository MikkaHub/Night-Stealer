-- // ============================================================ \\ --
-- //              St3al at Night | Grow a Garden 2               \\ --
-- // ============================================================ \\ --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- // ========== NETWORKING ========== \\ --
local Net
do
    local sm = ReplicatedStorage:WaitForChild("SharedModules", 15)
    local mod = sm and sm:FindFirstChild("Networking")
    if mod then
        local ok, m = pcall(require, mod)
        if ok then Net = m end
    end
end

if not Net then
    warn("Networking module not found — are you in Grow a Garden 2?")
    return
end

local function fire(path, ...)
    local cur = Net
    for part in string.gmatch(path, "[^.]+") do
        if type(cur) ~= "table" then return nil end
        cur = cur[part]
    end
    if not (cur and cur.Fire) then return false, "no action: " .. path end
    local args = table.pack(...)
    local ok, res = pcall(function() return cur:Fire(table.unpack(args, 1, args.n)) end)
    if not ok then return false, res end
    return true, res
end

-- // ========== WORLD HELPERS (from original) ========== \\ --
local function myPlot()
    local id = LocalPlayer:GetAttribute("PlotId")
    local gardens = Workspace:FindFirstChild("Gardens")
    if not (id and gardens) then return nil end
    return gardens:FindFirstChild("Plot" .. tostring(id))
end

local function myBasePos()
    local plot = myPlot()
    if not plot then return nil end
    for _, tag in ipairs({ "GardenTotalArea", "GardenZone" }) do
        for _, p in ipairs(CollectionService:GetTagged(tag)) do
            if p:IsA("BasePart") and p:IsDescendantOf(plot) then
                return Vector3.new(p.Position.X, p.Position.Y - p.Size.Y / 2 + 5, p.Position.Z)
            end
        end
    end
    local sp = plot:FindFirstChild("SpawnPoint")
    if sp and sp:IsA("BasePart") then return sp.Position end
    local ok, piv = pcall(function() return plot:GetPivot().Position end)
    return ok and piv or nil
end

local function promptCarrier(prompt)
    local node = prompt.Parent
    while node and node ~= Workspace and node:GetAttribute("PlantId") == nil do
        node = node.Parent
    end
    if node and node:GetAttribute("PlantId") ~= nil then return node end
    return prompt:FindFirstAncestorWhichIsA("Model")
end

local function isNight()
    local n = ReplicatedStorage:FindFirstChild("Night")
    return n and n.Value == true
end

-- ========== OWNER IN GARDEN CHECK ========== --
local function isOwnerInGarden(ownerUserId)
    if not ownerUserId or ownerUserId == 0 then return false end
    local gardens = Workspace:FindFirstChild("Gardens")
    if not gardens then return false end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == ownerUserId then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return false end
            
            for _, tag in ipairs({ "GardenTotalArea", "GardenZone" }) do
                for _, p in ipairs(CollectionService:GetTagged(tag)) do
                    if p:IsA("BasePart") then
                        for _, plot in ipairs(gardens:GetChildren()) do
                            if plot.Name:sub(1, 4) == "Plot" and p:IsDescendantOf(plot) then
                                local plotId = tonumber(plot.Name:sub(5))
                                if plotId and plr:GetAttribute("PlotId") == plotId then
                                    local pos = hrp.Position
                                    local min = p.Position - p.Size / 2
                                    local max = p.Position + p.Size / 2
                                    if pos.X >= min.X and pos.X <= max.X and
                                       pos.Y >= min.Y and pos.Y <= max.Y and
                                       pos.Z >= min.Z and pos.Z <= max.Z then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return false
        end
    end
    return false
end

-- ========================================== --

-- // ========== STEALABLE (original + owner check) ========== \\ --
local function stealable()
    local out = {}
    for _, pr in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            local pid = m and m:GetAttribute("PlantId")
            if pid then
                local owner = tonumber(m:GetAttribute("UserId")) or 0
                
                -- Skip if owner is IN their garden
                if owner ~= 0 and isOwnerInGarden(owner) then
                    continue
                end
                
                local pos
                local pp = pr.Parent
                if pp and pp:IsA("BasePart") then
                    pos = pp.Position
                elseif m then
                    local ok, pv = pcall(function() return m:GetPivot().Position end)
                    if ok then pos = pv end
                end
                out[#out + 1] = {
                    owner = owner,
                    plantId = tostring(pid),
                    fruitId = tostring(m:GetAttribute("FruitId") or ""),
                    pos = pos,
                }
            end
        end
    end
    return out
end

local function hrpNow()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- // ========== BEAUTIFUL PLAYER ESP ========== \\ --
local PlayerESPFolder = Instance.new("Folder")
PlayerESPFolder.Name = "PlayerESP"
PlayerESPFolder.Parent = Workspace

local PlayerESPObjects = {}

local function createPlayerESP(player)
    if player == LocalPlayer then return end
    if PlayerESPObjects[player.UserId] then return end
    
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Main Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlayerESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 220, 0, 70)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = hrp
    billboard.Parent = PlayerESPFolder
    
    -- Background frame with rounded corners
    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bg.BackgroundTransparency = 0.15
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10)
    bgCorner.Parent = bg
    
    -- Top accent bar
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.Position = UDim2.new(0, 0, 0, 0)
    accent.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    accent.BorderSizePixel = 0
    accent.Parent = bg
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 10)
    accentCorner.Parent = accent
    
    -- Player name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -10, 0, 22)
    nameLabel.Position = UDim2.new(0, 5, 0, 6)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextSize = 15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = bg
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -10, 0, 16)
    statusLabel.Position = UDim2.new(0, 5, 0, 28)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = bg
    
    -- Sub status (distance/fruit info)
    local subLabel = Instance.new("TextLabel")
    subLabel.Name = "Sub"
    subLabel.Size = UDim2.new(1, -10, 0, 14)
    subLabel.Position = UDim2.new(0, 5, 0, 44)
    subLabel.BackgroundTransparency = 1
    subLabel.TextSize = 10
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.Parent = bg
    
    -- Glow effect behind player
    local glow = Instance.new("PointLight")
    glow.Name = "ESPGlow"
    glow.Brightness = 2
    glow.Range = 8
    glow.Color = Color3.fromRGB(255, 255, 255)
    glow.Parent = hrp
    
    -- Tracer line (beam from bottom of screen)
    local tracer = Instance.new("Beam")
    tracer.Name = "Tracer"
    tracer.Width0 = 0.08
    tracer.Width1 = 0.08
    tracer.FaceCamera = true
    tracer.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    tracer.Transparency = NumberSequence.new(0.3)
    tracer.Parent = hrp
    
    local attachment0 = Instance.new("Attachment")
    attachment0.Name = "TracerStart"
    attachment0.Position = Vector3.new(0, -2, 0)
    attachment0.Parent = hrp
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Name = "TracerEnd"
    attachment1.Position = Vector3.new(0, 0, 0)
    attachment1.Parent = hrp
    
    tracer.Attachment0 = attachment0
    tracer.Attachment1 = attachment1
    
    -- 3D Box around player (using 4 corner beams for clean look)
    local boxFolder = Instance.new("Folder")
    boxFolder.Name = "Box"
    boxFolder.Parent = hrp
    
    local function createBeam(p0, p1, color)
        local beam = Instance.new("Beam")
        beam.Width0 = 0.05
        beam.Width1 = 0.05
        beam.Color = ColorSequence.new(color)
        beam.Transparency = NumberSequence.new(0.15)
        beam.FaceCamera = true
        
        local a0 = Instance.new("Attachment")
        a0.Position = p0
        a0.Parent = hrp
        local a1 = Instance.new("Attachment")
        a1.Position = p1
        a1.Parent = hrp
        
        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.Parent = boxFolder
        return beam
    end
    
    local boxColor = Color3.fromRGB(255, 255, 255)
    local s = Vector3.new(2, 4.5, 2)
    
    -- Box edges
    createBeam(Vector3.new(-s.X, -s.Y, -s.Z), Vector3.new(s.X, -s.Y, -s.Z), boxColor)
    createBeam(Vector3.new(s.X, -s.Y, -s.Z), Vector3.new(s.X, -s.Y, s.Z), boxColor)
    createBeam(Vector3.new(s.X, -s.Y, s.Z), Vector3.new(-s.X, -s.Y, s.Z), boxColor)
    createBeam(Vector3.new(-s.X, -s.Y, s.Z), Vector3.new(-s.X, -s.Y, -s.Z), boxColor)
    
    createBeam(Vector3.new(-s.X, s.Y, -s.Z), Vector3.new(s.X, s.Y, -s.Z), boxColor)
    createBeam(Vector3.new(s.X, s.Y, -s.Z), Vector3.new(s.X, s.Y, s.Z), boxColor)
    createBeam(Vector3.new(s.X, s.Y, s.Z), Vector3.new(-s.X, s.Y, s.Z), boxColor)
    createBeam(Vector3.new(-s.X, s.Y, s.Z), Vector3.new(-s.X, s.Y, -s.Z), boxColor)
    
    createBeam(Vector3.new(-s.X, -s.Y, -s.Z), Vector3.new(-s.X, s.Y, -s.Z), boxColor)
    createBeam(Vector3.new(s.X, -s.Y, -s.Z), Vector3.new(s.X, s.Y, -s.Z), boxColor)
    createBeam(Vector3.new(s.X, -s.Y, s.Z), Vector3.new(s.X, s.Y, s.Z), boxColor)
    createBeam(Vector3.new(-s.X, -s.Y, s.Z), Vector3.new(-s.X, s.Y, s.Z), boxColor)
    
    PlayerESPObjects[player.UserId] = {
        billboard = billboard,
        bg = bg,
        accent = accent,
        nameLabel = nameLabel,
        statusLabel = statusLabel,
        subLabel = subLabel,
        glow = glow,
        tracer = tracer,
        boxFolder = boxFolder,
        player = player,
    }
end

local function updatePlayerESP()
    for userId, esp in pairs(PlayerESPObjects) do
        local player = esp.player
        if not player or not player.Parent then
            pcall(function() esp.billboard:Destroy() end)
            pcall(function() esp.glow:Destroy() end)
            pcall(function() esp.tracer:Destroy() end)
            pcall(function() esp.boxFolder:Destroy() end)
            PlayerESPObjects[userId] = nil
            continue
        end
        
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then
            pcall(function() esp.billboard:Destroy() end)
            pcall(function() esp.glow:Destroy() end)
            pcall(function() esp.tracer:Destroy() end)
            pcall(function() esp.boxFolder:Destroy() end)
            PlayerESPObjects[userId] = nil
            continue
        end
        
        if esp.billboard.Adornee ~= hrp then
            esp.billboard.Adornee = hrp
        end
        
        local inGarden = isOwnerInGarden(player.UserId)
        local hasFruit = false
        
        for _, pr in ipairs(CollectionService:GetTagged("StealPrompt")) do
            if pr:IsA("ProximityPrompt") and pr.Enabled then
                local m = promptCarrier(pr)
                if m and tonumber(m:GetAttribute("UserId")) == player.UserId then
                    hasFruit = true
                    break
                end
            end
        end
        
        -- Calculate distance
        local myHrp = hrpNow()
        local distance = myHrp and math.floor((myHrp.Position - hrp.Position).Magnitude) or 0
        
        if inGarden then
            -- RED - Owner in garden, SKIP
            local color = Color3.fromRGB(255, 70, 70)
            esp.accent.BackgroundColor3 = color
            esp.nameLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
            esp.statusLabel.Text = "🔒 IN GARDEN"
            esp.statusLabel.TextColor3 = color
            esp.subLabel.Text = distance .. " studs away • SKIP"
            esp.glow.Color = color
            esp.glow.Brightness = 1
            
            for _, child in ipairs(esp.boxFolder:GetChildren()) do
                if child:IsA("Beam") then
                    child.Color = ColorSequence.new(color)
                end
            end
            esp.tracer.Color = ColorSequence.new(color)
            
        else
            if hasFruit then
                -- GREEN - AFK + has fruit, STEAL!
                local color = Color3.fromRGB(80, 255, 120)
                esp.accent.BackgroundColor3 = color
                esp.nameLabel.TextColor3 = Color3.fromRGB(200, 255, 210)
                esp.statusLabel.Text = "✅ AFK • READY TO STEAL"
                esp.statusLabel.TextColor3 = color
                esp.subLabel.Text = distance .. " studs away • " .. (isNight() and "🌙 NIGHT" or "☀️ DAY")
                esp.glow.Color = color
                esp.glow.Brightness = 3
                
                for _, child in ipairs(esp.boxFolder:GetChildren()) do
                    if child:IsA("Beam") then
                        child.Color = ColorSequence.new(color)
                    end
                end
                esp.tracer.Color = ColorSequence.new(color)
                
            else
                -- GRAY - AFK but no fruit
                local color = Color3.fromRGB(150, 150, 160)
                esp.accent.BackgroundColor3 = color
                esp.nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
                esp.statusLabel.Text = "💤 AFK • No fruit"
                esp.statusLabel.TextColor3 = color
                esp.subLabel.Text = distance .. " studs away"
                esp.glow.Color = color
                esp.glow.Brightness = 1
                
                for _, child in ipairs(esp.boxFolder:GetChildren()) do
                    if child:IsA("Beam") then
                        child.Color = ColorSequence.new(color)
                    end
                end
                esp.tracer.Color = ColorSequence.new(color)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        createPlayerESP(player)
    end)
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then
        createPlayerESP(plr)
    end
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        createPlayerESP(plr)
    end)
end

RunService.RenderStepped:Connect(function()
    if Settings.playerESP then
        updatePlayerESP()
    end
end)

-- // ========== GUI ========== \\ --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "St3alGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 280, 0, 240)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.BorderSizePixel = 0
Title.Text = "🌙 St3al at Night"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local function makeToggle(name, y, default)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 240, 0, 34)
    btn.Position = UDim2.new(0.5, -120, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(60, 60, 70)
    btn.BorderSizePixel = 0
    btn.Text = (default and "✅ " or "❌ ") .. name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = MainFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    return btn
end

local StealToggle = makeToggle("Auto-Steal", 50, false)
local TPToggle = makeToggle("Teleport to Fruit", 92, true)
local ReturnToggle = makeToggle("Return to Base", 134, true)
local ESPToggle = makeToggle("Player ESP", 176, true)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, -20, 0, 24)
StatusLabel.Position = UDim2.new(0, 10, 0, 216)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

local StolenLabel = Instance.new("TextLabel")
StolenLabel.Name = "Stolen"
StolenLabel.Size = UDim2.new(1, -20, 0, 20)
StolenLabel.Position = UDim2.new(0, 10, 0, 238)
StolenLabel.BackgroundTransparency = 1
StolenLabel.Text = "Stolen: 0"
StolenLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
StolenLabel.TextSize = 12
StolenLabel.Font = Enum.Font.GothamBold
StolenLabel.TextXAlignment = Enum.TextXAlignment.Center
StolenLabel.Parent = MainFrame

-- // ========== STATE ========== \\ --
local Settings = {
    autoSteal = false,
    stealTeleport = true,
    stealReturnBase = true,
    playerESP = true,
    stealDelay = 0.05,
}

local Stats = { stolen = 0 }

-- // ========== TOGGLE LOGIC ========== \\ --
local function updateToggle(btn, state)
    Settings[btn.Name:gsub("-", ""):lower()] = state
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(60, 60, 70)
    btn.Text = (state and "✅ " or "❌ ") .. btn.Name
end

StealToggle.MouseButton1Click:Connect(function()
    Settings.autoSteal = not Settings.autoSteal
    updateToggle(StealToggle, Settings.autoSteal)
end)

TPToggle.MouseButton1Click:Connect(function()
    Settings.stealTeleport = not Settings.stealTeleport
    updateToggle(TPToggle, Settings.stealTeleport)
end)

ReturnToggle.MouseButton1Click:Connect(function()
    Settings.stealReturnBase = not Settings.stealReturnBase
    updateToggle(ReturnToggle, Settings.stealReturnBase)
end)

ESPToggle.MouseButton1Click:Connect(function()
    Settings.playerESP = not Settings.playerESP
    updateToggle(ESPToggle, Settings.playerESP)
    PlayerESPFolder.Enabled = Settings.playerESP
    if not Settings.playerESP then
        for _, esp in pairs(PlayerESPObjects) do
            pcall(function() esp.billboard:Destroy() end)
            pcall(function() esp.glow:Destroy() end)
            pcall(function() esp.tracer:Destroy() end)
            pcall(function() esp.boxFolder:Destroy() end)
        end
        table.clear(PlayerESPObjects)
    end
end)

-- // ========== MAIN LOOP (exact original logic) ========== \\ --
task.spawn(function()
    while true do
        if Settings.autoSteal then
            if not isNight() then
                StatusLabel.Text = "☀️ Daytime — waiting..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                task.wait(2)
                continue
            end
            
            local targets = stealable()
            if #targets == 0 then
                StatusLabel.Text = "🔍 No targets"
                StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                task.wait(1.5)
                continue
            end
            
            StatusLabel.Text = "🌙 Stealing..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            for _, f in ipairs(targets) do
                if not (Settings.autoSteal and isNight()) then break end
                
                -- 1) Teleport to fruit (proximity is server-gated)
                if Settings.stealTeleport and f.pos then
                    local hrp = hrpNow()
                    if hrp then
                        hrp.CFrame = CFrame.new(f.pos + Vector3.new(0, 4, 0))
                        task.wait(0.4)
                    end
                end
                
                -- 2) Steal (original: fire + fire back-to-back)
                fire("Steal.BeginSteal", f.owner, f.plantId, f.fruitId)
                fire("Steal.CompleteSteal")
                Stats.stolen += 1
                StolenLabel.Text = "Stolen: " .. Stats.stolen
                
                -- 3) Return to base to bank
                if Settings.stealReturnBase then
                    local base = myBasePos()
                    local hrp = hrpNow()
                    if base and hrp then
                        hrp.CFrame = CFrame.new(base + Vector3.new(0, 4, 0))
                        local t0 = os.clock()
                        while LocalPlayer:GetAttribute("CarryingStolenFruit") 
                            and os.clock() - t0 < 3 
                            and Settings.autoSteal do
                            task.wait(0.15)
                        end
                    end
                end
                
                if (Settings.stealDelay or 0) > 0 then
                    task.wait(Settings.stealDelay)
                end
            end
        else
            StatusLabel.Text = "⏸️ Auto-Steal disabled"
            StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            task.wait(0.5)
        end
    end
end)

-- // ========== CLEANUP ========== \\ --
local function unload()
    Settings.autoSteal = false
    PlayerESPFolder:Destroy()
    ScreenGui:Destroy()
end

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(unload)

print("🌙 St3al at Night loaded | Beautiful Player ESP | Skip owner-in-garden")
