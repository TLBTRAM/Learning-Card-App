# Learning Card App — UI & Design System

## 1. Concept tổng thể

Concept **Modern Academic Atelier** kết hợp sự điềm tĩnh của một thư viện học thuật với độ tinh gọn của sản phẩm số cao cấp. Navy tạo cảm giác tập trung, kem và trắng ngà làm nền giấy, lavender đại diện cho sáng tạo, còn vàng đồng dùng rất tiết chế cho điểm nhấn và thành tích.

Nguyên tắc thiết kế:

- Thông tin học tập quan trọng luôn nổi bật hơn trang trí.
- Surface bo góc 16–24 px, viền mảnh và shadow nhẹ.
- Toàn bộ nội dung dùng Arial và font hệ thống tương thích để giữ nét cổ điển, rõ ràng và dễ đọc.
- Animation ngắn 180–450 ms, phục vụ phản hồi và định hướng.
- Light/dark mode dùng cùng hệ phân cấp thị giác, không chỉ đảo màu.
- Empty, loading, error và success dùng ngôn ngữ thân thiện, không lộ lỗi kỹ thuật.

## 2. Bảng màu

| Token | Hex | Vai trò |
|---|---:|---|
| Navy | `#17233C` | Primary, hero card, nút chính |
| Navy Light | `#263754` | Surface trên nền navy |
| Cream | `#F6F0E5` | Nền phụ, khối học thuật |
| Ivory | `#FCFAF5` | Nền chính light mode |
| Lavender | `#A99AD8` | Điểm nhấn sáng tạo |
| Lavender Soft | `#EAE5F6` | Selected state, chip, icon background |
| Lavender Deep | `#7565A7` | Accent dễ đọc |
| Brass | `#C7A565` | Achievement, CTA phụ cao cấp |
| Brass Soft | `#F2E6CE` | Background cho badge vàng đồng |
| Ink | `#202A3B` | Nội dung chính |
| Slate | `#667085` | Nội dung phụ |
| Success | `#4D8064` | Đã nhớ, đáp án đúng |
| Warning | `#B47B36` | Hơi nhớ, cần chú ý |
| Error | `#B85450` | Chưa nhớ, đáp án sai |
| Dark Background | `#101724` | Nền dark mode |
| Dark Surface | `#182233` | Card dark mode |
| Dark Surface High | `#202C40` | Surface nổi dark mode |

Token được khai báo tại `lib/theme/app_colors.dart`.

## 3. Typography

- **Toàn ứng dụng:** Arial, weight 400–700 — cổ điển, rõ ràng và quen thuộc trên màn hình nhỏ.
- **Fallback:** Helvetica Neue → Roboto → sans-serif khi thiết bị không cài Arial.
- Body mặc định 14–16 px, line height 1.45–1.55.
- Label 12–14 px, dùng weight 700 và letter spacing nhẹ cho eyebrow.

Typography được khai báo tại `lib/theme/app_text_styles.dart`; theme sáng/tối nằm trong `lib/theme/app_theme.dart`.

## 4. Cấu trúc thư mục

```text
lib/
├── core/
│   ├── constants/
│   ├── theme/                 # export tương thích code cũ
│   └── utils/                 # thông báo UI thân thiện
├── data/                      # nội dung tĩnh không phải dữ liệu học tập
├── models/                    # model API, dashboard, review, tìm kiếm, chia sẻ
├── providers/                 # state phiên đăng nhập và trạng thái màn hình
├── screens/
│   ├── ai/
│   ├── auth/
│   ├── flashcards/
│   ├── home/
│   ├── notes/
│   ├── profile/
│   ├── review/
│   └── splash/
├── services/                  # API service hiện hữu
├── theme/                     # AppColors, AppTextStyles, AppTheme
├── widgets/                   # component tái sử dụng
└── main.dart
```

## 5. Danh sách màn hình

1. Splash Screen — logo, slogan, loading và fade/scale animation.
2. Welcome Screen — giới thiệu ngắn và entry point đăng nhập/đăng ký.
3. Login Screen — validation, password visibility, loading, quên mật khẩu và lỗi thân thiện.
4. Register Screen — họ tên, email, password, confirm password và điều khoản.
5. Home Dashboard — tìm kiếm tức thì, hoạt động học thật trong ngày, tiến độ, bộ thẻ gần đây và AI shortcut.
6. Flashcard Library — bộ thẻ riêng tư/được chia sẻ, tác giả, responsive grid/list, loading, empty và error.
7. Create Flashcard Set — metadata, chủ đề, màu, nhiều thẻ, ví dụ, vị trí ảnh và autosave draft state.
8. Flashcard Set Detail — overview, tiến độ, học, quiz, chỉnh sửa và menu từng thẻ.
9. Create/Edit Flashcard — form validation và trạng thái lưu.
10. Study Mode — flip animation, swipe, phát âm UI, ba mức ghi nhớ và tổng kết.
11. Quiz Mode — 4 đáp án, timer tùy chọn, đúng/sai, giải thích và kết quả.
12. Review — hàng đợi đến hạn thật, biểu đồ phiên học 7 ngày, lịch sử 14 ngày và CTA ôn tập.
13. Notes — ghi chú riêng tư/được chia sẻ, tác giả, text note, canvas, màu/độ dày bút, tẩy, undo/redo.
14. AI Study Assistant — suggestion chip, chat bubble, typing animation và trạng thái lỗi.
15. Profile — avatar, thống kê, streak, achievement, settings, dark mode và đăng xuất.

Bottom navigation gồm Home, Flashcards, Review, Notes và Profile. AI được mở từ Home để giữ navigation chính tập trung vào chu trình học.

## 6. Thành phần Flutter chính

Các file trong `lib/screens/` chứa code hoàn chỉnh theo từng màn hình. Component dùng chung:

- `AppLogo`: logo flashcard code-native, không phụ thuộc asset.
- `AppButton`: primary action có loading state.
- `PremiumSurface`: card/surface đồng bộ radius, border và shadow.
- `ResponsiveContent`: giới hạn bề rộng nội dung trên màn hình lớn.
- `SectionHeader`: tiêu đề section có subtitle/action.
- `StatePanel`: empty/error state thống nhất.
- `SkeletonList`: loading skeleton có animation nhẹ.
- `ChatBubble`: phân biệt rõ tin nhắn người dùng và AI.
- `ShareSheet`: chia sẻ theo email, thu hồi quyền và chọn riêng tư/công khai.

Dashboard, Review, Profile, flashcard và ghi chú đều dùng dữ liệu thật theo tài khoản đăng nhập. `lib/data/sample_study_data.dart` chỉ còn nội dung suggestion chip của AI, không chứa số liệu học tập giả.

## 7. Hướng dẫn chạy

Yêu cầu: Flutter SDK, Android Studio/Android Emulator, Node.js và MySQL.

### Backend

Từ thư mục gốc repository:

```powershell
cd LearningCardApp_Backend
npm install
npm run db:demo
npm run dev
```

`npm run db:demo` chạy migration và nạp hai tài khoản mẫu có flashcard, ghi chú, dữ liệu chia sẻ, Dashboard và Review thật:

- `minh.demo@learningcard.local` / `Demo@123`
- `lan.demo@learningcard.local` / `Demo@123`

Nếu không muốn nạp dữ liệu mẫu, chỉ chạy `npm run migrate`.

Backend mặc định chạy tại `http://localhost:5000`. MySQL và file `.env` phải được cấu hình theo README ở thư mục gốc.

### Flutter

Mở terminal thứ hai:

```powershell
cd LearningCardApp
flutter pub get
flutter devices
flutter run
```

Để kiểm tra chất lượng:

```powershell
flutter analyze
flutter test
```

## 8. Kết nối API

Base URL nằm tại `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

Chọn URL theo môi trường:

- Android Emulator: `http://10.0.2.2:5000/api`
- iOS Simulator, Windows, macOS hoặc Web local: `http://localhost:5000/api`
- Điện thoại thật: `http://<IP-LAN-CUA-MAY>:5000/api`

Luồng hiện tại được giữ nguyên:

```text
Screen → Provider → Service → ApiService (Dio) → Backend
```

Khi bổ sung endpoint mới:

1. Thêm method vào service tương ứng trong `lib/services/`.
2. Map response sang model trong `lib/models/`.
3. Quản lý loading/success/empty/error tại provider.
4. UI chỉ đọc state và gọi action của provider.
5. Chuyển lỗi kỹ thuật thành thông báo thân thiện qua `UiFeedback`, không hiển thị nguyên văn response backend.

JWT được lưu bằng Shared Preferences và tự gắn vào `Authorization: Bearer <token>` trong `ApiService`; các endpoint và cơ chế xác thực cũ không bị thay đổi bởi redesign.

### Quyền riêng tư và chia sẻ

- Bộ thẻ và ghi chú mới mặc định là `private`.
- Chỉ chủ sở hữu được sửa, xóa, chia sẻ hoặc đổi visibility.
- Người được chia sẻ có quyền xem/học; giao diện luôn hiển thị người tạo.
- `public` cho phép người dùng khác tìm thấy nội dung, nhưng không trao quyền sửa.
- Khi đăng xuất, toàn bộ state theo người dùng được xóa trước khi vào tài khoản tiếp theo.

API bổ sung: `/api/search`, `/api/dashboard`, `/api/dashboard/review`, các route `/share`, `/shares`, `/visibility` của sets và notes, cùng `/api/progress/review`.
