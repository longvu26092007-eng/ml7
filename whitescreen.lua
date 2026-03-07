local TweenService = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Tìm hoặc Tạo ScreenGui (Đảm bảo phủ kín màn hình)
local screenGui = script.Parent -- Hoặc playerGui:WaitForChild("ScreenGui")
if screenGui:IsA("ScreenGui") then
	screenGui.IgnoreGuiInset = true -- QUAN TRỌNG: Phủ kín cả thanh TopBar
end

-- 2. Tham chiếu đến Frame trắng
local whiteFrame = screenGui:WaitForChild("White_screen")

-- 3. Thiết lập thuộc tính ban đầu để chắc chắn "không hiện gì" ngoài màu trắng
whiteFrame.Size = UDim2.new(1, 0, 1, 0)
whiteFrame.Position = UDim2.new(0, 0, 0, 0)
whiteFrame.BackgroundColor3 = Color3.new(1, 1, 1) -- Màu trắng tinh
whiteFrame.BorderSizePixel = 0
whiteFrame.ZIndex = 1000000 -- Đè lên mọi thứ khác
whiteFrame.Visible = true
whiteFrame.BackgroundTransparency = 1 -- Bắt đầu từ tàng hình

-- 4. Cấu hình Tween
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local createTween = TweenService:Create(whiteFrame, tweenInfo, {
	BackgroundTransparency = 0 -- Tiến về trắng xóa hoàn toàn
})

-- 5. Chạy
createTween:Play()

-- Sau khi trắng xóa, bạn có thể thêm lệnh xóa UI hoặc chuyển cảnh ở đây
createTween.Completed:Connect(function()
	print("Màn hình hiện đã trắng xóa hoàn toàn, không thấy gì khác!")
end)
