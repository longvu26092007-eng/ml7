-- [[ CONFIG AREA ]]
getgenv().Team = "Pirates"

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
MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -65)
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

-- Materials
local MatFrame = Instance.new("Frame", MainFrame)
MatFrame.Size = UDim2.new(1, -20, 0, 60)
MatFrame.Position = UDim2.new(0, 10, 0, 56)
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

StatusLabel.Text = "Status: Checking SA..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
print("[VFAndSA P1] ✅ Loaded | LeftAlt ẩn/hiện")

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
    task.wait(1) -- đợi character load
    local meleeName, isHolding = GetEquippedMelee()
    currentMelee = meleeName

    if meleeName ~= "None" then
        local holdText = isHolding and " (đang cầm)" or " (trong BP)"
        print("[P0.5] Melee: " .. meleeName .. holdText)
    else
        print("[P0.5] Không tìm thấy Melee nào")
    end
end)
