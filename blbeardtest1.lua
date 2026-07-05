--[[
================================================================================
 KILL AURA — TÁCH TỪ KaitunV4 (bản 2 clean)
================================================================================
 CHỈ GỒM: Load team + UI + chức năng Kill Aura (on/off).
 Nguồn hành vi: phần trial Human/Ghoul (set HP về 0) + FastAttack (đánh) của
 file gốc KaitunV4_ban2_fixed. KHÔNG kèm trial/training/hop/server-sync.

 UI có:
   • STATUS (live)
   • Kill Aura        : ON/OFF  → bật/tắt toàn bộ chức năng
   • Mode             : Attack | Set HP | Cực Xa   (3 mode)
   • Attack Range     : chỉnh tầm đánh (studs) cho Attack / Cực Xa
   • Test Mode        : ON/OFF  → bay lên quái gần nhất để test

 TỐI ƯU:
   • 1 loop nền duy nhất cho kill aura (không spawn loop mỗi tick).
   • FastAttack build 1 lần, chỉ bắn khi bật + đúng mode → tiết kiệm remote.
   • Refresh danh sách quái có throttle, mọi loop check Runtime.alive.
================================================================================
]]

--[[ ===== [00] SERVICES ===== ]]
local Players             = game:GetService("Players")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser         = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

--[[ ===== [01] BOOTSTRAP — chờ client load, timeout 30s ===== ]]
do
    if not game:IsLoaded() then game.Loaded:Wait() end
    local t0 = tick()
    repeat
        task.wait(0.1)
        local rem  = ReplicatedStorage:FindFirstChild("Remotes")
        local gui  = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
        local load = gui and gui:FindFirstChild("LoadingScreen")
        if rem and gui and not load then break end
    until (tick() - t0) > 30
end

--[[ ===== [02] CONFIG (chỉ team) ===== ]]
local Config = {}
do
    local raw = getgenv().Config or {}
    local team = raw["Team"]
    if team ~= "Marines" and team ~= "Pirates" then team = "Marines" end
    Config.team = team

    -- Ally/Main để KHÔNG đánh nhầm (nếu có config sẵn)
    Config.allies = {}
    Config.mains  = {}
    for _, v in ipairs(raw["Allies"] or {}) do if type(v) == "string" then Config.allies[v] = true end end
    for _, v in ipairs(raw["MainAccount"] or {}) do if type(v) == "string" then Config.mains[v] = true end end
end

--[[ ===== [03] RUNTIME ===== ]]
local Runtime = { alive = true }

--[[ ===== [04] STATUS ===== ]]
local function status(v) _G.KA_status = tostring(v) end

--[[ ===== [05] STATE (kill aura settings) ===== ]]
local KA = {
    enabled   = false,          -- Kill Aura ON/OFF
    mode      = "Attack",       -- "Attack" | "Set HP" | "Cực Xa"
    range     = 350,            -- tầm đánh (studs) — Cực Xa sẽ ép math.huge
    testMode  = false,          -- bay lên quái gần nhất để test
    lastHits  = 0,
}

--[[ ===== [06] SAFEREMOTE — InvokeServer trong thread con + timeout ===== ]]
local SafeRemote = {}
do
    local _commF
    local function resolve()
        local rem = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
        if not rem then return nil end
        return rem:FindFirstChild("CommF_") or rem:WaitForChild("CommF_", 10)
    end
    _commF = resolve()
    function SafeRemote.invoke(timeout, ...)
        if not _commF then _commF = resolve() end
        if not _commF then return false end
        local args = table.pack(...)
        local done, packed = false, nil
        task.spawn(function()
            packed = table.pack(pcall(function() return _commF:InvokeServer(table.unpack(args, 1, args.n)) end))
            done = true
        end)
        local t0 = tick()
        while not done and (tick() - t0) < timeout do task.wait() end
        if not done or not packed then return false end
        return table.unpack(packed, 1, packed.n)
    end
end

--[[ ===== [07] MOVEMENT — getHRP / getdis / topos(tween) / equip / haki ===== ]]
local Movement = {}
do
    local LP = LocalPlayer
    local function getHRP()
        local c = LP.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    Movement.getHRP = getHRP

    function Movement.getdis(x, y)
        if typeof(x) ~= "CFrame" then return math.huge end
        if not y then
            local hrp = getHRP(); if not hrp then return math.huge end
            y = hrp.CFrame
        end
        if typeof(y) == "CFrame" then y = y.Position end
        return (x.Position - y).Magnitude
    end

    function Movement.equip()
        local char = LP.Character
        local bp = LP:FindFirstChild("Backpack")
        if not (char and bp and char:FindFirstChild("Humanoid")) then return end
        -- ưu tiên Melee, fallback Sword/Blox Fruit/Gun
        local pick, any
        for _, L in pairs(bp:GetChildren()) do
            if L:IsA("Tool") then
                local tip = L.ToolTip
                if tip == "Melee" then pick = L break
                elseif tip == "Sword" or tip == "Blox Fruit" or tip == "Gun" then any = any or L end
            end
        end
        pick = pick or any
        if pick then pcall(function() char.Humanoid:EquipTool(pick) end) end
    end

    function Movement.haki()
        local char = LP.Character
        if char and not char:FindFirstChild("HasBuso") then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
        end
    end

    -- topos: hủy tween cũ + clamp 0.05..600 (200 studs/s) + nil-safe
    local _activeTween
    function Movement.cancel()
        if _activeTween then pcall(function() _activeTween:Cancel(); _activeTween:Destroy() end); _activeTween = nil end
    end
    function Movement.topos(targetCFrame)
        if typeof(targetCFrame) ~= "CFrame" then return end
        local hrp = getHRP(); if not hrp then return end
        pcall(function() LP.Character.Humanoid.Sit = false end)
        Movement.cancel()
        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        local dur = math.clamp(dist / 200, 0.05, 600)
        local tw = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = targetCFrame })
        _activeTween = tw
        tw.Completed:Once(function()
            if _activeTween == tw then _activeTween = nil end
            pcall(function() tw:Destroy() end)
        end)
        tw:Play()
        return tw
    end

    -- join team qua ChooseTeam UI (fallback firesignal)
    function Movement.joinTeam(v2)
        v2 = (v2 == "Marines" or v2 == "Pirates") and v2 or "Marines"
        for _, v in pairs(LP.PlayerGui:GetChildren()) do
            if v:FindFirstChild("ChooseTeam") then
                local b = v.ChooseTeam.Container:FindFirstChild(v2)
                b = b and b:FindFirstChild("Frame"); b = b and b:FindFirstChild("TextButton")
                if b then pcall(function() firesignal(b.Activated) end) end
            end
        end
    end

    -- anti-AFK
    pcall(function()
        LP.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end)
end
local function getdis(...) return Movement.getdis(...) end

--[[ ===== [08] TEAMMANAGER — chọn team bền + recovery loop ===== ]]
local TeamManager = { started = false }
function TeamManager.ensureTeamSelected()
    if not Runtime.alive then return end
    if LocalPlayer.Team then return true end
    local team = Config.team
    local t0, attempt = tick(), 0
    while Runtime.alive and not LocalPlayer.Team and (tick() - t0) < 60 do
        attempt = attempt + 1
        status("Chọn team " .. team .. " (lần " .. attempt .. ")")
        SafeRemote.invoke(3, "SetTeam", team)
        task.wait(0.5)
        if LocalPlayer.Team then break end
        Movement.joinTeam(team)      -- fallback qua UI
        task.wait(1)
    end
    return LocalPlayer.Team ~= nil
end
function TeamManager.start()
    if TeamManager.started then return end
    TeamManager.started = true
    task.spawn(function()
        TeamManager.ensureTeamSelected()
        while Runtime.alive do
            task.wait(2)
            if not LocalPlayer.Team then
                status("Recover team...")
                TeamManager.ensureTeamSelected()
            end
        end
    end)
end

--[[ ===== [09] TARGETS — quét quái/địch (loại ally + main của mình) ===== ]]
local Targets = {}
do
    local LP = LocalPlayer
    local function notFriendly(name) return not Config.allies[name] and not Config.mains[name] end

    -- danh sách địch sống trong các folder Enemies / Characters
    function Targets.list()
        local out = {}
        local function scan(folder, isPlayerFolder)
            if not folder then return end
            for _, v in ipairs(folder:GetChildren()) do
                if v ~= LP.Character then
                    local hum = v:FindFirstChildOfClass("Humanoid")
                    local hrp = v:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        if not isPlayerFolder or notFriendly(v.Name) then
                            out[#out + 1] = { model = v, hum = hum, hrp = hrp, head = v:FindFirstChild("Head") }
                        end
                    end
                end
            end
        end
        scan(workspace:FindFirstChild("Enemies"), false)
        scan(workspace:FindFirstChild("Characters"), true)
        return out
    end

    -- quái/địch gần nhất
    function Targets.nearest()
        local hrp = Movement.getHRP(); if not hrp then return nil end
        local best, bestD = nil, math.huge
        for _, t in ipairs(Targets.list()) do
            local d = (t.hrp.Position - hrp.Position).Magnitude
            if d < bestD then best, bestD = t, d end
        end
        return best, bestD
    end
end

--[[ ===== [10] FASTATTACK — build 1 lần, gate theo KA.enabled + mode ===== ]]
-- Port từ FastAttack (KaitunV4): RegisterAttack + RegisterHit + remote mã hóa.
-- Distance đọc động từ KA.range (Cực Xa → math.huge).
local FastAttack
do
    local function SafeWait(parent, name)
        local ok, res = pcall(function() return parent:WaitForChild(name, 10) end)
        return ok and res or nil
    end
    local Player   = LocalPlayer
    local Remotes  = SafeWait(ReplicatedStorage, "Remotes")
    local Modules  = SafeWait(ReplicatedStorage, "Modules")
    local NetMod   = Modules and SafeWait(Modules, "Net")

    if NetMod then
        pcall(function()
            local CameraShakerR = require(ReplicatedStorage.Util.CameraShaker)
            CameraShakerR:Stop()
        end)

        local RegisterAttack = SafeWait(NetMod, "RE/RegisterAttack")
        local RegisterHit    = SafeWait(NetMod, "RE/RegisterHit")

        if RegisterAttack and RegisterHit then
            FastAttack = {}

            -- remote mã hóa (bản game mới chỉ ăn damage khi kèm remote bxor + seed)
            local encSeed
            pcall(function() encSeed = NetMod:WaitForChild("seed", 10):InvokeServer() end)
            local remoteAttack, idremote
            local remoteFolders = {
                ReplicatedStorage:FindFirstChild("Util"),
                ReplicatedStorage:FindFirstChild("Common"),
                ReplicatedStorage:FindFirstChild("Remotes"),
                ReplicatedStorage:FindFirstChild("Assets"),
                ReplicatedStorage:FindFirstChild("FX"),
            }
            local function GetRemoteAttack()
                if remoteAttack and remoteAttack.Parent and idremote then return true end
                remoteAttack, idremote = nil, nil
                for _, folder in ipairs(remoteFolders) do
                    if folder then
                        for _, obj in ipairs(folder:GetChildren()) do
                            if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") then
                                remoteAttack = obj; idremote = obj:GetAttribute("Id"); return true
                            end
                        end
                    end
                end
                return false
            end
            for _, folder in ipairs(remoteFolders) do
                if folder then
                    folder.ChildAdded:Connect(function(obj)
                        if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") then
                            remoteAttack = obj; idremote = obj:GetAttribute("Id")
                        end
                    end)
                end
            end
            GetRemoteAttack()

            local function EncryptedRegisterHit(basePart, others)
                if not basePart or not others or #others == 0 then return end
                if not encSeed then pcall(function() encSeed = NetMod:WaitForChild("seed", 10):InvokeServer() end) end
                if not GetRemoteAttack() or not encSeed then return end
                pcall(function()
                    local encodedName = string.gsub("RE/RegisterHit", ".", function(c)
                        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                    end)
                    remoteAttack:FireServer(encodedName, bit32.bxor(idremote + 909090, encSeed * 2), basePart, others)
                end)
            end

            local function IsAlive(char) return char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 end
            local function ProcessEnemies(others, folder, dist)
                local basePart
                if not folder then return nil end
                for _, Enemy in pairs(folder:GetChildren()) do
                    local Head = Enemy:FindFirstChild("Head")
                    if Head and IsAlive(Enemy) and Player:DistanceFromCharacter(Head.Position) < dist then
                        if Enemy ~= Player.Character and not Config.allies[Enemy.Name] and not Config.mains[Enemy.Name] then
                            others[#others + 1] = { Enemy, Head }
                            basePart = Head
                        end
                    end
                end
                return basePart
            end

            function FastAttack:Attack(basePart, others)
                if not basePart or #others == 0 then return end
                RegisterAttack:FireServer(0)
                RegisterHit:FireServer(basePart, others)
                EncryptedRegisterHit(basePart, others)
            end
            function FastAttack:AttackNearest()
                local dist = (KA.mode == "Cực Xa") and math.huge or KA.range
                local others = {}
                local p1 = ProcessEnemies(others, workspace:FindFirstChild("Enemies"), dist)
                local p2 = ProcessEnemies(others, workspace:FindFirstChild("Characters"), dist)
                if #others == 0 then return end
                local char = Player.Character; if not char then return end
                self:Attack(p1 or p2, others)
                KA.lastHits = #others
                -- vũ khí đời mới có LeftClickRemote → bắn thêm theo hướng từng địch
                local weapon = char:FindFirstChildOfClass("Tool")
                if weapon and weapon:FindFirstChild("LeftClickRemote") then
                    local pivot = char:GetPivot().Position
                    for _, ed in ipairs(others) do
                        local ehrp = ed[1]:FindFirstChild("HumanoidRootPart")
                        if ehrp then
                            pcall(function() weapon.LeftClickRemote:FireServer((ehrp.Position - pivot).Unit, 1) end)
                        end
                    end
                end
            end
            function FastAttack:BladeHits()
                local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
                if Equipped and Equipped.ToolTip ~= "Gun" then self:AttackNearest() end
            end
        end
    end
    if not FastAttack then
        status("⚠ FastAttack không init được (thiếu Net) — Set HP vẫn chạy")
    end
end

--[[ ===== [11] SPAM-SKILLS — bật theo _G.SHOULDSPAMSKILLS (tăng damage) ===== ]]
do
    local LP = LocalPlayer
    local fruits = {
        ['Buddha-Buddha']=true,['T-Rex-T-Rex']=true,['Dragon-Dragon']=true,['Yeti-Yeti']=true,
        ['Leopard-Leopard']=true,['Venom-Venom']=true,['Phoenix-Phoenix']=true,['Kitsune-Kitsune']=true,
        ['Mammoth-Mammoth']=true,['Gas-Gas']=true,["Portal-Portal"]=true,
    }
    local isvalidtooltip = { ["Melee"]=true, ["Blox Fruit"]=true, ["Sword"]=true, ["Gun"]=true }
    local isvalidnameui  = { ["Z"]=true, ["X"]=true, ["C"]=true, ["V"]=true, ["F"]=true }
    local function getallweapon()
        local w, bp = {}, LP:FindFirstChild("Backpack")
        if bp then for _, v in pairs(bp:GetChildren()) do if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then w[#w+1]=v end end end
        if LP.Character then for _, v in pairs(LP.Character:GetChildren()) do if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then w[#w+1]=v end end end
        return w
    end
    local function EquipTool(name)
        local bp = LP:FindFirstChild("Backpack")
        local t = bp and bp:FindFirstChild(name)
        if t and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid:EquipTool(t) end
    end
    task.spawn(function()
        while Runtime.alive do
            task.wait()
            if _G.SHOULDSPAMSKILLS then
                pcall(function()
                    local char = LP.Character
                    local skillsUI = LP.PlayerGui:FindFirstChild("Main")
                    skillsUI = skillsUI and skillsUI:FindFirstChild("Skills")
                    if not (char and skillsUI) then return end
                    local weapon = getallweapon()
                    for _, v in pairs(weapon) do if not skillsUI:FindFirstChild(v.Name) then EquipTool(v.Name) end end
                    for _, v in pairs(weapon) do
                        if v.Parent ~= char then EquipTool(v.Name) end
                        local ui_ = skillsUI:FindFirstChild(v.Name)
                        if ui_ then
                            for _, vl in pairs(ui_:GetChildren()) do
                                if isvalidnameui[vl.Name] then
                                    local cd = vl:FindFirstChild("Cooldown")
                                    local ti = vl:FindFirstChild("Title")
                                    if cd and ti and (ti.TextColor3 == Color3.new(1,1,1) or ti.TextColor3 == Color3.fromRGB(255,255,255)) then
                                        if cd.Size == UDim2.new(0, 0, 1, -1) then
                                            if vl.Name == "V" then
                                                if not fruits[ui_.Name] then
                                                    VirtualInputManager:SendKeyEvent(true, "V", false, game); task.wait(0.1)
                                                    VirtualInputManager:SendKeyEvent(false, "V", false, game); task.wait(1.5)
                                                end
                                            else
                                                VirtualInputManager:SendKeyEvent(true, vl.Name, false, game); task.wait(0.1)
                                                VirtualInputManager:SendKeyEvent(false, vl.Name, false, game); task.wait(1.5)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

--[[ ===== [12] KILLAURA CORE — 1 loop nền, dispatch theo mode ===== ]]
-- Attack  : FastAttack:BladeHits() trong tầm KA.range, tween lại gần địch gần nhất.
-- Set HP  : port trial Human/Ghoul — tp lên đầu địch, set Humanoid.Health = 0.
-- Cực Xa  : FastAttack với Distance = math.huge → đánh MỌI địch trên map.
local KillAura = {}
do
    local LP = LocalPlayer
    local _atkEqT = 0

    -- KILL AURA ĐÚNG NGHĨA: chỉ equip + haki (throttle), KHÔNG di chuyển/bay.
    -- FastAttack:BladeHits() sẽ bắn remote đánh mọi địch trong KA.range → đứng im vẫn dính.
    -- Việc bay lên quái để riêng cho Test Mode (mục [13]).
    local function prepareAttack()
        if tick() - _atkEqT > 0.4 then
            _atkEqT = tick()
            pcall(Movement.equip); pcall(Movement.haki)
        end
    end

    -- Set HP: Y CHANG trial Human/Ghoul (KaitunV4 1778-1793), CHỈ BỎ dòng tween bay lên đầu quái.
    -- SimulationRadius = math.huge chiếm quyền vật lý mọi quái → ĐỨNG IM vẫn ép Health = 0 được.
    local function setHpTick()
        for _, t in ipairs(Targets.list()) do
            if not KA.enabled or KA.mode ~= "Set HP" then break end
            local v, hum, hrp = t.model, t.hum, t.hrp
            local t0 = tick()
            repeat
                task.wait()
                pcall(Movement.equip); pcall(Movement.haki)
                -- (đã bỏ) Movement.topos(hrp.CFrame * CFrame.new(0, 30, 0)) — không bay lên đầu quái nữa
                pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
                pcall(function() hrp.CanCollide = false; hum.Health = 0 end)
            until (not v.Parent) or (not v:FindFirstChild("Humanoid")) or hum.Health <= 0
                or (tick() - t0) > 8 or (not KA.enabled) or KA.mode ~= "Set HP"
        end
    end

    function KillAura.start()
        if KillAura._started then return end
        KillAura._started = true
        task.spawn(function()
            while Runtime.alive do
                task.wait()
                if KA.enabled then
                    -- KHÔNG tự spam skill kiếm/melee nữa (trước đây bật _G.SHOULDSPAMSKILLS ở đây)
                    if KA.mode == "Set HP" then
                        setHpTick()
                    else
                        -- Attack / Cực Xa: ĐỨNG IM, chỉ bắn remote đánh địch trong tầm
                        prepareAttack()
                        if FastAttack then pcall(function() FastAttack:BladeHits() end) end
                    end
                end
            end
        end)
    end
end

--[[ ===== [13] TEST MODE — bay lên quái gần nhất ===== ]]
do
    task.spawn(function()
        while Runtime.alive do
            task.wait(0.15)
            if KA.testMode then
                local t, d = Targets.nearest()
                if t then
                    status(string.format("TEST: bay lên quái gần nhất (d=%d)", math.floor(d)))
                    pcall(function() Movement.topos(t.hrp.CFrame * CFrame.new(0, 6, 0)) end)
                else
                    status("TEST: không thấy quái nào")
                end
            end
        end
    end)
end

--[[ ===== [14] UI ===== ]]
local UIManager = { started = false }
function UIManager.start()
    if UIManager.started then return end
    UIManager.started = true

    local StatusValue
    local okUI = pcall(function()
        pcall(function()
            local old = LocalPlayer.PlayerGui:FindFirstChild("KillAuraGui")
            if old then old:Destroy() end
        end)

        local function RegisterRGB(obj, offset, s, v, prop)
            pcall(function() obj[prop or "Color"] = Color3.fromHSV((0.65 + (offset or 0)) % 1, s or 0.85, v or 1) end)
        end

        local Gui = Instance.new("ScreenGui")
        Gui.Name = "KillAuraGui"; Gui.ResetOnSpawn = false; Gui.IgnoreGuiInset = false
        Gui.DisplayOrder = 1000; Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        local ToggleBtn = Instance.new("TextButton")
        ToggleBtn.Size = UDim2.new(0, 54, 0, 54); ToggleBtn.Position = UDim2.new(1, -70, 0.30, 0)
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(18, 20, 28); ToggleBtn.BorderSizePixel = 0
        ToggleBtn.Text = "⚔"; ToggleBtn.TextSize = 26; ToggleBtn.Font = Enum.Font.GothamBold
        ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleBtn.AutoButtonColor = false; ToggleBtn.Parent = Gui
        Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 14)
        local tbStroke = Instance.new("UIStroke", ToggleBtn); tbStroke.Thickness = 2.5; RegisterRGB(tbStroke, 0)

        local Panel = Instance.new("Frame")
        Panel.Size = UDim2.new(0, 320, 0, 420); Panel.Position = UDim2.new(0.5, -160, 0.5, -210)
        Panel.BackgroundColor3 = Color3.fromRGB(12, 14, 22); Panel.BorderSizePixel = 0
        Panel.Active = true; Panel.Draggable = true; Panel.Visible = true; Panel.Parent = Gui
        Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)
        local pStroke = Instance.new("UIStroke", Panel); pStroke.Thickness = 2.5; RegisterRGB(pStroke, 0)

        local Header = Instance.new("Frame")
        Header.Size = UDim2.new(1, -20, 0, 52); Header.Position = UDim2.new(0, 10, 0, 10)
        Header.BackgroundColor3 = Color3.fromRGB(20, 23, 35); Header.BorderSizePixel = 0; Header.Parent = Panel
        Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -50, 0, 24); Title.Position = UDim2.new(0, 14, 0, 6)
        Title.BackgroundTransparency = 1; Title.Text = "⚔ KILL AURA"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Font = Enum.Font.GothamBold; Title.TextSize = 15; Title.Parent = Header
        local SubTitle = Instance.new("TextLabel")
        SubTitle.Size = UDim2.new(1, -50, 0, 14); SubTitle.Position = UDim2.new(0, 14, 0, 30)
        SubTitle.BackgroundTransparency = 1; SubTitle.Text = "✦ tách từ KaitunV4"
        SubTitle.TextXAlignment = Enum.TextXAlignment.Left; SubTitle.Font = Enum.Font.GothamBold
        SubTitle.TextSize = 11; SubTitle.Parent = Header; RegisterRGB(SubTitle, 0.1, 0.7, 1, "TextColor3")
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Size = UDim2.new(0, 30, 0, 30); CloseBtn.Position = UDim2.new(1, -38, 0.5, -15)
        CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50); CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "✕"; CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 15; CloseBtn.AutoButtonColor = false; CloseBtn.Parent = Header
        Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
        CloseBtn.MouseButton1Click:Connect(function() Panel.Visible = false end)
        ToggleBtn.MouseButton1Click:Connect(function() Panel.Visible = not Panel.Visible end)

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, -20, 1, -74); Page.Position = UDim2.new(0, 10, 0, 68)
        Page.BackgroundTransparency = 1; Page.BorderSizePixel = 0; Page.ScrollBarThickness = 4
        Page.ScrollBarImageColor3 = Color3.fromRGB(120, 160, 240)
        Page.CanvasSize = UDim2.new(0, 0, 0, 0); Page.AutomaticCanvasSize = Enum.AutomaticSize.Y; Page.Parent = Panel
        local l = Instance.new("UIListLayout", Page); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Padding = UDim.new(0, 8)

        local function addCard(order, height)
            local f = Instance.new("Frame")
            f.LayoutOrder = order; f.Size = UDim2.new(1, 0, 0, height)
            f.BackgroundColor3 = Color3.fromRGB(18, 20, 30); f.BorderSizePixel = 0; f.Parent = Page
            Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
            return f
        end
        local function StatusCard(order)
            local f = addCard(order, 78)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -16, 0, 16); t.Position = UDim2.new(0, 12, 0, 8)
            t.BackgroundTransparency = 1; t.Text = "● STATUS"; t.TextColor3 = Color3.fromRGB(140, 200, 255)
            t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = Enum.Font.GothamBold; t.TextSize = 11; t.Parent = f
            local v = Instance.new("TextLabel")
            v.Size = UDim2.new(1, -20, 0, 46); v.Position = UDim2.new(0, 12, 0, 26)
            v.BackgroundTransparency = 1; v.Text = "Đang khởi động..."; v.TextColor3 = Color3.fromRGB(255, 255, 255)
            v.TextXAlignment = Enum.TextXAlignment.Left; v.TextYAlignment = Enum.TextYAlignment.Top
            v.Font = Enum.Font.GothamBold; v.TextSize = 12; v.TextWrapped = true; v.Parent = f
            return v
        end
        local function ToggleCard(order, text, default, callback)
            local f = addCard(order, 46)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -70, 1, 0); t.Position = UDim2.new(0, 12, 0, 0)
            t.BackgroundTransparency = 1; t.Text = text; t.TextColor3 = Color3.fromRGB(230, 235, 255)
            t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.Parent = f
            local sw = Instance.new("TextButton")
            sw.Size = UDim2.new(0, 44, 0, 22); sw.Position = UDim2.new(1, -54, 0.5, -11)
            sw.BackgroundColor3 = default and Color3.fromRGB(60, 200, 110) or Color3.fromRGB(60, 64, 82)
            sw.Text = ""; sw.AutoButtonColor = false; sw.Parent = f
            Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
            local state = default
            sw.MouseButton1Click:Connect(function()
                state = not state
                sw.BackgroundColor3 = state and Color3.fromRGB(60, 200, 110) or Color3.fromRGB(60, 64, 82)
                pcall(callback, state)
            end)
            return f
        end
        local function DropdownCard(order, text, options, default, callback)
            local f = addCard(order, 46)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -120, 1, 0); t.Position = UDim2.new(0, 12, 0, 0)
            t.BackgroundTransparency = 1; t.Text = text; t.TextColor3 = Color3.fromRGB(230, 235, 255)
            t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.Parent = f
            local cur = Instance.new("TextButton")
            cur.Size = UDim2.new(0, 100, 0, 30); cur.Position = UDim2.new(1, -110, 0.5, -15)
            cur.BackgroundColor3 = Color3.fromRGB(30, 34, 50); cur.Text = default
            cur.TextColor3 = Color3.fromRGB(255, 255, 255); cur.Font = Enum.Font.GothamBold; cur.TextSize = 12
            cur.AutoButtonColor = false; cur.Parent = f
            Instance.new("UICorner", cur).CornerRadius = UDim.new(0, 7)
            local idx = 1
            for i, o in ipairs(options) do if o == default then idx = i end end
            cur.MouseButton1Click:Connect(function()
                idx = (idx % #options) + 1
                cur.Text = options[idx]
                pcall(callback, options[idx])
            end)
            return f
        end
        local function TextboxCard(order, label, default, callback)
            local f = addCard(order, 46)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(0, 130, 1, 0); t.Position = UDim2.new(0, 12, 0, 0)
            t.BackgroundTransparency = 1; t.Text = label; t.TextColor3 = Color3.fromRGB(230, 235, 255)
            t.TextXAlignment = Enum.TextXAlignment.Left; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.Parent = f
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 120, 0, 30); box.Position = UDim2.new(1, -130, 0.5, -15)
            box.BackgroundColor3 = Color3.fromRGB(14, 16, 24); box.Text = tostring(default)
            box.TextColor3 = Color3.fromRGB(255, 255, 255); box.Font = Enum.Font.Gotham; box.TextSize = 13
            box.ClearTextOnFocus = false; box.Parent = f
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 7)
            box.FocusLost:Connect(function() pcall(callback, box.Text) end)
            return box
        end

        -- ===== Xếp UI =====
        StatusValue = StatusCard(1)

        ToggleCard(2, "Kill Aura", KA.enabled, function(v)
            KA.enabled = v
            status(v and ("Kill Aura BẬT — mode " .. KA.mode) or "Kill Aura TẮT")
        end)

        DropdownCard(3, "Mode", { "Attack", "Set HP", "Cực Xa" }, KA.mode, function(v)
            KA.mode = v
            status("Mode → " .. v)
        end)

        TextboxCard(4, "Attack Range", KA.range, function(txt)
            local n = tonumber(txt)
            if n and n > 0 then KA.range = n; status("Range → " .. n) end
        end)

        DropdownCard(5, "Team", { "Marines", "Pirates" }, Config.team, function(v)
            Config.team = v
            if not LocalPlayer.Team then TeamManager.ensureTeamSelected() end
            status("Team → " .. v)
        end)

        ToggleCard(6, "Test Mode (bay lên quái)", KA.testMode, function(v)
            KA.testMode = v
            status(v and "Test Mode BẬT" or "Test Mode TẮT")
        end)
    end)

    if not okUI then warn("[KillAura UI] build fail") end

    -- cập nhật STATUS live
    task.spawn(function()
        while Runtime.alive do
            pcall(function()
                if StatusValue then
                    local ka = KA.enabled and ("ON/" .. KA.mode) or "OFF"
                    StatusValue.Text = string.format(
                        "KA: %s | range=%s\nhits=%d | test=%s\n%s",
                        ka,
                        (KA.mode == "Cực Xa") and "∞" or tostring(KA.range),
                        KA.lastHits,
                        KA.testMode and "ON" or "OFF",
                        tostring(_G.KA_status or "…")
                    )
                end
            end)
            task.wait(0.2)
        end
    end)
end

--[[ ===== [15] BOOT ===== ]]
status("Khởi động Kill Aura...")
TeamManager.start()
KillAura.start()
UIManager.start()
status("Sẵn sàng. Bật Kill Aura trên UI để bắt đầu.")
