local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Combat Control",
    SubTitle = "Main Hub",
    TabWidth = 160,
    Size = UDim2.fromOffset(530, 350),
    Theme = "Dark"
})

local Tabs = {
    Combat = Window:AddTab({ Title = "Combat", Icon = "" })
}

local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- โหลด Module เก็บไว้ในตัวแปรก่อน เพื่อป้องกันอาการกระตุก
local Combat = require(LocalPlayer.PlayerScripts:WaitForChild("CombatFramework"))
local CameraShaker = require(LocalPlayer.PlayerScripts.CombatFramework:WaitForChild("CameraShaker"))

local attackLoop = nil

local Toggle = Tabs.Combat:AddToggle("FastAttackToggle", {
    Title = "Enable Fast Attack & Auto Click",
    Default = false
})

Toggle:OnChanged(function(Value)
    if Value then
        -- เปิดการทำงาน: ผูกฟังก์ชันเข้ากับ RenderStepped
        attackLoop = RunService.RenderStepped:Connect(function()
            pcall(function()
                CameraShaker.CameraShakeInstance.CameraShakeState = {FadingIn = 3, FadingOut = 2, Sustained = 0, Inactive = 1}
                
                if Combat.activeController then
                    Combat.activeController.timeToNextAttack = 0
                end
                
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(1280, 672))
            end)
        end)
    else
        -- ปิดการทำงาน: ยกเลิก Connection ทันทีเพื่อหยุดลูปและคืนค่า FPS
        if attackLoop then
            attackLoop:Disconnect()
            attackLoop = nil
        end
    end
end)
