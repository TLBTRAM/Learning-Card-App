# Learning Card App — Flutter

Ứng dụng flashcard, ghi chú và trợ lý học tập AI xây dựng bằng Flutter Material 3.

## Chạy nhanh

```powershell
flutter pub get
flutter run
```

Ứng dụng Android Emulator đang dùng API tại `http://10.0.2.2:5000/api`. Trước khi chạy Flutter, backend cần được migrate và khởi động:

```powershell
cd ..\LearningCardApp_Backend
npm install
npm run db:demo
npm run dev
```

Tài khoản mẫu:

- `minh.demo@learningcard.local` / `Demo@123`
- `lan.demo@learningcard.local` / `Demo@123`

Trong terminal khác, chạy app Flutter:

```powershell
cd ..\LearningCardApp
flutter pub get
flutter run
```

Xem hướng dẫn đầy đủ về thiết kế, cấu trúc, quyền riêng tư, chạy app và kết nối API trong [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

## Kiểm tra mã nguồn

```powershell
dart format lib test
flutter analyze
flutter test
```
