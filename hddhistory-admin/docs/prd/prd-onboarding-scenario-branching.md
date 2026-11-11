# PRD: Onboarding Scenario Branching

## 1) Mục tiêu
- Chuẩn hóa luồng cấu hình branching cho onboarding trong admin.
- Giảm lỗi dữ liệu scene/option khi biên tập và publish.
- Tăng tốc thao tác cho content team khi tạo flow nhiều nhánh.

## 2) Bối cảnh hiện tại
- Màn hình hiện hữu: `/onboarding-branching`.
- API hiện hữu: `GET/PUT /onboardings` (v2) qua `onboardingService`.
- Data model hiện hữu dùng `entrySceneId`, `scenes[]`, `contents[]`, `branch.options[]`.

## 3) Phạm vi
- In scope:
  - Quản lý scene tree (entry scene, scene con theo option).
  - Quản lý content theo type: `fact`, `activation`, `branch`, `fixed`, `person_admire`.
  - Tạo scene mới + link trực tiếp từ branch option.
  - Lưu payload đúng format backend đang dùng.
- Out of scope:
  - Thay đổi logic runtime của app learner.
  - Redesign toàn bộ UI sidebar/global layout.

## 4) Yêu cầu chức năng
- FR-01: Cho phép tạo/xóa/chọn scene, set entry scene.
- FR-02: Mỗi scene chỉ có tối đa 1 `branch` content.
- FR-03: `person_admire` chỉ được thêm ở entry scene.
- FR-04: Với mỗi branch option, cho phép:
  - sửa label/icon,
  - chọn `nextSceneId` đã có,
  - tạo scene mới và auto-link vào option.
- FR-05: Ở entry scene, option của branch hỗ trợ gán danh sách `courses`.
- FR-06: Hỗ trợ tìm nhanh theo scene ID / option label để điều hướng flow.
- FR-07: Khi save, hệ thống sanitize dữ liệu translation và giữ tương thích payload cũ.

## 5) Quy tắc dữ liệu
- Scene ID phải unique trong cùng 1 onboarding flow.
- Option ID được reindex liên tục sau khi thêm/xóa.
- `nextSceneId` nếu có phải trỏ tới scene tồn tại.
- Payload lưu gồm:
  - `entrySceneId: string`
  - `scenes: IOnboardingScenarioScene[]`

## 6) UX yêu cầu
- Có xác nhận trước khi xóa scene.
- Hiển thị rõ entry scene trong panel tree.
- Cho phép thao tác nhanh không rời context (inline edit trong editor).
- Thông báo lỗi/success rõ ràng khi save.

## 7) Tiêu chí chấp nhận
- AC-01: Tạo mới 1 flow có >= 3 scene, save thành công, reload không mất dữ liệu.
- AC-02: Xóa scene entry tự chuyển entry sang scene hợp lệ tiếp theo.
- AC-03: Tạo option mới, link scene mới, tree hiển thị đúng quan hệ cha-con.
- AC-04: Không thể thêm `person_admire` ngoài entry scene.
- AC-05: Với branch ở entry scene, add/remove course trong option hoạt động ổn định.

## 8) File ảnh hưởng dự kiến
- `src/pages/onboardings/OnboardingManagemantScenarioBranching.tsx`
- `src/services/onboardingService.ts`
- `src/types/interface/onboarding-scenario-branching.interface.ts`

## 9) Unresolved Questions
- Rule cycle trong graph: cho phép loop hay chặn tuyệt đối?
- Có cần validation “orphan scenes” (scene không reachable từ entry) trước khi save không?
