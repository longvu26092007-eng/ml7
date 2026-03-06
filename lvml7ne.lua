-- [[ VU NGUYEN KAITUN LEVI - MULTI-SCRIPT SUPPORT ]]
-- Chức năng: AUTO TEAM -> AUTO BUY DRAGON TALON -> WAIT 15S -> AUTO SEA 3 -> DETECT OWNER -> AUTO KICK

-- [[ CONFIG AREA ]]
getgenv().Team = getgenv().Team or "Marines"

-- ==========================================
-- [ PHẦN 0 : CHỌN TEAM & ĐỢI GAME LOAD ]
-- ==========================================
if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until game.Players.LocalPlayer
repeat task.wait() until game.Players.LocalPlayer:FindFirstChild("PlayerGui")
if game.Players.LocalPlayer.Team == nil then
    repeat
        task.wait()
        for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                pcall(function()
                    local teamBtn = v.ChooseTeam.Container[getgenv().Team].Frame.TextButton
                    teamBtn.Size     = UDim2.new(0, 10000, 0, 10000)
                    teamBtn.Position = UDim2.new(-4, 0, -5, 0)
                    teamBtn.BackgroundTransparency = 1
                    task.wait(0.5)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,true,game,1)
                    task.wait(0.05)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(0,0,0,false,game,1)
                    task.wait(0.05)
                end)
            end
        end
    until game.Players.LocalPlayer.Team ~= nil and game:IsLoaded()
    task.wait(3)
end
repeat task.wait() until game.Players.LocalPlayer.Character
    and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
task.wait(2)

-- [[ SECURITY & SERVICES ]]
local success, services = pcall(function()
    return {
        UserInputService = game:GetService("UserInputService"),
        TweenService = game:GetService("TweenService"),
        RunService = game:GetService("RunService"),
        CoreGui = game:GetService("CoreGui"),
        Players = game:GetService("Players"),
        ReplicatedStorage = game:GetService("ReplicatedStorage"),
        CommF = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")
    }
end)

if not success then return end

local Player = services.Players.LocalPlayer
local PlaceId = tostring(game.PlaceId)

local SEA_1 = {["2753915549"] = true, ["85211729168715"] = true}
local SEA_2 = {["4442272183"] = true, ["79091703265657"] = true}
local SEA_3 = {["7449423635"] = true, ["100117331123089"] = true}

-- ==========================================
-- [ DRAGON TALON - CHECK & BUY ]
-- ==========================================
local Uzoth_CFrame = CFrame.new(5661.898, 1210.877, 863.176)

local function CheckDragonTalon()
    local char = Player.Character
    local bp = Player:FindFirstChild("Backpack")
    return (char and char:FindFirstChild("Dragon Talon"))
        or (bp and bp:FindFirstChild("Dragon Talon"))
end

local function TweenTo(targetCFrame)
    local char = Player.Character or Player.CharacterAdded:Wait()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance <= 250 then
        hrp.CFrame = targetCFrame
        return true
    end

    local bv = hrp:FindFirstChild("LeviAntiGrav") or Instance.new("BodyVelocity")
    bv.Name = "LeviAntiGrav"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local tweenObj = services.TweenService:Create(hrp, TweenInfo.new(distance / 300, Enum.EasingStyle.Linear), {CFrame = targetCFrame})

    local noclip
    noclip = services.RunService.Stepped:Connect(function()
        if hum and hum.Parent then hum:ChangeState(11) end
        if char and char.Parent then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)

    tweenObj:Play()
    tweenObj.Completed:Wait()

    if bv and bv.Parent then bv:Destroy() end
    if noclip then noclip:Disconnect() end

    if hum and hum.Parent and hum.Health > 0 then
        hum:ChangeState(8)
        return true
    end
    return false
end

local function DoBuyDragonTalon()
    pcall(function()
        local check = services.CommF:InvokeServer("BuyDragonTalon", true)
        if check == 3 then
            services.CommF:InvokeServer("Bones", "Buy", 1, 1)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon", true)
        elseif check == 1 then
            services.CommF:InvokeServer("BuyDragonTalon")
        else
            services.CommF:InvokeServer("Bones", "Buy", 1, 1)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon", true)
            task.wait(0.3)
            services.CommF:InvokeServer("BuyDragonTalon")
        end
    end)
end

-- ==========================================
-- MONITOR UI (RIGHT SIDE - GOLD/BLACK)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 260, 0, 160)
MainFrame.Position = UDim2.new(1, -270, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(255, 200, 0)
Instance.new("UICorner", MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "VuNguyen Levi Multi-System"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 60)
StatusLabel.Position = UDim2.new(0, 10, 0, 40)
StatusLabel.Text = "Team: " .. tostring(Player.Team) .. " ✅"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextWrapped = true

-- ==========================================
-- LOGIC: BUY DRAGON TALON → WAIT 15S → SEA → DETECT
-- ==========================================
task.spawn(function()

    -- ========================================
    -- BƯỚC 0: CHECK & MUA DRAGON TALON
    -- ========================================
    if CheckDragonTalon() then
        StatusLabel.Text = "Dragon Talon: ✅ Đã có\nTiếp tục..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        warn("[Levi] Dragon Talon đã có, bỏ qua.")
        task.wait(1)
    else
        -- Chưa có → bay đến mua
        local maxRetry = 5
        for attempt = 1, maxRetry do
            if CheckDragonTalon() then break end

            StatusLabel.Text = "Dragon Talon: ❌ Chưa có\nĐang bay đến NPC... (" .. attempt .. "/" .. maxRetry .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            warn("[Levi] Chưa có Dragon Talon, bay đến NPC (lần " .. attempt .. ")")

            local arrived = TweenTo(Uzoth_CFrame)
            if arrived then
                StatusLabel.Text = "Dragon Talon: Đang mua..."
                task.wait(0.5)
                DoBuyDragonTalon()
                task.wait(1)

                if CheckDragonTalon() then
                    StatusLabel.Text = "Dragon Talon: ✅ Mua thành công!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    warn("[Levi] Mua Dragon Talon thành công!")
                    task.wait(1)
                    break
                else
                    StatusLabel.Text = "Dragon Talon: Mua thất bại, thử lại..."
                    warn("[Levi] Mua thất bại, retry...")
                end
            else
                StatusLabel.Text = "Dragon Talon: Bay thất bại, thử lại..."
            end
            task.wait(3)
        end

        -- Nếu sau max retry vẫn chưa có
        if not CheckDragonTalon() then
            StatusLabel.Text = "Dragon Talon: ⚠ Không mua được!\nTiếp tục script..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            warn("[Levi] Không mua được Dragon Talon sau " .. maxRetry .. " lần. Tiếp tục.")
            task.wait(2)
        end
    end

    -- ========================================
    -- BƯỚC 1: ĐỢI 15 GIÂY TRƯỚC KHI CHECK SEA
    -- ========================================
    for i = 15, 1, -1 do
        StatusLabel.Text = "Waiting before Sea check: " .. i .. "s"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(1)
    end

    -- BƯỚC 2: KIỂM TRA VÀ CHUYỂN SEA
    if SEA_1[PlaceId] then
        StatusLabel.Text = "Sea 1 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelDressrosa")
        return
    elseif SEA_2[PlaceId] then
        StatusLabel.Text = "Sea 2 Detected. Traveling to Sea 3..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 165, 0)
        task.wait(1)
        services.CommF:InvokeServer("TravelZou")
        return
    end

    -- BƯỚC 3: LOGIC QUÉT OWNER (CHỈ CHẠY TẠI SEA 3)
    if SEA_3[PlaceId] then
        local function GetOwnerInServer()
            for _, p in ipairs(services.Players:GetPlayers()) do
                local name = p.Name:lower()
                if name == "nlvrblx" or name == "nhkyqqox" or name == "minkawai2007" then 
                    return p.Name 
                end
            end
            return nil
        end

        if Player.Name:lower() ~= "nlvrblx" and Player.Name:lower() ~= "minkawai2007" then
            local foundOwner = nil
            local timeLeft = 20
            
            while timeLeft > 0 do
                foundOwner = GetOwnerInServer()
                if foundOwner then break end
                
                StatusLabel.Text = string.format("Scanning for Owner...\nTime left: %ds", timeLeft)
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                
                task.wait(2)
                timeLeft = timeLeft - 2
            end
            
            if foundOwner then
                StatusLabel.Text = "Owner Found: " .. foundOwner .. "\nExecuting Leviathan Script..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                
                getgenv().Key = "51e126ee832d3c4fff7b6178"
                getgenv().Config = {
                    ["Select Owner Boat Beast Hunter"] = foundOwner,
                    ["Auto light the torch"] = true,
                    ["No Frog"] = true,
                    ["Boost Fps"] = true,
                    ["Start Hunt Leviathan"] = true
                }
                loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()

                -- ========================================
                -- CHECK LEVIATHAN HEART (CHỈ ACC KHÁCH)
                -- ========================================
                task.spawn(function()
                    warn("[Levi] Bắt đầu check Leviathan Heart...")
                    while task.wait(5) do
                        local heartCount = 0
                        pcall(function()
                            local inv = services.CommF:InvokeServer("getInventory")
                            if type(inv) == "table" then
                                for _, item in ipairs(inv) do
                                    if item.Name == "Leviathan Heart" then
                                        heartCount = item.Count or 1
                                        break
                                    end
                                end
                            end
                        end)

                        -- Check trong Backpack + Character nữa
                        if heartCount == 0 then
                            pcall(function()
                                local bp = Player:FindFirstChild("Backpack")
                                local chr = Player.Character
                                if (bp and bp:FindFirstChild("Leviathan Heart"))
                                    or (chr and chr:FindFirstChild("Leviathan Heart")) then
                                    heartCount = 1
                                end
                            end)
                        end

                        if heartCount >= 1 then
                            StatusLabel.Text = "💎 Leviathan Heart: " .. heartCount .. " → Ghi file!"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            warn("[Levi] Phát hiện Leviathan Heart x" .. heartCount .. "! Ghi file...")

                            pcall(function()
                                writefile(Player.Name .. ".txt", "Completed-heart")
                            end)
                            warn("[Levi] Đã ghi file: " .. Player.Name .. ".txt → Completed-heart")

                            StatusLabel.Text = "✅ Completed-heart!\n📄 " .. Player.Name .. ".txt"
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            break
                        end
                    end
                end)
            else
                StatusLabel.Text = "No Owner detected. Auto Kicking..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                task.wait(2)
                Player:Kick("Không tìm thấy chủ tàu sau 20s quét.")
            end
        else
            StatusLabel.Text = "Main Account Mode Active.\nWaiting 120s before execute..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
            
            for i = 190, 1, -1 do
                StatusLabel.Text = string.format("Owner Mode: Waiting %d:%02d before execute...", math.floor(i/60), i%60)
                StatusLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
                task.wait(1)
            end
            
            StatusLabel.Text = "Owner Mode: Loading Leviathan Script..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            getgenv().Key = "51e126ee832d3c4fff7b6178"
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaCat-KaitunLevi.lua"))()
        end
    end
end)

-- Drag System
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true dragStart = input.Position startPos = MainFrame.Position end end)
services.UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
services.UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
