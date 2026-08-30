-- ==========================================
-- [สำคัญที่สุด] ระบบปลดล็อคปุ่มเดินและกระโดดบนมือถือแบบเด็ดขาด
-- ต้องรันก่อนโหลด UI เพื่อดักจับ ControlModule ของ Roblox
-- ==========================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local function PermanentMobileFix()
    -- 1. Hook และป้องกันไม่ให้ Roblox สั่ง Disable ปุ่มเดิน/กระโดด
    local function patchControls()
        pcall(function()
            local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
            if not PlayerScripts then return end
            
            local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule", 5))
            local Controls = PlayerModule:GetControls()
            
            if Controls then
                Controls:Enable(true)
                -- ล็อคไม่ให้ฟังก์ชัน Disable ทำงานได้
                Controls.Disable = function(self)
                    if self.activeController then
                        self.activeController:Enable(true)
                    end
                    if self.touchControlFrame then
                        self.touchControlFrame.Visible = true
                    end
                end
            end
        end)
    end
    
    task.spawn(patchControls)
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        patchControls()
    end)

    -- 2. ปลดล็อค Modal ทุกชิ้นแบบ Realtime ด้วย Property Signal
    local function removeModal(obj)
        if obj:IsA("GuiObject") then
            if obj.Modal then obj.Modal = false end
            obj:GetPropertyChangedSignal("Modal"):Connect(function()
                if obj.Modal then
                    obj.Modal = false
                end
            end)
        end
    end

    local containers = { LocalPlayer:WaitForChild("PlayerGui") }
    if gethui then pcall(function() table.insert(containers, gethui()) end) end
    pcall(function() table.insert(containers, game:GetService("CoreGui")) end)

    for _, container in ipairs(containers) do
        for _, desc in ipairs(container:GetDescendants()) do
            removeModal(desc)
        end
        container.DescendantAdded:Connect(removeModal)
    end

    -- 3. บังคับ TouchGui, TouchControlFrame และ JumpButton ให้แสดงผลตลอดเวลา
    RunService.RenderStepped:Connect(function()
        pcall(function()
            LocalPlayer.DevTouchMovementMode = Enum.DevTouchMovementMode.DynamicThumbstick
            
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local touchGui = playerGui:FindFirstChild("TouchGui")
                if touchGui then
                    touchGui.Enabled = true
                    local tcf = touchGui:FindFirstChild("TouchControlFrame")
                    if tcf then
                        tcf.Visible = true
                        local jump = tcf:FindFirstChild("JumpButton")
                        if jump then jump.Visible = true end
                        local stick = tcf:FindFirstChild("DynamicThumbstickFrame")
                        if stick then stick.Visible = true end
                    end
                end
            end
        end)
    end)
end

-- สั่งเริ่มระบบปลดล็อคปุ่มเดินทันที
PermanentMobileFix()

-- ==========================================
-- 1. โหลด Fluent UI และสร้างหน้าต่างหลัก
-- ==========================================
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- ตัวแปรระบบฟาร์มและการตั้งค่า
_G.AutoFarm = false
_G.AutoSell = false
_G.AutoBuySwords = false
_G.AutoBuyBelts = false
_G.AutoBuySkills = false
_G.AutoBuyShurikens = false
_G.AutoBuyRanks = false

_G.SpeedEnabled = false
_G.WalkSpeedValue = 16
_G.JumpEnabled = false
_G.JumpPowerValue = 50
_G.InfJump = false
_G.Noclip = false

_G.Flying = false
_G.FlySpeed = 50

-- พิกัดเกาะทั้งหมด
local Islands = {
    ["Ground / Spawn"] = CFrame.new(25, 3, 22),
    ["Enchanted Island"] = CFrame.new(51, 766, -138),
    ["Astral Island"] = CFrame.new(206, 2014, 237),
    ["Mystic Island"] = CFrame.new(171, 4047, 11),
    ["Space Island"] = CFrame.new(154, 5657, 85),
    ["Tundra Island"] = CFrame.new(198, 9197, 240),
    ["Eternal Island"] = CFrame.new(137, 13680, 58),
    ["Sandstorm Island"] = CFrame.new(177, 17686, 127),
    ["Thunder Island"] = CFrame.new(139, 24070, 163),
    ["Ancient Inferno Island"] = CFrame.new(147, 28256, 64),
    ["Midnight Shadow Island"] = CFrame.new(145, 33206, 68),
    ["Mythical Souls Island"] = CFrame.new(148, 39317, 143),
    ["Winter Wonder Island"] = CFrame.new(154, 46010, 138),
    ["Golden Master Island"] = CFrame.new(148, 52607, 140),
    ["Dragon Legend Island"] = CFrame.new(155, 59594, 155),
    ["Cybernetic Legends Island"] = CFrame.new(147, 66669, 149),
    ["Chaos Legends Island"] = CFrame.new(147, 74442, 149),
    ["Soul Fusion Island"] = CFrame.new(147, 79746, 149),
    ["Dark Elements Island"] = CFrame.new(147, 83145, 149),
    ["Inner Peace Island"] = CFrame.new(147, 87051, 149),
    ["Blazing Vortex Island"] = CFrame.new(167, 91245, 132)
}

local IslandNames = {}
for name, _ in pairs(Islands) do
    table.insert(IslandNames, name)
end

local Window = Fluent:CreateWindow({
    Title = "Ninja Legends Hub",
    SubTitle = "Mobile Controls Fixed",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- ต้องปิด Acrylic เพื่อป้องกันการบล็อกปุ่มทัชบนมือถือ
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main / Farm", Icon = "sword" }),
    AutoBuy = Window:AddTab({ Title = "Auto Buy", Icon = "shopping-cart" }),
    Player = Window:AddTab({ Title = "Player / Fly", Icon = "user" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Misc = Window:AddTab({ Title = "Misc / Settings", Icon = "settings" })
}

-- ------------------------------------------
-- Tab 1: Main / Auto Farm
-- ------------------------------------------
Tabs.Main:AddParagraph({
    Title = "Auto Farm",
    Content = "ระบบฟาร์มเหรียญ/Chi และขายอัตโนมัติ"
})

Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Swing Katana (ฟันอัตโนมัติ)",
    Default = false,
    Callback = function(state)
        _G.AutoFarm = state
        if _G.AutoFarm then
            task.spawn(function()
                while _G.AutoFarm do
                    pcall(function()
                        LocalPlayer:WaitForChild("ninjaEvent"):FireServer("swingKatana")
                    end)
                    task.wait(0.1)
                end
            end)
        end
    end
})

Tabs.Main:AddToggle("AutoSellToggle", {
    Title = "Auto Sell (ขายอัตโนมัติ)",
    Default = false,
    Callback = function(state)
        _G.AutoSell = state
        if _G.AutoSell then
            task.spawn(function()
                while _G.AutoSell do
                    pcall(function()
                        local sellPad = workspace:FindFirstChild("sellAreaCircles")
                        if sellPad and sellPad:FindFirstChild("sellAreaCircle16") then
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, sellPad.sellAreaCircle16.circleInner, 0)
                            task.wait(0.05)
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, sellPad.sellAreaCircle16.circleInner, 1)
                        end
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

-- ------------------------------------------
-- Tab 2: Auto Buy
-- ------------------------------------------
Tabs.AutoBuy:AddToggle("AutoSwords", {
    Title = "Auto Buy All Swords (ซื้อดาบทั้งหมด)",
    Default = false,
    Callback = function(state)
        _G.AutoBuySwords = state
        if _G.AutoBuySwords then
            task.spawn(function()
                while _G.AutoBuySwords do
                    pcall(function()
                        LocalPlayer:WaitForChild("ninjaEvent"):FireServer("buyAllSwords", "Ground")
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.AutoBuy:AddToggle("AutoBelts", {
    Title = "Auto Buy All Belts (ซื้อสายคาดทั้งหมด)",
    Default = false,
    Callback = function(state)
        _G.AutoBuyBelts = state
        if _G.AutoBuyBelts then
            task.spawn(function()
                while _G.AutoBuyBelts do
                    pcall(function()
                        LocalPlayer:WaitForChild("ninjaEvent"):FireServer("buyAllBelts", "Ground")
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.AutoBuy:AddToggle("AutoSkills", {
    Title = "Auto Buy All Skills (ซื้อสกิลกระโดดทั้งหมด)",
    Default = false,
    Callback = function(state)
        _G.AutoBuySkills = state
        if _G.AutoBuySkills then
            task.spawn(function()
                while _G.AutoBuySkills do
                    pcall(function()
                        LocalPlayer:WaitForChild("ninjaEvent"):FireServer("buyAllSkills", "Ground")
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.AutoBuy:AddToggle("AutoShurikens", {
    Title = "Auto Buy All Shurikens (ซื้อดาวกระจาย)",
    Default = false,
    Callback = function(state)
        _G.AutoBuyShurikens = state
        if _G.AutoBuyShurikens then
            task.spawn(function()
                while _G.AutoBuyShurikens do
                    pcall(function()
                        LocalPlayer:WaitForChild("ninjaEvent"):FireServer("buyAllShurikens", "Ground")
                    end)
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.AutoBuy:AddToggle("AutoRanks", {
    Title = "Auto Buy Ranks (ซื้อแรงค์อัตโนมัติ)",
    Default = false,
    Callback = function(state)
        _G.AutoBuyRanks = state
        if _G.AutoBuyRanks then
            task.spawn(function()
                local ranks = {
                    "Rookie", "Grasshopper", "Apprentice", "Samurai", "Assassin", "Shadow", "Ninja", 
                    "Master Ninja", "Sensei", "Master Sensei", "Ninja Legend", "Master Of Shadows", 
                    "Sun Master", "Myth", "Legend", "Awakened", "Shadow Legend", "Dragon Legend", 
                    "Master Legend", "Genesis Master", "Chaos Master", "Infinity Sensei"
                }
                while _G.AutoBuyRanks do
                    for _, rank in ipairs(ranks) do
                        if not _G.AutoBuyRanks then break end
                        pcall(function()
                            LocalPlayer:WaitForChild("ninjaEvent"):FireServer("buyRank", rank)
                        end)
                        task.wait(0.1)
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

-- ------------------------------------------
-- Tab 3: Player / Movement & Fly
-- ------------------------------------------
Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Enable WalkSpeed (เปิดความเร็วเดิน)",
    Default = false,
    Callback = function(state)
        _G.SpeedEnabled = state
        if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

Tabs.Player:AddSlider("SpeedSlider", {
    Title = "WalkSpeed Value",
    Default = 16,
    Min = 16,
    Max = 300,
    Rounding = 0,
    Callback = function(val)
        _G.WalkSpeedValue = val
    end
})

Tabs.Player:AddToggle("JumpToggle", {
    Title = "Enable JumpPower (เปิดแรงกระโดด)",
    Default = false,
    Callback = function(state)
        _G.JumpEnabled = state
        if not state and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
        end
    end
})

Tabs.Player:AddSlider("JumpSlider", {
    Title = "JumpPower Value",
    Default = 50,
    Min = 50,
    Max = 300,
    Rounding = 0,
    Callback = function(val)
        _G.JumpPowerValue = val
    end
})

Tabs.Player:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump (กระโดดไม่จำกัด)",
    Default = false,
    Callback = function(state)
        _G.InfJump = state
    end
})

UserInputService.JumpRequest:Connect(function()
    if _G.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Fly System
local bg, bv
local function startFly()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    bg = Instance.new("BodyGyro")
    bg.P = 9e4
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = hrp

    task.spawn(function()
        while _G.Flying and char and hrp and hum.Parent do
            local cam = workspace.CurrentCamera
            local moveDir = hum.MoveDirection
            if moveDir.Magnitude > 0 then
                bv.Velocity = (cam.CFrame.LookVector * (moveDir.Z * -1) + cam.CFrame.RightVector * moveDir.X + Vector3.new(0, (moveDir.Magnitude > 0 and (cam.CFrame.LookVector.Y * (moveDir.Z * -1)) or 0), 0)).Unit * _G.FlySpeed
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end
            bg.CFrame = cam.CFrame
            task.wait()
        end
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end)
end

Tabs.Player:AddToggle("FlyToggle", {
    Title = "Fly (บิน - ควบคุมด้วยปุ่มเดินหรือหน้าจอ)",
    Default = false,
    Callback = function(state)
        _G.Flying = state
        if _G.Flying then
            startFly()
        else
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
        end
    end
})

Tabs.Player:AddSlider("FlySpeedSlider", {
    Title = "Fly Speed (ความเร็วบิน)",
    Default = 50,
    Min = 10,
    Max = 300,
    Rounding = 0,
    Callback = function(val)
        _G.FlySpeed = val
    end
})

Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip (เดินทะลุกำแพง)",
    Default = false,
    Callback = function(state)
        _G.Noclip = state
    end
})

RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- ลูปความเร็วเดินและกระโดด
task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if _G.SpeedEnabled then
                    hum.WalkSpeed = _G.WalkSpeedValue
                end
                if _G.JumpEnabled then
                    hum.JumpPower = _G.JumpPowerValue
                end
            end
        end)
    end
end)

-- ------------------------------------------
-- Tab 4: Teleport (วาร์ป)
-- ------------------------------------------
local SelectedIsland = "Ground / Spawn"

Tabs.Teleport:AddDropdown("IslandDropdown", {
    Title = "Select Island (เลือกเกาะ)",
    Values = IslandNames,
    Multi = false,
    Default = "Ground / Spawn",
    Callback = function(val)
        SelectedIsland = val
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleport to Selected Island",
    Description = "วาร์ปไปยังเกาะที่เลือก",
    Callback = function()
        if Islands[SelectedIsland] and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = Islands[SelectedIsland]
        end
    end
})

Tabs.Teleport:AddButton({
    Title = "Unlock All Islands (ปลดล็อคทุกเกาะ)",
    Description = "วาร์ปแตะทุกเกาะอัตโนมัติ",
    Callback = function()
        task.spawn(function()
            for name, cframe in pairs(Islands) do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = cframe
                    task.wait(0.3)
                end
            end
        end)
    end
})

-- ------------------------------------------
-- Tab 5: Misc
-- ------------------------------------------
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new(0, 0))
end)

Window:SelectTab(1)

-- ==========================================
-- 2. ปุ่มโลโก้ลอย เปิด-ปิด UI สำหรับมือถือ
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyLogoToggle"
ScreenGui.ResetOnSpawn = false

local guiParent
if gethui then
    guiParent = gethui()
else
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        guiParent = coreGui
    else
        guiParent = LocalPlayer:WaitForChild("PlayerGui")
    end
end
ScreenGui.Parent = guiParent
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local LogoButton = Instance.new("ImageButton")
LogoButton.Parent = ScreenGui
LogoButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LogoButton.BackgroundTransparency = 1 
LogoButton.Position = UDim2.new(0.1, 0, 0.1, 0) 
LogoButton.Size = UDim2.new(0, 50, 0, 50) 
LogoButton.Image = "rbxthumb://type=Asset&id=138065724886036&w=150&h=150" 
LogoButton.Modal = false

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.5, 0)
UICorner.Parent = LogoButton

local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    LogoButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

LogoButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = LogoButton.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

LogoButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

LogoButton.MouseButton1Click:Connect(function()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
    task.wait(0.05) 
    vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
end)
