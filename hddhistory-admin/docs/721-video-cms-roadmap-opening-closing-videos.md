# PRD: #721 - Video CMS và roadmap node dùng `openingVideo` / `closingVideo`

## 1) Mục tiêu
- Loại bỏ toàn bộ logic video inline trong roadmap node dựa trên `video?: INodeVideo` và `VideoPositionInNode`.
- Chuyển roadmap node sang chọn 2 lesson type `VIDEO` riêng biệt: `openingVideo` và `closingVideo`.
- Bổ sung module quản trị video riêng trong sidebar, gồm `VideoList` và `VideoForm`.
- Cho phép content team tạo/sửa video lesson với `summary` dạng HTML, `videoUrl` upload Cloudflare, và `videoQuestions`.

## 2) Bối cảnh hiện tại
- [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx) vẫn đang render/saving `node.video` và `VideoPositionInNode`.
- [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts) hiện đang chứa cả shape cũ `video?: INodeVideo` lẫn các field mới `openingVideoId`, `closingVideoId`, `openingVideo`, `closingVideo`.
- [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts) đã có `summary?: ITranslation` và `videoUrl?: string`, đồng thời enum lesson đã có `LessonType.VIDEO`.
- Sidebar hiện chưa có module video trong [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx), routes cũng chưa có `/video`.
- `videoQuestions` đang được khai báo trên [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts), không nằm trên `ILesson`.
- [RoleplayForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/roleplays/RoleplayForm.tsx) đã có pattern save `learning item` trước rồi gắn `learningItemId` khi save lesson; đây là pattern cần tái dùng cho video nếu backend vẫn giữ `videoQuestions` trên `ILearningItem`.

## 3) Phạm vi
- In scope:
  - Xóa UI/payload/type usage của roadmap inline video.
  - Cập nhật roadmap editor để chọn `openingVideo` và `closingVideo`.
  - Tạo module `video` mới trong sidebar, routes, list, create/detail form.
  - Tạo `VideoForm` cho lesson type `VIDEO`.
  - `VideoForm` quản lý:
    - metadata lesson chung,
    - `summary` HTML,
    - `videoUrl` upload,
    - `videoQuestions`.
  - Đồng bộ save flow giữa `lessonService` và `learningItemService` cho video nếu cần.
- Out of scope:
  - Thay đổi schema backend ngoài những field đã được backend bổ sung.
  - Migration dữ liệu video cũ trong DB.
  - Refactor lớn `LessonForm`/`LessonList` sang shared abstraction nếu không thật sự cần.

## 4) Yêu cầu chức năng
- FR-01: Roadmap node không còn hiển thị, chỉnh sửa, hoặc submit `node.video`.
- FR-02: Roadmap node hiển thị thứ tự section cố định:
  - `openingVideo`
  - `roleplay`
  - `lessons`
  - `output`
  - `closingVideo`
- FR-03: Mỗi node cho phép chọn `openingVideo` và `closingVideo` bằng lesson type `VIDEO`.
- FR-04: `openingVideo` và `closingVideo` là optional; node cũ không có video vẫn render bình thường.
- FR-05: Sidebar có thêm item `Video`, điều hướng tới module riêng ngang hàng với `Lesson`.
- FR-06: Router có đủ:
  - `/video`
  - `/video/create`
  - `/video/:videoId`
- FR-07: `VideoList` hiển thị danh sách lesson type `VIDEO`, hỗ trợ search/filter course như [LessonList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonList.tsx).
- FR-08: `VideoForm` dùng lesson type `VIDEO`, không có block chọn keypoints như [LessonForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/lessons/LessonForm.tsx).
- FR-09: `VideoForm` phải cho nhập:
  - `title`
  - `description`
  - `summary` dạng HTML
  - `videoUrl` upload bằng [CloudflareFileUpload.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/files/CloudflareFileUpload.tsx)
  - các field lesson chung cần giữ lại cho video
  - `videoQuestions`
- FR-10: Mỗi `videoQuestion` gồm:
  - `atSecond`: numeric input
  - `exercise`: editor theo shape `ExerciseInput`, dùng pattern tương tự [ExerciseForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/exercises/ExerciseForm.tsx)
- FR-11: Khi save video:
  - lesson payload phải có `type: LessonType.VIDEO`
  - `summary` và `videoUrl` được gửi đúng lên lesson API
  - `videoQuestions` được lưu qua learning item API theo pattern liên kết với `learningItemId`
- FR-12: Khi edit video đã có dữ liệu, `summary`, `videoUrl`, `videoQuestions` phải load lại đầy đủ.

## 5) Quy tắc dữ liệu
- Frontend không còn dùng `INodeVideo` trong roadmap flow.
- `VideoPositionInNode` phải bị loại khỏi roadmap UI logic và payload mapping.
- `RoadmapNodePayload` chỉ còn submit:
  - `id`
  - `title`
  - `description`
  - `openingVideoId`
  - `roleplayId`
  - `lessonIds`
  - `outputId`
  - `closingVideoId`
- `openingVideo` và `closingVideo` đều là `ILessonBrief | null`.
- `VideoList` và roadmap video selector chỉ lấy lesson type `VIDEO`, ưu tiên filter theo `courseId` hiện tại.
- `summary` là `ITranslation` chứa HTML, cần sanitize trước khi preview/render.
- `videoUrl` là string URL trả về từ Cloudflare upload.
- Giả định triển khai:
  - `videoQuestions` tiếp tục thuộc `ILearningItem`.
  - mỗi video lesson có thể liên kết 1 `learning item` qua `learningItemId`, tương tự roleplay lesson.

## 6) UX yêu cầu
- Roadmap card cần tách block `Opening Video` và `Closing Video` rõ ràng, cùng kiểu badge/click navigation với các lesson section khác.
- Video selector modal trong roadmap nên tái dùng pattern chọn lesson hiện tại, nhưng filter `LessonType.VIDEO`.
- `VideoList` nên giữ trải nghiệm gần `LessonList` để content team không phải học lại flow.
- `VideoForm` nên giữ bố cục lớn của `LessonForm`/`RoleplayForm`, nhưng block nội dung chính đổi thành:
  - HTML summary editor
  - video upload/preview
  - video questions editor
- HTML editor nên tái dùng Tiptap setup đang có ở [OnboardingManagemant.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/onboardings/OnboardingManagemant.tsx) thay vì tự viết editor mới.
- `videoQuestions` nên cho add/remove nhiều item và hiển thị `atSecond` rõ ràng để editor dễ đối chiếu timeline video.

## 7) Tiêu chí chấp nhận
- AC-01: Save roadmap không còn gửi `video`/`position`, chỉ gửi `openingVideoId` và `closingVideoId` khi được chọn.
- AC-02: Roadmap reload lại đúng video opening/closing cho từng node.
- AC-03: Sidebar có menu `Video`, route hoạt động đầy đủ cho list/create/detail.
- AC-04: User tạo video mới thành công với `summary` HTML và `videoUrl`.
- AC-05: User edit video hiện có, dữ liệu `summary`, `videoUrl`, `videoQuestions` load đúng và save lại được.
- AC-06: `VideoList` chỉ hiển thị lesson type `VIDEO`.
- AC-07: Không còn UI roadmap nào cho upload video trực tiếp vào node.
- AC-08: Repo compile pass sau khi bỏ `VideoPositionInNode` khỏi roadmap flow và thêm module video mới.

## 8) File ảnh hưởng dự kiến
- Modify: [Sidebar.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/components/layout/Sidebar.tsx)
- Modify: [index.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/routes/index.tsx)
- Modify: [CourseDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/courses/CourseDetail.tsx)
- Modify: [course.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/course.interface.ts)
- Modify: [course.enum.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/enum/course.enum.ts)
- Modify: [lesson.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/lesson.interface.ts)
- Modify: [learning-item.interface.ts](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/types/interface/learning-item/learning-item.interface.ts)
- Create: [VideoList.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoList.tsx)
- Create: [VideoCreate.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoCreate.tsx)
- Create: [VideoDetail.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoDetail.tsx)
- Create: [VideoForm.tsx](/Users/nguyenvietha/Source/HDDhistory/hddhistory-admin/src/pages/video/VideoForm.tsx)

## 9) Ghi chú triển khai
- Tránh refactor lan rộng `LessonForm` nếu không cần; module video nên tách file riêng để giảm coupling.
- Có thể trích một số helper dùng chung sau khi xong flow chính nếu file vượt ngưỡng quản lý.
- `VideoForm` cần ưu tiên save `learning item` chứa `videoQuestions` trước, sau đó save lesson với `learningItemId`, giống `RoleplayForm`.
- Cần kiểm tra kỹ behavior khi video lesson chưa có `learningItemId` nhưng user đã nhập `videoQuestions`.

## 10) Unresolved Questions
- None. Plan hiện giả định `videoQuestions` sẽ tiếp tục được lưu qua `learning item` liên kết bởi `lesson.learningItemId`.
