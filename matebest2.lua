-- ==========================================
-- CHECK LEVIATHAN CRAFT MATERIALS
-- ==========================================
local Player = game.Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes", 30):WaitForChild("CommF_", 30)

local MATERIALS = {
    {"Leviathan Scale", 20},
    {"Electric Wing", 6},
    {"Mutant Tooth", 2},
    {"Fool's Gold", 30},
    {"Shark Tooth", 6},
}

-- ==========================================
-- UI
-- ==========================================
local SafeGuiParent = pcall(function() return gethui() end) and gethui()
    or CoreGui:FindFirstChild("RobloxGui") or CoreGui

if SafeGuiParent:FindFirstChild("LeviMatUI") then
    SafeGuiParent.LeviMatUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LeviMatUI"
ScreenGui.Parent = SafeGuiParent
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 240, 0, 195)
MainFrame.Position = UDim2.new(1, -250, 0.5, -97)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(0, 180, 255)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 28)
Title.Text = "Leviathan Materials"
Title.TextColor3 = Color3.fromRGB(0, 180, 255)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13

local Line = Instance.new("Frame", MainFrame)
Line.Size = UDim2.new(1, -16, 0, 1)
Line.Position = UDim2.new(0, 8, 0, 28)
Line.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Line.BorderSizePixel = 0

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -16, 0, 16)
StatusLabel.Position = UDim2.new(0, 8, 0, 32)
StatusLabel.Text = "🔍 Đang check..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Material labels
local matLabels = {}
local yPos = 52
for i, data in ipairs(MATERIALS) do
    local l = Instance.new("TextLabel", MainFrame)
    l.Size = UDim2.new(1, -16, 0, 22)
    l.Position = UDim2.new(0, 8, 0, yPos)
    l.BackgroundTransparency = 1
    l.Text = "📦 " .. data[1] .. ": .../" .. data[2]
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    matLabels[i] = l
    yPos = yPos + 25
end

-- ==========================================
-- CHECK FUNCTIONS
-- ==========================================
local function GetInventory()
    local ok, inv = pcall(function() return CommF:InvokeServer("getInventory") end)
    if ok and type(inv) == "table" then return inv end
    return {}
end

local function GetMaterialCount(matName, inv)
    -- Check Character
    local chr = Player.Character
    if chr and chr:FindFirstChild(matName) then return 1 end
    -- Check Backpack
    local bp = Player:FindFirstChild("Backpack")
    if bp and bp:FindFirstChild(matName) then return 1 end
    -- Check Inventory
    for _, item in pairs(inv) do
        if type(item) == "table" and item.Name == matName then
            return item.Count or 1
        end
    end
    return 0
end

local function CheckAll()
    local inv = GetInventory()
    local allDone = true

    for i, data in ipairs(MATERIALS) do
        local name, needed = data[1], data[2]
        local count = GetMaterialCount(name, inv)
        local label = matLabels[i]
        local ok = count >= needed

        label.Text = string.format("📦 %s: %d/%d %s", name, count, needed, ok and "✅" or "")
        label.TextColor3 = ok and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 100)

        if not ok then allDone = false end
    end

    if allDone then
        StatusLabel.Text = "✅ ĐỦ TẤT CẢ NGUYÊN LIỆU!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        StatusLabel.Text = "❌ Chưa đủ nguyên liệu"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    end

    return allDone
end

-- ==========================================
-- AUTO CHECK LOOP (mỗi 10s)
-- ==========================================
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    while ScreenGui.Parent do
        CheckAll()
        task.wait(10)
    end
end)

print("[LeviMat] ✅ Loaded | Auto check mỗi 10s")
