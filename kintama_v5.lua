--==============================
-- Services
--==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

--==============================
-- State（完全一元管理）
--==============================
local State = {
    Speed = {
        Base = 16,
        Value = 16,
        Enabled = true
    },

    Move = {
        Noclip = false
    },

    Utility = {
        TP = false
    },

    Dash = {
        Energy = 100,
        Max = 100,
        Using = false
    }
}

local DASH_SPEED = 60

--==============================
-- Character（死んでも維持）
--==============================
local char, hum, hrp

local function setupCharacter(c)
    char = c
    hum = c:WaitForChild("Humanoid")
    hrp = c:WaitForChild("HumanoidRootPart")
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

--==============================
-- UI（プロツール風）
--==============================
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,300)
frame.Position = UDim2.new(0,20,0,160)
frame.BackgroundColor3 = Color3.fromRGB(20,20,25)
frame.Visible = false
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,28)
title.Text = "KINTAMA HUB V4"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(35,35,45)
title.BorderSizePixel = 0

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0,150,0,30)
toggleBtn.Position = UDim2.new(1,-170,0,20)
toggleBtn.Text = "KINTAMA HUB"
toggleBtn.Font = Enum.Font.Gotham
toggleBtn.TextSize = 13
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
toggleBtn.BorderSizePixel = 0

toggleBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
end)

local function Toggle(text, y, getter, setter)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(1,-16,0,30)
    b.Position = UDim2.new(0,8,0,y)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.BorderSizePixel = 0

    local function refresh()
        local on = getter()
        b.Text = text .. ": " .. (on and "ON" or "OFF")
        b.BackgroundColor3 = on and Color3.fromRGB(0,170,120)
            or Color3.fromRGB(60,60,70)
        b.TextColor3 = Color3.new(1,1,1)
    end

    b.MouseButton1Click:Connect(function()
        setter(not getter())
        refresh()
    end)

    refresh()
end

Toggle("Speed",40,
    function() return State.Speed.Enabled end,
    function(v) State.Speed.Enabled = v end
)

Toggle("Noclip",80,
    function() return State.Move.Noclip end,
    function(v) State.Move.Noclip = v end
)

Toggle("Teleport",120,
    function() return State.Utility.TP end,
    function(v) State.Utility.TP = v end
)

--==============================
-- Speed入力
--==============================
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-16,0,30)
box.Position = UDim2.new(0,8,0,160)
box.PlaceholderText = "Speed"
box.ClearTextOnFocus = true
box.Font = Enum.Font.Code
box.TextSize = 13
box.TextColor3 = Color3.new(1,1,1)
box.BackgroundColor3 = Color3.fromRGB(50,50,60)
box.BorderSizePixel = 0

box.FocusLost:Connect(function(enter)
    if enter then
        local v = tonumber(box.Text)
        if v then
            State.Speed.Value = math.clamp(v, 0, 120)
        end
        box.Text = ""
    end
end)

--==============================
-- Dashゲージ
--==============================
local dashBg = Instance.new("Frame", frame)
dashBg.Size = UDim2.new(1,-16,0,10)
dashBg.Position = UDim2.new(0,8,0,205)
dashBg.BackgroundColor3 = Color3.fromRGB(40,40,50)
dashBg.BorderSizePixel = 0

local dashBar = Instance.new("Frame", dashBg)
dashBar.Size = UDim2.new(1,0,1,0)
dashBar.BackgroundColor3 = Color3.fromRGB(0,170,120)
dashBar.BorderSizePixel = 0

--==============================
-- Info
--==============================
local info = Instance.new("TextLabel", frame)
info.Size = UDim2.new(1,-16,0,24)
info.Position = UDim2.new(0,8,0,225)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextColor3 = Color3.new(1,1,1)
info.BackgroundTransparency = 1

--==============================
-- Dash入力
--==============================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        if State.Dash.Energy > 10 then
            State.Dash.Using = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        State.Dash.Using = false
    end
end)

--==============================
-- 常時処理
--==============================
RunService.RenderStepped:Connect(function(dt)
    if hum then
        local speed = State.Speed.Enabled and State.Speed.Value or State.Speed.Base

        if State.Dash.Using then
            speed = DASH_SPEED
            State.Dash.Energy = math.max(0, State.Dash.Energy - dt * 120)
            if State.Dash.Energy <= 0 then
                State.Dash.Using = false
            end
        else
            State.Dash.Energy = math.min(
                State.Dash.Max,
                State.Dash.Energy + dt * 60
            )
        end

        hum.WalkSpeed = speed
    end

    dashBar.Size = UDim2.new(
        State.Dash.Energy / State.Dash.Max,
        0, 1, 0
    )

    info.Text = string.format(
        "SPD:%d | DASH:%d%%",
        State.Speed.Value,
        (State.Dash.Energy / State.Dash.Max) * 100
    )
end)

RunService.Stepped:Connect(function()
    if State.Move.Noclip and char then
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
end)

--==============================
-- Teleport
--==============================
mouse.Button1Down:Connect(function()
    if State.Utility.TP and hrp and mouse.Hit then
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
    end
end)
