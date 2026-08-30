-- ==========================================================
-- Services
-- ==========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

-- ==========================================================
-- Variables
-- ==========================================================
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ป้องกัน UI ซ้อนกันเมื่อรันสคริปต์ซ้ำ (Clean Up Old Instance)
if _G.BloxFruitsHubInstance then
    pcall(function()
        _G.BloxFruitsHubInstance:Destroy()
    end)
    _G.BloxFruitsHubInstance = nil
end

local HubState = {
    Running = true,
    Connections = {},
    AutoFarm = {
        FarmMobs = false,
        FastAttack = false,
        AutoChests = false,
        AutoStats = false,
        SelectedWeapon = "Melee",
        StatType = "Melee",
        HoverDistance = 7
    },
    PlayerMods = {
        WalkSpeed = 16,
        JumpPower = 50,
        ApplySpeed = false,
        ApplyJump = false,
        NoClip = false,
        InfJump = false
    },
    Visuals = {
        PlayerESP = false,
        NpcESP = false,
        ChestESP = false,
        FruitESP = false,
        Containers = {}
    }
}
_G.BloxFruitsHubInstance = HubState

-- ตารางพิกัด Teleport
local Locations = {
    ["Spawn / Starter Island"] = CFrame.new(1050, 45, 1200),
    ["Pirate Village"] = CFrame.new(-1200, 50, 1800),
    ["Desert Area"] = CFrame.new(2400, 60, -950),
    ["Frozen Village"] = CFrame.new(1150, 80, -1450),
    ["Marine Fortress"] = CFrame.new(-4800, 20, 4300),
    ["Skylands"] = CFrame.new(-4850, 720, -2600),
    ["Colosseum"] = CFrame.new(-1500, 25, -3000),
    ["Boss Area"] = CFrame.new(3500, 120, 3100),
    ["Fruit Dealer / Shop"] = CFrame.new(-450, 30, -780),
    ["Safe Zone"] = CFrame.new(50, 100, 50)
}

-- ==========================================================
-- Fluent Library
-- ==========================================================
local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

if not Library then
    warn("[Blox Fruits Hub] ไม่สามารถโหลด Fluent Library ได้")
    return
end

-- ==========================================================
-- Window
-- ==========================================================
local Window = Library:CreateWindow({
    Title = "Blox Fruits Hub",
    SubTitle = "Auto Farm & Universal Hub",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- ปิด Acrylic เพื่อให้รันติดทันทีในทุก Executor
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- ==========================================================
-- Floating Logo Toggle Button (ปุ่มโลโก้เปิด/ปิด UI)
-- ==========================================================
local ButtonGui = Instance.new("ScreenGui")
ButtonGui.Name = "BF_Logo_ToggleGui"
ButtonGui.ResetOnSpawn = false

local ParentTarget = (gethui and gethui()) or (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
ButtonGui.Parent = ParentTarget

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "BF_LogoButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 15, 0.4, 0)
ToggleButton.Image = "rbxassetid://138065724886036"
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleButton.BackgroundTransparency = 0.2
ToggleButton.BorderSizePixel = 0
ToggleButton.Active = true
ToggleButton.Draggable = true -- รองรับการลากวางบนจอ
ToggleButton.Parent = ButtonGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = ToggleButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 255, 170)
UIStroke.Thickness = 2
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Parent = ToggleButton

-- ฟังก์ชันสลับการแสดงผลของหน้าต่าง UI เมื่อกดปุ่มโลโก้
ToggleButton.MouseButton1Click:Connect(function()
    if Window and Window.Root then
        Window.Root.Visible = not Window.Root.Visible
    elseif Window and Window.Frame then
        Window.Frame.Visible = not Window.Frame.Visible
    end
end)

-- ==========================================================
-- Tabs
-- ==========================================================
local Tabs = {
    Main = Window:AddTab({ Title = "Main Farm", Icon = "sword" }),
    Stats = Window:AddTab({ Title = "Auto Stats", Icon = "bar-chart-2" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Credits = Window:AddTab({ Title = "Credits", Icon = "info" })
}

-- ==========================================================
-- Main Functions
-- ==========================================================

-- ตรวจสอบชิ้นส่วนตัวละคร
local function GetCharacterParts()
    local character = LocalPlayer.Character
    if not character then return nil, nil, nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    return character, humanoid, rootPart
end

-- สวมใส่อาวุธตามประเภท (Melee / Sword / Blox Fruit / Gun)
local function EquipWeapon(weaponType)
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not character or not backpack then return end

    -- ค้นหาใน Backpack หรือในตัวละคร
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local toolType = item:GetAttribute("WeaponType") or item.ToolTip or ""
            if string.find(string.lower(item.Name), string.lower(weaponType)) or string.find(string.lower(toolType), string.lower(weaponType)) or weaponType == "All" then
                character:FindFirstChildOfClass("Humanoid"):EquipTool(item)
                return
            end
        end
    end
end

-- ฟังก์ชันโจมตีรวดเร็ว (Fast Attack)
local function TriggerAttack()
    VirtualUser:CaptureController()
    VirtualUser:Button1Down(Vector2.new(50, 50))
    task.wait(0.05)
    VirtualUser:Button1Up(Vector2.new(50, 50))
end

-- ฟังก์ชันค้นหามอนสเตอร์ที่ใกล้ที่สุด
local function GetClosestMob()
    local _, _, myRoot = GetCharacterParts()
    if not myRoot then return nil end

    local closestMob = nil
    local shortestDist = math.huge

    -- ค้นหาใน Enemies โฟลเดอร์ หรือใน Workspace
    local enemyFolder = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("NPCs") or Workspace

    for _, mob in ipairs(enemyFolder:GetDescendants()) do
        if mob:IsA("Model") and mob:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(mob) then
            local hum = mob:FindFirstChildOfClass("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")

            if hum and hum.Health > 0 and root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestMob = mob
                end
            end
        end
    end
    return closestMob
end

-- วาร์ปอย่างปลอดภัย
local function SafeTeleport(targetCFrame, name)
    local _, humanoid, rootPart = GetCharacterParts()
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        Library:Notify({
            Title = "Teleport Error",
            Content = "ไม่สามารถวาร์ปได้ (ไม่พบตัวละครหรือตัวละครหมดสติ)",
            Duration = 3
        })
        return false
    end

    local success, err = pcall(function()
        rootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    end)

    if success then
        Library:Notify({
            Title = "Teleport Success",
            Content = "วาร์ปไปยัง " .. (name or "จุดหมาย") .. " สำเร็จ!",
            Duration = 2
        })
        return true
    end
    return false
end

-- Rejoin & ServerHop
local function RejoinServer()
    Library:Notify({ Title = "Rejoining", Content = "กำลัง Rejoin...", Duration = 3 })
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

local function ServerHop()
    Library:Notify({ Title = "Server Hop", Content = "กำลังค้นหาเซิร์ฟเวอร์...", Duration = 4 })
    task.spawn(function()
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", tostring(game.PlaceId))
        local success, res = pcall(function() return HttpService:JSONDecode(game:HttpGet(url)) end)
        if success and res and res.data then
            for _, s in ipairs(res.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers and s.playing > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        Library:Notify({ Title = "Server Hop", Content = "ไม่พบเซิร์ฟเวอร์ที่เหมาะสม", Duration = 3 })
    end)
end

-- ฟังก์ชันสร้าง Highlight & Billboard
local function CreateHighlight(adornee, color)
    if not adornee or not adornee:IsA("Model") then return nil end
    local hl = Instance.new("Highlight")
    hl.Name = "BF_Highlight"
    hl.Adornee = adornee
    hl.FillColor = color or Color3.fromRGB(0, 255, 170)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.Parent = adornee
    return hl
end

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

local function ClearVisualElement(key)
    if HubState.Visuals.Containers[key] then
        for _, obj in pairs(HubState.Visuals.Containers[key]) do
            if typeof(obj) == "Instance" then pcall(function() obj:Destroy() end) end
        end
        HubState.Visuals.Containers[key] = nil
    end
end

-- ==========================================================
-- Main Tab (Auto Farm & Fast Attack)
-- ==========================================================
Tabs.Main:AddParagraph({
    Title = "Auto Farm Combat System",
    Content = "ระบบฟาร์มมอนสเตอร์อัตโนมัติ ลอยตัวเหนือมอนสเตอร์ และโจมตีอย่างรวดเร็ว"
})

Tabs.Main:AddDropdown("WeaponSelect", {
    Title = "Select Weapon",
    Values = { "Melee", "Sword", "Blox Fruit", "Gun" },
    Default = "Melee",
    Callback = function(Value)
        HubState.AutoFarm.SelectedWeapon = Value
    end
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm Closest Mob",
    Description = "วาร์ปลอยตัวเหนือมอนสเตอร์และตีอัตโนมัติ",
    Default = false,
    Callback = function(Value)
        HubState.AutoFarm.FarmMobs = Value
        Library:Notify({
            Title = "Auto Farm",
            Content = "Auto Farm: " .. (Value and "เปิดใช้งาน" or "ปิดใช้งาน"),
            Duration = 2
        })
    end
})

Tabs.Main:AddToggle("FastAttackToggle", {
    Title = "Fast Attack (Auto Clicker)",
    Description = "ตีอัตโนมัติแบบความเร็วสูง",
    Default = false,
    Callback = function(Value)
        HubState.AutoFarm.FastAttack = Value
    end
})

Tabs.Main:AddToggle("AutoChestToggle", {
    Title = "Auto Collect Chests",
    Description = "วาร์ปเก็บกล่องเงินรอบแมพอัตโนมัติ",
    Default = false,
    Callback = function(Value)
        HubState.AutoFarm.AutoChests = Value
    end
})

-- เธรดจัดการระบบ Auto Farm Mobs
task.spawn(function()
    while HubState.Running do
        task.wait()
        if HubState.AutoFarm.FarmMobs then
            local _, humanoid, rootPart = GetCharacterParts()
            if humanoid and rootPart and humanoid.Health > 0 then
                local mob = GetClosestMob()
                if mob then
                    local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
                    local mobHum = mob:FindFirstChildOfClass("Humanoid")

                    if mobRoot and mobHum and mobHum.Health > 0 then
                        -- ลอยตัวเหนือหัวมอนสเตอร์เพื่อป้องกันการถูกโจมตี
                        rootPart.CFrame = mobRoot.CFrame * CFrame.new(0, HubState.AutoFarm.HoverDistance, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        
                        -- ถืออาวุธและสั่งโจมตี
                        EquipWeapon(HubState.AutoFarm.SelectedWeapon)
                        TriggerAttack()
                    end
                end
            end
        end
    end
end)

-- เธรด Fast Attack
task.spawn(function()
    while HubState.Running do
        task.wait(0.08)
        if HubState.AutoFarm.FastAttack then
            TriggerAttack()
        end
    end
end)

-- เธรด Auto Farm Chests
task.spawn(function()
    while HubState.Running do
        task.wait(0.5)
        if HubState.AutoFarm.AutoChests then
            local _, humanoid, rootPart = GetCharacterParts()
            if humanoid and rootPart and humanoid.Health > 0 then
                for _, chest in ipairs(Workspace:GetDescendants()) do
                    if not HubState.AutoFarm.AutoChests then break end
                    if chest:IsA("BasePart") and string.find(string.lower(chest.Name), "chest") and chest.Transparency < 1 then
                        rootPart.CFrame = chest.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.4)
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- Auto Stats Tab
-- ==========================================================
Tabs.Stats:AddParagraph({
    Title = "Auto Stats Upgrade",
    Content = "อัพค่าสเตตัสอัตโนมัติเมื่อมี Point เหลือ"
})

Tabs.Stats:AddDropdown("StatDropdown", {
    Title = "Select Stat to Upgrade",
    Values = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" },
    Default = "Melee",
    Callback = function(Value)
        HubState.AutoFarm.StatType = Value
    end
})

Tabs.Stats:AddToggle("AutoStatsToggle", {
    Title = "Enable Auto Stats",
    Default = false,
    Callback = function(Value)
        HubState.AutoFarm.AutoStats = Value
    end
})

-- เธรด Auto Stats
task.spawn(function()
    while HubState.Running do
        task.wait(1)
        if HubState.AutoFarm.AutoStats then
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
                if remote then
                    local statArg = HubState.AutoFarm.StatType
                    if statArg == "Defense" then statArg = "Defense" end
                    if statArg == "Demon Fruit" then statArg = "Demon Fruit" end
                    remote:InvokeServer("AddPoint", statArg, 1)
                end
            end)
        end
    end
end)

-- ==========================================================
-- Player Tab
-- ==========================================================
Tabs.Player:AddSlider("WalkSpeedSlider", {
    Title = "WalkSpeed",
    Default = 16,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(Value)
        HubState.PlayerMods.WalkSpeed = Value
        local _, hum = GetCharacterParts()
        if hum and HubState.PlayerMods.ApplySpeed then hum.WalkSpeed = Value end
    end
})

Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Enable WalkSpeed",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.ApplySpeed = Value
        local _, hum = GetCharacterParts()
        if hum then hum.WalkSpeed = Value and HubState.PlayerMods.WalkSpeed or 16 end
    end
})

Tabs.Player:AddSlider("JumpPowerSlider", {
    Title = "JumpPower",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(Value)
        HubState.PlayerMods.JumpPower = Value
        local _, hum = GetCharacterParts()
        if hum and HubState.PlayerMods.ApplyJump then hum.JumpPower = Value end
    end
})

Tabs.Player:AddToggle("JumpToggle", {
    Title = "Enable JumpPower",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.ApplyJump = Value
        local _, hum = GetCharacterParts()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = Value and HubState.PlayerMods.JumpPower or 50
        end
    end
})

Tabs.Player:AddToggle("NoClipToggle", {
    Title = "NoClip (ทะลุกำแพง)",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.NoClip = Value
    end
})

Tabs.Player:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump (กระโดดไม่จำกัด)",
    Default = false,
    Callback = function(Value)
        HubState.PlayerMods.InfJump = Value
    end
})

-- Stepped Loop สำหรับ NoClip และ Modifiers
local SteppedConn = RunService.Stepped:Connect(function()
    if not HubState.Running then return end
    local char, hum = GetCharacterParts()
    if char then
        if HubState.PlayerMods.NoClip then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
        if hum then
            if HubState.PlayerMods.ApplySpeed and hum.WalkSpeed ~= HubState.PlayerMods.WalkSpeed then
                hum.WalkSpeed = HubState.PlayerMods.WalkSpeed
            end
            if HubState.PlayerMods.ApplyJump and hum.JumpPower ~= HubState.PlayerMods.JumpPower then
                hum.UseJumpPower = true
                hum.JumpPower = HubState.PlayerMods.JumpPower
            end
        end
    end
end)
table.insert(HubState.Connections, SteppedConn)

-- Infinite Jump Event
local JumpConn = UserInputService.JumpRequest:Connect(function()
    if HubState.Running and HubState.PlayerMods.InfJump then
        local _, hum = GetCharacterParts()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
table.insert(HubState.Connections, JumpConn)

Tabs.Player:AddButton({
    Title = "Reset Character",
    Callback = function()
        local _, hum = GetCharacterParts()
        if hum then hum.Health = 0 end
    end
})

Tabs.Player:AddButton({ Title = "Rejoin Server", Callback = RejoinServer })
Tabs.Player:AddButton({ Title = "Server Hop", Callback = ServerHop })

-- ==========================================================
-- Teleport Tab
-- ==========================================================
local LocList = {}
for k, _ in pairs(Locations) do table.insert(LocList, k) end
table.sort(LocList)

local SelectedLoc = LocList[1] or "Spawn / Starter Island"

Tabs.Teleport:AddDropdown("TeleportDropdown", {
    Title = "Select Destination",
    Values = LocList,
    Default = 1,
    Callback = function(v) SelectedLoc = v end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Selected Destination",
    Callback = function()
        SafeTeleport(Locations[SelectedLoc], SelectedLoc)
    end
})

Tabs.Teleport:AddParagraph({ Title = "Quick Islands", Content = "คลิกเพื่อวาร์ปทันที" })

for _, name in ipairs(LocList) do
    Tabs.Teleport:AddButton({
        Title = "Go to: " .. name,
        Callback = function() SafeTeleport(Locations[name], name) end
    })
end

-- ==========================================================
-- Visual Tab (ESP & Highlights)
-- ==========================================================
Tabs.Visual:AddToggle("PlayerESPToggle", {
    Title = "Player Highlight & Distance",
    Default = false,
    Callback = function(v)
        HubState.Visuals.PlayerESP = v
        if not v then
            for _, p in ipairs(Players:GetPlayers()) do ClearVisualElement("Player_" .. p.Name) end
        end
    end
})

Tabs.Visual:AddToggle("NpcESPToggle", {
    Title = "NPC / Monster ESP",
    Default = false,
    Callback = function(v)
        HubState.Visuals.NpcESP = v
        if not v then ClearVisualElement("NPCs") end
    end
})

Tabs.Visual:AddToggle("ChestESPToggle", {
    Title = "Chest ESP (กล่องเงิน)",
    Default = false,
    Callback = function(v)
        HubState.Visuals.ChestESP = v
        if not v then ClearVisualElement("Chests") end
    end
})

Tabs.Visual:AddToggle("FruitESPToggle", {
    Title = "Fruit ESP (ผลปีศาจที่ตก)",
    Default = false,
    Callback = function(v)
        HubState.Visuals.FruitESP = v
        if not v then ClearVisualElement("Fruits") end
    end
})

-- เธรด Visual Loop
task.spawn(function()
    while HubState.Running do
        task.wait(0.3)
        local _, _, myRoot = GetCharacterParts()

        -- Player ESP
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
                            local hl = CreateHighlight(char, Color3.fromRGB(0, 255, 170))
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

        -- Chest ESP
        if HubState.Visuals.ChestESP and myRoot then
            if not HubState.Visuals.Containers["Chests"] then
                HubState.Visuals.Containers["Chests"] = {}
                for _, chest in ipairs(Workspace:GetDescendants()) do
                    if chest:IsA("BasePart") and string.find(string.lower(chest.Name), "chest") and chest.Transparency < 1 then
                        local bbg, lbl = CreateBillboard(chest, "📦 Chest", Color3.fromRGB(255, 215, 0))
                        table.insert(HubState.Visuals.Containers["Chests"], bbg)
                    end
                end
            end
        end

        -- Fruit ESP
        if HubState.Visuals.FruitESP and myRoot then
            if not HubState.Visuals.Containers["Fruits"] then
                HubState.Visuals.Containers["Fruits"] = {}
                for _, tool in ipairs(Workspace:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
                        local bbg, lbl = CreateBillboard(tool.Handle, "🍎 " .. tool.Name, Color3.fromRGB(255, 50, 50))
                        table.insert(HubState.Visuals.Containers["Fruits"], bbg)
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- Settings Tab
-- ==========================================================
Tabs.Settings:AddDropdown("ThemeSelect", {
    Title = "UI Theme",
    Values = { "Dark", "Darker", "Light", "Aqua", "Amethyst", "Rose" },
    Default = "Dark",
    Callback = function(v)
        Library:SetTheme(v)
    end
})

Tabs.Settings:AddToggle("ToggleLogoVisible", {
    Title = "Show/Hide Floating Logo Button",
    Default = true,
    Callback = function(v)
        ToggleButton.Visible = v
    end
})

Tabs.Settings:AddButton({
    Title = "Destroy UI & Stop All Scripts",
    Callback = function()
        HubState:Destroy()
        Library:Notify({
            Title = "Blox Fruits Hub",
            Content = "ปิดระบบและทำลาย UI เรียบร้อยแล้ว",
            Duration = 3
        })
    end
})

-- ==========================================================
-- Credits Tab
-- ==========================================================
Tabs.Credits:AddParagraph({
    Title = "Blox Fruits Hub",
    Content = "พัฒนาด้วย Fluent UI Library\nมาพร้อมปุ่มโลโก้เปิด/ปิด (Asset: 138065724886036)"
})

Tabs.Credits:AddButton({
    Title = "Copy Community Link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/example")
            Library:Notify({ Title = "Clipboard", Content = "คัดลอกลิงก์สำเร็จ!", Duration = 3 })
        end
    end
})

-- ==========================================================
-- Notifications & Teardown Lifecycle
-- ==========================================================
function HubState:Destroy()
    HubState.Running = false

    -- ตัด Connection ทั้งหมด
    for _, conn in pairs(HubState.Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    HubState.Connections = {}

    -- ลบปุ่มโลโก้
    if ButtonGui then
        pcall(function() ButtonGui:Destroy() end)
    end

    -- ล้าง Visuals
    for key, _ in pairs(HubState.Visuals.Containers) do
        ClearVisualElement(key)
    end

    -- คืนค่าตัวละคร
    local _, hum = GetCharacterParts()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
    end

    -- ทำลาย Fluent Window
    if Window then
        pcall(function() Window:Destroy() end)
    end

    _G.BloxFruitsHubInstance = nil
end

-- ==========================================================
-- Initialization
-- ==========================================================
Window:SelectTab(1)

Library:Notify({
    Title = "Blox Fruits Hub",
    Content = "โหลดสคริปต์สำเร็จ! คลิกที่ปุ่มโลโก้หรือกด LeftControl เพื่อเปิด/ปิดเมนู",
    Duration = 5
})
