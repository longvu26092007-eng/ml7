-- [[ VU NGUYEN - DETECT SEA & TRAVEL (WAIT LOAD) ]]

-- [ CONFIG 6 PLACE ID ]
local SEAS = {
    ["SEA1"] = {["2753915549"] = true, ["85211729168715"] = true},
    ["SEA2"] = {["4442272183"] = true, ["79091703265657"] = true},
    ["SEA3"] = {["7449423635"] = true, ["100117331123089"] = true}
}

local PlaceId = tostring(game.PlaceId)

-- [ UI MINI GÓC TRÁI TRÊN CÙNG ]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 35)
Main.Position = UDim2.new(0, 10, 0, 10)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BackgroundTransparency = 0.2
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 5)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 1, 0)
Status.Text = "Waiting for Game Load..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamBold
Status.TextSize = 11

-- [ LOGIC CHÍNH ]
task.spawn(function()
    -- Đợi game load xong hẳn
    if not game:IsLoaded() then game.Loaded:Wait() end
    
    -- Đợi Player và Character tồn tại
    repeat task.wait() until game.Players.LocalPlayer
    local Player = game.Players.LocalPlayer
    repeat task.wait() until Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    
    -- Đợi hệ thống Remote của game sẵn sàng
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 30)
    local CommF = Remotes:WaitForChild("CommF_", 30)

    if not CommF then 
        Status.Text = "❌ Remote Not Found!"
        return 
    end

    -- Kiểm tra Sea và Travel
    if SEAS.SEA1[PlaceId] then
        Status.Text = "📍 Sea 1 -> Travel to Sea 2"
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(3) -- Đợi 3 giây ổn định trước khi bay
        CommF:InvokeServer("TravelDressrosa")
    elseif SEAS.SEA2[PlaceId] then
        Status.Text = "📍 Sea 2 -> Travel to Sea 3"
        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(3)
        CommF:InvokeServer("TravelZou")
    elseif SEAS.SEA3[PlaceId] then
        Status.Text = "✅ Already in Sea 3"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        Status.Text = "❌ Unknown Place ID: " .. PlaceId
    end
end)
