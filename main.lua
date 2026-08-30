local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- ==========================================
-- 1. ส่วนของ UI หลัก (Fluent)
-- ==========================================
local Window = Fluent:CreateWindow({
    Title = "My Custom Hub",
    SubTitle = "Auto Farm Script",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

_G.AutoFarm = false 

local Toggle = Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm (Swing Katana)",
    Default = false,
    Callback = function(state)
        _G.AutoFarm = state 

        if _G.AutoFarm then
            task.spawn(function()
                while _G.AutoFarm do
                    local args = { "swingKatana" }
                    -- เพิ่ม pcall ป้องกันสคริปต์พังถ้าหา event ไม่เจอ
                    pcall(function()
                        game:GetService("Players").LocalPlayer:WaitForChild("ninjaEvent"):FireServer(unpack(args))
                    end)
                    task.wait(0.1) 
                end
            end)
        end
    end
})

Window:SelectTab(1)

-- ==========================================
-- 2. ส่วนของปุ่มโลโก้ (แก้ไขปัญหาโลโก้ล่องหน)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MyLogoToggle"

-- [แก้ปัญหา 1] หาที่อยู่ให้ UI ตามการรองรับของตัวรัน
local guiParent
if gethui then
    guiParent = gethui()
else
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui then
        guiParent = coreGui
    else
        guiParent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
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

-- [แก้ปัญหา 2] ใช้ rbxthumb ดึงรูปจาก Decal ID ได้ทันที หมดปัญหารูปไม่โหลด
LogoButton.Image = "rbxthumb://type=Asset&id=138065724886036&w=150&h=150" 

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.5, 0)
UICorner.Parent = LogoButton

-- ระบบลากปุ่ม (Draggable)
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

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- ระบบกดปุ่มโลโก้เพื่อเปิด/ปิด UI
LogoButton.MouseButton1Click:Connect(function()
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, Enum.KeyCode.RightControl, false, game)
    task.wait(0.05) -- ใส่ดีเลย์นิดหน่อยกันกดไม่ติด
    vim:SendKeyEvent(false, Enum.KeyCode.RightControl, false, game)
end)
