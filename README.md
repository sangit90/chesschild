# Cờ Vua Của Bé

Ứng dụng cờ vua cho iPad 6, viết bằng SwiftUI. Có thể chọn **Chơi với máy** hoặc **Hai người chơi** trên cùng iPad. Trong chế độ hai người, quân Trắng và Đen lần lượt đi; nút **Đi lại** hoàn tác một nước. Trong chế độ chơi với máy, bé chọn cầm quân **Trắng** hoặc **Đen**; nếu chọn Đen, bàn cờ xoay về phía bé, chữ cái cột chuyển lên trên, số hàng chuyển sang phải và máy đi trước. Đổi màu quân bắt đầu ván mới. Bé có bốn thử thách đầu tiên: kiểm soát trung tâm, phát triển Mã, ăn quân và nhập thành. Máy có hai mức **Tập chơi** và **Thử thách**. Bấm **Gợi ý** nhiều lần để lần lượt xem các phương án khác nhau cho bên đang đi; danh sách được làm mới sau mỗi nước đi. Tiến bộ khi chơi với máy (số ván, số thắng, sao thử thách) được lưu trên iPad.

## Tạo IPA bằng GitHub Actions

1. Đưa mã nguồn lên một repository GitHub.
2. Mở tab **Actions** → **Build iPad IPA** → **Run workflow**. Workflow cũng chạy khi push lên `main` hoặc `master`.
3. Khi job hoàn tất, tải artifact **ChessChild-iPad-IPA** và giải nén để lấy `ChessChild-unsigned.ipa`.
4. Trên máy tính, mở [Sideloadly](https://sideloadly.io/), chọn iPad, kéo IPA vào cửa sổ, nhập Apple ID và chọn **Apple ID Sideload** để Sideloadly ký và cài ứng dụng.

IPA từ Actions **chưa được ký**; không cài trực tiếp bằng Files trên iPad. Sideloadly ký IPA khi cài. Với tài khoản Apple miễn phí, ứng dụng thường cần ký lại sau 7 ngày. Trên iPadOS 16 trở lên, bật **Developer Mode** trong Settings → Privacy & Security; nếu iPad báo nhà phát triển chưa tin cậy, vào Settings → General → VPN & Device Management để tin cậy tài khoản. Dùng cùng Apple ID và bundle ID để cài đè bản mới, giữ dữ liệu trên máy.

## Phát triển trên Mac

```sh
brew install xcodegen
xcodegen generate
open ChessChild.xcodeproj
```

Project dùng iOS 15 làm mức tối thiểu và chỉ nhắm đến iPad. Khi chạy từ Xcode trên thiết bị, chọn Team ký ứng dụng của bạn trong phần Signing & Capabilities. GitHub Actions build trên macOS và đóng gói IPA chưa ký để dùng với Sideloadly, nên không cần đưa chứng chỉ Apple lên GitHub.

## Phạm vi bản đầu

Luật cờ gồm chiếu, chiếu hết, hòa do hết nước đi, nhập thành, bắt tốt qua đường và phong Hậu tự động. Trợ lý gợi ý tối đa tám nước ứng viên được xếp hạng, rồi quay lại từ đầu khi đã xem hết; nếu chỉ còn một nước hợp lệ, gợi ý đó sẽ lặp lại. Đây là bản học qua thực hành; lộ trình bài học, bài tập thế cờ, âm thanh và đánh giá kỹ năng theo chủ đề có thể bổ sung ở các bản sau.
"# chesschild" 
