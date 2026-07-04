-- ============================================================
--  CHEST BP  |  v4.0 STANDALONE  |  2026-07-04
--  Farm Dark Fragment chest (Sea 2) - tele thang + fix ghost
--
--  Base : BLb.txt + New Text Document.txt (SetPrimaryPartCFrame)
--  Fix  : ghost chest, detect truoc khi hop, dem dung, HopServer V17.3,
--         load team fallback (SetTeam -> click UI)
--
--  CACH DUNG: chi can execute file nay. Doi config thi sua getgenv().Settings
-- ============================================================

-- ============================================================
-- CONFIG
-- ============================================================
getgenv().Settings = getgenv().Settings or {}
do
    local S = getgenv().Settings
    local function def(k, v) if S[k] == nil then S[k] = v end end
    def("Team", "Pirates")                     -- Pirates / Marines
    def("Max Chests", 40)                       -- an du bao nhieu chest thi hop
    def("Reset After Collect Chests", 8)        -- reset nhan vat sau N chest (anti-kick)
    def("Chest Wait Timeout", 12)               -- doi chest spawn bao nhieu giay truoc khi hop
    def("Ghost Retry Count", 2)                 -- so lan thu lai 1 chest ghost truoc khi bo
    def("Skip Chest Delay", 0.3)                -- cho truoc khi bo ghost chest
    def("Hop Max Players", 5)                   -- chi hop vao server it hon N nguoi
    def("Max Jump Distance", 3000)              -- nhay xa hon nay = xuyen dao -> reset+hop (chong kick)
    def("Collect Verify Time", 1.4)             -- doi bao lau de xac nhan da an chest (giay)
    def("Debug", true)                          -- ghi log debug ra file (ChestBP_Debug/)
    def("Ghost Model Radius", 14)               -- ban kinh quet model xuat hien quanh chest (chi debug)
end

-- ============================================================
-- SERVICES
-- ============================================================
PlaceId, JobId      = game.PlaceId, game.JobId
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

cloneref = cloneref or function(x) return x end

LocalPlayer = Players.LocalPlayer
COMMF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

LocalPlayer.CharacterAdded:Connect(function(v)
    Character = v
    Humanoid = v:WaitForChild("Humanoid")
    HumanoidRootPart = v:WaitForChild("HumanoidRootPart")
end)
if LocalPlayer.Character then
    Character = LocalPlayer.Character
    Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart")
end

StarterGui:SetCore("SendNotification", {Title = "Chest BP", Text = "Loading... please wait", Duration = 5})
if not game:IsLoaded() or workspace.DistributedGameTime <= 10 then
    task.wait(10 - workspace.DistributedGameTime)
end
if not COMMF_ then repeat task.wait(1) until COMMF_ end

-- ============================================================
-- LOAD TEAM (fallback: SetTeam -> click UI)
-- ============================================================
local function ChooseTeam()
    if LocalPlayer.Team ~= nil then return end

    -- doi loading screen xong
    if LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen") then
        repeat task.wait(0.5) until not LocalPlayer.PlayerGui:FindFirstChild("LoadingScreen")
    end

    local team = getgenv().Settings["Team"] or "Pirates"

    -- Cach 1: remote SetTeam (nhanh nhat)
    local ok = pcall(function() COMMF_:InvokeServer("SetTeam", team) end)
    task.wait(1)
    if LocalPlayer.Team ~= nil then
        print("[Team] SetTeam thanh cong:", team)
        return
    end

    -- Cach 2: firesignal nut Pirates/Marines
    pcall(function()
        local gui = LocalPlayer.PlayerGui:FindFirstChild("Main (minimal)")
        if gui and gui:FindFirstChild("ChooseTeam") then
            firesignal(gui.ChooseTeam.Container[team])
        end
    end)
    task.wait(1)
    if LocalPlayer.Team ~= nil then
        print("[Team] firesignal thanh cong:", team)
        return
    end

    -- Cach 3: click that bang VirtualInputManager (phong to nut cho de trung)
    local deadline = tick() + 15
    repeat
        task.wait()
        for _, v in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if string.find(v.Name, "Main") then
                local ct = v:FindFirstChild("ChooseTeam")
                local btn = ct and ct.Container:FindFirstChild(team)
                if btn and btn:FindFirstChild("Frame") and btn.Frame:FindFirstChild("TextButton") then
                    local tb = btn.Frame.TextButton
                    tb.Size = UDim2.new(0, 10000, 0, 10000)
                    tb.Position = UDim2.new(-4, 0, -5, 0)
                    tb.BackgroundTransparency = 1
                    task.wait(0.3)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                    task.wait(0.05)
                end
            end
        end
    until LocalPlayer.Team ~= nil or tick() >= deadline
    print("[Team] Ket qua cuoi:", tostring(LocalPlayer.Team))
end

ChooseTeam()
task.wait(2)

repeat task.wait(2) until Character
    and Character:FindFirstChild("HumanoidRootPart")
    and Character:FindFirstChildWhichIsA("Humanoid")
    and Character:IsDescendantOf(workspace.Characters)

-- ============================================================
-- HELPERS
-- ============================================================
function CheckSea(v) return v == tonumber(workspace:GetAttribute("MAP"):match("%d+")) end

local remoteAttack, idremote
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer()
task.spawn(function()
    for _, v in next, {ReplicatedStorage.Util, ReplicatedStorage.Common, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.FX} do
        for _, n in next, v:GetChildren() do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
        end
        v.ChildAdded:Connect(function(n)
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then remoteAttack, idremote = n, n:GetAttribute("Id") end
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

CheckInventory = function(...)
    for _, v in pairs(COMMF_:InvokeServer("getInventory")) do
        for _, n in next, {...} do if v.Name == n then return true end end
    end
    return false
end

CheckMonster = function(...)
    local args = {...}
    local containers = {workspace.Enemies, ReplicatedStorage}
    for i = 1, #args do
        local n = args[i]
        local m = workspace.Enemies:FindFirstChild(n) or ReplicatedStorage:FindFirstChild(n)
        if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
            local h = m:FindFirstChild("Humanoid") local r = m:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then return m end
        end
    end
    for c = 1, #containers do
        for _, m in next, containers[c]:GetChildren() do
            local h = m:FindFirstChild("Humanoid") local r = m:FindFirstChild("HumanoidRootPart")
            if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
                for i = 1, #args do
                    local n = args[i]
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
    if tool and tool.ToolTip == v then return end
    for _, x in next, LocalPlayer.Backpack:GetChildren() do
        if x:IsA("Tool") and x.ToolTip == v then Humanoid:EquipTool(x) return end
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
            and (hrp.Position - HumanoidRootPart.Position).Magnitude <= 65 then t[#t + 1] = e end
    end
    local n = ReplicatedStorage.Modules.Net
    local h = {[2] = {}}
    for i = 1, #t do
        local part = t[i]:FindFirstChild("Head") or t[i]:FindFirstChild("HumanoidRootPart")
        if not h[1] then h[1] = part end
        h[2][#h[2] + 1] = {t[i], part}
    end
    n:FindFirstChild("RE/RegisterAttack"):FireServer()
    n:FindFirstChild("RE/RegisterHit"):FireServer(unpack(h))
    cloneref(remoteAttack):FireServer(string.gsub("RE/RegisterHit", ".", function(c)
        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow()/10%10)+1))
    end), bit32.bxor(idremote+909090, seed*2), unpack(h))
    lastCallFA = tick()
end

PressKeyEvent = newcclosure(function(k, d)
    VirtualInputManager:SendKeyEvent(true, k, false, game) task.wait(d or 0)
    VirtualInputManager:SendKeyEvent(false, k, false, game)
end)

-- ============================================================
-- HOP SERVER V17.3
-- ============================================================
function IfTableHaveIndex(j) for _ in j do return true end end

local LastServersDataPulled, CachedServers
function GetServers()
    if LastServersDataPulled and os.time() - LastServersDataPulled < 60 then
        return CachedServers
    end
    for i = 1, 100 do
        local ok, data = pcall(function()
            return ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer(i)
        end)
        if ok and data and IfTableHaveIndex(data) then
            LastServersDataPulled = os.time()
            CachedServers = data
            return data
        end
    end
    warn("[HOP] Khong lay duoc danh sach server!")
    return nil
end

HopServer = function(Reason, MaxPlayers, ForcedRegion)
    MaxPlayers = MaxPlayers or getgenv().Settings["Hop Max Players"] or 5

    local Servers = GetServers()
    if not Servers then
        warn("[HOP] Khong co du lieu server, hop random...")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        return
    end

    local ArrayServers = {}
    for id, v in Servers do
        if id ~= JobId then
            table.insert(ArrayServers, {JobId = id, Players = v.Count, LastUpdate = v.__LastUpdate, Region = v.Region})
        end
    end
    print("[HOP] Nhan duoc", #ArrayServers, "servers")

    if #ArrayServers == 0 then
        warn("[HOP] Danh sach rong, hop random...")
        TeleportService:Teleport(PlaceId, LocalPlayer)
        return
    end

    local Filtered = {}
    for _, s in ipairs(ArrayServers) do
        local passP = not MaxPlayers or s.Players < MaxPlayers
        local passR = not ForcedRegion or s.Region == ForcedRegion
        if passP and passR then table.insert(Filtered, s) end
    end
    print("[HOP] Sau loc:", #Filtered, "servers phu hop")

    if #Filtered == 0 then
        for _, s in ipairs(ArrayServers) do
            if not MaxPlayers or s.Players < MaxPlayers then table.insert(Filtered, s) end
        end
    end
    if #Filtered == 0 then Filtered = ArrayServers end

    local ServerData = Filtered[math.random(1, #Filtered)]
    if Reason then print("[HOP] Ly do:", Reason) end
    print("[HOP] Chon:", ServerData.JobId, "| Players:", ServerData.Players, "| Region:", ServerData.Region)
    ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer('teleport', ServerData.JobId)
end

-- ============================================================
-- TWEEN (dung cho di chuyen den boss/detection, khong dung cho chest)
-- ============================================================
local connection, tween, pathPart, isTweening = nil, nil, nil, false
function Tween(targetCFrame, target)
    pcall(function() Character.Humanoid.Sit = false end)
    if not Character.Humanoid or Character.Humanoid.Health <= 0 then
        pcall(function() workspace.TweenGhost:Destroy() end)
        connection, tween, pathPart, isTweening = nil, nil, nil, false return
    end
    if targetCFrame == false then
        if tween then pcall(function() tween:Cancel() end) tween = nil end
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        isTweening = false return
    end
    if isTweening or not targetCFrame then return end
    isTweening = true
    local char = LocalPlayer.Character
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
    tween = TweenService:Create(pathPart, TweenInfo.new(distance / 250, Enum.EasingStyle.Linear), {CFrame = targetCFrame * (target ~= root and CFrame.new(0, 30, 0) or CFrame.new(0, 5, 0))})
    connection = RunService.Heartbeat:Connect(function()
        if target and pathPart then
            target.CFrame = pathPart.CFrame * (target ~= root and CFrame.new(0, 30, 0) or CFrame.new(0, 5, 0))
        end
    end)
    tween.Completed:Connect(function()
        if connection then connection:Disconnect() connection = nil end
        if pathPart then pathPart:Destroy() pathPart = nil end
        tween = nil isTweening = false
    end)
    tween:Play()
end

local lastKenCall = tick()
KillMonster = function(x)
    xpcall(function()
        if workspace.Enemies:FindFirstChild(x) then
            for _, v in next, workspace.Enemies:GetChildren() do
                local vh = v:FindFirstChild("Humanoid") local vhrp = v:FindFirstChild("HumanoidRootPart")
                if vh and vh.Health > 0 and vhrp and v.Name == x then
                    local dx, dy, dz = HumanoidRootPart.Position.X - vhrp.Position.X, HumanoidRootPart.Position.Y - vhrp.Position.Y, HumanoidRootPart.Position.Z - vhrp.Position.Z
                    if dx*dx + dy*dy + dz*dz <= 4900 then
                        FastAttack(x)
                        if tick() - lastKenCall >= 10 then lastKenCall = tick() ReplicatedStorage.Remotes.CommE:FireServer("Ken", true) end
                        Tween(CFrame.new(vhrp.Position + (vhrp.CFrame.LookVector * 20) + Vector3.new(0, vhrp.Position.Y > 60 and -20 or 20, 0)))
                        EquipWeapon("Melee") return
                    end
                    Tween(vhrp.CFrame) return
                end
            end
        end
        for _, v in next, ReplicatedStorage:GetChildren() do
            local vhrp = v:FindFirstChild("HumanoidRootPart")
            if v:IsA("Model") and vhrp and v.Name == x then Tween(vhrp.CFrame) return end
        end
    end, function(e) warn("KillMonster ERROR:", e) end)
end

local WorldsConfig = {["1"] = "TravelMain", ["2"] = "TravelDressrosa", ["3"] = "TravelZou"}
TeleportSea = function(sea, msg)
    local target = WorldsConfig[tostring(sea)]
    if not target then return end
    if msg then print(msg) end
    COMMF_:InvokeServer(target)
end

-- ============================================================
-- DEBUG LOGGER (ghi ra file de gui lai fix)
-- ============================================================
-- Yeu cau executor co: writefile, appendfile, isfolder, makefolder (hau het co)
local DBG = {}
do
    local hasFS = (type(writefile) == "function") and (type(appendfile) == "function")
    local folder = "ChestBP_Debug"
    local sessionFile = folder .. "/session.log"
    local ghostFile   = folder .. "/ghost_chests.log"
    local enabled = (getgenv().Settings["Debug"] ~= false) and hasFS

    if enabled then
        pcall(function()
            if type(isfolder) == "function" and not isfolder(folder) then
                if type(makefolder) == "function" then makefolder(folder) end
            end
            writefile(sessionFile, "=== ChestBP Debug Session ===\n")
            if type(isfile) == "function" and not isfile(ghostFile) then
                writefile(ghostFile, "=== GHOST CHESTS (rương lỗi) ===\n")
            end
        end)
    end

    local function stamp()
        -- os.time() -> gio tuong doi, du de doi chieu thu tu su kien
        return "[" .. tostring(os.time()) .. "] "
    end

    function DBG.log(msg)
        if enabled then pcall(function() appendfile(sessionFile, stamp() .. msg .. "\n") end) end
        print("[ChestBP]", msg)
    end

    -- lay full path cua 1 instance (Game.Workspace.Enemies...)
    function DBG.fullPath(inst)
        if not inst then return "nil" end
        local ok, path = pcall(function() return inst:GetFullName() end)
        if ok then return path end
        return tostring(inst)
    end

    -- dump toan bo cay con + thuoc tinh cua 1 model/part ra chuoi
    function DBG.dumpTree(inst, depth, lines)
        lines = lines or {}
        depth = depth or 0
        if not inst then return lines end
        local indent = string.rep("  ", depth)
        local extra = ""
        pcall(function()
            if inst:IsA("BasePart") then
                extra = string.format(
                    " | Pos=%s Size=%s CanTouch=%s CanCollide=%s Transparency=%.2f Anchored=%s",
                    tostring(inst.Position), tostring(inst.Size),
                    tostring(inst.CanTouch), tostring(inst.CanCollide),
                    inst.Transparency, tostring(inst.Anchored)
                )
            end
        end)
        lines[#lines + 1] = string.format("%s[%s] %s%s", indent, inst.ClassName, inst.Name, extra)
        -- attributes
        pcall(function()
            for k, v in pairs(inst:GetAttributes()) do
                lines[#lines + 1] = string.format("%s   @attr %s = %s", indent, tostring(k), tostring(v))
            end
        end)
        -- tags
        pcall(function()
            local tags = CollectionService:GetTags(inst)
            if #tags > 0 then
                lines[#lines + 1] = string.format("%s   #tags = %s", indent, table.concat(tags, ", "))
            end
        end)
        if depth < 4 then
            for _, child in ipairs(inst:GetChildren()) do
                DBG.dumpTree(child, depth + 1, lines)
            end
        end
        return lines
    end

    -- ghi lai 1 rương ghost: full path + cay con + moi thu quanh no
    function DBG.dumpGhost(chest, reason)
        if not enabled then
            print("[ChestBP] GHOST:", DBG.fullPath(chest), "|", reason)
            return
        end
        pcall(function()
            local out = {}
            out[#out+1] = "\n" .. string.rep("=", 60)
            out[#out+1] = stamp() .. "GHOST CHEST | reason: " .. tostring(reason)
            out[#out+1] = "FullPath : " .. DBG.fullPath(chest)
            out[#out+1] = "Parent   : " .. DBG.fullPath(chest and chest.Parent)
            if chest then
                out[#out+1] = "ClassName: " .. chest.ClassName
                out[#out+1] = "Name     : " .. chest.Name
                pcall(function() out[#out+1] = "Position : " .. tostring(chest.Position) end)
                pcall(function() out[#out+1] = "CanTouch : " .. tostring(chest.CanTouch) end)
            end
            -- cay con cua rương
            out[#out+1] = "-- Tree of chest --"
            for _, l in ipairs(DBG.dumpTree(chest)) do out[#out+1] = l end
            -- quet moi Model/Part xuat hien quanh rương (nghi la model ghost)
            local pos = chest and chest.Position
            if pos then
                out[#out+1] = "-- Nearby instances (ban kinh " .. tostring(getgenv().Settings["Ghost Model Radius"]) .. ") --"
                local r = tonumber(getgenv().Settings["Ghost Model Radius"]) or 14
                for _, d in ipairs({workspace}) do
                    for _, obj in ipairs(d:GetDescendants()) do
                        if obj:IsA("BasePart") and obj ~= chest then
                            local ok, mag = pcall(function() return (obj.Position - pos).Magnitude end)
                            if ok and mag <= r then
                                out[#out+1] = string.format("  ~%.1f | %s | %s", mag, obj.ClassName, DBG.fullPath(obj))
                            end
                        end
                    end
                end
            end
            appendfile(ghostFile, table.concat(out, "\n") .. "\n")
        end)
        print("[ChestBP] GHOST logged ->", folder .. "/ghost_chests.log |", DBG.fullPath(chest))
    end

    DBG.enabled = enabled
    if not hasFS then
        warn("[ChestBP] Executor khong ho tro writefile -> debug chi in ra console")
    end
end

-- ============================================================
-- CHEST: bay toi + FIX GHOST + DEBUG
-- ============================================================
local function _cfg(key, default)
    local v = getgenv().Settings and getgenv().Settings[key]
    return (v ~= nil) and tonumber(v) or default
end

-- blacklist rương ghost da gap: khong bao gio cham lai (chong kick)
local _ghostSeen = {}

local function _isValidChest(v)
    return v and v.Parent and v:IsA("BasePart") and v.CanTouch and v.Name:find("Chest")
        and not _ghostSeen[v]   -- da xac dinh ghost -> bo qua, khong cham lai
end

-- Dau hieu GHOST: sau khi cham, 1 Model xuat hien ngay canh chest.
-- (chest that bien mat luon; chest loi giu nguyen + spawn model rong).
-- Tra ve model neu phat hien, nil neu khong.
local function _ghostModelNear(chest)
    if not chest or not chest.Parent then return nil end
    local pos = chest.Position
    local r = tonumber(getgenv().Settings["Ghost Model Radius"]) or 14
    for _, obj in ipairs(chest.Parent:GetChildren()) do
        if obj:IsA("Model") and obj ~= chest then
            local ok, prim = pcall(function() return obj:GetPivot().Position end)
            if ok and (prim - pos).Magnitude <= r then
                return obj
            end
        end
    end
    return nil
end

local function _getChestList()
    local pos = HumanoidRootPart and HumanoidRootPart.Position
    if not pos then return {} end
    local list = {}
    for _, v in next, CollectionService:GetTagged("_ChestTagged") do
        if _isValidChest(v) then
            list[#list + 1] = {obj = v, dist = (v.Position - pos).Magnitude}
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function _waitForChest(timeout)
    local deadline = tick() + (timeout or _cfg("Chest Wait Timeout", 12))
    repeat
        task.wait(0.5)
        if #_getChestList() > 0 then return true end
    until tick() >= deadline
    return false
end

-- Dau hieu DA AN CHEST: loot van ra o _WorldOrigin (Silver/Gold/BounceLoot/Lid).
-- Tu debug log: khi an duoc, cac Part nay xuat hien sat vi tri chest.
local function _lootAppeared()
    local wo = workspace:FindFirstChild("_WorldOrigin")
    if not wo then return false end
    for _, o in ipairs(wo:GetChildren()) do
        local n = o.Name
        if n == "Silver" or n == "Gold" or n == "BounceLoot"
            or n == "SilverLid" or n == "GoldLid" then
            return true
        end
    end
    return false
end

-- NHAY 1 PHAT toi chest (instant) + touch + verify.
-- Khong tween. Zero velocity vai frame chong fling.
-- Tra ve: "collected" | "ghost" | "skip" | "died" | "stopped"
local function _teleChest(chest, stopCondition)
    if not _isValidChest(chest) then return "skip" end
    local root = HumanoidRootPart
    local humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return "died" end
    if stopCondition and stopCondition() then return "stopped" end

    local verifyTime = _cfg("Collect Verify Time", 1.4)

    pcall(function() Tween(false) end)
    humanoid.Sit = false

    -- nhay instant den ngay tren chest
    local targetCF = chest.CFrame * CFrame.new(0, 2, 0)
    pcall(function()
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = targetCF
    end)

    -- giu vi tri + zero velocity vai frame (chong fling / bi day ra)
    local holdConn
    holdConn = RunService.Heartbeat:Connect(function()
        if not root or not root.Parent then return end
        pcall(function()
            humanoid.Sit = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end)

    -- cham 1 lan (khong hammer)
    pcall(function()
        firetouchinterest(root, chest, 0)
        task.wait(0.05)
        firetouchinterest(root, chest, 1)
    end)

    -- verify: doi chest bien mat / CanTouch tat / loot van ra
    local deadline = tick() + verifyTime
    local result = "ghost"
    repeat
        task.wait(0.1)
        if not Character or not humanoid or humanoid.Health <= 0 then result = "died" break end
        if stopCondition and stopCondition() then result = "stopped" break end
        if not (chest and chest.Parent) or not chest.CanTouch then result = "collected" break end
        if _lootAppeared() then result = "collected" break end
    until tick() >= deadline

    if holdConn then holdConn:Disconnect() end

    -- van con sau verifyTime = chest loi that -> blacklist, KHONG cham lai (chong kick)
    if result == "ghost" then
        _ghostSeen[chest] = true
        pcall(function() if chest and chest.Parent then chest.CanTouch = false end end)
        DBG.dumpGhost(chest, "khong an duoc sau " .. verifyTime .. "s -> blacklist")
    end
    return result
end

local all = 0
local resetCounter = 0  -- dem chest tu lan reset gan nhat (giu qua cac batch)
FarmBeli = function(stopCondition)
    local maxChests   = _cfg("Max Chests", 50)
    local resetEvery  = _cfg("Reset After Collect Chests", 8)
    local waitTimeout = _cfg("Chest Wait Timeout", 12)

    if stopCondition and stopCondition() then return end
    if not Character or not HumanoidRootPart then return end
    local humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    if all >= maxChests then
        print("Chest | Da du " .. maxChests .. " -> Hop")
        HopServer("Max Chests")
        return
    end

    local maxJump = _cfg("Max Jump Distance", 3000)
    local farResetTried = false  -- da thu reset vi chest qua xa chua

    -- vong lap chinh (thay dequy -> tranh stack overflow)
    while true do
        if stopCondition and stopCondition() then return end
        if all >= maxChests then
            print("Chest | Du " .. maxChests .. " -> Hop")
            HopServer("Max Chests")
            return
        end

        -- detect chest, doi neu chua co
        local chests = _getChestList()
        if #chests == 0 then
            print("Chest | Khong co chest, doi toi da " .. waitTimeout .. "s...")
            if not _waitForChest(waitTimeout) then
                if not (stopCondition and stopCondition()) and not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
                    print("Chest | Het chest sau khi doi -> Hop")
                    HopServer("No chest after wait")
                end
                return
            end
            chests = _getChestList()
        end

        -- CHONG KICK XUYEN DAO: chest gan nhat xa hon maxJump = khac dao
        -- (list sort gan->xa, chests[1] la gan nhat)
        if chests[1] and chests[1].dist > maxJump then
            if not farResetTried then
                DBG.log(string.format("Chest gan nhat xa %.0f studs (>%d) -> reset ve spawn dao", chests[1].dist, maxJump))
                local h = Character and Character:FindFirstChildWhichIsA("Humanoid")
                if h and h.Health > 0 then
                    h:ChangeState(Enum.HumanoidStateType.Dead)
                    task.wait(2.5)
                    repeat task.wait(0.2) until Character and Character:FindFirstChild("HumanoidRootPart")
                end
                farResetTried = true
                -- cho char settle roi quay lai dau while, do lai khoang cach
                task.wait(0.5)
                continue
            else
                -- reset roi van xa -> server nay khong co chest gan, hop
                DBG.log("Reset roi chest van xa -> Hop")
                if not (stopCondition and stopCondition()) and not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
                    HopServer("Chest too far after reset")
                end
                return
            end
        end
        farResetTried = false  -- da co chest gan -> reset lai co che

        -- collect het batch hien tai
        for i, entry in next, chests do
            local v = entry.obj
            if _isValidChest(v) then
                if stopCondition and stopCondition() then return end
                if all >= maxChests then
                    print("Chest | Du " .. maxChests .. " -> Hop")
                    HopServer("Max Chests")
                    return
                end

                -- bo qua chest o dao khac (tinh lai khoang cach thoi diem toi luot)
                if HumanoidRootPart and (v.Position - HumanoidRootPart.Position).Magnitude > maxJump then
                    continue
                end

                local result = _teleChest(v, stopCondition)

                if result == "collected" then
                    all += 1
                    resetCounter += 1
                    DBG.log(string.format("OK collected | Total: %d/%d | %s", all, maxChests, DBG.fullPath(v)))
                    if resetCounter >= resetEvery and not (stopCondition and stopCondition()) then
                        local h = Character and Character:FindFirstChildWhichIsA("Humanoid")
                        if h and h.Health > 0 then
                            DBG.log("Reset sau " .. resetEvery .. " chests (anti-kick)...")
                            h:ChangeState(Enum.HumanoidStateType.Dead)
                            task.wait(1.5)
                        end
                        resetCounter = 0
                    end
                elseif result == "ghost" then
                    DBG.log("GHOST skip -> blacklist | " .. DBG.fullPath(v))
                elseif result == "died" or result == "stopped" then
                    return
                end
            end
            if i % 100 == 0 then task.wait(0.1) end
        end

        -- het batch: con chest moi thi lap tiep, khong thi hop
        if stopCondition and stopCondition() then return end
        if #_getChestList() == 0 then
            if not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
                print("Chest | Het chest -> Hop")
                HopServer("No chest left")
            end
            return
        end
        -- else: quay lai dau while, collect batch moi
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
CheckInventory("Leviathan Heart") -- warmup inventory cache

spawn(function()
    while task.wait(0.2) do
        xpcall(function()
            if CheckSea(2) then
                Tween(false)
                if CheckMonster("Darkbeard") then
                    for _, cont in next, {workspace.Enemies, ReplicatedStorage} do
                        for _, v in next, cont:GetChildren() do
                            if v.Name == "Darkbeard" then
                                repeat task.wait()
                                    print("Killing Darkbeard | Health: " .. math.floor(v.Humanoid.Health / v.Humanoid.MaxHealth * 100) .. "%")
                                    KillMonster(v.Name)
                                until not v or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0
                                Tween(false)
                            end
                        end
                    end
                elseif CheckTool("Fist of Darkness") then
                    local Detection = workspace.Map.DarkbeardArena.Summoner.Detection
                    Tween(false)
                    print("Spawn Darkbeard | Tweening")
                    Tween(Detection.CFrame)
                    if (HumanoidRootPart.Position - Detection.Position).Magnitude <= 200 then
                        firetouchinterest(Detection, HumanoidRootPart, 0) task.wait(0.2)
                        firetouchinterest(Detection, HumanoidRootPart, 1)
                    end
                else
                    FarmBeli(function()
                        return all >= getgenv().Settings["Max Chests"]
                            or CheckTool("Fist of Darkness")
                            or CheckMonster("Darkbeard")
                    end)
                end
            else
                TeleportSea(2, "Travel to Sea 2 for farm Dark Fragment")
            end
        end, function(err) warn("MAIN:", err) end)
    end
end)

-- Buy haki abilities
task.spawn(function()
    while task.wait(4) do
        xpcall(function()
            if not Character.Humanoid or Character.Humanoid.Health <= 0 then
                pcall(function() workspace.TweenGhost:Destroy() end)
                connection, tween, pathPart, isTweening = nil, nil, nil, false return
            end
            if not Character:FindFirstChild("HasBuso") then COMMF_:InvokeServer("Buso") end
            for _, v in next, {"Buso", "Geppo", "Soru"} do
                if not CollectionService:HasTag(Character, v) then
                    local cost = (v == "Geppo" and 1e4) or (v == "Buso" and 2.5e4) or (v == "Soru" and 1e5) or 0
                    if LocalPlayer.Data.Beli.Value >= cost then
                        print("Buy Ability:", v)
                        COMMF_:InvokeServer("BuyHaki", v)
                    end
                end
            end
        end, function(err) warn("HAKI:", err) end)
    end
end)

-- ============================================================
-- ERROR / DISCONNECT HANDLING
-- ============================================================
TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, message)
    if teleportResult == Enum.TeleportResult.GameFull then
        task.delay(2, function() HopServer("Retry - server full") end)
    elseif teleportResult == Enum.TeleportResult.IsTeleporting and message:find("previous teleport") then
        StarterGui:SetCore("SendNotification", {Title = "Death Hop Found", Text = message, Duration = 8})
        task.delay(10, function() game:Shutdown() end)
    else
        warn("[HOP] Teleport fail:", tostring(teleportResult), message)
        task.delay(3, function() HopServer("Retry - teleport fail") end)
    end
end)

GuiService.ErrorMessageChanged:Connect(newcclosure(function()
    if GuiService:GetErrorType() == Enum.ConnectionError.DisconnectErrors then
        while true do TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer) task.wait(5) end
    end
end))

StarterGui:SetCore("SendNotification", {Title = "Chest BP", Text = "Started! Max Chests = " .. getgenv().Settings["Max Chests"], Duration = 5})
print("[Chest BP] v4.0 Loaded & Running")
