-- ==========================================
-- [ CONFIG AREA ]
-- ==========================================
getgenv().Team = "Pirates"
getgenv().Key = getgenv().Key or "NHAP_KEY_VAO_DAY"
getgenv().Settings = {
    ["Max Chests"] = 45;
    ["Reset After Collect Chests"] = 10;
}

-- ==========================================
-- [ HOP CONFIG - CHỈNH Ở ĐÂY ]
-- ==========================================
getgenv().HOP_CONFIG = {
    MaxPlayers    = 8,       -- Chỉ hop vào server < MaxPlayers người (nil = bỏ qua)
    ForcedRegion  = nil,     -- Ép region: "US", "EU", "AP" (nil = bỏ qua)
    MaxRetries    = 10,      -- Số lần thử tối đa
    RetryDelay    = 1,       -- Giây chờ giữa mỗi lần thử
    CacheDuration = 60,      -- Giây cache danh sách server
    MaxPages      = 100,     -- Số trang tối đa khi lấy danh sách server
}

-- ==========================================
-- [ GAME LOAD - Source_SG Style ]
-- ==========================================
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait(0.5) until game:IsLoaded()
    and game.Players.LocalPlayer
    and game.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui")

task.wait(1) -- chờ executor ổn định, tránh lỗi tab không load

getgenv().cloneref       = cloneref or clonereference or function(x) return x end
getgenv().isnetworkowner = isnetworkowner or isNetworkOwner or function() return true end
workspace = cloneref(workspace) or cloneref(Workspace)
    or (getrenv and (getrenv().workspace or getrenv().Workspace))
    or cloneref(game:GetService("Workspace"))
getfenv = getfenv or _G or _ENV or shared or function() return {} end

-- ==========================================
-- [ SERVICES & GLOBALS ]
-- ==========================================
RunService          = game:GetService("RunService")
TweenService        = game:GetService("TweenService")
HttpService         = game:GetService("HttpService")
Players             = game:GetService("Players")
ReplicatedStorage   = game:GetService("ReplicatedStorage")
Lighting            = game:GetService("Lighting")
CollectionService   = game:GetService("CollectionService")
UserInputService    = game:GetService("UserInputService")
VirtualInputManager = game:GetService("VirtualInputManager")
StarterGui          = game:GetService("StarterGui")
GuiService          = game:GetService("GuiService")
TeleportService     = game:GetService("TeleportService")

COMMF_      = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
LocalPlayer = Players.LocalPlayer
PlaceId, JobId = game.PlaceId, game.JobId

LocalPlayer.CharacterAdded:Connect(function(v)
    Character        = v
    Humanoid         = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)
if LocalPlayer.Character then
    Character        = LocalPlayer.Character
    Humanoid         = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
end

local Player = LocalPlayer

local success, services = pcall(function()
    return {
        UserInputService = UserInputService,
        CoreGui          = game:GetService("CoreGui"),
        Players          = Players,
        CommF            = COMMF_
    }
end)
if not success then return end

-- ==========================================
-- [ CHỌN TEAM - Source_SG Style ]
-- ==========================================
task.spawn(function()
    xpcall(function()
        if not LocalPlayer.Team then
            if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
                repeat task.wait(1) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
            end
            xpcall(function()
                COMMF_:InvokeServer("SetTeam", getgenv().Team)
            end, function()
                firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container[getgenv().Team])
            end)
            task.wait(2)
        end
    end, function(err) warn("????", err) end)
end)

repeat task.wait(2) until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

-- ==========================================
-- [ SOURCE_SG HELPER FUNCTIONS ]
-- ==========================================
function CheckSea(v) return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end

local remoteAttack, idremote
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
task.spawn(function()
    for _, v in next, {ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX} do
        for _, n in next, v:GetChildren() do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remoteAttack, idremote = n, n:GetAttribute("Id")
            end
        end
        v.ChildAdded:Connect(function(n)
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                remoteAttack, idremote = n, n:GetAttribute("Id")
            end
        end)
    end
end)

CheckTool = function(v)
    for _, x in next, {LocalPlayer.Backpack, Character} do
        for _, v2 in next, x:GetChildren() do
            if v2:IsA("Tool") and (v2.Name == v or v2.Name:find(v)) then return true end
        end
    end
    return false
end

CheckMaterial = function(x)
    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
        if v.Type == "Material" then
            if v.Name == x then return v.Count end
        end
    end
    return 0
end

CheckInventory = function(...)
    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
        for _, n in next, {...} do
            if v.Name == n then return true end
        end
    end
    return false
end

CheckMonster = function(...) local args = {...}
    local containers = {workspace.Enemies, ReplicatedStorage}
    for i = 1, #args do local n = args[i]
        local m = workspace.Enemies:FindFirstChild(n) or ReplicatedStorage:FindFirstChild(n)
        if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
            local h = m:FindFirstChild("Humanoid") local r = m:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then return m end
        end
    end
    for c = 1, #containers do local container = containers[c] local ms = container:GetChildren()
        for m = 1, #ms do local m = ms[m] local h = m:FindFirstChild("Humanoid")
            local r = m:FindFirstChild("HumanoidRootPart")
            if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
                for i = 1, #args do local n = args[i]
                    if m.Name == n or m.Name:lower():find(n:lower()) then return m end
                end
            end
        end
    end
    return false
end

EquipWeapon = function(v)
    if not Character then return end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if tool and (tool.ToolTip and tool.ToolTip == v) then return end
    for _, x in next, LocalPlayer.Backpack:GetChildren() do
        if x:IsA("Tool") and x.ToolTip == v then
            Humanoid:EquipTool(x)
            return
        end
    end
end

local lastCallFA = tick()
FastAttack = function(x)
    if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid")
        or Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
    local FAD = 0.01
    if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
    local t = {}
    for _, e in next, workspace.Enemies:GetChildren() do
        local h = e:FindFirstChild("Humanoid") local hrp = e:FindFirstChild("HumanoidRootPart")
        if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0
            and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then
            t[#t + 1] = e
        end
    end
    local n = ReplicatedStorage.Modules.Net
    local h = {[2] = {}}
    for i = 1, #t do local v = t[i]
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

-- ======================================================================
-- [ HOP SERVER - DRACO HUNTER V17.3 (NGUYÊN BẢN) ]
-- Chỉ dùng __ServerBrowser, giữ nguyên logic V17.3
-- ======================================================================
local function IfTableHaveIndex(j)
    for _ in j do
        return true
    end
end

local LastServersDataPulled, CachedServers

local function GetServers()
    if LastServersDataPulled then
        if os.time() - LastServersDataPulled < getgenv().HOP_CONFIG.CacheDuration then
            return CachedServers
        end
    end

    for i = 1, getgenv().HOP_CONFIG.MaxPages do
        local ok, data = pcall(function()
            return ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i)
        end)

        if ok and data and IfTableHaveIndex(data) then
            LastServersDataPulled = os.time()
            CachedServers = data
            return data
        end
    end

    warn("[HOP] Không lấy được danh sách server!")
    return nil
end

local function HopServer(Reason, MaxPlayers, ForcedRegion)
    -- Ưu tiên tham số truyền vào, nếu không thì lấy từ config
    MaxPlayers   = MaxPlayers   or getgenv().HOP_CONFIG.MaxPlayers
    ForcedRegion = ForcedRegion or getgenv().HOP_CONFIG.ForcedRegion

    local Servers = GetServers()
    if not Servers then
        warn("[HOP] Không có dữ liệu server, thử hop random bằng TeleportService...")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        return
    end

    -- Chuyển dictionary → mảng, loại bỏ server hiện tại
    local ArrayServers = {}
    for id, v in Servers do
        if id ~= JobId then
            table.insert(ArrayServers, {
                JobId      = id,
                Players    = v.Count,
                LastUpdate = v.__LastUpdate,
                Region     = v.Region
            })
        end
    end

    print("[HOP] Nhận được", #ArrayServers, "servers")

    if #ArrayServers == 0 then
        warn("[HOP] Danh sách server rỗng, hop random...")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        return
    end

    -- Lọc server theo điều kiện
    local FilteredServers = {}
    for _, server in ipairs(ArrayServers) do
        local passPlayers = true
        local passRegion  = true

        if MaxPlayers and server.Players >= MaxPlayers then
            passPlayers = false
        end

        if ForcedRegion and server.Region ~= ForcedRegion then
            passRegion = false
        end

        if passPlayers and passRegion then
            table.insert(FilteredServers, server)
        end
    end

    print("[HOP] Sau lọc:", #FilteredServers, "servers phù hợp",
        "(MaxPlayers <", tostring(MaxPlayers) .. ",",
        "Region:", tostring(ForcedRegion) .. ")")

    -- Nếu không có server nào phù hợp, nới lỏng điều kiện
    if #FilteredServers == 0 then
        warn("[HOP] Không có server nào khớp filter, thử bỏ filter region...")
        for _, server in ipairs(ArrayServers) do
            if not MaxPlayers or server.Players < MaxPlayers then
                table.insert(FilteredServers, server)
            end
        end
    end

    -- Vẫn không có → dùng toàn bộ
    if #FilteredServers == 0 then
        warn("[HOP] Vẫn không có server phù hợp, dùng toàn bộ danh sách...")
        FilteredServers = ArrayServers
    end

    -- Chọn random từ danh sách đã lọc
    local ServerData = FilteredServers[math.random(1, #FilteredServers)]

    print("[HOP] Đã chọn server:", ServerData.JobId,
        "| Players:", ServerData.Players,
        "| Region:", ServerData.Region)

    if Reason then
        print("[HOP] Lý do:", Reason)
    end

    -- Teleport bằng __ServerBrowser
    print("[HOP] Đang teleport đến", ServerData.JobId, "...")
    ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer('teleport', ServerData.JobId)
end

-- Gán global để BananaHub và script bên ngoài gọi được
getgenv().GetServers = GetServers
getgenv().HopServer  = HopServer

-- ==========================================
-- ERROR HANDLING V17.3 (GLOBAL - GIỮ NGUYÊN TỪ V17.2)
-- ==========================================
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
    if teleportResult == Enum.TeleportResult.GameFull then
        warn("[HOP] Server đầy, thử hop lại...")
        task.delay(2, function()
            HopServer("Retry - Server đầy")
        end)
    elseif teleportResult == Enum.TeleportResult.IsTeleporting
        and (message:find("previous teleport")) then
        StarterGui:SetCore("SendNotification", {
            Title    = "Death Hop Found",
            Text     = message,
            Duration = 8
        })
        task.delay(10, function() game:Shutdown() end)
    else
        warn("[HOP] Teleport thất bại:", tostring(teleportResult), message)
        task.delay(3, function()
            HopServer("Retry - Teleport fail")
        end)
    end
end)

GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do
            TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            task.wait(5)
        end
    end
end))

-- ======================================================================
-- [ HẾT PHẦN HOP SERVER V17.3 ]
-- ======================================================================

local function getCFrame(v)
    if not v then return nil end
    if typeof(v) == "CFrame" then return v end
    if typeof(v) == "Vector3" then return CFrame.new(v) end
    if typeof(v) ~= "Instance" then return end
    if v:IsA("BasePart") then return v.CFrame end
    if v:IsA("Model") then
        if v.GetPivot then return v:GetPivot() end
        local root = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart")
        if root then return root.CFrame end
    end
    if v:IsA("CFrameValue") then return v.Value end
    if v:IsA("Vector3Value") then return CFrame.new(v.Value) end
end

local connection, tween, pathPart, isTweening = nil, nil, nil, false
Tween = function(targetCFrame, target)
    if targetCFrame == false then
        if tween then pcall(function() tween:Cancel() end) tween = nil end
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        isTweening = false
        return
    end
    targetCFrame = getCFrame(targetCFrame)
    if isTweening or not targetCFrame then return end
    isTweening = true
    local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
    if not char then isTweening = false return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then isTweening = false return end
    humanoid.Sit = false
    target = target or root
    local distance = (targetCFrame.Position - target.Position).Magnitude
    if target == root and distance < 200 then
        target.CFrame = targetCFrame
        isTweening = false
        return
    end
    pathPart = Instance.new("Part")
    pathPart.Name         = "TweenGhost"
    pathPart.Transparency = 1
    pathPart.Anchored     = true
    pathPart.CanCollide   = false
    pathPart.CFrame       = target.CFrame
    pathPart.Size         = Vector3.new(50, 50, 50)
    pathPart.Parent       = workspace
    tween = TweenService:Create(pathPart, TweenInfo.new(distance / 275, Enum.EasingStyle.Linear), {CFrame = targetCFrame * (function()
        if target ~= root then return CFrame.new(0, 30, 0) end
        return CFrame.new(0, 5, 0)
    end)()})
    connection = RunService.Heartbeat:Connect(function()
        if target and pathPart then
            target.CFrame = pathPart.CFrame * (function()
                if target ~= root then return CFrame.new(0, 30, 0) end
                return CFrame.new(0, 5, 0)
            end)()
        end
    end)
    tween.Completed:Connect(function()
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        tween = nil
        isTweening = false
    end)
    tween:Play()
end

BringMonster = function(name, count) count = count or 3
    if count < 2 then return end
    pcall(function() setscriptable(LocalPlayer, "SimulationRadius", true) end)
    pcall(function() sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge) end)
    xpcall(function()
        local mob, t = {}, nil
        for _, v in next, workspace.Enemies:GetChildren() do
            local h   = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 and (not name or v.Name == name)
                and (HumanoidRootPart.Position - hrp.Position).Magnitude <= ((count or 3) * 250) then
                if not table.find(mob, function(chosen)
                    local chrp = chosen:FindFirstChild("HumanoidRootPart")
                    return chrp and (hrp.Position - chrp.Position).Magnitude <= 5
                end) then mob[#mob+1], t = v, t or hrp.CFrame
                end
                if #mob >= (count or 3) then break end
            end
        end
        if not t then return end
        for i = 1, #mob do
            local hrp = mob[i]:FindFirstChild("HumanoidRootPart")
            if hrp and (not isnetworkowner or isnetworkowner(hrp)) then
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = t * CFrame.new((i-1) * 2, 0, 0)
            end
        end
    end, function(r) warn("Modules Error [BM]: " .. r) end)
end

local lastKenCall = tick()
KillMonster = function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _, v in next, workspace.Enemies:GetChildren() do
                local vh   = v:FindFirstChild("Humanoid")
                local vhrp = v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp and v.Name == x then
                    local dx = HumanoidRootPart.Position.X - vhrp.Position.X
                    local dy = HumanoidRootPart.Position.Y - vhrp.Position.Y
                    local dz = HumanoidRootPart.Position.Z - vhrp.Position.Z
                    local sqrMag = dx*dx + dy*dy + dz*dz
                    if sqrMag <= 4900 then
                        BringMonster(x, 3)
                        FastAttack(x)
                        if tick() - lastKenCall >= 10 then
                            lastKenCall = tick()
                            ReplicatedStorage.Remotes.CommE:FireServer("Ken", true)
                        end
                        Tween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        EquipWeapon("Melee")
                        return
                    end
                    Tween(vhrp.CFrame) return
                end
            end
        end
        for _, v in next, ReplicatedStorage:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name == x then Tween(vhrp.CFrame) return end
        end
    end, function(e) warn("Modules ERROR:", e) end)
end

local function GetInventory()
    local ok, inv = pcall(function() return COMMF_:InvokeServer("getInventory") end)
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
-- [ UI (XANH DƯƠNG - ĐEN) ]
-- ==========================================
if services.CoreGui:FindFirstChild("VFAndSA_UI") then
    services.CoreGui.VFAndSA_UI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui", services.CoreGui)
ScreenGui.Name = "VFAndSA_UI"

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size             = UDim2.new(0, 300, 0, 175)
MainFrame.Position         = UDim2.new(0.5, -150, 0.5, -87)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.Active           = true
MainFrame.Draggable        = true
Instance.new("UIStroke", MainFrame).Color        = Color3.fromRGB(0, 120, 255)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size                   = UDim2.new(1, 0, 0, 30)
Title.Text                   = "Sanguine Art Kaitun By Vu Nguyen"
Title.TextColor3             = Color3.fromRGB(0, 150, 255)
Title.BackgroundTransparency = 1
Title.Font                   = Enum.Font.GothamBold
Title.TextSize               = 14

local Line = Instance.new("Frame", MainFrame)
Line.Size             = UDim2.new(1, -20, 0, 1)
Line.Position         = UDim2.new(0, 10, 0, 30)
Line.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
Line.BorderSizePixel  = 0

local StatusLabel = Instance.new("TextLabel", MainFrame)
StatusLabel.Size                   = UDim2.new(1, -20, 0, 20)
StatusLabel.Position               = UDim2.new(0, 10, 0, 34)
StatusLabel.Text                   = "Status: Checking..."
StatusLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font                   = Enum.Font.GothamSemibold
StatusLabel.TextSize               = 11
StatusLabel.TextXAlignment         = Enum.TextXAlignment.Left

local MeleeLabel = Instance.new("TextLabel", MainFrame)
MeleeLabel.Size                   = UDim2.new(1, -20, 0, 16)
MeleeLabel.Position               = UDim2.new(0, 10, 0, 54)
MeleeLabel.Text                   = "🥊 Melee: Checking..."
MeleeLabel.TextColor3             = Color3.fromRGB(0, 150, 255)
MeleeLabel.BackgroundTransparency = 1
MeleeLabel.Font                   = Enum.Font.GothamSemibold
MeleeLabel.TextSize               = 11
MeleeLabel.TextXAlignment         = Enum.TextXAlignment.Left

local MatFrame = Instance.new("Frame", MainFrame)
MatFrame.Size                   = UDim2.new(1, -20, 0, 78)
MatFrame.Position               = UDim2.new(0, 10, 0, 73)
MatFrame.BackgroundTransparency = 1
Instance.new("UIListLayout", MatFrame).Padding = UDim.new(0, 3)

local MaterialChecks = {
    {"Dark Fragment", 2},
    {"Vampire Fang",  20},
    {"Demonic Wisp",  20}
}

local matLabels = {}
for _, data in ipairs(MaterialChecks) do
    local l = Instance.new("TextLabel", MatFrame)
    l.Size                   = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text                   = "📦 " .. data[1] .. ": .../" .. data[2]
    l.TextColor3             = Color3.fromRGB(200, 200, 200)
    l.Font                   = Enum.Font.Gotham
    l.TextSize               = 11
    l.TextXAlignment         = Enum.TextXAlignment.Left
    matLabels[data[1]] = l
end

local fragL = Instance.new("TextLabel", MatFrame)
fragL.Size                   = UDim2.new(1, 0, 0, 16)
fragL.BackgroundTransparency = 1
fragL.Text                   = "💎 Fragment: .../5000"
fragL.TextColor3             = Color3.fromRGB(200, 200, 200)
fragL.Font                   = Enum.Font.Gotham
fragL.TextSize               = 11
fragL.TextXAlignment         = Enum.TextXAlignment.Left
matLabels["Fragment"] = fragL

local function UpdateMaterials()
    local inv = GetInventory()
    for _, data in ipairs(MaterialChecks) do
        local count = GetMaterialCount(data[1], inv)
        local label = matLabels[data[1]]
        if label then
            label.Text       = string.format("📦 %s: %d/%d", data[1], count, data[2])
            label.TextColor3 = (count >= data[2]) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(200, 200, 200)
        end
    end
    local fragCount = 0
    pcall(function() fragCount = Player.Data.Fragments.Value end)
    local fragLabel = matLabels["Fragment"]
    if fragLabel then
        fragLabel.Text       = string.format("💎 Fragment: %d/5000", fragCount)
        fragLabel.TextColor3 = (fragCount >= 5000) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(200, 200, 200)
    end
end

UpdateMaterials()
task.spawn(function()
    while task.wait(10) do UpdateMaterials() end
end)

services.UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.LeftAlt then
        MainFrame.Visible = not MainFrame.Visible
    end
end)

StatusLabel.Text       = "Status: Checking Fragment..."
StatusLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
print("[VFAndSA P1] ✅ Loaded | LeftAlt ẩn/hiện")

-- ==========================================
-- CHECK FRAGMENT
-- ==========================================
local fragmentOk = false

task.spawn(function()
    local fragCount = 0
    pcall(function()
        fragCount = Player:FindFirstChild("Data")
            and Player.Data:FindFirstChild("Fragments")
            and Player.Data.Fragments.Value or 0
    end)

    print("[Fragment] Fragments: " .. fragCount .. "/5000")

    if fragCount >= 5000 then
        fragmentOk             = true
        StatusLabel.Text       = "Fragment: " .. fragCount .. "/5000 ✅"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("[Fragment] Đủ! Tiếp tục Phần 0...")
    else
        StatusLabel.Text       = "Fragment: " .. fragCount .. "/5000 → Farm Katakuri..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        print("[Fragment] Chưa đủ! Farm Katakuri...")

        task.spawn(function()
            while task.wait(15) do
                local currentFrag = 0
                pcall(function() currentFrag = Player.Data.Fragments.Value end)
                StatusLabel.Text = "Fragment: " .. currentFrag .. "/5000 | Farming..."
                if currentFrag >= 5000 then
                    StatusLabel.Text       = "Fragment: 5000 ✅ KICK!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    print("[Fragment] Đủ 5000! Kick rejoin...")
                    task.wait(2)
                    Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 5000 Fragments!\nRejoin để tiếp tục.")
                    break
                end
            end
        end)

        task.spawn(function()
            getgenv().NewUI  = true
            getgenv().Config = {
                ["Select Method Farm"] = "Farm Katakuri",
                ["Hop Find Katakuri"]  = true,
                ["Start Farm"]         = true,
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
        end)

        return
    end
end)

repeat task.wait(1) until fragmentOk

-- ==========================================
-- PHẦN 0: CHECK SANGUINE ART STATUS
-- ==========================================
local saActive = false

task.spawn(function()
    local ok, result = pcall(function()
        return COMMF_:InvokeServer("BuySanguineArt", true)
    end)
    if ok then
        if type(result) == "string" and result:lower():find("bring me") then
            saActive               = false
            StatusLabel.Text       = "SA: ❌ Chưa active"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            print("[P0] Sanguine Art chưa active. Server:", result)
        else
            saActive               = true
            StatusLabel.Text       = "SA: ✅ Đã active! (" .. tostring(result) .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[P0] Sanguine Art đã active! Response:", tostring(result))
        end
    else
        StatusLabel.Text       = "SA: ⚠ Lỗi check"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        warn("[P0] Lỗi check SA:", tostring(result))
    end
end)

-- ==========================================
-- PHẦN 0.5: CHECK MELEE ĐANG EQUIP
-- ==========================================
local currentMelee = "None"

local function GetEquippedMelee()
    local char = Player.Character
    local bp   = Player:FindFirstChild("Backpack")
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then return tool.Name, true end
        end
    end
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Melee" then return tool.Name, false end
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
            MeleeLabel.Text       = "🥊 Melee: " .. meleeName .. " (" .. (isHolding and "cầm" or "BP") .. ")"
            MeleeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        else
            MeleeLabel.Text       = "🥊 Melee: Không có"
            MeleeLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        task.wait(5)
    end
end)

-- ==========================================
-- HÀM GET SA (dùng chung cho cả 2 nhánh)
-- ==========================================
local function RunGetSA()
    print("[getSA] SA đã active! Check melee...")
    task.wait(2)

    if currentMelee == "Sanguine Art" then
        StatusLabel.Text       = "✅ Có SA! Ghi file..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("[getSA] Đang cầm Sanguine Art → Ghi file!")
        pcall(function() writefile(Player.Name .. ".txt", "Completed-melee") end)
        warn("[getSA] Đã ghi: " .. Player.Name .. ".txt → Completed-melee")
        StatusLabel.Text = "✅ Completed-melee!"
        return
    end

    StatusLabel.Text       = "SA Active → Chạy getSA..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    print("[getSA] Chưa cầm SA → Load getSA script...")

    task.spawn(function()
        loadstring(game:HttpGet("https://gist.githubusercontent.com/longvu26092007-eng/2f576450d81d7643d532062f82461464/raw/77db4980c68c917613b9cf04848183606816cf12/getSA"))()
    end)

    while true do
        task.wait(5)
        local meleeName = GetEquippedMelee()
        currentMelee = meleeName

        if meleeName == "Sanguine Art" then
            StatusLabel.Text       = "✅ Có SA! Ghi file..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[getSA] Phát hiện Sanguine Art → Ghi file!")
            pcall(function() writefile(Player.Name .. ".txt", "Completed-melee") end)
            warn("[getSA] Đã ghi: " .. Player.Name .. ".txt → Completed-melee")
            StatusLabel.Text = "✅ Completed-melee!"
            break
        else
            StatusLabel.Text       = "Đợi SA... (" .. meleeName .. ")"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    end
end

-- ==========================================
-- PHẦN 1: AUTOMATION
-- ==========================================
task.spawn(function()
    -- Đợi kết quả check SA xong
    repeat task.wait(1) until StatusLabel.Text:find("SA:") and not StatusLabel.Text:find("Checking")

    -- ====================================================
    -- NHÁNH A: SA đã active → chạy getSA ngay, không cần farm gì
    -- ====================================================
    if saActive then
        print("[P1] SA đã active ngay từ đầu → RunGetSA")
        RunGetSA()
        return
    end

    -- ====================================================
    -- NHÁNH B: SA chưa active → kiểm tra và farm nguyên liệu
    -- ====================================================
    print("[P1B] SA chưa active → Check nguyên liệu...")

    local inv     = GetInventory()
    local dfCount = GetMaterialCount("Dark Fragment", inv)

    if dfCount >= 2 then
        -- ==========================================
        -- PHẦN 1C: ĐỦ DF → CHECK VAMPIRE FANG
        -- ==========================================
        StatusLabel.Text       = "P1B: DF " .. dfCount .. "/1 ✅ → Tiếp..."
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        print("[P1B] Dark Fragment " .. dfCount .. "/1 → Đủ! Chuyển bước tiếp...")

        local vfCount = GetMaterialCount("Vampire Fang", inv)

        if vfCount >= 20 then
            StatusLabel.Text       = "P1C: VF " .. vfCount .. "/20 ✅ → P1D..."
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            print("[P1C] Vampire Fang " .. vfCount .. "/20 → Đủ! Chuyển P1D...")

            local dwCount = GetMaterialCount("Demonic Wisp", inv)

            if dwCount >= 20 then
                -- Đủ tất cả materials, SA vẫn chưa active → đợi
                StatusLabel.Text       = "P1D: DW " .. dwCount .. "/20 ✅ Đủ tất cả! Đợi SA..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                print("[P1D] Demonic Wisp đủ → Đủ tất cả! Đợi SA active...")

                -- Đợi SA active rồi getSA
                task.spawn(function()
                    while true do
                        task.wait(10)
                        local saOk, saResult = pcall(function()
                            return COMMF_:InvokeServer("BuySanguineArt", true)
                        end)
                        if saOk and type(saResult) ~= "string" then saActive = true
                        elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then saActive = true end

                        if saActive then
                            StatusLabel.Text       = "P1D: SA Active! → GetSA..."
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            RunGetSA()
                            break
                        end
                    end
                end)
            else
                StatusLabel.Text       = "P1D: DW " .. dwCount .. "/20 → Farm..."
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
                print("[P1D] Demonic Wisp " .. dwCount .. "/20 → Farm!")

                task.spawn(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/longvu26092007-eng/ml7/refs/heads/main/ultmiaxrada.lua"))()
                end)
                task.wait(10)

                task.spawn(function()
                    getgenv().NewUI  = true
                    getgenv().Config = {
                        ["Select Material"] = "Demonic Wisp",
                        ["Farm Material"]   = true,
                        ["Start Farm"]      = true,
                        ["Hop Sever"]       = true
                    }
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
                end)

                task.spawn(function()
                    while true do
                        local checkInv  = GetInventory()
                        local currentDW = GetMaterialCount("Demonic Wisp", checkInv)
                        local currentVF = GetMaterialCount("Vampire Fang",  checkInv)
                        local currentDF = GetMaterialCount("Dark Fragment", checkInv)
                        StatusLabel.Text = string.format("P1D: DW %d/20 | VF %d/20 | DF %d/1", currentDW, currentVF, currentDF)

                        local saOk, saResult = pcall(function()
                            return COMMF_:InvokeServer("BuySanguineArt", true)
                        end)
                        if saOk and type(saResult) ~= "string" then saActive = true
                        elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then saActive = true end

                        if saActive then
                            StatusLabel.Text       = "P1D: SA Active! → GetSA..."
                            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                            warn("[P1D] SA đã active trong lúc farm! Chạy getSA...")
                            RunGetSA()
                            break
                        end

                        local meleeName = GetEquippedMelee()
                        currentMelee = meleeName
                        if meleeName ~= "None" then
                            MeleeLabel.Text       = "🥊 Melee: " .. meleeName
                            MeleeLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        end
                        task.wait(15)
                    end
                end)
            end

        else
            StatusLabel.Text       = "P1C: VF " .. vfCount .. "/20 → Farm..."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
            print("[P1C] Vampire Fang " .. vfCount .. "/20 → Farm!")

            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/longvu26092007-eng/ml7/refs/heads/main/ultmiaxrada.lua"))()
            end)
            task.wait(10)

            task.spawn(function()
                while task.wait(10) do
                    local checkInv  = GetInventory()
                    local currentVF = GetMaterialCount("Vampire Fang", checkInv)
                    StatusLabel.Text = "P1C: VF " .. currentVF .. "/20 | Farming..."

                    local saOk, saResult = pcall(function()
                        return COMMF_:InvokeServer("BuySanguineArt", true)
                    end)
                    if saOk and type(saResult) ~= "string" then saActive = true
                    elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then saActive = true end

                    if saActive then
                        StatusLabel.Text       = "P1C: SA Active! → GetSA..."
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        warn("[P1C] SA đã active trong lúc farm VF! Chạy getSA...")
                        RunGetSA()
                        break
                    end

                    if currentVF >= 20 then
                        StatusLabel.Text       = "P1C: VF 20/20 ✅ KICK!"
                        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                        task.wait(2)
                        Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 20/20 Vampire Fang!\nRejoin để tiếp tục.")
                        break
                    end
                end
            end)

            task.spawn(function()
                getgenv().NewUI  = true
                getgenv().Config = {
                    ["Select Material"] = "Vampire Fang",
                    ["Farm Material"]   = true,
                    ["Start Farm"]      = true,
                    ["Hop Sever"]       = true
                }
                loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
            end)
        end

    else
        -- ==========================================
        -- PHẦN 1B: CHƯA ĐỦ DF → FARM DARKBEARD (Source_SG Full)
        -- ==========================================
        StatusLabel.Text       = "P1B: DF " .. dfCount .. "/1 → Farm Darkbeard..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        print("[P1B] Dark Fragment " .. dfCount .. "/1 → Chưa đủ, bật farm Darkbeard!")

        -- Monitor: kick khi đủ DF hoặc SA active → getSA
        -- + Watchdog: chống kẹt khi farm đủ chest nhưng hop fail
        local _lastHopAttempt = 0
        task.spawn(function()
            while task.wait(10) do
                local currentDF = CheckMaterial("Dark Fragment")
                StatusLabel.Text = "P1B: DF " .. currentDF .. "/1 | Farming Darkbeard..."

                local saOk, saResult = pcall(function()
                    return COMMF_:InvokeServer("BuySanguineArt", true)
                end)
                if saOk and type(saResult) ~= "string" then saActive = true
                elseif saOk and type(saResult) == "string" and not saResult:lower():find("bring me") then saActive = true end

                if saActive then
                    StatusLabel.Text       = "P1B: SA Active! → GetSA..."
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    warn("[P1B] SA đã active trong lúc farm DF! Chạy getSA...")
                    RunGetSA()
                    break
                end

                if currentDF >= 2 then
                    StatusLabel.Text       = "P1B: DF 1/1 ✅ KICK!"
                    StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                    print("[P1B] Dark Fragment đủ 2/2! Kick rejoin...")
                    task.wait(2)
                    Player:Kick("\n[ VFAndSA Kaitun ]\nĐã đủ 1/1 Dark Fragment!\nRejoin để tiếp tục.")
                    break
                end

                -- Watchdog: nếu đã farm đủ chest mà vẫn ở server cũ → force hop lại
                if getgenv().Settings and type(getgenv().Settings["Max Chests"]) == "number" then
                    local chestsDone = true
                    pcall(function()
                        local tagged = CollectionService:GetTagged("_ChestTagged")
                        local touchable = 0
                        for _, v in next, tagged do
                            if v and v.CanTouch then touchable = touchable + 1 end
                        end
                        if touchable > 3 then chestsDone = false end
                    end)
                    if chestsDone and not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
                        if tick() - _lastHopAttempt > 30 then
                            _lastHopAttempt = tick()
                            warn("[Watchdog] Phát hiện kẹt server (hết chest, không có mob/item) → Force hop!")
                            StatusLabel.Text = "P1B: Watchdog → Force Hop..."
                            pcall(function() HopServer("Watchdog - stuck server") end)
                        end
                    end
                end
            end
        end)

        -- ==========================================
        -- KAITUNBOSS FULL SOURCE (NGUYÊN BẢN)
        -- ==========================================
        task.spawn(function()
            getgenv().Settings = {
                ["Max Chests"] = 50; -- if you collected 50 chests, hop server
                ["Reset After Collect Chests"] = 10; -- if you collected 10 chests, it will reset for safe (anti kick)
            };
            PlaceId, JobId = game.PlaceId, game.JobId
            RunService = game:GetService("RunService")
            TweenService = game:GetService("TweenService")
            HttpService = game:GetService("HttpService")
            Players = game:GetService("Players")
            ReplicatedStorage = game:GetService("ReplicatedStorage")
            Lighting = game:GetService("Lighting")
            CollectionService = game:GetService("CollectionService")
            UserInputService = game:GetService("UserInputService")
            VirtualInputManager = game:GetService("VirtualInputManager")
            StarterGui = game:GetService("StarterGui")
            GuiService = game:GetService("GuiService")
            TeleportService = game:GetService("TeleportService")
            COMMF_ = ReplicatedStorage:WaitForChild("Remotes") and ReplicatedStorage.Remotes:WaitForChild("CommF_")
            LocalPlayer = Players.LocalPlayer
            LocalPlayer.CharacterAdded:Connect(function(v)
                Character = v Humanoid = v:WaitForChild("Humanoid")
                HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
            end)
            if LocalPlayer.Character then
                Character = LocalPlayer.Character
                Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
                HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
            end

            StarterGui:SetCore("SendNotification", {Title = "Executed", Text = "Loading… Please wait", Duration = 5})
            if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
                task.wait(10 - workspace.DistributedGameTime)
            end
            if not COMMF_ then repeat task.wait(1) until COMMF_ end
            task.spawn(function()
                xpcall(function()
                    if not LocalPlayer.Team then
                        if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
                            repeat task.wait(1) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
                        end
                        xpcall(function() COMMF_:InvokeServer("SetTeam", "Pirates")
                        end, function() firesignal(LocalPlayer.PlayerGui["Main (minimal)"].ChooseTeam.Container.Pirates) end)
                        task.wait(2)
                        -- pcall(function() require(ReplicatedStorage.Effect).new("BlindCam"):replicate({["Color"] = Color3.new(0, 0, 0); ["Duration"] = 2; ["Fade"] = 0.4; ["ZIndex"] = 1}) end)
                    end
                end, function(err) warn("????", err) end)
            end)
            repeat task.wait(2) until Character and Character:FindFirstChild("HumanoidRootPart") and Character:FindFirstChildWhichIsA("Humanoid") and Character:IsDescendantOf(workspace.Characters) -- workspace.CurrentCamera.CameraSubject, Players.CharacterAdded:Wait()
            function CheckSea(v: number) return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end
            local remoteAttack, idremote
            local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
            task.spawn((function() for _, v in next, ({ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX}) do
                for _, n in next, v:GetChildren() do if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
                end v.ChildAdded:Connect(function(n) if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id")
                end end) end
            end))
            print("file")
            CheckTool = (function(v)
                for _, x in next, {LocalPlayer.Backpack, Character} do
                for _, v2 in next, x:GetChildren() do if v2:IsA("Tool") and (v2.Name == v or v2.Name:find(v)) then return true end
                end end return false
            end)
            CheckMaterial = (function(x)
                for _, v in pairs(COMMF_:InvokeServer("getInventory")) do if v.Type == "Material" then if v.Name == x then return v.Count end end
                end return 0
            end)
            CheckInventory = (function(...)
                for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
                for _, n in next, {...} do if v.Name == n then return true end end
                end return false
            end)
            CheckMonster = (function(...) local args = {...}
                local v2 = {workspace.Enemies, ReplicatedStorage}
                for i = 1, #args do local n = args[i]
                    local m = workspace.Enemies:FindFirstChild(n) or ReplicatedStorage:FindFirstChild(n)
                    if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
                        local h = m:FindFirstChild("Humanoid") local r = m:FindFirstChild("HumanoidRootPart")
                        if h and r and h.Health > 0 then return m end
                    end
                end
                for c = 1, #v2 do local container = v2[c] local ms = container:GetChildren()
                    for m = 1, #ms do local m = ms[m] local h = m:FindFirstChild("Humanoid")
                        local r = m:FindFirstChild("HumanoidRootPart")
                        if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
                            for i = 1, #args do local n = args[i]
                                if m.Name == n or m.Name:lower():find(n:lower()) then
                                    return m
                                end
                            end
                        end
                    end
                end
                return false
            end)

            EquipWeapon = (function(v)
                if not Character then return end
                local tool = Character:FindFirstChildWhichIsA("Tool")
                if tool and (tool.ToolTip and tool.ToolTip == v) then return end --((tool:GetAttribute("WeaponType") or "") == v
                for _, x in next, LocalPlayer.Backpack:GetChildren() do
                    if x:IsA("Tool") and x.ToolTip == v then
                        Humanoid:EquipTool(x)
                        return
                    end
                end
            end)

            local lastCallFA = tick()
            FastAttack = (function(x)
                if not HumanoidRootPart or not Character:FindFirstChildWhichIsA("Humanoid") or Character.Humanoid.Health <= 0 or not Character:FindFirstChildWhichIsA("Tool") then return end
                local FAD = 0.01 -- throttle
                if FAD ~= 0 and tick() - lastCallFA <= FAD then return end
                local t = {}
                for _, e in next, workspace.Enemies:GetChildren() do
                    local h = e:FindFirstChild("Humanoid") local hrp = e:FindFirstChild("HumanoidRootPart")
                    if e ~= Character and (x and e.Name == x or not x) and h and hrp and h.Health > 0 and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then t[#t + 1] = e end
                end
                local n = ReplicatedStorage.Modules.Net
                local h = {[2] = {}}
                local last
                for i = 1, #t do local v = t[i]
                    local part = v:FindFirstChild("Head") or v:FindFirstChild("HumanoidRootPart")
                    if not h[1] then h[1] = part end
                    h[2][#h[2] + 1] = {v, part} last = v
                end
                -- h[2][#h[2] + 1] = last
                n:FindFirstChild("RE/RegisterAttack"):FireServer()
                n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
                cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".",function(c)
                    return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
                end), bit32.bxor(idremote+909090, seed*2), unpack(h))
                lastCallFA = tick()
            end)
            print('func')
            function IfTableHaveIndex(j)
                for _ in j do
                    return true
                end
            end
            local LastServersDataPulled, CachedServers
            function GetServers()
                if LastServersDataPulled then
                    if os.time() - LastServersDataPulled < 60 then
                        return CachedServers
                    end
                end

                for i = 1, 100, 1 do
                    local data = game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer(i)
                    if IfTableHaveIndex(data) then
                        LastServersDataPulled = os.time()
                        CachedServers = data
                        return data
                    end
                end
            end
            HopServer = function(Reason, MaxPlayers, ForcedRegion)
                local Servers = GetServers()
                local ArrayServers = {}

                for i, v in Servers do
                    table.insert(ArrayServers, {
                        JobId = i,
                        Players = v.Count,
                        LastUpdate = v.__LastUpdate,
                        Region = v.Region
                    })
                end
                print(#ArrayServers, 'servers received')
                local ServerData
                for i = 1, #ArrayServers do
                    while task.wait() do
                        local Index = math.random(1, #ArrayServers)
                        ServerData = ArrayServers[Index]
                        if ServerData then
                            if not MaxPlayers or ServerData.Players < 5 then
                                if not ForcedRegion or ServerData.Regoin == ForcedRegion then
                                    print("Found Server:", ServerData.JobId, 'Player Count:', ServerData.Players, "Region:",
                                        ServerData.Region)
                                    break
                                end
                            end
                        end
                    end

                    print('Teleporting to', ServerData.JobId, '...')
                    game:GetService("ReplicatedStorage"):WaitForChild("__ServerBrowser"):InvokeServer('teleport', ServerData.JobId)
                end
            end
            local connection, tween, pathPart, isTweening = nil, nil, nil, false
            function Tween(targetCFrame: CFrame | boolean, target: CFrame) --old tween, lastest update: 5 months ago
                pcall(function() Character.Humanoid.Sit = false end)
                if not Character.Humanoid or Character.Humanoid.Health <= 0 then pcall(function() workspace.TweenGhost:Destroy() end) connection, tween, pathPart, isTweening = nil, nil, nil, false return end
                if targetCFrame == false then
                    if tween then pcall(function() tween:Cancel() end) tween = nil end
                    if connection then connection:Disconnect() connection = nil end
                    if pathPart then pathPart:Destroy() pathPart = nil end
                    isTweening = false
                    return
                end
                if isTweening or not targetCFrame then return end
                isTweening = true
                local char = game.Players.LocalPlayer and game.Players.LocalPlayer.Character
                if not char then isTweening = false return end
                local root = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if not root or not humanoid then isTweening = false return end
                humanoid.Sit = false
                target = target or root
                local distance = (targetCFrame.Position - target.Position).Magnitude
                pathPart = Instance.new("Part")
                pathPart.Name = "TweenGhost"
                pathPart.Transparency = 1
                pathPart.Anchored = true
                pathPart.CanCollide = false
                pathPart.CFrame = target.CFrame
                pathPart.Size = Vector3.new(50, 50, 50)
                pathPart.Parent = workspace
                tween = game:GetService("TweenService"):Create(pathPart, TweenInfo.new(distance / 250, Enum.EasingStyle.Linear), {CFrame = targetCFrame * (function()
                    if target ~= root then
                        return CFrame.new(0, 30, 0)
                    end
                    return CFrame.new(0, 5, 0)
                end)()})
                connection = game:GetService("RunService").Heartbeat:Connect(function()
                    if target and pathPart then
                        target.CFrame = pathPart.CFrame * (function()
                            if target ~= root then
                                return CFrame.new(0, 30, 0)
                            end
                            return CFrame.new(0, 5, 0)
                        end)()
                    end
                end)
                tween.Completed:Connect(function()
                    if connection then connection:Disconnect() connection = nil end
                    if pathPart then pathPart:Destroy() pathPart = nil end
                    tween = nil
                    isTweening = false
                end)

                tween:Play()
            end

            local lastKenCall=tick() -- pray
            KillMonster=(function(x)
                xpcall(function()
                    if workspace.Enemies:FindFirstChild(x) then
                        for _,v in next,workspace.Enemies:GetChildren() do
                            local vh=v:FindFirstChild("Humanoid") local vhrp=v:FindFirstChild("HumanoidRootPart")
                            if vh and vh.Health > 0 and vhrp and v.Name==x then
                                local dx,dy,dz=HumanoidRootPart.Position.X-vhrp.Position.X, HumanoidRootPart.Position.Y-vhrp.Position.Y, HumanoidRootPart.Position.Z-vhrp.Position.Z
                                local sqrMag=dx*dx+dy*dy+dz*dz
                                if sqrMag<=4900 then
                                    FastAttack(x)
                                    if tick()-lastKenCall>=10 then lastKenCall=tick() ReplicatedStorage.Remotes.CommE:FireServer("Ken",true) end
                                    Tween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                                    EquipWeapon("Melee")
                                    return
                                end
                                Tween(vhrp.CFrame) return
                            end
                        end
                    end
                    for _,v in next,ReplicatedStorage:GetChildren() do
                        local vhrp=v:FindFirstChild("HumanoidRootPart")
                        if v:IsA("Model") and vhrp and v.Name==x then Tween(vhrp.CFrame) return end
                    end
                end,function(e) warn("Modules ERROR:",e) end)
            end)
            local WorldsConfig = {
                ["1"] = "TravelMain",
                ["2"] = "TravelDressrosa",
                ["3"] = "TravelZou"
            }
            TeleportSea = function(sea, msg)
                local s = tostring(sea)
                local target = WorldsConfig[s]
                if not target then return end
                pcall(function() print(msg) end)
                COMMF_:InvokeServer(target)
            end
            PressKeyEvent = newcclosure(function(k, d)
                game:GetService("VirtualInputManager"):SendKeyEvent(true, k, false, game) task.wait(d or 0)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, k, false, game)
            end)
            local all = 0; FarmBeli = (function(x)
                if type(x) ~= "function" then warn("ddijt con me may") end
                local chests, c = {}, 0 local m = CollectionService:GetTagged("_ChestTagged")
                if all < getgenv().Settings["Max Chests"] and not CheckTool("Fist of Darkness") then
                    for _, v in next, CollectionService:GetTagged("_ChestTagged") do if v and v.CanTouch then local dist = (v.Position - HumanoidRootPart.Position).Magnitude table.insert(chests, {obj = v, dist = dist}) end end
                        table.sort(chests, function(a, b) return a.dist < b.dist end)
                        if not CheckTool("Fist of Darkness") then 
                            for i, t in next, chests do local v = t.obj
                                if v:IsA("BasePart") and v.Name:find("Chest") then
                                    if v.CanTouch then
                                        repeat task.wait()
                                            print("Collect Chests | Collected: " .. c.."/"..all .. "/"..getgenv().Settings["Max Chests"].." Chests")
                                            task.delay(2, function() v.CanTouch = false end)
                                            if Character and Character.Humanoid and Character.Humanoid.Health > 0 then
                                                Character:SetPrimaryPartCFrame(v.CFrame)
                                            end
                                            PressKeyEvent("Space")
                                        until not v.CanTouch or CheckTool("Fist of Darkness") c += 1 all += 1
                                        if all >= getgenv().Settings["Max Chests"] then print("Stopped: Max Chests reached") HopServer(8) break
                                        elseif CheckTool("Fist of Darkness") then print("Stopped: Fist of Darkness detected") break
                                        elseif CheckMonster("Darkbeard") then print("Stopped: Darkbeard nearby") HopServer(8) break
                                        end
                                        print(c, getgenv().Settings["Reset After Collect Chests"])
                                        if Character and c >= getgenv().Settings["Reset After Collect Chests"] and not CheckTool("Fist of Darkness") then
                                            if Character and Character:FindFirstChildWhichIsA("Humanoid")then
                                                Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
                                                print("Collect Chests | Reset: Collected: "..tostring(getgenv().Settings["Reset After Collect Chests"]) .." Chests")
                                            end
                                            c = 0 task.wait(1)
                                        end
                                    end
                                    if i % 250 == 0 then task.wait(0.1) end
                                end
                            end
                        else
                            Tween(false)
                            print("Stopped: Found Special Item")
                        end
                    if not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then HopServer(10) end 
                end
            end)
            local hasLeviHeart = CheckInventory("Leviathan Heart")
            spawn(function()
                while task.wait(0.2) do
                    xpcall(function()
                        if CheckSea(2) then Tween(false)
                            if CheckMonster("Darkbeard") then
                                for _, v2 in next, {workspace.Enemies, ReplicatedStorage} do
                                    for _, v in next, v2:GetChildren() do
                                        if v.Name == "Darkbeard" then
                                            repeat task.wait() print("Killing Darkbeard\nHealth: ".. math.floor(v.Humanoid.Health / v.Humanoid.MaxHealth * 100).."%") KillMonster(v.Name)
                                            until not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0 Tween(false)
                                        end
                                    end
                                end
                            elseif CheckTool("Fist of Darkness") then local Detection = workspace.Map.DarkbeardArena.Summoner.Detection
                                Tween(false) print("Spawn Darkbeard\nTweening") Tween(Detection.CFrame)
                                if (HumanoidRootPart.Position - Detection.Position).Magnitude <= 200 then
                                    firetouchinterest(Detection, HumanoidRootPart, 0) task.wait(0.2)
                                    firetouchinterest(Detection, HumanoidRootPart, 1)
                                end
                            else
                                FarmBeli(function()
                                    return all >= getgenv().Settings["Max Chests"] or CheckTool("Fist of Darkness") or CheckTool("Darkbeard")
                                end)
                            end
                        else TeleportSea(2, "Travel to sea 2 for farm Dark Fragments")
                        end
                    end, function(err) warn(err) end)
                end
            end)

            task.spawn(function()
                while task.wait(4) do
                    xpcall(function()
                        if not Character.Humanoid or Character.Humanoid.Health <= 0 then pcall(function() workspace.TweenGhost:Destroy() end) connection, tween, pathPart, isTweening = nil, nil, nil, false return end
                        if not Character:FindFirstChild("HasBuso") then COMMF_:InvokeServer("Buso") end
                        for _, v in next, {"Buso", "Geppo", "Soru"} do
                            if not CollectionService:HasTag(Character, v) then
                                if LocalPlayer.Data.Beli.Value >= ((function(t)
                                    return t == "Geppo" and 1e4 or t == "Buso" and 2.5e4 or t == "Soru" and 1e5 or 0
                                end)(v)) then print("Buy Abilies: ".. v) COMMF_:InvokeServer("BuyHaki", v)
                                end
                            end
                        end
                    end, function(err) warn("LL: ".. err) end)
                end
            end)
            TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
                if teleportResult == Enum.TeleportResult.GameFull then inHopPP = false
                elseif teleportResult == Enum.TeleportResult.IsTeleporting and (message:find("previous teleport")) then
                    StarterGui:SetCore("SendNotification", {Title = "Death Hop Found", Text = message, Duration = 8})
                    task.delay(10, function() game:Shutdown() end)
                end
                -- player.Name -- my LocalPlayer
                -- teleportResult -- Enum.TeleportResult
                -- message -- Request experience is full
            end)
            GuiService.ErrorMessageChanged:Connect(newcclosure(function()
                if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
                    while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end
                end
            end))
        end)
    end
end)
