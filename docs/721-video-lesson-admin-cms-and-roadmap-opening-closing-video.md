# PRD: #721 - Video lesson CMS và roadmap node dùng `openingVideo` / `closingVideo`

## 1) Mục tiêu
- Loại bỏ hoàn toàn logic roadmap node cũ dùng `video?: INodeVideo` và `VideoPositionInNode`.
- Đổi roadmap node sang chọn 2 lesson type `VIDEO`:
  - `openingVideo`
  - `closingVideo`
- Bổ sung CMS riêng cho video trong sidebar, ngang cấp với lesson:
  - `VideoList`
  - `VideoForm` cho create/edit detail
- `VideoForm` quản trị dữ liệu video riêng:
  - `summary` dạng HTML
  - `videoUrl` upload qua [CloudflareFileUpload.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/files/CloudflareFileUpload.tsx)
  - `videoQuestions`

## 2) Bối cảnh hiện tại
- Roadmap editor ở [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx) vẫn render/upload video trực tiếp trong node qua:
  - `IRoadmapNode.video?: INodeVideo`
  - `RoadmapNodePayload.video?: INodeVideo`
  - `VideoPositionInNode`
- Data model roadmap đã được backend/frontend mở rộng một phần:
  - `IRoadmapNode.openingVideoId?: string`
  - `IRoadmapNode.closingVideoId?: string`
  - `IRoadmapNode.openingVideo?: ILessonBrief | null`
  - `IRoadmapNode.closingVideo?: ILessonBrief | null`
  - `RoadmapNodePayload.openingVideoId?: string`
  - `RoadmapNodePayload.closingVideoId?: string`
- Lesson model đã có:
  - `summary?: ITranslation`
  - `videoUrl?: string`
  - `LessonType.VIDEO`
- Chưa có module video riêng trong router/sidebar/pages.
- `videoQuestions` hiện nằm trong [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts), chưa có UI nào quản trị.

## 3) Phạm vi
- In scope:
  - Xóa type và UI cũ của roadmap node video theo position.
  - Cập nhật roadmap editor để chọn `openingVideo` và `closingVideo`.
  - Tạo module `video` mới trong `src/pages/video/`.
  - Thêm route và sidebar item cho video.
  - Tạo `VideoList` filter `LessonType.VIDEO`.
  - Tạo `VideoForm` để create/edit video lesson.
  - `VideoForm` quản trị `summary` HTML, `videoUrl`, `videoQuestions`.
  - Đồng bộ save/load giữa video lesson và learning item video questions.
- Out of scope:
  - Refactor lớn toàn bộ `LessonForm`, `RoleplayForm`, `OutputForm`.
  - Migration dữ liệu backend cũ ngoài phần frontend mapping.
  - Thay đổi schema backend ngoài các field user xác nhận đã bổ sung.

## 4) Yêu cầu chức năng
- FR-01: Sidebar có thêm menu `Video` trong [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx).
- FR-02: Router có thêm:
  - `/video`
  - `/video/create`
  - `/video/:videoId`
- FR-03: `VideoList` hiển thị danh sách lesson type `VIDEO`, UX tương tự [LessonList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonList.tsx):
  - search theo title
  - filter theo course
  - pagination / infinite scroll theo pattern hiện có
- FR-04: `VideoForm` dùng lesson entity làm shell chính, UX/detail tương tự lesson detail page:
  - title
  - description
  - image
  - status
  - course
  - index
  - icon / lightIcon nếu pattern lesson hiện tại vẫn cần giữ
  - `summary` dạng HTML
  - `videoUrl` upload
- FR-05: `VideoForm` không có block chọn keypoints như [LessonForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonForm.tsx).
- FR-06: `VideoForm` có block `videoQuestions`, mỗi item gồm:
  - `atSecond: number`
  - `exercise: ExerciseInput`
- FR-07: Editor `exercise` trong `videoQuestions` tái sử dụng pattern nhập exercise từ [ExerciseForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx), nhưng embed bên trong `VideoForm`.
- FR-08: Roadmap node trong [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx) hiển thị thứ tự mới:
  - `openingVideo`
  - `roleplay`
  - `lessons`
  - `output`
  - `closingVideo`
- FR-09: Roadmap node cho phép chọn/bỏ chọn `openingVideo` và `closingVideo` bằng lesson type `VIDEO`.
- FR-10: Save roadmap chỉ gửi:
  - `openingVideoId`
  - `roleplayId`
  - `lessonIds`
  - `outputId`
  - `closingVideoId`
  - cùng các metadata node khác như `title`, `description`, `sectionId` nếu có
- FR-11: UI roadmap không còn render:
  - upload video trực tiếp trong node
  - select `VideoPositionInNode`

## 5) Quy tắc dữ liệu
- Xóa frontend references tới:
  - `INodeVideo`
  - `VideoPositionInNode`
  - `IRoadmapNode.video`
  - `RoadmapNodePayload.video`
- `openingVideo` và `closingVideo` đều là `ILessonBrief`, nhưng source list phải filter `LessonType.VIDEO`.
- `VideoForm` lưu lesson với:
  - `type: LessonType.VIDEO`
  - `summary?: ITranslation`
  - `videoUrl?: string`
- `videoQuestions` tiếp tục nằm ở learning item payload hiện tại:
  - `ILearningItem.videoQuestions?: IVideoQuestion[]`
  - `LearningItemPayload.videoQuestions?: VideoQuestionPayload[]`
- Frontend cần đồng bộ quan hệ lesson-video và learning-item-video-questions qua `learningItemId`.
- `summary` là HTML string theo từng ngôn ngữ, cần sanitize trước preview/render.

## 6) UX yêu cầu
- `VideoList` và `VideoForm` nên follow visual language hiện có của lesson/roleplay/output để không lệch admin CMS.
- `VideoForm.summary` dùng rich text editor hiện có trong repo, ưu tiên reuse pattern TipTap + DOMPurify đang dùng ở onboarding management.
- `videoUrl` upload bằng [CloudflareFileUpload.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/files/CloudflareFileUpload.tsx) với `accept="video/*"`.
- `videoQuestions` nên hiển thị thành danh sách card:
  - số giây
  - loại exercise
  - preview ngắn
  - edit / delete / reorder nếu cần
- Ở roadmap node, opening/closing video nên có badge hoặc icon khác lesson thường để editor phân biệt nhanh.

## 7) Tiêu chí chấp nhận
- AC-01: Sidebar mở được module `Video`.
- AC-02: `VideoList` load được lesson type `VIDEO`, search/filter hoạt động.
- AC-03: Tạo video mới thành công từ `/video/create`.
- AC-04: Edit video hiện có thành công tại `/video/:videoId`.
- AC-05: `VideoForm` save được `summary` HTML và `videoUrl`.
- AC-06: `VideoForm` save/load được `videoQuestions`.
- AC-07: `CourseDetail` không còn UI/video payload cũ theo `position`.
- AC-08: `CourseDetail` chọn được `openingVideo` và `closingVideo`, save roadmap thành công, reload vẫn đúng dữ liệu.
- AC-09: Thứ tự section trong node render đúng: opening video -> roleplay -> lessons -> output -> closing video.
- AC-10: Repo build pass sau thay đổi type và route.

## 8) File ảnh hưởng dự kiến
- [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx)
- [index.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/routes/index.tsx)
- [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- [course.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/course.enum.ts)
- [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)
- [lessonService.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/services/lessonService.ts)
- `src/pages/video/VideoList.tsx`
- `src/pages/video/VideoForm.tsx`
- `src/pages/video/VideoCreate.tsx`
- `src/pages/video/VideoDetail.tsx`
- Có thể cần tách shared helpers/editor từ:
  - [ExerciseForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx)
  - [OnboardingManagemant.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/onboardings/OnboardingManagemant.tsx)

## 9) Ghi chú triển khai
- `CourseDetail.tsx` hiện đã rất dài; nếu tiếp tục mở rộng nên tách selector block/video badge helper để giữ file manageable.
- `LessonList`, `RoleplayList`, `OutputList` đang có pattern rất giống nhau; `VideoList` nên bám pattern này, tránh refactor lớn trong ticket này.
- `VideoForm` không nên copy toàn bộ `LessonForm`; cần tách phần thật sự dùng chung hoặc clone tối thiểu rồi lược bỏ keypoints để giảm rủi ro.
- `videoQuestions.exercise` dùng union `ExerciseInput`; cần chuẩn hóa subset được hỗ trợ trong video form nếu UI embed full `ExerciseForm` là quá nặng.

## 10) Unresolved Questions
- Frontend sẽ tạo `learningItem` video theo lifecycle nào:
  - tạo cùng lúc khi save video lesson đầu tiên,
  - hay chỉ tạo khi user thêm `videoQuestions` đầu tiên?
- `videoQuestions.exercise` có cần support full 100% các loại exercise hiện có, hay chỉ subset thực tế đang dùng trong video?
