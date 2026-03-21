-- [[ VU NGUYEN - ONLY DETECT SEA, TRAVEL & UI ]]

local SEAS = {
    ["SEA1"] = {["2753915549"] = true, ["85211729168715"] = true},
    ["SEA2"] = {["4442272183"] = true, ["79091703265657"] = true},
    ["SEA3"] = {["7449423635"] = true, ["100117331123089"] = true}
}

local PlaceId = tostring(game.PlaceId)

-- [ UI MINI GÓC TRÁI TRÊN CÙNG ]
local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 180, 0, 35)
Main.Position = UDim2.new(0, 10, 0, 10)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 4)

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 1, 0)
Status.Text = "Checking Sea..."
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.BackgroundTransparency = 1
Status.Font = Enum.Font.GothamBold
Status.TextSize = 11

-- [ LOGIC TRAVEL ]
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

    if SEAS.SEA1[PlaceId] then
        Status.Text = "Sea 1 -> Traveling to Sea 2"
        task.wait(2)
        CommF:InvokeServer("TravelDressrosa")
    elseif SEAS.SEA2[PlaceId] then
        Status.Text = "Sea 2 -> Traveling to Sea 3"
        task.wait(2)
        CommF:InvokeServer("TravelZou")
    elseif SEAS.SEA3[PlaceId] then
        Status.Text = "✅ Already in Sea 3"
        Status.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        Status.Text = "❌ Unknown Place ID"
    end
end)
