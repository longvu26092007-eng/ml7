-- [[ CONFIG AREA ]]
getgenv().Team = "Pirates" 

-- [[ DRAGO HUB V2 - SPEED OPTIMIZED ]]

-- ==========================================
-- CHỌN TEAM (style V3 - autobuydraco)
-- ==========================================
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")

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
local SEA_2_MAIN = "4442272183"
local SEA_2_OLD = "79091703265657"

-- Hệ thống lưu trữ file
local FolderName = "DragoHubV2_" .. Player.Name
local FileName = FolderName .. "/Spawn.txt"
local FangFileName = FolderName .. "/VampireFang.txt"

local function CheckSpawnDone()
    if isfolder(FolderName) and isfile(FileName) then
        return readfile(FileName) == "Spawn:Done"
    end
    return false
end

-- ==========================================
-- GIAO DIỆN MONITOR (VÀNG - ĐEN)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 450, 0, 150)
MainFrame.Position = UDim2.new(0.5, -225, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "VuNguyen_Software - Kaitun V1"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

-- Cột Trái: Trạng thái Sea & Spawn
local LeftPanel = Instance.new("Frame", MainFrame)
LeftPanel.Size = UDim2.new(0.5, -15, 1, -50)
LeftPanel.Position = UDim2.new(0, 10, 0, 40)
LeftPanel.BackgroundTransparency = 1

local SpawnLabel = Instance.new("TextLabel", LeftPanel)
SpawnLabel.Size = UDim2.new(1, 0, 0, 30)
local isDone = CheckSpawnDone()
SpawnLabel.Text = "Spawn: " .. (isDone and "Done" or "Not Done")
SpawnLabel.TextColor3 = isDone and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
SpawnLabel.Font = Enum.Font.GothamBold
SpawnLabel.BackgroundTransparency = 1
SpawnLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Cột Phải: Materials Tracker
local RightPanel = Instance.new("Frame", MainFrame)
RightPanel.Size = UDim2.new(0.5, -15, 1, -50)
RightPanel.Position = UDim2.new(0.5, 5, 0, 40)
RightPanel.BackgroundTransparency = 1
Instance.new("UIListLayout", RightPanel).Padding = UDim.new(0, 2)

local function GetMaterialCount(matName)
    local success, inventory = pcall(function() return services.CommF:InvokeServer("getInventory") end)
    if success and type(inventory) == "table" then
        for _, item in ipairs(inventory) do
            if item.Name == matName then return item.Count end
        end
    end
    return 0
end

local function UpdateMaterials()
    local success, inventory = pcall(function() return services.CommF:InvokeServer("getInventory") end)
    RightPanel:ClearAllChildren()
    Instance.new("UIListLayout", RightPanel).Padding = UDim.new(0, 2)
    if success and type(inventory) == "table" then
        local MaterialChecks = {{"Demonic Wisp", 20}, {"Vampire Fang", 20}, {"Dark Fragment", 2}}
        for _, data in ipairs(MaterialChecks) do
            local count = 0
            for _, item in ipairs(inventory) do if item.Name == data[1] then count = item.Count break end end
            local mLabel = Instance.new("TextLabel", RightPanel)
            mLabel.Size = UDim2.new(1, 0, 0, 20)
            mLabel.BackgroundTransparency = 1
            mLabel.Text = string.format("📦 %s: %d/%d", data[1], count, data[2])
            mLabel.TextColor3 = (count >= data[2]) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 255)
            mLabel.Font = Enum.Font.Gotham
            mLabel.TextSize = 11
            mLabel.TextXAlignment = Enum.TextXAlignment.Right
        end
    end
end
task.spawn(function() while task.wait(10) do UpdateMaterials() end end)

-- ==========================================
-- CHỨC NĂNG MỚI: GIÁM SÁT & CHECK FILE ĐỂ CHẠY getSA
-- ==========================================
task.spawn(function()
    local fangDone = false

    -- 1. Vòng lặp liên tục đọc file txt (Chờ xem file có báo "Đã Done" không)
    task.spawn(function()
        while not fangDone do
            if isfolder(FolderName) and isfile(FangFileName) then
                if readfile(FangFileName) == "Đã Done" then
                    print("[Hệ Thống] Phát hiện file ghi nhận Đã Done. Tiến hành chạy Sanguine Art Script...")
                    loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
                    fangDone = true
                    break
                end
            end
            task.wait(1)
        end
    end)

    -- 2. Vòng lặp đếm lượng Fang thực tế trong kho đồ (Check đột biến)
    while not fangDone do
        local fangCount = GetMaterialCount("Vampire Fang")
        
        local currentFileContent = ""
        if isfolder(FolderName) and isfile(FangFileName) then
            currentFileContent = readfile(FangFileName)
        end

        if currentFileContent:match("VampireFang:(%d+)/20") then
            local lastRecordedCount = tonumber(currentFileContent:match("VampireFang:(%d+)/20"))
            if lastRecordedCount >= 18 and fangCount == 0 then
                writefile(FangFileName, "Đã Done")
                print("[Hệ Thống] Phát hiện Vampire Fang tụt từ >=18 về 0 (Đã Active). Tiến hành chạy Sanguine Art!")
                break
            end
        end
        
        if fangCount >= 20 then
            if not isfolder(FolderName) then makefolder(FolderName) end
            writefile(FangFileName, "Đã Done")
            print("[Hệ Thống] Vampire Fang đã đạt 20/20. Đã lưu trạng thái vào file!")
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
-- HÀM CHẠY 2 SCRIPT FARM BOSS
-- DragonHub trước → 5s → BananaHub
-- ==========================================
local function RunBossScripts()
    -- Chạy DragonHub TRƯỚC
    task.spawn(function()
        getgenv().SettingFarm = { ["Team"] = getgenv().Team or "Pirates", ["Boss"] = "Darkbread", ["FPS"] = "false" }
        loadstring(game:HttpGet("https://raw.githubusercontent.com/luacoder-byte/DragonHub/refs/heads/main/KaitunBoss.lua"))()
    end)

    -- 5 GIÂY SAU → BananaHub
    task.wait(5)

    task.spawn(function()
        getgenv().Key = "1f34f32b6f1917a66d57e8c6" 
        getgenv().NewUI = true
        getgenv().Config = {["Attack Darkbeard"] = true, ["Hop Find Darkbeard"] = true}
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
end

-- ==========================================
-- LOGIC ĐIỀU HƯỚNG SCRIPT (TỐI ƯU TỐC ĐỘ)
-- ==========================================
task.spawn(function()
    -- KIỂM TRA FILE ĐÃ DONE NGAY TỪ ĐẦU
    if isfolder(FolderName) and isfile(FangFileName) then
        if readfile(FangFileName) == "Đã Done" then
            SpawnLabel.Text = "Status: Fast Run SA!"
            SpawnLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[Hệ Thống] Đầu vào quét thấy file Đã Done. Chạy getSA và bỏ qua các logic khác!")
            loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
            return
        end
    end

    -- PHẦN CHECK MATERIAL SIÊU TỐC
    SpawnLabel.Text = "Status: Fast Checking..."
    local darkFragCount = GetMaterialCount("Dark Fragment")

    if darkFragCount >= 2 then
        SpawnLabel.Text = "Status: Material 2/2! Running Farm..."
        SpawnLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        
        -- [SỬA 3] Chạy Ultimax Radar TRƯỚC
        task.spawn(function()
            loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/27187e5ea4ba15fbffa2168b5e85bc84/raw/c726ae806cc5e9c78a865949f29d669ec5ce8dfe/ultimaxradar"))()
        end)

        -- 5 giây sau → BananaHub farm Vampire Fang
        task.wait(5)

        task.spawn(function()
            getgenv().Key = "51e126ee832d3c4fff7b6178" 
            getgenv().NewUI = true
            getgenv().Config = {
                ["Select Material"] = "Vampire Fang",
                ["Farm Material"] = true,
                ["Start Farm"] = true,
                ["Hop Sever"] = true
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
        end)
        
        return 
    end

    -- LOGIC SĂN BOSS (Chạy ngay nếu không đủ đá)
    if PlaceId == SEA_2_OLD then
        if CheckSpawnDone() then
            task.wait(1)
            repeat wait() until game:IsLoaded() and game.Players.LocalPlayer 
            
            -- [SỬA 2] DragonHub trước → 5s → BananaHub
            RunBossScripts()
            
        else
            -- Bay lưu spawn (Tween nhanh hơn: 400)
            local targetCFrame = CFrame.new(933.2, 41.5, -5045.3) 
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                SpawnLabel.Text = "Spawn: Moving Fast..."
                local dist = (hrp.Position - targetCFrame.Position).Magnitude
                local tween = services.TweenService:Create(hrp, TweenInfo.new(dist / 400, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                tween:Play()
                tween.Completed:Connect(function()
                    task.wait(1)
                    services.CommF:InvokeServer("SetSpawnPoint")
                    if not isfolder(FolderName) then makefolder(FolderName) end
                    writefile(FileName, "Spawn:Done")
                    SpawnLabel.Text = "Spawn: Done"
                    
                    -- [SỬA 2] DragonHub trước → 5s → BananaHub
                    RunBossScripts()
                end)
            end
        end
    elseif PlaceId == SEA_2_MAIN then
        task.wait(1)
        
        -- [SỬA 2] DragonHub trước → 5s → BananaHub
        RunBossScripts()
        
    else
        local OTHER = {["2753915549"] = true, ["85211729168715"] = true, ["7449423635"] = true, ["100117331123089"] = true}
        if OTHER[PlaceId] then task.wait(1) services.CommF:InvokeServer("TravelDressrosa") end
    end
end)

-- ALT to Toggle & Drag (Giữ nguyên)
services.UserInputService.InputBegan:Connect(function(input, gpe) if not gpe and input.KeyCode == Enum.KeyCode.LeftAlt then MainFrame.Visible = not MainFrame.Visible end end)
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = MainFrame.Position end end)
services.UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
services.UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
