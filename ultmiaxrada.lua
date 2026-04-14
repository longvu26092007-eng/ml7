--[[
    RADAR ULTIMATE - FIXED BY GEMINI
    - Quét liên tục mỗi 2 giây.
    - Random: 10s, 25s, 40s, 60s, 80s (Đã fix lỗi lặp số).
]]

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local coreGui = game:GetService("CoreGui")

-- LÀM MỚI HẠT GIỐNG NGẪU NHIÊN
math.randomseed(os.time() + tick())

-- CẤU HÌNH
local DETECT_RADIUS = 700
local SCAN_INTERVAL = 2 

-- URL SCRIPT HOP CỦA VŨ (ĐÃ SỬA CHUỖI)
local hopURL = "https://raw.githubusercontent.com/longvu26092007-eng/Uiaauiaa/refs/heads/main/hopsever.lua"

-- XÓA GUI CŨ
if coreGui:FindFirstChild("RadarRandomFix_System") then
    coreGui.RadarRandomFix_System:Destroy()
end

-- TẠO GIAO DIỆN (GUI)
local sg = Instance.new("ScreenGui", coreGui)
sg.Name = "RadarRandomFix_System"

local mainFrame = Instance.new("Frame", sg)
mainFrame.Size = UDim2.new(0, 230, 0, 65)
mainFrame.Position = UDim2.new(0.5, -115, 0.05, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(0, 255, 120)
stroke.Thickness = 1.8

local statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.Size = UDim2.new(1, 0, 0, 30); statusLabel.Position = UDim2.new(0, 0, 0, 5)
statusLabel.BackgroundTransparency = 1; statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14; statusLabel.Text = "🛡️ RADAR: READY"; statusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)

local distLabel = Instance.new("TextLabel", mainFrame)
distLabel.Size = UDim2.new(1, 0, 0, 20); distLabel.Position = UDim2.new(0, 0, 0, 32)
distLabel.BackgroundTransparency = 1; distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 11; distLabel.Text = "Đang quét bãi farm (2s)..."; distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)

-- HÀM KIỂM TRA NGƯỜI LẠ
local function GetNearbyPlayer()
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = char.HumanoidRootPart.Position
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if not lp:IsFriendsWith(p.UserId) then
                local dist = (myPos - p.Character.HumanoidRootPart.Position).Magnitude
                if dist <= DETECT_RADIUS then return p, math.floor(dist) end
            end
        end
    end
    return nil
end

-- HÀM LẤY THỜI GIAN CHỜ NGẪU NHIÊN
local function GetRandomWaitTime()
    local times = {30, 40, 53, 68, 75}
    return times[math.random(1, #times)]
end

-- VÒNG LẶP XỬ LÝ
task.spawn(function()
    while true do
        local intruder, distance = GetNearbyPlayer()

        if intruder then
            -- Chọn một thời gian ngẫu nhiên ngay khi phát hiện
            local chosenWaitTime = GetRandomWaitTime()
            local startDetectionTime = tick()
            
            mainFrame.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
            stroke.Color = Color3.fromRGB(255, 50, 50)
            statusLabel.TextColor3 = Color3.new(1, 1, 1)

            -- Vòng lặp kiểm tra 2 giây/lần trong lúc đợi
            while true do
                local currentIntruder, currentDist = GetNearbyPlayer()
                
                if not currentIntruder then
                    -- Người lạ đã đi -> Hủy
                    break 
                end

                local elapsed = tick() - startDetectionTime
                if elapsed >= chosenWaitTime then
                    -- ĐÃ HẾT THỜI GIAN ĐỢI -> NHẢY SERVER (ĐÃ SỬA)
                    statusLabel.Text = "🚀 ĐANG NHẢY SERVER..."
                    pcall(function() 
                        loadstring(game:HttpGet(hopURL))() 
                    end)
                    return -- Dừng script này để teleport
                end

                local remaining = math.ceil(chosenWaitTime - elapsed)
                statusLabel.Text = "⚠️ PHÁT HIỆN: " .. currentIntruder.Name
                distLabel.Text = "Cách " .. currentDist .. "m - Né sau: " .. remaining .. "s"
                
                task.wait(2) 
            end

            -- Nếu thoát vòng lặp nhỏ mà chưa teleport nghĩa là người lạ đã đi
            mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            stroke.Color = Color3.fromRGB(0, 255, 120)
            statusLabel.Text = "Bị Vũ Nguyễn Đuổi Đi Thành Công"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            distLabel.Text = "Người lạ đã rời đi - Hủy lệnh Hop"
        else
            -- AN TOÀN
            mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            stroke.Color = Color3.fromRGB(0, 255, 120)
            statusLabel.Text = "Bị Vũ Nguyễn Đuổi Đi Thành Công"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            distLabel.Text = "Bãi farm hiện đang trống"
        end

        task.wait(SCAN_INTERVAL)
    end
end)
