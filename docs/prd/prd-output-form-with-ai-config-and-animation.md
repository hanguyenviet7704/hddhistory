# PRD: Output Form với AI Config và Animation

## 1) Mục tiêu
- Chuẩn hóa màn hình tạo/sửa Output lesson để content team nhập đầy đủ `AIConfig` và `animation`.
- Giảm lỗi payload khi publish output.
- Tăng khả năng preview nhanh tài nguyên media khi biên tập.

## 2) Bối cảnh hiện tại
- Màn hình liên quan: `/output/create`, `/output/:lessonId`.
- API lesson hiện dùng create/update chung, type `OUTPUT`.
- Trường dữ liệu trọng tâm: `AIConfig` (HTML string), `animation` (avatar id).

## 3) Phạm vi
- In scope:
  - Form tạo/sửa output.
  - AI Config editor (rich text cơ bản).
  - Search/chọn animation từ avatar service.
  - Save payload đầy đủ cho backend.
- Out of scope:
  - Thay đổi schema backend lesson.
  - Thiết kế lại trang list output toàn bộ.

## 4) Yêu cầu chức năng
- FR-01: Form có đầy đủ field:
  - `title`, `description`, `image`, `icon`, `lightIcon`, `status`, `course`, `AIConfig`, `animation`.
- FR-02: `AIConfig` hỗ trợ định dạng cơ bản: bold, italic, bullet list, ordered list.
- FR-03: Animation picker:
  - search theo tên,
  - chọn 1 animation,
  - clear animation đã chọn.
- FR-04: Khi save:
  - map `animation` về `_id`,
  - giữ `AIConfig` dưới dạng HTML string,
  - gửi đúng `LessonPayload` type `OUTPUT`.
- FR-05: Hỗ trợ create mới và edit hiện có trên cùng một form component.

## 5) Quy tắc dữ liệu
- `type` luôn là `LessonType.OUTPUT`.
- `AIConfig` cho phép rỗng, nhưng nếu có phải serialize đúng HTML.
- `animation` cho phép null.
- Translation fields (`title`, `description`, `estimateCompleTime`) phải được clean trước khi submit.

## 6) UX yêu cầu
- Form hiển thị trạng thái loading/saving rõ ràng.
- Search dropdown cho icon/lightIcon/animation phản hồi nhanh.
- Có thể xóa Output ở màn hình detail với confirm dialog.
- Error message ưu tiên hiển thị từ backend nếu có.

## 7) Tiêu chí chấp nhận
- AC-01: Tạo output mới với `AIConfig` + `animation`, lưu thành công và redirect về detail.
- AC-02: Sửa output hiện có, giữ nguyên dữ liệu cũ khi không thay đổi field.
- AC-03: Clear animation rồi save, backend nhận `animation` rỗng/null hợp lệ.
- AC-04: `AIConfig` nhập rich text, reload detail không mất format cơ bản.

## 8) File ảnh hưởng dự kiến
- `src/pages/output/OutputForm.tsx`
- `src/pages/output/OutputCreate.tsx`
- `src/pages/output/OutputDetail.tsx`
- `src/types/interface/lesson.interface.ts`

## 9) Unresolved Questions
- Có cần sanitize HTML `AIConfig` phía client trước submit (ngoài sanitize ở backend) không?
- Có cần preview animation trực tiếp trong form (không chỉ chọn theo tên/avatar) không?
