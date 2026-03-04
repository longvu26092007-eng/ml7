-- [[ CHECK DARK FRAGMENT 2/2 → GHI FILE ]]

local Player = game.Players.LocalPlayer
local CommF_ = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CommF_")

local function GetDarkFragCount()
    local ok, inv = pcall(function() return CommF_:InvokeServer("getInventory") end)
    if ok and type(inv) == "table" then
        for _, item in ipairs(inv) do
            if item.Name == "Dark Fragment" then return item.Count end
        end
    end
    return 0
end

while true do
    local count = GetDarkFragCount()
    print("[DF Check] Dark Fragment: " .. count .. "/2")

    if count >= 2 then
        pcall(function()
            writefile(Player.Name .. ".txt", "Completed-df")
        end)
        warn("[DF Check] ✅ 2/2! Đã ghi: " .. Player.Name .. ".txt → Completed-df")
        break
    end

    task.wait(10)
end
