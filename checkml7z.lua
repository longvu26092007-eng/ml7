-- [[ TEST MUA SANGUINE ART - THỬ TẤT CẢ REMOTE ]]
-- Gửi lệnh đến NPC theo nhiều kiểu, log response để tìm đúng cách

local RS = game:GetService("ReplicatedStorage")
local CommF_ = RS:WaitForChild("Remotes"):WaitForChild("CommF_")
local Net = RS:WaitForChild("Modules"):WaitForChild("Net")

local function SafeLog(tag, func)
    local ok, result = pcall(func)
    print("==========================================")
    if ok then
        print("[" .. tag .. "] Response type:", type(result))
        if type(result) == "table" then
            for k, v in pairs(result) do
                print("  ", k, "=", tostring(v))
            end
        else
            print("[" .. tag .. "] Value:", tostring(result))
        end
    else
        warn("[" .. tag .. "] LỖI:", tostring(result))
    end
    print("==========================================")
    task.wait(0.5)
end

print("\n🔍 BẮT ĐẦU TEST MUA SANGUINE ART\n")

-- 1. CommF_ BuySanguineArt (cách cũ)
SafeLog("CommF BuySanguineArt", function()
    return CommF_:InvokeServer("BuySanguineArt")
end)

-- 2. CommF_ BuySanguineArt với true (kiểu BuyDragonTalon check)
SafeLog("CommF BuySanguineArt true", function()
    return CommF_:InvokeServer("BuySanguineArt", true)
end)

-- 3. RF/InteractDragonQuest - Command = BuySanguineArt
SafeLog("RF/InteractDragonQuest BuySanguineArt", function()
    local RF = Net:FindFirstChild("RF/InteractDragonQuest")
    if RF then
        return RF:InvokeServer({NPC = "Dragon Wizard", Command = "BuySanguineArt"})
    end
    return "RF not found"
end)

-- 4. RF/InteractDragonQuest - Command = SanguineArt
SafeLog("RF/InteractDragonQuest SanguineArt", function()
    local RF = Net:FindFirstChild("RF/InteractDragonQuest")
    if RF then
        return RF:InvokeServer({NPC = "Dragon Wizard", Command = "SanguineArt"})
    end
    return "RF not found"
end)

-- 5. RF/InteractDragonQuest - Command = Buy
SafeLog("RF/InteractDragonQuest Buy", function()
    local RF = Net:FindFirstChild("RF/InteractDragonQuest")
    if RF then
        return RF:InvokeServer({NPC = "Dragon Wizard", Command = "Buy"})
    end
    return "RF not found"
end)

-- 6. RF/InteractDragonQuest - Command = Speak (xem NPC nói gì)
SafeLog("RF/InteractDragonQuest Speak", function()
    local RF = Net:FindFirstChild("RF/InteractDragonQuest")
    if RF then
        return RF:InvokeServer({NPC = "Dragon Wizard", Command = "Speak"})
    end
    return "RF not found"
end)

-- 7. CommF_ UpgradeRace Buy (kiểu V4)
SafeLog("CommF UpgradeRace Buy", function()
    return CommF_:InvokeServer("UpgradeRace", "Buy")
end)

-- 8. CommF_ UpgradeRace Check
SafeLog("CommF UpgradeRace Check", function()
    return CommF_:InvokeServer("UpgradeRace", "Check")
end)

-- 9. RF/Craft - Craft Sanguine Art
SafeLog("RF/Craft SanguineArt", function()
    local RFCraft = Net:FindFirstChild("RF/Craft")
    if RFCraft then
        return RFCraft:InvokeServer("Craft", "Sanguine Art", {})
    end
    return "RF/Craft not found"
end)

-- 10. RF/Craft - Craft SanguineArt (no space)
SafeLog("RF/Craft SanguineArt nospace", function()
    local RFCraft = Net:FindFirstChild("RF/Craft")
    if RFCraft then
        return RFCraft:InvokeServer("Craft", "SanguineArt", {})
    end
    return "RF/Craft not found"
end)

-- 11. CommF_ BuyFightingStyle SanguineArt
SafeLog("CommF BuyFightingStyle SanguineArt", function()
    return CommF_:InvokeServer("BuyFightingStyle", "Sanguine Art")
end)

-- 12. CommF_ BuyFightingStyle Sanguine
SafeLog("CommF BuyFightingStyle Sanguine", function()
    return CommF_:InvokeServer("BuyFightingStyle", "Sanguine")
end)

-- 13. Scan tất cả RF/ trong Net để tìm liên quan
print("\n📋 DANH SÁCH TẤT CẢ RF/ TRONG NET:")
for _, child in ipairs(Net:GetChildren()) do
    if child.Name:find("RF/") then
        print("  →", child.Name, "| Class:", child.ClassName)
    end
end

print("\n✅ TEST HOÀN TẤT! Check Console (F9) để xem response.")
