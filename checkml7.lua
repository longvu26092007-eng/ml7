-- Chèn đoạn này vào phần xử lý sau khi Tween hoàn tất
task.spawn(function()
    print("[Hệ Thống] Đang gửi yêu cầu mua Sanguine Art tới Server...")
    
    -- Gửi yêu cầu và hứng kết quả trả về vào biến 'result'
    local success, result = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySanguineArt")
    end)

    -- In kết quả ra Console (F9)
    if success then
        print("------------------------------------------")
        print("[Phản hồi từ Server]:", result)
        
        -- Phân tích kết quả (tùy vào game trả về gì)
        if type(result) == "string" then
            print("[Thông báo]: " .. result)
        elseif type(result) == "boolean" and result == true then
            print("[Thông báo]: Mua thành công!")
        else
            print("[Thông báo]: Có lỗi hoặc thiếu điều kiện (Nguyên liệu/Level/Tiền).")
        end
        print("------------------------------------------")
    else
        warn("[Lỗi hệ thống]: Không thể kết nối tới Remote. Lỗi:", result)
    end
end)
