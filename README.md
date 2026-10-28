# Cờ Vua Của Bé

Ứng dụng cờ vua một người cho iPad 6, viết bằng SwiftUI. Bé cầm quân trắng, chọn quân để xem nước đi hợp lệ, bấm **Gợi ý** khi cần, **Đi lại** để thử cách khác và học cách đi của từng quân ngay trong lúc chơi. Bốn thử thách đầu tiên dẫn bé từ kiểm soát trung tâm đến phát triển Mã, ăn quân và nhập thành. Máy có hai mức **Tập chơi** và **Thử thách**. Tiến bộ (số ván, số thắng, sao thử thách) được lưu trên iPad.

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

Luật cờ gồm chiếu, chiếu hết, hòa do hết nước đi, nhập thành, bắt tốt qua đường và phong Hậu tự động. Trợ lý gợi ý một nước đi và giải thích cách đi của quân đang chọn. Đây là bản học qua thực hành; lộ trình bài học, bài tập thế cờ, âm thanh và đánh giá kỹ năng theo chủ đề có thể bổ sung ở các bản sau.
