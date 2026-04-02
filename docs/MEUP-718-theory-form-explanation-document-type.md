# PRD: MEUP-718 - Theory Form hỗ trợ document type `EXPLANATION`

## 1) Mục tiêu
- Bổ sung loại document `EXPLANATION` trong [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx) để content team nhập theory explanation trực tiếp trên form.
- Đồng bộ frontend với thay đổi type `IMediaDocument -> IDocumentData`.
- Đảm bảo payload theory gửi lên backend chứa đúng `content` và `options` cho document type mới.
- Mỗi `IExplanationOption` hỗ trợ thêm `icon: string | null` để upload icon riêng cho từng option.

## 2) Bối cảnh hiện tại
- Enum `DocumentType` đã có `EXPLANATION = "explanation"` trong [course.enum.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/utils/enum/course.enum.ts).
- Interface document đã đổi sang `IDocumentData` và đã có `options?: IExplanationOption[]` trong [document.interface.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/learning-item/document.interface.ts).
- [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx) vẫn đang import và dùng tên cũ `IMediaDocument`.
- UI documents của theory hiện mới support:
  - text-like: `TITLE`, `CAPTION`, `TEXT`
  - media-like: `IMAGE`, `VIDEO`, `AUDIO`, `ANIMATION`
- Hiện chưa có nhánh render, validate, clean data và preview cho `EXPLANATION`.

## 3) Phạm vi
- In scope:
  - Thêm option `EXPLANATION` trong dropdown type của document ở [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx).
  - Khi chọn `EXPLANATION`, form cho nhập:
    - `content: ITranslation`
    - `options?: IExplanationOption[]`
    - `options[].icon: string | null`
  - Chuẩn hóa các chỗ còn dùng `IMediaDocument` sang `IDocumentData`.
  - Cập nhật logic clean/submit/preview để support `EXPLANATION`.
- Out of scope:
  - Thay đổi schema backend.
  - Thêm UI `EXPLANATION` cho module ngoài task này nếu không đang dùng theory documents.
  - Refactor lớn cấu trúc `TheoryForm`.

## 4) Yêu cầu chức năng
- FR-01: Dropdown type trong document editor của theory có thêm giá trị `EXPLANATION`.
- FR-02: Khi type là `EXPLANATION`, hiển thị input cho `content`:
  - dùng `ITranslation`,
  - nhập theo ngôn ngữ đang chọn giống các field translation hiện có.
- FR-03: Khi type là `EXPLANATION`, hiển thị danh sách `options` dạng lặp:
  - mỗi option có `id`,
  - `icon: string | null`,
  - `value: ITranslation`,
  - `explanation: ITranslation`.
- FR-04: Editor cho phép:
  - thêm option mới,
  - sửa option hiện có,
  - xóa option.
  - upload icon riêng cho từng option qua `CloudflareFileUpload`.
- FR-05: Khi save theory document:
  - `content` được clean như các field translation khác,
  - `options` được giữ lại nếu có dữ liệu hợp lệ,
  - option rỗng hoàn toàn bị loại khỏi payload.
- FR-06: Ở list preview documents của theory, document type `EXPLANATION` phải hiển thị được ít nhất:
  - `content`,
  - số lượng options hoặc tóm tắt option đầu tiên để editor nhận biết dữ liệu đã lưu.
- FR-07: Các type document cũ tiếp tục hoạt động như trước, không hồi quy với text/media documents.
- FR-08: Rename type alias:
  - thay mọi import/usage `IMediaDocument` bằng `IDocumentData`
  - không đổi shape dữ liệu runtime ngoài phần rename.

## 5) Quy tắc dữ liệu
- `IDocument.data` dùng `IDocumentData`.
- Với `DocumentType.EXPLANATION`:
  - `data.content` là field chính, dùng `ITranslation`.
  - `data.options` là optional.
  - mỗi `option.id` cần ổn định trong phạm vi document để phục vụ render/update.
  - mỗi `option.icon` là string URL hoặc `null`, cho phép rỗng.
- Với `DocumentType.EXPLANATION`, `url` và `thumbnail` không dùng; cần tránh gửi rác nếu không có giá trị.
- Với các type text/media khác, hành vi hiện tại được giữ nguyên.
- `cleanDocumentItems` cần coi `EXPLANATION` là document hợp lệ khi:
  - có `content` hợp lệ, hoặc
  - có ít nhất 1 option hợp lệ.

## 6) UX yêu cầu
- `EXPLANATION` nên có layout rõ ràng, tách 2 phần:
  - explanation content,
  - explanation options.
- `content` dùng textarea.
- Mỗi option nên hiển thị thành một block/card nhỏ để editor dễ đọc:
  - field `icon`,
  - field `value`,
  - field `explanation`,
  - nút remove.
- Có nút `Add Option`.
- Khi đổi type từ type khác sang `EXPLANATION`, data cũ của document được reset về shape mặc định an toàn.
- Khi đổi từ `EXPLANATION` sang type khác, `options` không tiếp tục bám theo payload type mới.

## 7) Tiêu chí chấp nhận
- AC-01: User tạo theory document mới với type `EXPLANATION`, nhập `content`, thêm `options` và upload `icon`, save thành công.
- AC-02: User edit theory document `EXPLANATION` hiện có, dữ liệu `content/options/icon` được load lại đúng và update được.
- AC-03: Save theory không làm mất dữ liệu của các document type cũ.
- AC-04: Payload frontend gửi lên không còn phụ thuộc tên `IMediaDocument`.
- AC-05: Repo compile pass sau khi rename `IMediaDocument -> IDocumentData` ở các chỗ đang import type cũ.

## 8) File ảnh hưởng dự kiến
- [TheoryForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/theories/TheoryForm.tsx)
- [document.interface.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/learning-item/document.interface.ts)
- [theory.interface.ts](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/types/interface/learning-item/theories/theory.interface.ts)
- [ExerciseForm.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/exercises/ExerciseForm.tsx)
- [RoleplayFromDetail.tsx](/Users/macbook/Documents/eUp Group/admin-ai-tutor/src/pages/roleplays/RoleplayFromDetail.tsx)

## 9) Ghi chú triển khai
- `TEXTUAL_DOCUMENT_TYPES` hiện chưa gồm `EXPLANATION`; cần quyết định rõ:
  - nếu chỉ `content` là textual còn `options` có UI riêng, không nên gộp chung hoàn toàn vào nhánh text hiện tại;
  - nên thêm nhánh render riêng cho `DocumentType.EXPLANATION`.
- Hàm `createEmptyMediaDocument` nên đổi tên theo data model mới, ví dụ `createEmptyDocumentData`, để tránh lệch nghĩa với `options`.
- Những type helper như `keyof IMediaDocument` cần đổi theo `keyof IDocumentData`.

## 10) Unresolved Questions
- Với `EXPLANATION`, có bắt buộc phải có ít nhất 1 option hay cho phép chỉ lưu `content`?
- Ở list preview, cần hiển thị toàn bộ options hay chỉ hiển thị số lượng/tóm tắt ngắn?
- Task rename `IMediaDocument -> IDocumentData` có cần thực hiện toàn repo trong cùng ticket này hay chỉ các file chạm để compile pass?
