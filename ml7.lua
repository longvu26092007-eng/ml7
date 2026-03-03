-- [[ CONFIG AREA ]]
getgenv().Team = "Pirates" -- Marines

-- [[ DRAGO HUB V3 - SIMPLIFIED ]]
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")

-- ==========================================
-- CHỌN TEAM (style autobuydraco)
-- ==========================================
if game:GetService("Players").LocalPlayer.Team == nil then
    repeat task.wait()
        for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Size = UDim2.new(0, 10000, 0, 10000)
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.Position = UDim2.new(-4, 0, -5, 0)
                v.ChooseTeam.Container[getgenv().Team].Frame.TextButton.BackgroundTransparency = 1
                task.wait(.5)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, true, game, 1)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(0, 0, 0, false, game, 1)
                task.wait(0.05)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end

-- ==========================================
-- SERVICES
-- ==========================================
local success, services = pcall(function()
    return {
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        CoreGui = game:GetService("CoreGui"),
        Players = game:GetService("Players"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    }
end)
if not success then return end

local Player = services.Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)

-- File system
local FolderName = "DragoHubV3_" .. Player.Name
local FangFileName = FolderName .. "/VampireFang.txt"

-- ==========================================
-- GIAO DIỆN MONITOR (VÀNG - ĐEN)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
ScreenGui.Name = "DragoHubV3"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 420, 0, 130)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "VuNguyen - Drago Hub V3"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 30)
StatusLabel.Text = "Status: Đang khởi động..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Material labels
local MatFrame = Instance.new("Frame", MainFrame)
MatFrame.Size = UDim2.new(1, -20, 0, 60)
MatFrame.Position = UDim2.new(0, 10, 0, 52)
MatFrame.BackgroundTransparency = 1
Instance.new("UIListLayout", MatFrame).Padding = UDim.new(0, 2)

local matLabels = {}
local MaterialChecks = {
    {"Dark Fragment", 2},
    {"Demonic Wisp", 20},
    {"Vampire Fang", 20}
}

for _, data in ipairs(MaterialChecks) do
    local l = Instance.new("TextLabel", MatFrame)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = "📦 " .. data[1] .. ": .../​" .. data[2]
    l.TextColor3 = Color3.fromRGB(255, 255, 255)
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    matLabels[data[1]] = l
end

-- ==========================================
-- FUNCTIONS
-- ==========================================
local function GetInventory()
    local ok, inv = pcall(function()
        return services.CommF:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then return inv end
    return {}
end

local function GetMaterialCount(inv, matName)
    for _, item in ipairs(inv) do
        if item.Name == matName then return item.Count end
    end
    return 0
end

local function UpdateMaterials()
    local inv = GetInventory()
    for _, data in ipairs(MaterialChecks) do
        local count = GetMaterialCount(inv, data[1])
        local label = matLabels[data[1]]
        if label then
            label.Text = string.format("📦 %s: %d/%d", data[1], count, data[2])
            label.TextColor3 = (count >= data[2]) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
        end
    end
end

-- ==========================================
-- GIÁM SÁT VAMPIRE FANG → CHẠY getSA
-- ==========================================
task.spawn(function()
    local fangDone = false

    -- Check file đã done từ trước
    task.spawn(function()
        while not fangDone do
            if isfolder(FolderName) and isfile(FangFileName) then
                if readfile(FangFileName) == "Đã Done" then
                    print("[DragoV3] File Đã Done → Chạy getSA")
                    loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
                    fangDone = true
                    break
                end
            end
            task.wait(1)
        end
    end)

    -- Monitor fang count
    while not fangDone do
        local inv = GetInventory()
        local fangCount = GetMaterialCount(inv, "Vampire Fang")

        local currentFileContent = ""
        if isfolder(FolderName) and isfile(FangFileName) then
            currentFileContent = readfile(FangFileName)
        end

        -- Detect đột biến: từ >=18 tụt về 0
        if currentFileContent:match("VampireFang:(%d+)/20") then
            local lastCount = tonumber(currentFileContent:match("VampireFang:(%d+)/20"))
            if lastCount >= 18 and fangCount == 0 then
                writefile(FangFileName, "Đã Done")
                print("[DragoV3] Fang tụt >=18 → 0 → Done!")
                break
            end
        end

        if fangCount >= 20 then
            if not isfolder(FolderName) then makefolder(FolderName) end
            writefile(FangFileName, "Đã Done")
            print("[DragoV3] Fang 20/20 → Done!")
            break
        elseif fangCount >= 18 then
            if not isfolder(FolderName) then makefolder(FolderName) end
            writefile(FangFileName, "VampireFang:" .. tostring(fangCount) .. "/20")
            task.wait(0.4)
        else
            task.wait(5)
        end
    end
end)

-- ==========================================
-- LOGIC CHÍNH: LUÔN CHẠY 2 SCRIPT
-- DragonHub trước → 5s sau → BananaHub
-- ==========================================
task.spawn(function()
    -- Check file done → chạy getSA luôn
    if isfolder(FolderName) and isfile(FangFileName) then
        if readfile(FangFileName) == "Đã Done" then
            StatusLabel.Text = "Status: ✅ Đã Done → Chạy getSA!"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
            return
        end
    end

    -- Nếu ở Sea khác → travel về Sea 2
    local SEA_2 = {["4442272183"] = true, ["79091703265657"] = true}
    if not SEA_2[PlaceId] then
        local OTHER = {["2753915549"] = true, ["85211729168715"] = true, ["7449423635"] = true, ["100117331123089"] = true}
        if OTHER[PlaceId] then
            StatusLabel.Text = "Status: 🚀 Travel về Sea 2..."
            services.CommF:InvokeServer("TravelDressrosa")
        end
        return
    end

    -- Update materials 1 lần
    UpdateMaterials()

    -- CHẠY DRAGON HUB TRƯỚC
    StatusLabel.Text = "Status: 🐉 Chạy DragonHub..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)

    task.spawn(function()
        getgenv().SettingFarm = {
            ["Team"] = getgenv().Team or "Pirates",
            ["Boss"] = "Darkbread",
            ["FPS"] = "false"
        }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/luacoder-byte/DragonHub/refs/heads/main/KaitunBoss.lua"))()
    end)

    -- 5 GIÂY SAU → CHẠY BANANA HUB
    task.wait(5)

    StatusLabel.Text = "Status: 🍌 Chạy BananaHub..."
    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)

    task.spawn(function()
        getgenv().Key = "1f34f32b6f1917a66d57e8c6"
        getgenv().NewUI = true
        getgenv().Config = {
            ["Attack Darkbeard"] = true,
            ["Hop Find Darkbeard"] = true
        }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)

    task.wait(2)
    StatusLabel.Text = "Status: ⚔ Đang farm Darkbeard..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
end)

-- Auto update materials
task.spawn(function()
    while task.wait(10) do
        UpdateMaterials()
    end
end)

-- LeftAlt toggle + drag
services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

print("[DragoV3] ✅ Loaded | DragonHub → 5s → BananaHub | LeftAlt ẩn/hiện")
