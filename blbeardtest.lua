-- ============================================================
--  CHEST BP MODULE  |  v3.0  |  2026-07-04
--  Logic gốc: kaituncyborg (TweenChest) + New Text Document.txt (SetPrimaryPartCFrame)
--
--  Cải tiến so với bản gốc:
--    • Tele thẳng vào chest (SetPrimaryPartCFrame) thay tween bình thường
--      → không bị hop hụt, không bị lag giữa đường
--    • Detect chest trước khi hop (đợi spawn tối đa N giây)
--      → không hop khi server đang trống chờ respawn
--    • Verify chest biến mất sau khi tele + touch
--      → phân biệt ghost chest vs collected thật
--    • Ghost chest: retry firetouchinterest x3 rồi force skip
--      → không loop vô hạn trên 1 chest không lấy được
--    • Counter all chỉ tăng khi THỰC SỰ lấy được (chest biến mất)
--    • HopServer chỉ gọi khi không còn chest sau khi đã đợi
--    • Reset nhân vật bằng ChangeState(Dead) đúng chuẩn
-- ============================================================

-- ============================================================
-- DEPENDENCIES (phải có sẵn từ main script):
--   CollectionService, RunService
--   Character, HumanoidRootPart
--   IsDied(char) hoặc check Health <= 0
--   CheckTool(name), CheckMonster(name)
--   HopServer(reason, maxPlayers), SetText(text) / print
--   PressKeyEvent(key)
--   getgenv().Settings = {
--       ["Max Chests"]                 = 25,
--       ["Reset After Collect Chests"] = 10,
--       ["Chest Wait Timeout"]         = 12,   -- giây đợi chest spawn
--       ["Ghost Retry Count"]          = 3,    -- số lần retry trước khi skip
--       ["Skip Chest Delay"]           = 0.5,  -- chờ sau mỗi ghost trước khi bỏ
--   }
-- ============================================================

local function _cfg(key, default)
    local v = getgenv().Settings and getgenv().Settings[key]
    return (v ~= nil) and tonumber(v) or default
end

-- Chest còn valid để collect không
local function _isValidChest(v)
    return v
        and v.Parent
        and v:IsA("BasePart")
        and v.CanTouch
        and v.Name:find("Chest")
end

-- Lấy danh sách chest hợp lệ, sort gần → xa
local function _getChestList()
    local pos = HumanoidRootPart and HumanoidRootPart.Position
    if not pos then return {} end
    local list = {}
    for _, v in next, CollectionService:GetTagged("_ChestTagged") do
        if _isValidChest(v) then
            list[#list + 1] = { obj = v, dist = (v.Position - pos).Magnitude }
        end
    end
    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

-- Đợi chest xuất hiện, trả về true nếu có trước timeout
local function _waitForChest(timeout)
    local deadline = tick() + (timeout or _cfg("Chest Wait Timeout", 12))
    repeat
        task.wait(0.5)
        if #_getChestList() > 0 then return true end
    until tick() >= deadline
    return false
end

-- ─────────────────────────────────────────────────────────────
-- CORE: TELE ĐẾN CHEST + TOUCH
-- Dùng SetPrimaryPartCFrame (như New Text Document.txt) thay vì tween
-- Thêm verify + retry ghost
--
-- Trả về:
--   "collected" – lấy được (chest biến mất)
--   "ghost"     – đã retry đủ lần, vẫn không lấy được
--   "skip"      – chest invalid ngay từ đầu
--   "died"      – nhân vật chết
--   "stopped"   – stopCondition trả về true
--   "timeout"   – vượt quá giới hạn thời gian
-- ─────────────────────────────────────────────────────────────
local function _teleChest(chest, stopCondition)
    if not _isValidChest(chest) then return "skip" end

    local humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return "died" end

    local ghostRetry  = _cfg("Ghost Retry Count", 3)
    local skipDelay   = _cfg("Skip Chest Delay", 0.5)
    local timeout     = 8
    local startTick   = tick()
    local retryCount  = 0

    repeat
        -- Guard đầu mỗi vòng
        if not _isValidChest(chest) then return "collected" end
        if not Character or not humanoid or humanoid.Health <= 0 then return "died" end
        if stopCondition and stopCondition() then return "stopped" end
        if tick() - startTick > timeout then return "timeout" end

        -- Tele thẳng vào chest (SetPrimaryPartCFrame như bản gốc)
        pcall(function()
            Character:SetPrimaryPartCFrame(chest.CFrame)
        end)
        task.wait(0.05)

        -- Nhảy để trigger touch (như bản gốc)
        PressKeyEvent("Space")
        task.wait(0.1)

        -- firetouchinterest để chắc chắn hơn (như kaituncyborg)
        pcall(function()
            local root = HumanoidRootPart
            if root then
                firetouchinterest(root, chest, 0)
                task.wait(0.05)
                firetouchinterest(root, chest, 1)
            end
        end)
        task.wait(0.2)

        -- Verify: chest biến mất = collected
        if not _isValidChest(chest) then
            return "collected"
        end

        -- Chest vẫn còn = ghost, retry
        retryCount += 1
        if retryCount >= ghostRetry then
            -- Force disable rồi skip
            task.wait(skipDelay)
            pcall(function()
                if chest and chest.Parent then chest.CanTouch = false end
            end)
            return "ghost"
        end

        task.wait(0.3)
    until false
end

-- ─────────────────────────────────────────────────────────────
-- PUBLIC: FarmBeli  (tên giống bản New Text Document.txt để dễ tích hợp)
--
-- Params:
--   stopCondition : function() → bool
--   onCollect     : function(c, all) – callback mỗi chest lấy được (optional)
-- ─────────────────────────────────────────────────────────────
local _all = 0  -- counter session, reset bằng FarmBeli.Reset()

FarmBeli = function(stopCondition, onCollect)
    local maxChests  = _cfg("Max Chests", 25)
    local resetEvery = _cfg("Reset After Collect Chests", 10)
    local waitTimeout = _cfg("Chest Wait Timeout", 12)

    -- Guard
    if stopCondition and stopCondition() then return end
    if not Character or not HumanoidRootPart then return end
    local humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    -- Đã đủ max chests?
    if _all >= maxChests then
        print("Collect Chests | Đã đủ " .. maxChests .. " → Hop")
        HopServer("Max Chests")
        return
    end

    -- ── Detect chest, đợi nếu chưa có ───────────────────────
    local chests = _getChestList()

    if #chests == 0 then
        print("Collect Chests | Không có chest, đợi tối đa " .. waitTimeout .. "s...")

        local appeared = _waitForChest(waitTimeout)
        if not appeared then
            -- Sau khi đợi vẫn không có → mới hop
            if not (stopCondition and stopCondition()) and not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
                print("Collect Chests | Không có chest sau " .. waitTimeout .. "s → Hop")
                HopServer("No chest after wait")
            end
            return
        end

        chests = _getChestList()
    end

    -- ── Vòng lặp collect ─────────────────────────────────────
    local c = 0  -- batch counter

    for i, entry in next, chests do
        local v = entry.obj

        if not _isValidChest(v) then continue end
        if stopCondition and stopCondition() then break end
        if _all >= maxChests then
            print("Collect Chests | Đủ " .. maxChests .. " → Hop")
            HopServer("Max Chests")
            return
        end

        print(string.format(
            "Collect Chests | Batch: %d | Total: %d/%d | → %s",
            c, _all, maxChests, v.Name
        ))

        local result = _teleChest(v, stopCondition)

        if result == "collected" then
            c   += 1
            _all += 1
            if onCollect then pcall(onCollect, c, _all) end

            print(string.format(
                "Collect Chests | ✓ Batch: %d | Total: %d/%d",
                c, _all, maxChests
            ))

            -- Reset nhân vật sau N chests
            if c >= resetEvery and not (stopCondition and stopCondition()) then
                local h = Character and Character:FindFirstChildWhichIsA("Humanoid")
                if h and h.Health > 0 then
                    print("Collect Chests | Reset sau " .. resetEvery .. " chests...")
                    h:ChangeState(Enum.HumanoidStateType.Dead)
                    task.wait(1.5)
                end
                c = 0
            end

        elseif result == "ghost" then
            print("Collect Chests | Ghost chest: " .. v.Name .. " → Skip")

        elseif result == "died" then
            return

        elseif result == "stopped" then
            return

        elseif result == "timeout" then
            print("Collect Chests | Timeout: " .. v.Name .. " → Skip")
        end

        if stopCondition and stopCondition() then break end

        if i % 250 == 0 then task.wait(0.1) end
    end

    -- ── Sau batch: check còn chest mới không ─────────────────
    if not (stopCondition and stopCondition()) and _all < maxChests then
        local remaining = _getChestList()
        if #remaining > 0 then
            -- Còn chest mới spawn → chạy tiếp (không hop)
            FarmBeli(stopCondition, onCollect)
            return
        end
        -- Không còn chest thật → hop
        if not CheckTool("Fist of Darkness") and not CheckMonster("Darkbeard") then
            print("Collect Chests | Hết chest → Hop")
            HopServer("No chest left")
        end
    end
end

-- Reset counter session (gọi khi rejoin hoặc bắt đầu lại)
FarmBeli.Reset = function()
    _all = 0
end

-- Đọc counter hiện tại
FarmBeli.GetTotal = function()
    return _all
end

-- ─────────────────────────────────────────────────────────────
-- CÁCH DÙNG TRONG MAIN SCRIPT (thay FarmBeli cũ):
--
--  else
--      FarmBeli(
--          function()  -- stopCondition
--              return _all >= getgenv().Settings["Max Chests"]
--                  or CheckTool("Fist of Darkness")
--                  or CheckMonster("Darkbeard")
--          end,
--          function(c, total)  -- onCollect (optional, sync biến all nếu cần)
--              all = total
--          end
--      )
--  end
-- ─────────────────────────────────────────────────────────────
