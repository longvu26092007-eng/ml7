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
local lastHop, inHopPP = tick(), false
HopServer = (function(mx) if mx then if mx >= Players.MaxPlayers then mx = Players.MaxPlayers - 1 end end
    if inHopPP then return false end
    if tick() - lastHop < 5 then return end lastHop = tick()
    mx = math.abs(mx) or 4 local id, c = PlaceId, ""
    local THop = function()
        local r = pcall(function()
            local j = HttpService:JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/"..id.."/servers/Public?sortOrder=Asc&limit=100"..(c ~= "" and "&cursor="..c or "")))
            for _,v in next, j.data do if v.playing <= mx and v.id ~= JobId then TeleportService:TeleportToPlaceInstance(PlaceId, v.id, LocalPlayer) return true end
            end c = j.nextPageCursor or ""
        end)
        if not r or c == "" then warn("Couldn't find a server") end
    end
    spawn(function() pcall(function()
        while true do inHopPP = true THop() task.wait(30) end
    end) end)
end)
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
