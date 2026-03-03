# PRD: Update Course Roadmap - Hiển thị `sectionId` và mô tả node

## 1) Mục tiêu
- Bổ sung khả năng quản trị `sectionId` cho từng roadmap node.
- Đảm bảo mô tả node (`description`) được hiển thị/chỉnh sửa rõ ràng trong UI roadmap.
- Đồng bộ payload save để backend nhận đủ metadata node.

## 2) Bối cảnh hiện tại
- Màn hình liên quan: `/course/:courseId` (Course Detail roadmap editor).
- Roadmap node hiện có `id`, `title`, `description`, `roleplayId`, `lessonIds`, `outputId`.
- UI đã có node card + create node form + save roadmap.

## 3) Phạm vi
- In scope:
  - Data model frontend cho `sectionId`.
  - UI node card hiển thị/chỉnh sửa `sectionId`.
  - Create node form hỗ trợ nhập `sectionId` + description.
  - Save payload gửi `sectionId` + `description` cho từng node.
- Out of scope:
  - Migration dữ liệu backend cũ.
  - Thay đổi cấu trúc level/badge.

## 4) Yêu cầu chức năng
- FR-01: Mỗi node hiển thị:
  - Node ID (read-only, copy),
  - Section ID (editable),
  - Title (editable),
  - Description (editable textarea).
- FR-02: Form tạo node mới cho phép nhập:
  - `title` (bắt buộc),
  - `sectionId` (theo rule backend),
  - `description` (không bắt buộc).
- FR-03: Khi save roadmap, `sectionId` và `description` được map vào payload node.
- FR-04: Node không có `sectionId` từ dữ liệu cũ vẫn render ổn (backward compatible).

## 5) Quy tắc dữ liệu
- Đề xuất mở rộng type:
  - `IRoadmapNode.sectionId?: string`
  - `RoadmapNodePayload.sectionId?: string`
- `description` tiếp tục dùng `ITranslation`.
- Chuẩn hóa trim cho `sectionId` trước khi submit.

## 6) UX yêu cầu
- Section ID đặt gần Node ID để editor dễ đối chiếu.
- Description textarea hỗ trợ text dài, không phá layout timeline node.
- Tooltip/ellipsis cho text quá dài để giữ card gọn.

## 7) Tiêu chí chấp nhận
- AC-01: Tạo node mới có `sectionId` + description, save thành công, reload vẫn còn dữ liệu.
- AC-02: Sửa `sectionId` node hiện có, save thành công, không ảnh hưởng roleplay/lesson/output mapping.
- AC-03: Node cũ không có `sectionId` vẫn hiển thị và có thể bổ sung sau.
- AC-04: Payload gửi lên API chứa đúng `sectionId` và `description` cho node đã nhập.

## 8) File ảnh hưởng dự kiến
- `src/types/interface/course.interface.ts`
- `src/pages/courses/CourseDetail.tsx`
- `src/services/courseService.ts` (nếu cần điều chỉnh typing payload)

## 9) Unresolved Questions
- `sectionId` cần unique theo `course`, theo `level`, hay không cần unique?
- `sectionId` có format bắt buộc (vd: `S01`, `SEC-001`) không?
