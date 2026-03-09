-- [[ CONFIG AREA ]]
getgenv().Team = "Pirates"
getgenv().Key = getgenv().Key or "NHAP_KEY_VAO_DAY"

-- ==========================================
-- CHỌN TEAM
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
        CoreGui = game:GetService("CoreGui"),
        Players = game:GetService("Players"),
        CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    }
end)
if not success then return end

local Player = services.Players.LocalPlayer

-- ==========================================
-- FUNCTIONS
-- ==========================================
local function GetInventory()
    local ok, inv = pcall(function() return services.CommF:InvokeServer("getInventory") end)
    if ok and type(inv) == "table" then return inv end
    return {}
end

local function GetMaterialCount(matName, inv)
    if not inv then inv = GetInventory() end
    for _, item in ipairs(inv) do
        if item.Name == matName then return item.Count end
    end
    return 0
end

-- ==========================================
-- UI (XANH DƯƠNG - ĐEN)
-- ==========================================
if services.CoreGui:FindFirstChild("VFAndSA_UI") then
    services.CoreGui.VFAndSA_UI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
ScreenGui.Name = "VFAndSA_UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 175)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -87)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 120, 255)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "VFAndSA Kaitun P1"
Title.TextColor3 = Color3.fromRGB(0, 150, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(1, -20, 0, 1)
Line.Position = UDim2.new(0, 10, 0, 30)
Line.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Line.BorderSizePixel = 0

-- Status
local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 34)
StatusLabel.Text = "Status: Checking..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Melee
local MeleeLabel = Instance.new("TextLabel", MainFrame)
MeleeLabel.Size = UDim2.new(1, -20, 0, 16)
MeleeLabel.Position = UDim2.new(0, 10, 0, 54)
MeleeLabel.Text = "🥊 Melee: Checking..."
MeleeLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
MeleeLabel.BackgroundTransparency = 1
MeleeLabel.Font = Enum.Font.GothamSemibold
MeleeLabel.TextSize = 11
MeleeLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Materials
local MatFrame = Instance.new("Frame", MainFrame)
MatFrame.Size = UDim2.new(1, -20, 0, 78)
MatFrame.Position = UDim2.new(0, 10, 0, 73)
MatFrame.BackgroundTransparency = 1
Instance.new("UIListLayout", MatFrame).Padding = UDim.new(0, 3)

local MaterialChecks = {
    {"Dark Fragment", 2},
    {"Vampire Fang", 20},
    {"Demonic Wisp", 20}
}

local matLabels = {}
for _, data in ipairs(MaterialChecks) do
    local l = Instance.new("TextLabel", MatFrame)
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = "📦 " .. data[1] .. ": .../​" .. data[2]
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    matLabels[data[1]] = l
end

-- Fragment label
local fragL = Instance.new("TextLabel", MatFrame)
fragL.Size = UDim2.new(1, 0, 0, 16)
fragL.BackgroundTransparency = 1
fragL.Text = "💎 Fragment: .../5000"
fragL.TextColor3 = Color3.fromRGB(200, 200, 200)
fragL.Font = Enum.Font.Gotham
fragL.TextSize = 11
fragL.TextXAlignment = Enum.TextXAlignment.Left
matLabels["Fragment"] = fragL

local function UpdateMaterials()
    local inv = GetInventory()
    for _, data in ipairs(MaterialChecks) do
        local count = GetMaterialCount(data[1], inv)
        local label = matLabels[data[1]]
        if label then
            label.Text = string.format("📦 %s: %d/%d", data[1], count, data[2])
            label.TextColor3 = (count >= data[2]) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(200, 200, 200)
        end
    end
    -- Update Fragment
    local fragCount = 0
    pcall(function()
        fragCount = Player.Data.Fragments.Value
    end)
    local fragLabel = matLabels["Fragment"]
    if fragLabel then
        fragLabel.Text = string.format("💎 Fragment: %d/5000", fragCount)
        fragLabel.TextColor3 = (fragCount >= 5000) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(200, 200, 200)
    end
end

-- Update lần đầu + auto mỗi 10s
UpdateMaterials()
task.spawn(function()
    while task.wait(10) do
        UpdateMaterials()
    end
end)

-- LeftAlt toggle
services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

StatusLabel.Text = "Status: Checking Fragment..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
print("[VFAndSA P1] ✅ Loaded | LeftAlt ẩn/hiện")

-- ==========================================
-- CHECK FRAGMENT (trước Phần 0)
-- Dưới 5000 → farm Katakuri | Trên 5000 → tiếp Phần 0
-- ==========================================
local fragmentOk = false

task.spawn(function()
    local fragCount = 0
    pcall(function()
        fragCount = Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Fragments") and Player.Data.Fragments.Value or 0
    end)

    print("[Fragment] Fragments: " .. fragCount .. "/5000")

    if fragCount >= 5000 then
        fragmentOk = true
        StatusLabel.Text = "Fragment: " .. fragCount .. "/5000 ✅"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("[Fragment] Đủ! Tiếp tục Phần 0...")
    else
        StatusLabel.Text = "Fragment: " .. fragCount .. "/5000 → Farm Katakuri..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        print("[Fragment] Chưa đủ! Farm Katakuri...")

        -- Giám sát Fragment mỗi 15s → đủ 5000 → kick
        task.spawn(function()
            while task.wait(15) do
                local currentFrag = 0
                pcall(function()
                    currentFrag = Player.Data.Fragments.Value
                end)
                StatusLabel.Text = "Fragment: " .. currentFrag .. "/5000 | Farming..."

                if currentFrag >= 5000 then
                    StatusLabel.Text = "Fragment: 5000 ✅ KICK!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    print("[Fragment] Đủ 5000! Kick rejoin...")
                    task.wait(2)
                    Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 5000 Fragments!\nRejoin để tiếp tục.")
                    break
                end
            end
        end)

        -- Load BananaHub farm Katakuri
        task.spawn(function()
            getgenv().NewUI = true
            getgenv().Config = {
                ["Select Method Farm"] = "Farm Katakuri",
                ["Hop Find Katakuri"] = true,
                ["Start Farm"] = true,
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
        end)

        return -- Dừng luồng, không vào Phần 0
    end
end)

-- Đợi Fragment check xong trước khi vào Phần 0
repeat task.wait(1) until fragmentOk

-- ==========================================
-- PHẦN 0: CHECK SANGUINE ART STATUS
-- ==========================================
local saActive = false

task.spawn(function()
    local ok, result = pcall(function()
        return services.CommF:InvokeServer("BuySanguineArt", true)
    end)

    if ok then
        if type(result) == "string" and result:lower():find("bring me") then
            -- Chưa active - server yêu cầu materials
            saActive = false
            StatusLabel.Text = "SA: ❌ Chưa active"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            print("[P0] Sanguine Art chưa active. Server:", result)
        else
            -- Đã active (trả về number hoặc không phải "bring me")
            saActive = true
            StatusLabel.Text = "SA: ✅ Đã active! (" .. tostring(result) .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[P0] Sanguine Art đã active! Response:", tostring(result))
        end
    else
        StatusLabel.Text = "SA: ⚠ Lỗi check"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        warn("[P0] Lỗi check SA:", tostring(result))
    end
end)

-- Thêm logic mới ở đây

-- ==========================================
-- PHẦN 0.5: CHECK MELEE ĐANG EQUIP
-- ==========================================
local currentMelee = "None"

local function GetEquippedMelee()
    local char = Player.Character
    local bp = Player:FindFirstChild("Backpack")

    -- Check trong Character (đang cầm)
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                return tool.Name, true -- tên, đang cầm
            end
        end
    end

    -- Check trong Backpack (có nhưng chưa cầm)
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then
                return tool.Name, false -- tên, chưa cầm
            end
        end
    end

    return "None", false
end

task.spawn(function()
    task.wait(1)
    while true do
        local meleeName, isHolding = GetEquippedMelee()
        currentMelee = meleeName

        if meleeName ~= "None" then
            local holdText = isHolding and "cầm" or "BP"
            MeleeLabel.Text = "🥊 Melee: " .. meleeName .. " (" .. holdText .. ")"
            MeleeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            MeleeLabel.Text = "🥊 Melee: Không có"
            MeleeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end

        task.wait(5)
    end
end)

-- ==========================================
-- PHẦN 1: AUTOMATION
-- A. Check SA active → check melee → ghi file hoặc chạy getSA
-- ==========================================
task.spawn(function()
    -- Đợi P0 check SA xong
    repeat task.wait(1) until StatusLabel.Text:find("SA:") and not StatusLabel.Text:find("Checking")

    if not saActive then
        -- ==========================================
        -- PHẦN 1B: SA CHƯA ACTIVE → CHECK NGUYÊN LIỆU
        -- B1. Check Dark Fragment
        -- ==========================================
        print("[P1B] SA chưa active → Check nguyên liệu...")

        local inv = GetInventory()
        local dfCount = GetMaterialCount("Dark Fragment", inv)

        if dfCount >= 2 then
            -- Đủ DF → phần sau (sẽ thêm)
            StatusLabel.Text = "P1B: DF " .. dfCount .. "/2 ✅ → Tiếp..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[P1B] Dark Fragment " .. dfCount .. "/2 → Đủ! Chuyển bước tiếp...")

            -- ==========================================
            -- PHẦN 1C: DF ĐỦ → CHECK VAMPIRE FANG
            -- ==========================================
            local vfCount = GetMaterialCount("Vampire Fang", inv)

            if vfCount >= 20 then
                -- Đủ VF → tiếp P1D
                StatusLabel.Text = "P1C: VF " .. vfCount .. "/20 ✅ → P1D..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                print("[P1C] Vampire Fang " .. vfCount .. "/20 → Đủ! Chuyển P1D...")

                -- ==========================================
                -- PHẦN 1D: VF ĐỦ → CHECK DEMONIC WISP
                -- ==========================================
                local dwCount = GetMaterialCount("Demonic Wisp", inv)

                if dwCount >= 20 then
                    -- Đủ cả 3 materials → check SA lại (vì rejoin sẽ check từ đầu)
                    StatusLabel.Text = "P1D: DW " .. dwCount .. "/20 ✅ Đủ tất cả!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    print("[P1D] Demonic Wisp " .. dwCount .. "/20 → Đủ tất cả materials!")
                else
                    -- Chưa đủ DW → farm Demonic Wisp + Vampire Fang
                    StatusLabel.Text = "P1D: DW " .. dwCount .. "/20 → Farm..."
                    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                    print("[P1D] Demonic Wisp " .. dwCount .. "/20 → Farm!")

                    -- Chạy Ultimax Radar trước 10s
                    task.spawn(function()
                        loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/27187e5ea4ba15fbffa2168b5e85bc84/raw/9562e5bece3c7d0e36cf09938fbe9ed46304cea9/ultimaxradar"))()
                    end)

                    task.wait(10)

                    -- Load BananaHub farm Demonic Wisp
                    task.spawn(function()
                        getgenv().NewUI = true
                        getgenv().Config = {
                            ["Select Material"] = "Demonic Wisp",
                            ["Farm Material"] = true,
                            ["Start Farm"] = true,
                            ["Hop Sever"] = true
                        }
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                    end)

                    -- Giám sát DW + SA Active + Melee (tối ưu: 1 lần gọi inventory)
                    task.spawn(function()
                        while true do
                            local checkInv = GetInventory()
                            local currentDW = GetMaterialCount("Demonic Wisp", checkInv)
                            local currentVF = GetMaterialCount("Vampire Fang", checkInv)
                            local currentDF = GetMaterialCount("Dark Fragment", checkInv)
                            StatusLabel.Text = string.format("P1D: DW %d/20 | VF %d/20 | DF %d/2", currentDW, currentVF, currentDF)

                            -- Check SA Active (mỗi lần loop)
                            local saOk, saResult = pcall(function()
                                return services.CommF:InvokeServer("BuySanguineArt", true)
                            end)
                            if saOk and type(saResult) ~= "string" then
                                saActive = true
                            elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then
                                saActive = true
                            end

                            -- Nếu SA active → kick ngay để rejoin vào P1A
                            if saActive then
                                StatusLabel.Text = "P1D: SA Active! KICK!"
                                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                warn("[P1D] SA đã active trong lúc farm! Kick rejoin...")
                                task.wait(2)
                                Player:Kick("\n[ VFAndSA Kaitun ]\nSanguine Art đã active!\nRejoin để nhận SA.")
                                break
                            end

                            -- Check Melee
                            local meleeName = GetEquippedMelee()
                            currentMelee = meleeName
                            if meleeName ~= "None" then
                                MeleeLabel.Text = "🥊 Melee: " .. meleeName
                                MeleeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            end

                            task.wait(15)
                        end
                    end)
                end

            else
                -- Chưa đủ VF → farm Vampire Fang
                StatusLabel.Text = "P1C: VF " .. vfCount .. "/20 → Farm..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                print("[P1C] Vampire Fang " .. vfCount .. "/20 → Farm!")

                -- Chạy Ultimax Radar trước 10s
                task.spawn(function()
                    loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/27187e5ea4ba15fbffa2168b5e85bc84/raw/9562e5bece3c7d0e36cf09938fbe9ed46304cea9/ultimaxradar"))()
                end)

                task.wait(10)

                -- Giám sát VF mỗi 10s → đủ 20/20 → kick | SA active → kick
                task.spawn(function()
                    while task.wait(10) do
                        local checkInv = GetInventory()
                        local currentVF = GetMaterialCount("Vampire Fang", checkInv)
                        StatusLabel.Text = "P1C: VF " .. currentVF .. "/20 | Farming..."

                        -- Check SA Active
                        local saOk, saResult = pcall(function()
                            return services.CommF:InvokeServer("BuySanguineArt", true)
                        end)
                        if saOk and type(saResult) ~= "string" then
                            saActive = true
                        elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then
                            saActive = true
                        end

                        if saActive then
                            StatusLabel.Text = "P1C: SA Active! KICK!"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            warn("[P1C] SA đã active trong lúc farm VF! Kick rejoin...")
                            task.wait(2)
                            Player:Kick("\n[ VFAndSA Kaitun ]\nSanguine Art đã active!\nRejoin để nhận SA.")
                            break
                        end

                        if currentVF >= 20 then
                            StatusLabel.Text = "P1C: VF 20/20 ✅ KICK!"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            print("[P1C] Vampire Fang đủ 20/20! Kick rejoin...")
                            task.wait(2)
                            Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 20/20 Vampire Fang!\nRejoin để tiếp tục.")
                            break
                        end
                    end
                end)

                -- Load BananaHub farm Vampire Fang
                task.spawn(function()
                    getgenv().NewUI = true
                    getgenv().Config = {
                        ["Select Material"] = "Vampire Fang",
                        ["Farm Material"] = true,
                        ["Start Farm"] = true,
                        ["Hop Sever"] = true
                    }
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)
            end

        else
            -- Chưa đủ DF → farm Darkbeard
            StatusLabel.Text = "P1B: DF " .. dfCount .. "/2 → Farm..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            print("[P1B] Dark Fragment " .. dfCount .. "/2 → Chưa đủ, bật farm Darkbeard!")

            -- Check Sea 2
            local PlaceId = tostring(game.PlaceId)
            local SEA_2 = {["4442272183"] = true, ["79091703265657"] = true}

            if not SEA_2[PlaceId] then
                StatusLabel.Text = "P1B: Travel về Sea 2..."
                services.CommF:InvokeServer("TravelDressrosa")
                return
            end

            -- Giám sát DF mỗi 10s → đủ 2/2 → kick | SA active → kick
            task.spawn(function()
                while task.wait(10) do
                    local checkInv = GetInventory()
                    local currentDF = GetMaterialCount("Dark Fragment", checkInv)
                    StatusLabel.Text = "P1B: DF " .. currentDF .. "/2 | Farming..."

                    -- Check SA Active
                    local saOk, saResult = pcall(function()
                        return services.CommF:InvokeServer("BuySanguineArt", true)
                    end)
                    if saOk and type(saResult) ~= "string" then
                        saActive = true
                    elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then
                        saActive = true
                    end

                    if saActive then
                        StatusLabel.Text = "P1B: SA Active! KICK!"
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        warn("[P1B] SA đã active trong lúc farm DF! Kick rejoin...")
                        task.wait(2)
                        Player:Kick("\n[ VFAndSA Kaitun ]\nSanguine Art đã active!\nRejoin để nhận SA.")
                        break
                    end

                    if currentDF >= 2 then
                        StatusLabel.Text = "P1B: DF 2/2 ✅ KICK!"
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        print("[P1B] Dark Fragment đủ 2/2! Kick rejoin...")

                        pcall(function()
                            writefile(Player.Name .. ".txt", "Completed-df")
                        end)

                        task.wait(2)
                        Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 2/2 Dark Fragment!\nRejoin để tiếp tục.")
                        break
                    end
                end
            end)

            -- Load KaitunBoss farm Darkbeard (tích hợp trực tiếp)
            task.spawn(function()
                local RS = game:GetService("ReplicatedStorage")
                local CollectionService = game:GetService("CollectionService")
                local RunService = game:GetService("RunService")
                local TeleportService = game:GetService("TeleportService")
                local StarterGui = game:GetService("StarterGui")
                local GuiService = game:GetService("GuiService")
                local VIM = game:GetService("VirtualInputManager")
                local COMMF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
                local LocalPlayer = game.Players.LocalPlayer
                local Character = LocalPlayer.Character
                local Humanoid = Character and Character:FindFirstChild("Humanoid")
                local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

                getgenv().Settings = getgenv().Settings or {}
                getgenv().Settings["Max Chests"] = 50
                getgenv().Settings["Reset After Collect Chests"] = 10

                LocalPlayer.CharacterAdded:Connect(function(v)
                    Character = v
                    Humanoid = v:WaitForChild("Humanoid")
                    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
                end)

                repeat task.wait() until Character and HumanoidRootPart and Humanoid

                -- Seed & RemoteAttack
                local remoteAttack, idremote
                local seed = RS.Modules.Net.seed:InvokeServer()
                task.spawn(function()
                    for _, v in next, ({RS.Util, RS.Common, RS.Remotes, RS.Assets, RS.FX}) do
                        for _, n in next, v:GetChildren() do
                            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
                        end
                        v.ChildAdded:Connect(function(n)
                            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
                        end)
                    end
                end)

                local function CheckTool(v)
                    for _, x in next, {LocalPlayer.Backpack, Character} do
                        for _, v2 in next, x:GetChildren() do
                            if v2:IsA("Tool") and (v2.Name == v or v2.Name:find(v)) then return true end
                        end
                    end
                    return false
                end

                local function CheckMonster(...)
                    local args = {...}
                    for _, container in next, {workspace.Enemies, RS} do
                        for _, m in next, container:GetChildren() do
                            if m:IsA("Model") and m.Name ~= "Blank Buddy" then
                                local h = m:FindFirstChild("Humanoid")
                                local r = m:FindFirstChild("HumanoidRootPart")
                                if h and r and h.Health > 0 then
                                    for _, n in next, args do
                                        if m.Name == n or m.Name:lower():find(n:lower()) then return m end
                                    end
                                end
                            end
                        end
                    end
                    return false
                end

                local function EquipWeapon(v)
                    if not Character then return end
                    for _, x in next, LocalPlayer.Backpack:GetChildren() do
                        if x:IsA("Tool") and x.ToolTip == v then Humanoid:EquipTool(x) return end
                    end
                end

                -- FastAttack
                local lastCallFA = tick()
                local function FastAttack(x)
                    if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
                    if tick() - lastCallFA <= 0.01 then return end
                    local t = {}
                    for _, e in next, workspace.Enemies:GetChildren() do
                        local h = e:FindFirstChild("Humanoid")
                        local hrp = e:FindFirstChild("HumanoidRootPart")
                        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then
                            t[#t + 1] = e
                        end
                    end
                    local n = RS.Modules.Net
                    local h = {[2] = {}}
                    for i = 1, #t do
                        local v = t[i]
                        local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
                        if not h[1] then h[1] = part end
                        h[2][#h[2] + 1] = {v, part}
                    end
                    n:FindFirstChild("RE/RegisterAttack"):FireServer()
                    n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
                    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
                        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
                    end), bit32.bxor(idremote+909090, seed*2), unpack(h))
                    lastCallFA = tick()
                end

                -- Tween
                local conn, tw, pp, isTw = nil, nil, nil, false
                local function DoTween(targetCFrame)
                    pcall(function() Character.Humanoid.Sit = false end)
                    if not Character.Humanoid or Character.Humanoid.Health <= 0 then
                        pcall(function() if pp then pp:Destroy() end end)
                        conn, tw, pp, isTw = nil, nil, nil, false
                        return
                    end
                    if targetCFrame == false then
                        if tw then pcall(function() tw:Cancel() end) tw = nil end
                        if conn then conn:Disconnect() conn = nil end
                        if pp then pp:Destroy() pp = nil end
                        isTw = false
                        return
                    end
                    if isTw or not targetCFrame then return end
                    isTw = true
                    local root = Character:FindFirstChild("HumanoidRootPart")
                    if not root then isTw = false return end
                    local distance = (targetCFrame.Position - root.Position).Magnitude
                    pp = Instance.new("Part")
                    pp.Name = "TweenGhost"
                    pp.Transparency = 1
                    pp.Anchored = true
                    pp.CanCollide = false
                    pp.CFrame = root.CFrame
                    pp.Size = Vector3.new(50, 50, 50)
                    pp.Parent = workspace
                    tw = game:GetService("TweenService"):Create(pp, TweenInfo.new(distance / 250, Enum.EasingStyle.Linear), {CFrame = targetCFrame * CFrame.new(0, 5, 0)})
                    conn = RunService.Heartbeat:Connect(function()
                        if root and pp then root.CFrame = pp.CFrame * CFrame.new(0, 5, 0) end
                    end)
                    tw.Completed:Connect(function()
                        if conn then conn:Disconnect() conn = nil end
                        if pp then pp:Destroy() pp = nil end
                        tw = nil
                        isTw = false
                    end)
                    tw:Play()
                end

                -- KillMonster
                local lastKenCall = tick()
                local function KillMonster(x)
                    xpcall(function()
                        for _, container in next, {workspace.Enemies, RS} do
                            for _, v in next, container:GetChildren() do
                                if v.Name == x then
                                    local vh = v:FindFirstChild("Humanoid")
                                    local vhrp = v:FindFirstChild("HumanoidRootPart")
                                    if vh and vh.Health > 0 and vhrp then
                                        local dist = (HumanoidRootPart.Position - vhrp.Position).Magnitude
                                        if dist <= 70 then
                                            FastAttack(x)
                                            if tick() - lastKenCall >= 10 then lastKenCall = tick() RS.Remotes.CommE:FireServer("Ken", true) end
                                            DoTween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                                            EquipWeapon("Melee")
                                            return
                                        end
                                        DoTween(vhrp.CFrame)
                                        return
                                    end
                                end
                            end
                        end
                    end, function(e) warn("KillMonster:", e) end)
                end

                -- HopServer (__ServerBrowser)
                local function IfTableHaveIndex(j) for _ in j do return true end end
                local LSP, CS
                local function GetServers()
                    if LSP and os.time() - LSP < 60 then return CS end
                    for i = 1, 100 do
                        local ok, data = pcall(function()
                            return RS:WaitForChild("__ServerBrowser"):InvokeServer(i)
                        end)
                        if ok and type(data) == "table" and IfTableHaveIndex(data) then
                            LSP = os.time()
                            CS = data
                            return data
                        end
                    end
                    return nil
                end

                local function HopServer()
                    local servers = GetServers()
                    if not servers then return end
                    local arr = {}
                    for jobId, v in pairs(servers) do
                        if type(v) == "table" and jobId ~= game.JobId then
                            table.insert(arr, {JobId = jobId, Players = tonumber(v.Count) or 0})
                        end
                    end
                    for _ = 1, #arr do
                        local idx = math.random(1, #arr)
                        local s = arr[idx]
                        if s and s.Players < 5 then
                            RS:WaitForChild("__ServerBrowser"):InvokeServer('teleport', s.JobId)
                            return
                        end
                    end
                end

                -- PressKeyEvent
                local PressKeyEvent = function(k, d)
                    VIM:SendKeyEvent(true, k, false, game) task.wait(d or 0)
                    VIM:SendKeyEvent(false, k, false, game)
                end

                -- FarmBeli
                local all = 0
                local function FarmBeli()
                    local chests, c = {}, 0
                    if all < getgenv().Settings["Max Chests"] and not CheckTool("Fist of Darkness") then
                        for _, v in next, CollectionService:GetTagged("_ChestTagged") do
                            if v and v.CanTouch then
                                table.insert(chests, {obj = v, dist = (v.Position - HumanoidRootPart.Position).Magnitude})
                            end
                        end
                        table.sort(chests, function(a, b) return a.dist < b.dist end)
                        if not CheckTool("Fist of Darkness") then
                            for i, t in next, chests do
                                local v = t.obj
                                if v:IsA("BasePart") and v.Name:find("Chest") and v.CanTouch then
                                    repeat task.wait()
                                        task.delay(2, function() v.CanTouch = false end)
                                        if Character and Character.Humanoid and Character.Humanoid.Health > 0 then
                                            Character:SetPrimaryPartCFrame(v.CFrame)
                                        end
                                        PressKeyEvent("Space")
                                    until not v.CanTouch or CheckTool("Fist of Darkness")
                                    c += 1; all += 1
                                    if all >= getgenv().Settings["Max Chests"] then HopServer() break
                                    elseif CheckTool("Fist of Darkness") then break
                                    elseif CheckMonster("Darkbeard") then HopServer() break end
                                    if c >= getgenv().Settings["Reset After Collect Chests"] and not CheckTool("Fist of Darkness") then
                                        if Character and Character:FindFirstChildWhichIsA("Humanoid") then
                                            Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
                                        end
                                        c = 0; task.wait(1)
                                    end
                                end
                            end
                        end
                        if not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then HopServer() end
                    end
                end

                -- CheckSea
                local function CheckSea(v)
                    return v == tonumber(workspace:GetAttribute("MAP"):match("%d+"))
                end

                -- WorldsConfig + TeleportSea
                local WorldsConfig = {
                    ["1"] = "TravelMain",
                    ["2"] = "TravelDressrosa",
                    ["3"] = "TravelZou"
                }
                local function TeleportSea(sea, msg)
                    local s = tostring(sea)
                    local target = WorldsConfig[s]
                    if not target then return end
                    pcall(function() print(msg) end)
                    COMMF_:InvokeServer(target)
                end

                -- CheckMaterial
                local function CheckMaterial(x)
                    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
                        if v.Type == "Material" and v.Name == x then return v.Count end
                    end
                    return 0
                end

                -- CheckInventory
                local function CheckInventory(...)
                    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
                        for _, n in next, {...} do if v.Name == n then return true end end
                    end
                    return false
                end

                local hasLeviHeart = CheckInventory("Leviathan Heart")

                -- MAIN LOOP (y như gốc: CheckSea wrapper)
                spawn(function()
                    while task.wait(0.2) do
                        xpcall(function()
                            if CheckSea(2) then
                                DoTween(false)
                                if CheckMonster("Darkbeard") then
                                    for _, container in next, {workspace.Enemies, RS} do
                                        for _, v in next, container:GetChildren() do
                                            if v.Name == "Darkbeard" then
                                                repeat task.wait()
                                                    print("Killing Darkbeard\nHealth: ".. math.floor(v.Humanoid.Health / v.Humanoid.MaxHealth * 100).."%")
                                                    KillMonster(v.Name)
                                                until not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0
                                                DoTween(false)
                                            end
                                        end
                                    end
                                elseif CheckTool("Fist of Darkness") then
                                    local Detection = workspace.Map.DarkbeardArena.Summoner.Detection
                                    DoTween(false)
                                    print("Spawn Darkbeard\nTweening")
                                    DoTween(Detection.CFrame)
                                    if (HumanoidRootPart.Position - Detection.Position).Magnitude <= 200 then
                                        firetouchinterest(Detection, HumanoidRootPart, 0) task.wait(0.2)
                                        firetouchinterest(Detection, HumanoidRootPart, 1)
                                    end
                                else
                                    FarmBeli()
                                end
                            else
                                TeleportSea(2, "Travel to sea 2 for farm Dark Fragments")
                            end
                        end, function(err) warn(err) end)
                    end
                end)

                -- Auto Buso/Geppo/Soru
                task.spawn(function()
                    while task.wait(4) do
                        xpcall(function()
                            if not Character.Humanoid or Character.Humanoid.Health <= 0 then return end
                            if not Character:FindFirstChild("HasBuso") then COMMF_:InvokeServer("Buso") end
                            for _, v in next, {"Buso", "Geppo", "Soru"} do
                                if not CollectionService:HasTag(Character, v) then
                                    if LocalPlayer.Data.Beli.Value >= (v == "Geppo" and 1e4 or v == "Buso" and 2.5e4 or v == "Soru" and 1e5 or 0) then
                                        COMMF_:InvokeServer("BuyHaki", v)
                                    end
                                end
                            end
                        end, function() end)
                    end
                end)

                -- Error handling
                TeleportService.TeleportInitFailed:Connect(function(_, teleportResult, message)
                    if teleportResult == Enum.TeleportResult.IsTeleporting and message:find("previous teleport") then
                        task.delay(10, function() game:Shutdown() end)
                    end
                end)
                GuiService.ErrorMessageChanged:Connect(function()
                    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
                        while true do TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) task.wait(5) end
                    end
                end)
            end)
        end

        return
    end

    -- SA đã active → check melee
    print("[P1] SA đã active! Check melee...")

    -- Check lần đầu
    task.wait(2) -- đợi melee update
    if currentMelee == "Sanguine Art" then
        -- Đang cầm SA → ghi file luôn
        StatusLabel.Text = "P1: ✅ Có SA! Ghi file..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("[P1] Đang cầm Sanguine Art → Ghi file!")

        pcall(function()
            writefile(Player.Name .. ".txt", "Completed-melee")
        end)
        warn("[P1] Đã ghi: " .. Player.Name .. ".txt → Completed-melee")
        StatusLabel.Text = "P1: ✅ Completed-melee!"
        return
    end

    -- Chưa cầm SA → chạy getSA
    StatusLabel.Text = "P1: Chạy getSA..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    print("[P1] Chưa cầm SA → Load getSA script...")

    task.spawn(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
    end)

    -- Loop check melee mỗi 5s chờ cầm SA
    while true do
        task.wait(5)
        local meleeName, isHolding = GetEquippedMelee()
        currentMelee = meleeName

        if meleeName == "Sanguine Art" then
            StatusLabel.Text = "P1: ✅ Có SA! Ghi file..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[P1] Phát hiện Sanguine Art → Ghi file!")

            pcall(function()
                writefile(Player.Name .. ".txt", "Completed-melee")
            end)
            warn("[P1] Đã ghi: " .. Player.Name .. ".txt → Completed-melee")
            StatusLabel.Text = "P1: ✅ Completed-melee!"
            break
        else
            StatusLabel.Text = "P1: Đợi SA... (" .. meleeName .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
end)
