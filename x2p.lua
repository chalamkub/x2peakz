-- ==========================================================
-- Services
-- ==========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

-- ==========================================================
-- Variables
-- ==========================================================
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ระบบป้องกัน UI ซ้อนกันเมื่อรันสคริปต์ซ้ำ (Anti-Duplicate / Clean Old Instance)
if _G.BloxFruitsHubInstance then
    pcall(function()
        _G.BloxFruitsHubInstance:Destroy()
    end)
    _G.BloxFruitsHubInstance = nil
end

local HubState = {
    Running = true,
    Connections = {},
    Visuals = {
        PlayerESP = false,
        NpcESP = false,
        PoiESP = false,
        Containers = {}
    },
    PlayerMods = {
        WalkSpeed = 16,
        JumpPower = 50,
        ApplySpeed = false,
        ApplyJump = false
    }
}
_G.BloxFruitsHubInstance = HubState

-- พิกัด Teleport สำหรับโปรเจกต์ Blox Fruits / Universal Hub
local Locations = {
    ["Spawn"] = CFrame.new(0, 50, 0),
    ["Island 1 (Starter Island)"] = CFrame.new(1050, 45, 1200),
    ["Island 2 (Pirate Village)"] = CFrame.new(-1200, 50, 1800),
    ["Island 3 (Desert Area)"] = CFrame.new(2400, 60, -950),
    ["Boss Area"] = CFrame.new(3500, 120, 3100),
    ["Shop / Merchant"] = CFrame.new(-450, 30, -780),
    ["Safe Zone"] = CFrame.new(50, 100, 50)
}

-- จุดสำคัญสำหรับระบบ Visual POI Debug
local PointsOfInterest = {
    ["Fruit Dealer"] = Vector3.new(-450, 30, -780),
    ["Quest Giver"] = Vector3.new(100, 20, 150),
    ["Boss Spawn"] = Vector3.new(3500, 120, 3100),
    ["Safe Zone Center"] = Vector3.new(50, 100, 50)
}

-- ==========================================================
-- Fluent Library
-- ==========================================================
local FluentSuccess, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)

if not FluentSuccess or not Fluent then
    warn("[Blox Fruits Hub Error] ไม่สามารถดาวน์โหลด Fluent Library ได้")
    return
end

local SaveManagerSuccess, SaveManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)

local InterfaceManagerSuccess, InterfaceManager = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

-- ==========================================================
-- Window
-- ==========================================================
local Window = Fluent:CreateWindow({
    Title = "Blox Fruits Hub",
    SubTitle = "Universal Roblox Hub",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ==========================================================
-- Tabs
-- ==========================================================
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = Window:AddTab({ Title = "Credits", Icon = "info" })
}

local Options = Fluent.Options

-- ==========================================================
-- Main Functions
-- ==========================================================

-- ตรวจสอบและดึงข้อมูล Character & Humanoid
local function GetCharacterParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, rootPart
end

-- ฟังก์ชันวาร์ป CFrame อย่างปลอดภัย
local function SafeTeleport(targetCFrame, destinationName)
    local _, humanoid, rootPart = GetCharacterParts()
    if not humanoid or not rootPart then
        Fluent:Notify({
            Title = "Teleport Error",
            Content = "ไม่พบตัวละครหรือ HumanoidRootPart",
            Duration = 3
        })
        return false
    end

    if humanoid.Health <= 0 then
        Fluent:Notify({
            Title = "Teleport Error",
            Content = "ตัวละครหมดสติ (Dead) ไม่สามารถวาร์ปได้",
            Duration = 3
        })
        return false
    end

    local success, err = pcall(function()
        rootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end)

    if success then
        Fluent:Notify({
            Title = "Teleport Success",
            Content = "วาร์ปไปยัง " .. (destinationName or "พิกัดเป้าหมาย") .. " สำเร็จ!",
            Duration = 3
        })
        return true
    else
        Fluent:Notify({
            Title = "Teleport Failed",
            Content = "เกิดข้อผิดพลาด: " .. tostring(err),
            Duration = 4
        })
        return false
    end
end

-- ฟังก์ชัน Rejoin เซิร์ฟเวอร์เดิม
local function RejoinServer()
    Fluent:Notify({
        Title = "Rejoining",
        Content = "กำลังเชื่อมต่อเซิร์ฟเวอร์ใหม่...",
        Duration = 3
    })
    task.wait(0.5)
    local success, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    if not success then
        Fluent:Notify({
            Title = "Rejoin Error",
            Content = "ไม่สามารถ Rejoin ได้: " .. tostring(err),
            Duration = 4
        })
    end
end

-- ฟังก์ชัน Server Hop (สุ่มย้ายเซิร์ฟเวอร์)
local function ServerHop()
    Fluent:Notify({
        Title = "Server Hop",
        Content = "กำลังค้นหาเซิร์ฟเวอร์ที่มีผู้เล่นว่าง...",
        Duration = 4
    })
    task.spawn(function()
        local placeId = game.PlaceId
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(placeId))
        
        local fetchSuccess, response = pcall(function()
            return game:HttpGet(url)
        end)
        
        if not fetchSuccess or not response then
            Fluent:Notify({
                Title = "Server Hop Error",
                Content = "ไม่สามารถดึงข้อมูลเซิร์ฟเวอร์ได้",
                Duration = 4
            })
            return
        end

        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)

        if not decodeSuccess or not data or not data.data then
            Fluent:Notify({
                Title = "Server Hop Error",
                Content = "ข้อมูลเซิร์ฟเวอร์ไม่ถูกต้อง",
                Duration = 4
            })
            return
        end

        local targetServer = nil
        for _, server in ipairs(data.data) do
            if type(server) == "table" and server.id ~= game.JobId and server.playing and server.maxPlayers then
                if server.playing < server.maxPlayers and server.playing > 0 then
                    targetServer = server.id
                    break
                end
            end
        end

        if targetServer then
            TeleportService:TeleportToPlaceInstance(placeId, targetServer, LocalPlayer)
        else
            Fluent:Notify({
                Title = "Server Hop",
                Content = "ไม่พบเซิร์ฟเวอร์อื่นที่เหมาะสม",
                Duration = 4
            })
        end
    end)
end

-- ดึงข้อมูล Level ของผู้เล่น
local function GetPlayerLevel()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local lvl = leaderstats:FindFirstChild("Level") or leaderstats:FindFirstChild("Lvl")
        if lvl then return tostring(lvl.Value) end
    end
    local data = LocalPlayer:FindFirstChild("Data")
    if data then
        local lvl = data:FindFirstChild("Level")
        if lvl then return tostring(lvl.Value) end
    end
    return "N/A (Custom Game)"
end

-- ฟังก์ชันสร้าง Highlight
local function CreateHighlight(adornee, color, fillTrans)
    if not adornee or not adornee:IsA("Model") then return nil end
    local highlight = Instance.new("Highlight")
    highlight.Name = "BF_Highlight"
    highlight.Adornee = adornee
    highlight.FillColor = color or Color3.fromRGB(0, 255, 170)
    highlight.FillTransparency = fillTrans or 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0.2
    highlight.Parent = adornee
    return highlight
end

-- ฟังก์ชันสร้าง BillboardGui
local function CreateBillboard(adorneePart, textContent, textColor)
    if not adorneePart or not adorneePart:IsA("BasePart") then return nil end
    local bbg = Instance.new("BillboardGui")
    bbg.Name = "BF_Billboard"
    bbg.Adornee = adorneePart
    bbg.Size = UDim2.new(0, 160, 0, 40)
    bbg.StudsOffset = Vector3.new(0, 2.5, 0)
    bbg.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = textContent
    label.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0.3
    label.TextSize = 13
    label.Font = Enum.Font.GothamBold
    label.Parent = bbg

    bbg.Parent = adorneePart
    return bbg, label
end

-- ฟังก์ชันล้าง Visuals
local function ClearVisualElement(key)
    if HubState.Visuals.Containers[key] then
        for _, obj in pairs(HubState.Visuals.Containers[key]) do
            if typeof(obj) == "Instance" then
                pcall(function() obj:Destroy() end)
            end
        end
        HubState.Visuals.Containers[key] = nil
    end
end

local function ClearAllVisuals()
    for key, _ in pairs(HubState.Visuals.Containers) do
        ClearVisualElement(key)
    end
    HubState.Visuals.Containers = {}
end

-- ==========================================================
-- Main Tab
-- ==========================================================
Tabs.Main:AddParagraph({
    Title = "Welcome to Blox Fruits Hub",
    Content = "สคริปต์ Universal Hub สำหรับการควบคุม ทดสอบระบบ และพัฒนาเกม"
})

local StatusParagraph = Tabs.Main:AddParagraph({
    Title = "Player & Character Status",
    Content = "กำลังโหลดข้อมูลสถานะ..."
})

-- Heartbeat Loop: อัปเดตข้อมูลตัวละครแบบ Real-time
local StatusConnection = RunService.Heartbeat:Connect(function()
    if not HubState.Running then return end
    
    local _, humanoid, rootPart = GetCharacterParts()
    local level = GetPlayerLevel()
    local hp = humanoid and math.floor(humanoid.Health) or 0
    local maxHp = humanoid and math.floor(humanoid.MaxHealth) or 0
    local speed = humanoid and math.floor(humanoid.WalkSpeed) or 0
    local jump = humanoid and math.floor(humanoid.JumpPower) or 0
    local pos = rootPart and string.format("X: %.1f | Y: %.1f | Z: %.1f", rootPart.Position.X, rootPart.Position.Y, rootPart.Position.Z) or "N/A"

    local contentString = string.format(
        "• Player: %s\n• Level: %s\n• Health: %d / %d\n• WalkSpeed: %d\n• JumpPower: %d\n• Position: %s",
        LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")",
        level,
        hp,
        maxHp,
        speed,
        jump,
        pos
    )

    StatusParagraph:SetDesc(contentString)
end)
table.insert(HubState.Connections, StatusConnection)

-- ==========================================================
-- Player Tab
-- ==========================================================
Tabs.Player:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Description = "ปรับระดับความเร็วการเดินของตัวละคร",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        HubState.PlayerMods.WalkSpeed = Value
        local _, humanoid = GetCharacterParts()
        if humanoid and HubState.PlayerMods.ApplySpeed then
            humanoid.WalkSpeed = Value
        end
    end
})

Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Enable Custom WalkSpeed",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.ApplySpeed = Value
        local _, humanoid = GetCharacterParts()
        if humanoid then
            humanoid.WalkSpeed = Value and HubState.PlayerMods.WalkSpeed or 16
        end
        Fluent:Notify({
            Title = "Player Setting",
            Content = "WalkSpeed Override: " .. (Value and "เปิดใช้งาน" or "ปิดใช้งาน"),
            Duration = 2
        })
    end
})

Tabs.Player:AddSlider("JumpPowerSlider", {
    Title = "JumpPower",
    Description = "ปรับระดับแรงกระโดดของตัวละคร",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        HubState.PlayerMods.JumpPower = Value
        local _, humanoid = GetCharacterParts()
        if humanoid and HubState.PlayerMods.ApplyJump then
            humanoid.JumpPower = Value
        end
    end
})

Tabs.Player:AddToggle("JumpToggle", {
    Title = "Enable Custom JumpPower",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.ApplyJump = Value
        local _, humanoid = GetCharacterParts()
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Value and HubState.PlayerMods.JumpPower or 50
        end
        Fluent:Notify({
            Title = "Player Setting",
            Content = "JumpPower Override: " .. (Value and "เปิดใช้งาน" or "ปิดใช้งาน"),
            Duration = 2
        })
    end
})

-- รักษาระดับ Speed & Jump แม้ตัวละครเปลี่ยนหรือรีเซ็ต
local ModifiersConnection = RunService.Stepped:Connect(function()
    if not HubState.Running then return end
    local _, humanoid = GetCharacterParts()
    if humanoid then
        if HubState.PlayerMods.ApplySpeed and humanoid.WalkSpeed ~= HubState.PlayerMods.WalkSpeed then
            humanoid.WalkSpeed = HubState.PlayerMods.WalkSpeed
        end
        if HubState.PlayerMods.ApplyJump and humanoid.JumpPower ~= HubState.PlayerMods.JumpPower then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = HubState.PlayerMods.JumpPower
        end
    end
end)
table.insert(HubState.Connections, ModifiersConnection)

Tabs.Player:AddButton({
    Title = "Reset Character",
    Description = "สั่งให้ตัวละครตายและเกิดใหม่ทันที",
    Callback = function()
        local _, humanoid = GetCharacterParts()
        if humanoid then
            humanoid.Health = 0
            Fluent:Notify({
                Title = "Character Reset",
                Content = "สั่งรีเซ็ตตัวละครสำเร็จ",
                Duration = 2
            })
        else
            Fluent:Notify({
                Title = "Reset Error",
                Content = "ไม่พบ Humanoid",
                Duration = 3
            })
        end
    end
})

Tabs.Player:AddButton({
    Title = "Rejoin Server",
    Description = "ออกจากเกมและเข้าเซิร์ฟเวอร์เดิมใหม่อีกครั้ง",
    Callback = function()
        RejoinServer()
    end
})

Tabs.Player:AddButton({
    Title = "Server Hop",
    Description = "ค้นหาและย้ายไปยังเซิร์ฟเวอร์อื่นที่มีผู้เล่น",
    Callback = function()
        ServerHop()
    end
})

-- ==========================================================
-- Teleport Tab
-- ==========================================================
local LocationNames = {}
for name, _ in pairs(Locations) do
    table.insert(LocationNames, name)
end
table.sort(LocationNames)

local SelectedLocation = LocationNames[1] or "Spawn"

Tabs.Teleport:AddDropdown("LocationDropdown", {
    Title = "Select Destination",
    Values = LocationNames,
    Multi = false,
    Default = 1,
    Callback = function(Value)
        SelectedLocation = Value
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Selected Location",
    Description = "วาร์ปไปยังสถานที่ที่เลือกไว้ในเมนูด้านบน",
    Callback = function()
        local targetCFrame = Locations[SelectedLocation]
        if targetCFrame then
            SafeTeleport(targetCFrame, SelectedLocation)
        else
            Fluent:Notify({
                Title = "Teleport Error",
                Content = "ไม่พบพิกัดของสถานที่ที่เลือก",
                Duration = 3
            })
        end
    end
})

Tabs.Teleport:AddParagraph({
    Title = "Quick Teleport Locations",
    Content = "กดปุ่มเพื่อวาร์ปไปยังสถานที่ปลายทางได้ทันที"
})

for _, locName in ipairs(LocationNames) do
    Tabs.Teleport:AddButton({
        Title = "Teleport: " .. locName,
        Callback = function()
            SafeTeleport(Locations[locName], locName)
        end
    })
end

-- ==========================================================
-- Visual Tab
-- ==========================================================
Tabs.Visual:AddParagraph({
    Title = "Visual & ESP Debugging",
    Content = "ระบบแสดงผลวัตถุ ผู้เล่น และ NPC เพื่อการทดสอบในเกม"
})

Tabs.Visual:AddToggle("PlayerESPToggle", {
    Title = "Player ESP & Highlight",
    Description = "แสดงชื่อ ระยะห่าง และ Highlight ผู้เล่นคนอื่นในเซิร์ฟเวอร์",
    Default = false,
    Callback = function(Value)
        HubState.Visuals.PlayerESP = Value
        if not Value then
            for _, plr in pairs(Players:GetPlayers()) do
                ClearVisualElement("Player_" .. plr.Name)
            end
        end
    end
})

Tabs.Visual:AddToggle("NpcESPToggle", {
    Title = "NPC / Monster Highlight",
    Description = "Highlight มอนสเตอร์และ NPC ในแผนที่",
    Default = false,
    Callback = function(Value)
        HubState.Visuals.NpcESP = Value
        if not Value then
            ClearVisualElement("NPCs")
        end
    end
})

Tabs.Visual:AddToggle("PoiESPToggle", {
    Title = "Points of Interest (POI) ESP",
    Description = "แสดงจุดสำคัญ เช่น ร้านค้า จุดรับเควสต์ จุดเกิดบอส",
    Default = false,
    Callback = function(Value)
        HubState.Visuals.PoiESP = Value
        if not Value then
            ClearVisualElement("POI")
        end
    end
})

-- เธรดจัดการการแสดงผล Visuals (ประหยัด CPU ด้วย Interval 0.2 วินาที)
task.spawn(function()
    while HubState.Running do
        task.wait(0.2)
        local _, _, myRoot = GetCharacterParts()

        -- 1. Player ESP Loop
        if HubState.Visuals.PlayerESP and myRoot then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local pKey = "Player_" .. player.Name
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")

                    if char and root and hum and hum.Health > 0 then
                        if not HubState.Visuals.Containers[pKey] then
                            HubState.Visuals.Containers[pKey] = {}
                            local hl = CreateHighlight(char, Color3.fromRGB(0, 255, 170), 0.6)
                            local bbg, lbl = CreateBillboard(root, player.DisplayName, Color3.fromRGB(255, 255, 255))
                            table.insert(HubState.Visuals.Containers[pKey], hl)
                            table.insert(HubState.Visuals.Containers[pKey], bbg)
                            HubState.Visuals.Containers[pKey].Label = lbl
                        else
                            local dist = math.floor((myRoot.Position - root.Position).Magnitude)
                            local lbl = HubState.Visuals.Containers[pKey].Label
                            if lbl and lbl.Parent then
                                lbl.Text = string.format("%s\n[%d studs | HP: %d]", player.DisplayName, dist, math.floor(hum.Health))
                            end
                        end
                    else
                        ClearVisualElement(pKey)
                    end
                end
            end
        end

        -- 2. NPC ESP Loop
        if HubState.Visuals.NpcESP and myRoot then
            if not HubState.Visuals.Containers["NPCs"] then
                HubState.Visuals.Containers["NPCs"] = {}
                for _, model in ipairs(Workspace:GetDescendants()) do
                    if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
                        if hum and hum.Health > 0 and root then
                            local hl = CreateHighlight(model, Color3.fromRGB(255, 80, 80), 0.6)
                            local bbg, lbl = CreateBillboard(root, model.Name, Color3.fromRGB(255, 150, 150))
                            table.insert(HubState.Visuals.Containers["NPCs"], hl)
                            table.insert(HubState.Visuals.Containers["NPCs"], bbg)
                        end
                    end
                end
            end
        end

        -- 3. Points of Interest ESP Loop
        if HubState.Visuals.PoiESP and myRoot then
            if not HubState.Visuals.Containers["POI"] then
                HubState.Visuals.Containers["POI"] = {}
                for poiName, poiPos in pairs(PointsOfInterest) do
                    local part = Instance.new("Part")
                    part.Size = Vector3.new(1, 1, 1)
                    part.Position = poiPos
                    part.Anchored = true
                    part.CanCollide = false
                    part.Transparency = 1
                    part.Parent = Workspace

                    local bbg, lbl = CreateBillboard(part, poiName, Color3.fromRGB(255, 220, 50))
                    table.insert(HubState.Visuals.Containers["POI"], part)
                    table.insert(HubState.Visuals.Containers["POI"], bbg)
                    HubState.Visuals.Containers["POI"][poiName .. "_Label"] = lbl
                end
            else
                for poiName, poiPos in pairs(PointsOfInterest) do
                    local dist = math.floor((myRoot.Position - poiPos).Magnitude)
                    local lbl = HubState.Visuals.Containers["POI"][poiName .. "_Label"]
                    if lbl and lbl.Parent then
                        lbl.Text = string.format("📍 %s\n[%d studs]", poiName, dist)
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- Settings Tab
-- ==========================================================
if InterfaceManagerSuccess and InterfaceManager then
    InterfaceManager:SetLibrary(Fluent)
    InterfaceManager:SetFolder("BloxFruitsHub")
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
end

if SaveManagerSuccess and SaveManager then
    SaveManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    SaveManager:SetFolder("BloxFruitsHub/Config")
    SaveManager:BuildConfigSection(Tabs.Settings)
end

Tabs.Settings:AddParagraph({
    Title = "Script Management",
    Content = "จัดการและควบคุมการทำงานของตัว Hub"
})

Tabs.Settings:AddButton({
    Title = "Destroy UI & Clean Up",
    Description = "ปิดการทำงานของ Script ทำลาย UI และล้าง Connection ทั้งหมด",
    Callback = function()
        HubState:Destroy()
        Fluent:Notify({
            Title = "Blox Fruits Hub",
            Content = "ปิดการทำงานและทำลาย UI เรียบร้อยแล้ว",
            Duration = 3
        })
    end
})

-- ==========================================================
-- Credits Tab
-- ==========================================================
Tabs.Credits:AddParagraph({
    Title = "Blox Fruits Hub Project",
    Content = "Universal Roblox Hub Architecture\nสร้างขึ้นด้วย Fluent UI Library โดย dawid-scripts"
})

Tabs.Credits:AddParagraph({
    Title = "Features & Highlights",
    Content = "• Smooth Draggable Fluent UI\n• Real-Time Health, Speed & Level Display\n• WalkSpeed & JumpPower Overrides\n• Safe CFrame Teleportation System\n• Modular ESP & Highlight Engine\n• Memory Leak & Connection Protected"
})

Tabs.Credits:AddButton({
    Title = "Copy Project Link / Community",
    Description = "คัดลอกลิงก์คอมมูนิตี้ไปยัง Clipboard",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/example")
            Fluent:Notify({
                Title = "Clipboard",
                Content = "คัดลอกลิงก์สำเร็จ!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Clipboard Error",
                Content = "Executor ไม่รองรับฟังก์ชัน setclipboard",
                Duration = 3
            })
        end
    end
})

-- ==========================================================
-- Notifications & Teardown Lifecycle
-- ==========================================================
function HubState:Destroy()
    HubState.Running = false

    -- ยกเลิกการเชื่อมต่อ Events ทั้งหมด
    for _, conn in pairs(HubState.Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    HubState.Connections = {}

    -- ล้าง Visuals ทั้งหมดออกจากหน่วยความจำ
    ClearAllVisuals()

    -- คืนค่าความเร็วและแรงกระโดดตัวละครเป็นค่าเริ่มต้น
    local _, humanoid = GetCharacterParts()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
    end

    -- ทำลาย Fluent Window
    if Window then
        pcall(function()
            Window:Destroy()
        end)
    end

    _G.BloxFruitsHubInstance = nil
end

-- ==========================================================
-- Initialization
-- ==========================================================
if SaveManagerSuccess and SaveManager then
    SaveManager:LoadAutoloadConfig()
end

Window:SelectTab(1)

Fluent:Notify({
    Title = "Blox Fruits Hub",
    Content = "Script Loaded Successfully! (กด Left Control เพื่อย่อ/ขยาย UI)",
    Duration = 5
})
