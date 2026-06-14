-- // ============================================================ \\ --
-- //              St3al at Night | Grow a Garden 2               \\ --
-- // ============================================================ \\ --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
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

-- // ========== WORLD HELPERS ========== \\ --
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
    
    local player = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.UserId == ownerUserId then
            player = plr
            break
        end
    end
    if not player then return false end
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local plotId = player:GetAttribute("PlotId")
    if not plotId then return false end
    
    local gardens = Workspace:FindFirstChild("Gardens")
    if not gardens then return false end
    local plot = gardens:FindFirstChild("Plot" .. tostring(plotId))
    if not plot then return false end
    
    for _, tag in ipairs({ "GardenTotalArea", "GardenZone" }) do
        for _, zone in ipairs(CollectionService:GetTagged(tag)) do
            if zone:IsA("BasePart") and zone:IsDescendantOf(plot) then
                local pos = hrp.Position
                local zp = zone.Position
                local hs = zone.Size / 2
                if pos.X >= zp.X - hs.X and pos.X <= zp.X + hs.X and
                   pos.Y >= zp.Y - hs.Y and pos.Y <= zp.Y + hs.Y and
                   pos.Z >= zp.Z - hs.Z and pos.Z <= zp.Z + hs.Z then
                    return true
                end
            end
        end
    end
    return false
end

-- ========== GET PLANT NAME FROM MODEL ========== --
local function getPlantName(model)
    if not model then return "Unknown" end
    -- Try common attribute names for plant type
    local name = model:GetAttribute("PlantName") 
        or model:GetAttribute("SeedName") 
        or model:GetAttribute("Type")
        or model:GetAttribute("Name")
        or model.Name
    return tostring(name)
end

-- ========== BLACKLIST ========== --
local BLACKLIST = {
    ["Bamboo"] = true,
    ["Carrot"] = true,
    -- Add more here: ["PlantName"] = true
}

-- ========== GET FRUIT VOLUME ========== --
local function getFruitVolume(model)
    if not model then return 0 end
    local size = model:GetExtentsSize()
    return math.floor(size.X * size.Y * size.Z)
end

local HIGH_VOLUME = 750

-- ========================================== --

-- // ========== STEALABLE ========== \\ --
local function stealable(onlyHighValue)
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
                
                -- Skip blacklisted plants
                local plantName = getPlantName(m)
                if BLACKLIST[plantName] then
                    continue
                end
                
                local volume = getFruitVolume(m)
                if onlyHighValue and volume < HIGH_VOLUME then
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
                    volume = volume,
                    plantName = plantName,
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

-- // ========== HIGH VOLUME FRUIT ESP (>750) ========== \\ --
local FruitESPFolder = Instance.new("Folder")
FruitESPFolder.Name = "HighFruitESP"
FruitESPFolder.Parent = Workspace

local FruitESPObjects = {}

local function createFruitESP(model)
    if not model or not model.Parent then return end
    if FruitESPObjects[model] then return end
    
    local volume = getFruitVolume(model)
    if volume < HIGH_VOLUME then return end
    
    local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then
        for _, child in ipairs(model:GetDescendants()) do
            if child:IsA("BasePart") then adornee = child; break end
        end
    end
    if not adornee then return end
    
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "HighFruitBox"
    box.Size = adornee.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Transparency = 0.2
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Adornee = adornee
    box.Parent = FruitESPFolder
    
    if volume > 1500 then box.Color3 = Color3.fromRGB(255, 215, 0)
    elseif volume > 1000 then box.Color3 = Color3.fromRGB(255, 100, 100)
    else box.Color3 = Color3.fromRGB(100, 255, 100) end
    
    FruitESPObjects[model] = { box = box, model = model }
end

local function scanFruitESP()
    for model, esp in pairs(FruitESPObjects) do
        if not model or not model.Parent then
            pcall(function() esp.box:Destroy() end)
            FruitESPObjects[model] = nil
        end
    end
    
    for _, pr in ipairs(CollectionService:GetTagged("StealPrompt")) do
        if pr:IsA("ProximityPrompt") and pr.Enabled and pr:IsDescendantOf(Workspace) then
            local m = promptCarrier(pr)
            if m then createFruitESP(m) end
        end
    end
end

-- // ========== GUI ========== \\ --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "St3alGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 280, 0, 280)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 36)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.BorderSizePixel = 0
Title.Text = "🌙 St3al at Night"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local StealToggle = makeToggle("Auto-Steal", 50, false)
local HighValueToggle = makeToggle("Steal High Value Only (>750)", 92, true)
local TPToggle = makeToggle("Teleport to Fruit", 134, true)
local ReturnToggle = makeToggle("Return to Base", 176, true)
local ESPToggle = makeToggle("High Volume ESP", 218, true)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 24)
StatusLabel.Position = UDim2.new(0, 10, 0, 256)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

local StolenLabel = Instance.new("TextLabel")
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
local S = {
    autoSteal = false,
    stealHighValue = true,
    stealTeleport = true,
    stealReturnBase = true,
    espEnabled = true,
    stealDelay = 0.05,
}

local Stats = { stolen = 0 }

-- // ========== TOGGLE LOGIC ========== \\ --
local function updateToggle(btn, state)
    local key = btn.Name:gsub("[^a-zA-Z]", ""):lower()
    S[key] = state
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(60, 60, 70)
    btn.Text = (state and "✅ " or "❌ ") .. btn.Name
end

StealToggle.MouseButton1Click:Connect(function()
    S.autoSteal = not S.autoSteal
    updateToggle(StealToggle, S.autoSteal)
end)

HighValueToggle.MouseButton1Click:Connect(function()
    S.stealHighValue = not S.stealHighValue
    updateToggle(HighValueToggle, S.stealHighValue)
end)

TPToggle.MouseButton1Click:Connect(function()
    S.stealTeleport = not S.stealTeleport
    updateToggle(TPToggle, S.stealTeleport)
end)

ReturnToggle.MouseButton1Click:Connect(function()
    S.stealReturnBase = not S.stealReturnBase
    updateToggle(ReturnToggle, S.stealReturnBase)
end)

ESPToggle.MouseButton1Click:Connect(function()
    S.espEnabled = not S.espEnabled
    updateToggle(ESPToggle, S.espEnabled)
    FruitESPFolder.Enabled = S.espEnabled
    if not S.espEnabled then
        for _, esp in pairs(FruitESPObjects) do
            pcall(function() esp.box:Destroy() end)
        end
        table.clear(FruitESPObjects)
    end
end)

-- // ========== ESP UPDATE LOOP ========== \\ --
task.spawn(function()
    while true do
        if S.espEnabled then scanFruitESP() end
        task.wait(2)
    end
end)

-- // ========== MAIN STEAL LOOP (EXACT ORIGINAL LOGIC) ========== \\ --
task.spawn(function()
    while true do
        if S.autoSteal then
            if not isNight() then
                StatusLabel.Text = "☀️ Daytime — waiting..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
                task.wait(2)
                continue
            end
            
            local targets = stealable(S.stealHighValue)
            if #targets == 0 then
                StatusLabel.Text = "🔍 No " .. (S.stealHighValue and "high value " or "") .. "targets"
                StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                task.wait(1.5)
                continue
            end
            
            StatusLabel.Text = "🌙 Stealing " .. #targets .. " fruit(s)..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            for _, f in ipairs(targets) do
                if not (S.autoSteal and isNight()) then break end
                
                -- Re-check owner before each steal
                if f.owner ~= 0 and isOwnerInGarden(f.owner) then
                    StatusLabel.Text = "⏭️ Owner returned — skipping"
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
                    task.wait(0.3)
                    continue
                end
                
                -- 1) Teleport to fruit (proximity is server-gated)
                if S.stealTeleport and f.pos then
                    local hrp = hrpNow()
                    if hrp then
                        hrp.CFrame = CFrame.new(f.pos + Vector3.new(0, 4, 0))
                        task.wait(0.4)
                    end
                end
                
                -- 2) Steal: Begin + Complete back-to-back (original)
                fire("Steal.BeginSteal", f.owner, f.plantId, f.fruitId)
                fire("Steal.CompleteSteal")
                Stats.stolen += 1
                StolenLabel.Text = "Stolen: " .. Stats.stolen .. (f.plantName and " (" .. f.plantName .. ")" or "")
                
                -- 3) Carry it home: standing in own garden zone banks it
                if S.stealReturnBase then
                    local base = myBasePos()
                    local hrp = hrpNow()
                    if base and hrp then
                        hrp.CFrame = CFrame.new(base + Vector3.new(0, 4, 0))
                        local t0 = os.clock()
                        while LocalPlayer:GetAttribute("CarryingStolenFruit") 
                            and os.clock() - t0 < 3 
                            and S.autoSteal do
                            task.wait(0.15)
                        end
                    end
                end
                
                if (S.stealDelay or 0) > 0 then
                    task.wait(S.stealDelay)
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
    S.autoSteal = false
    FruitESPFolder:Destroy()
    ScreenGui:Destroy()
end

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -32, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.BorderSizePixel = 0
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 20
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(unload)

print("🌙 St3al at Night loaded | Blacklist: Bamboo, Carrot | Owner check | High Vol ESP >750")
