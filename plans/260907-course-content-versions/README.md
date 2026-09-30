# Content version theo tag cho từng khoá học (design, 2026-09-07)

Nguồn: brainstorm với owner 2026-09-07. Mô hình do owner chọn: **giống đánh tag
trong git** — sửa nội dung bao nhiêu cũng được, user vẫn đọc tag hiện tại cho
tới khi đánh tag mới; rollback = trỏ current về tag cũ (`v1.0.1` → `v1.0.0`).

Phạm vi đợt này: **version + đổi current + rollback**. A/B test **để sau**,
nhưng data model phải chừa chỗ sao cho thêm A/B không phải đổi schema và không
phải sửa lại 14 service ở mục 3.

Không có phần việc nào ở hddhistory-flutter. App dùng nguyên endpoint cũ.

---

## 1. Quyết định đã chốt (và vì sao)

1. **Tag = ảnh chụp bất biến, không phải fork.** Snapshot giữ nguyên `_id` của
   entity trong working tree. Hệ quả là hai chi phí đắt nhất biến mất:
   `UserProgress` khoá theo `keypointId`/`lessonId`/`exerciseId` nên tiến trình
   vẫn khớp xuyên tag, và voiceover (`keypoint.audio`) **không bao giờ phải gen
   lại** — đã đo 2.97M ký tự / 433 keypoint cho bản card-only, fork sẽ phải trả
   lại số tiền đó mỗi version.
2. **Lưu một row cho mỗi entity, không lưu một blob JSON cả cây.** Blob sẽ đụng
   trần 16MB của Mongo với khoá nhiều theory 5 ngôn ngữ, và tra ngược
   `keypointId → khoá nào` sẽ không làm được vì `keypoint.schema.ts` **không có
   `courseId`** (keypoint là document tự do, chỉ được `lesson.keypoints[]` trỏ
   tới). Row mang sẵn `courseId` nên tra ngược là một query có index.
3. **Tag đóng băng nội dung học, kể cả `audio`; không đóng băng phân phối và
   giá.** `status`/`publishAt`/`isNew`/`newDurationDays`/`countries`/`prices`/
   `author`/`viewCount` vẫn live trên `Course` — nếu đóng băng, `course-publish.
   scheduler.ts` flip `status` sẽ vô hiệu và việc đổi giá / chặn khoá khỏi một
   thị trường sẽ bị trộn vào quy trình biên tập. `audio` **có** đóng băng: nếu
   không, một đợt regen theo bản chữ mới sẽ phát lời đọc không khớp chữ user
   đang thấy — lỗi rất khó truy.
4. **`coach` và `habit` đọc theo tag.** Nếu không, nội dung sửa mà chưa tag sẽ
   lọ ra qua Coach (Coach dựng tình huống từ chữ mới trong khi bài học hiện chữ
   cũ), và `habit-practice` có thể hiện exercise không tồn tại trong bản user
   đang học — nó **derive** từ exercise của keypoint, không đọc bảng join.
5. **Admin đọc bản đang sửa theo HEADER `x-ignore-content-version`, cộng
   `?version=` để xem tag bất kỳ.** `courses`/`lesson`/`keypoint` controller
   hiện **không tách admin và app** — `GET /courses/:id`, `GET /lessons/:id`,
   `GET /keypoints/:id` chỉ có `AuthGuard`, hai bên gọi chung route.

   **SỬA so với bản duyệt ngày 2026-09-07:** bản đầu định phân biệt bằng
   `user.role === ADMIN`. Không dùng được. Không có gì trong codebase populate
   `role`: `CreateUserDto` mặc định mọi account là `USER`, không endpoint nào
   chạy `RoleGuard`, và **tài khoản admin thật có `role: USER`** — giả định này
   đã 403 cả admin panel ba lần (xem note trên `UserHabitAdminController`,
   `HabitPracticeAdminController`, `CommunityPostController`). Thêm nữa
   `PUT /users/:id` cho phép caller tự đặt role của mình, nên nó không phải
   ranh giới tin cậy. Ở đây nó còn vỡ *im lặng* chứ không 403: editor mở bài ra
   sẽ thấy nội dung ĐÃ PHÁT HÀNH trong khi đang sửa bản nháp.

   Thay bằng header đặt một lần trong `axiosClient` của panel, đúng cách repo
   đã giải bài y hệt cho market targeting (`IGNORE_MARKET_TARGETING_HEADER`
   trong `@utils/market-query.util`, xem phần "Why a header and not a role
   check" trong đó). Vẫn giữ được điều quan trọng nhất: **chỉ sửa 1 dòng trong
   hddhistory-admin**, và tặng luôn preview bản nháp trên app thật.

   `?version=` **chỉ có nghĩa khi có header**. Không có header thì bỏ qua chứ
   không 400 — để một query string lạc không làm vỡ màn học của ai, và bỏ qua
   chứ không tôn trọng vì khi A/B lên, client tự chọn nhánh được là hỏng đo
   lường. Không phải hàng rào bảo mật và không giả vờ là, y như header market.
6. **Không thêm provider `Scope.REQUEST` nào — kể cả gián tiếp.** courses
   module đã có sẵn vấn đề request-scope DI bleed (mục perf còn deferred). Nên
   version context truyền như **tham số tường minh**, không inject.

   **SỬA thêm khi code:** `CourseVersionService` ban đầu inject `RequestService`
   để lấy `createdBy`. Chỉ riêng việc đó đã làm nó thành request-scoped, và
   `course-publish.scheduler.ts` phải gọi `createTag` khi publish khoá chưa có
   tag (mục 6) → **cron publish khoá học sẽ chết im lặng**. Đây là cái bẫy có
   ghi sẵn trên `SegmentModule`: "a background job that imported the latter
   would bubble that scope up and silently kill its own @Cron". Nên user thực
   hiện là **tham số** `actor?: IUserMeta | null`, controller lấy bằng
   `@CurrentUser()` — decorator này đã có sẵn và doc của nó nói đúng lý do đó.
   Tag không có actor (`createdBy: null`) là tag của hệ thống.

---

## 2. Mô hình dữ liệu

Ba thứ mới. Không đụng schema nội dung hiện có.

### `course_content_versions` — bản tag (append-only, bất biến)
```
{ courseId, tag, note, entityCounts: { lessons, keypoints, learningItems },
  createdBy: IUserMeta, createdAt }
```
- `tag` validate `^v\d+\.\d+\.\d+$`, do admin đặt; UI gợi ý patch kế tiếp.
- unique `(courseId, tag)`. Index `(courseId, createdAt: -1)` cho danh sách.
- Row **không bao giờ update sau khi chèn**. Khác `paywall_configs`: ở đó
  `isCurrent` nằm trên chính row config, còn ở đây con trỏ thuộc về khoá nên nó
  là `Course.currentVersionId`.

### `published_content` — bản checkout bất biến, một row / entity
```
{ versionId, courseId, entityType, entityId, doc, docHash }
entityType ∈ 'course' | 'roadmap' | 'lesson' | 'keypoint' | 'learningItem'
```
- `doc`: `SchemaTypes.Mixed`, bản sao nguyên văn document lúc đánh tag.
- `docHash`: sha256 của JSON chuẩn hoá của `doc` **trừ** `updatedAt`/`updatedBy`
  — dùng cho mục 4 ("N thay đổi chưa tag").
- unique `(versionId, entityType, entityId)`.
- Index `(entityType, entityId)` cho tra ngược `keypointId → courseId` mà
  `coach`/`habit` cần.
- Index `(versionId, entityType)` cho "lấy hết lesson của version này".

### Trên `Course`
- `currentVersionId?: string | null` — HEAD. `null` = chưa từng tag → đọc
  working tree (hành vi hôm nay).
- `published?: { title, description, image }` — **cache của row
  `entityType: 'course'` thuộc tag current, denormalize tại chỗ.** Bản gốc nằm
  trong tag (nếu chỉ nằm ở đây thì rollback về tag cũ không có gì để lấy lại —
  ô này chỉ giữ được một bản). Bắt buộc phải có cache, không được để app tra
  `published_content`: 10 index `title.en`…`description.ko` đang nằm trên
  collection `courses` và `CourseRepository.findOption()` search regex trực tiếp
  trên đó. Nếu title đóng băng mà không copy về đây thì (a) list/search của app
  phải tra N lượt, (b) search sẽ khớp theo **title bản nháp**. Thêm 10 index
  song song trên `published.title.*` / `published.description.*`; app query
  theo `published.*`, admin giữ nguyên query cũ.

Ước lượng dung lượng: ~48 row/khoá/tag (1 roadmap + ~6 lesson + ~10 keypoint +
~30 learning item). 44 khoá × 5 tag ≈ 10k row. Không đáng kể.

---

## 3. Đường đọc

### `ContentSource` (singleton, module mới `course-version`)
```ts
getRoadmap(courseId, versionId)
getLesson(id, versionId)          getLessonsByIds(ids, versionId)
getLessonsByCourse(courseId, versionId)
getKeypoint(id, versionId)        getKeypointBriefsByIds(ids, versionId)
getLearningItems(keypointId, versionId)
resolveCourseOfKeypoint(keypointId)   // dùng index (entityType, entityId);
                                      // không thấy row nào (keypoint chưa từng
                                      // được tag) → trả null → đọc working tree
```
`versionId === null` → delegate xuống repository như hôm nay. Khác `null` → đọc
`published_content`. Không `Scope.REQUEST`, không lan DI.

### `resolveVersionId` (hàm thuần, có spec riêng)
```
resolveVersionId(course, user, queryVersion?):
  queryVersion === 'current'  → course.currentVersionId
  queryVersion khớp một tag   → id của tag đó        (chỉ ADMIN, RoleGuard)
  user.role === ADMIN         → null                 // đọc bản đang sửa
  còn lại                     → course.currentVersionId
```

### 14 service đổi dependency (repository thô → `ContentSource`)
Nội dung user đọc — 9:
`courses/course.service.ts` · `courses/lesson/lesson.service.ts` ·
`courses/keypoint/keypoint.service.ts` ·
`courses/learning-item/learning-item.service.ts` ·
`courses/warm-up/warm-up.service.ts` ·
`courses/saved-card/saved-card.service.ts` ·
`courses/progress/src/modules/user-progress/user-progress.service.ts` ·
`courses/output-practice/conversation/output-practice-conversation.service.ts` ·
`courses/progress/src/modules/user-video-lesson-activity/user-video-lesson-activity.service.ts`

Liền kề — 5:
`coach/src/modules/situation/coach-situation.service.ts` ·
`coach/src/modules/quiz/coach-quiz.service.ts` ·
`coach/src/modules/session/coach-session.service.ts` ·
`habit/src/modules/habit-practice/habit-practice.service.ts` ·
`habit/src/shared/habit-content-resolver.service.ts`

Sửa mang tính máy móc, **không đụng business logic**: đổi chỗ inject và thêm
tham số `versionId` chảy xuống.

### Giữ nguyên — phải đọc working tree
`courses/voiceover/*` (gen audio cho bản đang sửa) ·
`courses/import/course-content-transfer.service.ts` (export/import) ·
`courses/progress/.../user-progress-export.helper.ts` (export cho admin).

`keypoint-access` không đọc nội dung, chỉ đếm id → không đụng.
`learning-import` nằm ngoài hẳn: nó có collection `user_lesson` riêng, không
phải nội dung khoá.

Chỗ cần để ý khi thực thi: `courses/course/repository/course.repository.ts`
hiện **inject `KeypointRepository`** — một repository gọi repository khác. Chỗ
này phải rà tay xem lời gọi nào thuộc đường app (theo tag) và nào thuộc đường
admin, vì layering không cho repository nhận `ContentSource`.

---

## 4. Đóng gói tag

`CourseVersionService.createTag(courseId, { tag, note, setCurrent })`:
1. Đọc working tree cả cây. Tập lesson là **hợp** của `Lesson.find({courseId})`
   và những id mà roadmap trỏ tới (`levels[].nodes[].lessonIds`, cộng
   `openingVideoId`/`roleplayId`/`outputId`/`closingVideoId`) — lấy hợp chứ
   không chỉ theo roadmap, vì lesson mới tạo có thể chưa được gắn vào roadmap.
   Từ lesson → `lesson.keypoints[]` + `levels[].keypointIds` → keypoint →
   learning item theo `keypointId`. Cộng row `course` (title/description/image)
   và row `roadmap`.
2. Chèn `course_content_versions` + bulk insert `published_content` (tính
   `docHash` từng row).
3. `setCurrent` → ghi `Course.currentVersionId` + `Course.published` (copy
   `title`/`description`/`image`).

### "N thay đổi chưa tag" — bằng hash, **không** bằng `updatedAt` (đã xác nhận khi code)
`updatedAt` không dùng được: schema nội dung dùng `@Schema()` trơn (không
`timestamps: true`), và `AbstractRepository` chỉ set `updatedAt` trong
`updateOne`/`updateMany`, **không** trong `findOneAndUpdate`/`bulkWrite`. Mà
sắp xếp lại lesson (`lesson.service.ts:416`) và sửa folder câu hỏi
(`learning-item.service.ts:362`, `:385`, `:441`, `:469`) đều đi qua `bulkWrite`
→ sẽ báo "0 thay đổi" trong khi thực tế có.

`diffAgainstCurrent(courseId)` đọc ~48 doc working tree, hash rồi so với
`docHash` của version current → trả `{ added, changed, removed }` kèm tên
entity. Chạy khi admin mở tab Versions. Đây không phải trang trí: tag chụp
**cả cây**, nên nếu không thấy danh sách này thì đánh tag để lấy audio mới sẽ
publish luôn mấy chỗ sửa chữ còn dở.

---

## 5. API (tất cả `RoleGuard` admin, trừ chỗ ghi khác)

| Route | Việc |
|---|---|
| `POST /courses/:id/versions` | đánh tag `{ tag, note, setCurrent }` |
| `GET /courses/:id/versions` | lịch sử + `diffAgainstCurrent` |
| `PUT /courses/:id/current-version` | `{ tag }` — rollback, 1 field write |
| `DELETE /courses/:id/versions/:tag` | chỉ tag không phải current; xoá luôn `published_content` của version đó |
| `POST /courses/versions/backfill` | migration mục 6 |

Thêm query `?version=` (`current` \| `vX.Y.Z`) cho các route đọc nội dung sẵn
có: `GET /courses/:id`, `/courses/:id/roadmap`, `/lessons/:id`, `/keypoints/:id`.

---

## 6. Rollout

Backfill đánh `v1.0.0` cho cả 44 khoá từ trạng thái hiện tại rồi set current →
**ngày deploy user không thấy gì khác**; thay đổi duy nhất là từ đó sửa phải
đánh tag.

Backfill làm bằng **endpoint admin** `POST /courses/versions/backfill`
(idempotent, bỏ qua khoá đã có tag), **không** bằng script `ts-node` chạy trực
tiếp vào Mongo: DB của api-dev hosted khác DB trong `.env` local, nên seed phải
đi qua API bằng bearer token. Mongo cũng không có cơ chế migration — thay đổi
schema ở đây là additive nên không cần migration file.

Khoá tạo mới: `currentVersionId = null` → đọc working tree, mà khoá mới đang
`DRAFT` nên user không thấy. **Chuyển `status` sang `PUBLISHED` khi chưa có tag
thì tự đánh `v1.0.0`** — để không tồn tại khoá live mà không có tag. Áp cho cả
`course-publish.scheduler.ts`.

---

## 7. Admin

Tab "Versions" trong `src/pages/courses/CourseDetail.tsx` + service mới
`src/services/courseVersionService.ts`:
- Bảng tag: tag · note · người đánh · thời điểm · số lesson/keypoint/exercise ·
  nhãn "current".
- Nút "Đánh tag mới" (ô nhập tag gợi ý patch kế tiếp + note).
- Mỗi dòng: "Đặt làm current".
- Banner "có N thay đổi chưa tag" + danh sách entity thay đổi.

Không đổi URL nào, không phải sửa service nào khác trong hddhistory-admin.

---

## 8. Chừa chỗ cho A/B (chưa làm đợt này)

`published_content` đã khoá theo `versionId`, nên A/B về sau chỉ cần:
1. một collection gán nhánh per-user (nhánh phải dính, không đổi giữa khoá),
2. `resolveVersionId` trả version theo cohort thay vì `course.currentVersionId`,
3. `courseVersionTag` nhét vào `user_events.params` — `params` là
   `SchemaTypes.Mixed` nên không cần migration.

**Không đổi schema, không sửa lại 14 service ở mục 3.**

---

## 8b. Thứ tự làm

Chia được thành ba chặng deploy độc lập, chặng nào cũng để hệ thống ở trạng thái
chạy được:

1. **Hạ tầng + đóng gói.** Hai collection mới, `Course.currentVersionId` +
   `published`, `ContentSource` (mới chỉ có nhánh `versionId === null`),
   `createTag` / `diffAgainstCurrent`, API mục 5, tab admin. Chưa service nào
   đọc theo tag → **không đổi hành vi gì**, chỉ đã đánh tag được.
2. **Chuyển 9 service nội dung sang `ContentSource`** + `resolveVersionId` +
   `?version=`, rồi backfill `v1.0.0`. Đây là chặng đổi hành vi thật.
3. **Chuyển 5 service `coach`/`habit`.** Tách riêng vì hai feature này đang chạy
   prod và `habit-practice` là chỗ dễ vỡ nhất (rủi ro 1).

---

## 8c. Excel / Google Sheets

Sáu route đang có: `GET template`, `POST import`, `POST drive-sync` (kéo mọi
sheet trong folder Drive qua importer rồi ghi id/lỗi trả lại sheet),
`POST drive-template`, `GET :courseId/export`, `POST :courseId/push-to-drive`.

**Export theo tag.** `GET :courseId/export?version=v1.0.0` (hoặc `current`) xuất
tag đã đóng băng; không truyền thì vẫn là bản đang sửa, y như trước. Rẻ vì 5 hàm
`build*ExportSheet` mỗi hàm chỉ có đúng một lời gọi repository ở đầu rồi map,
nên chỉ cần thêm tham số `preloaded` — có thì không query.

**Tặng không: khôi phục từ tag.** Id bên trong tag là id thật của bản đang sửa,
nên **export một tag rồi import lại workbook đó = ghi nội dung của tag đó lên
bản đang sửa**. Không phải viết gì thêm. (Vì thế mục này rời khỏi YAGNI.)

**Import và drive-sync vẫn ghi bản đang sửa** — không đổi. Nhưng thêm `autoTag`
**mặc định tắt**: bật thì mỗi khoá import sạch lỗi được đánh patch kế tiếp
(`v1.0.0` → `v1.0.1`) và trỏ current sang đó. Đây là thứ luồng Google Sheet cần
(sửa sheet → sync → live). Tắt mặc định vì cả feature này dựa trên chuyện phát
hành phải là hành động có chủ ý.

**Phải nói rõ "chưa live".** Không có tín hiệu này thì người sửa sheet sẽ tưởng
đã live trong khi app vẫn phát tag cũ:
- `POST import` trả header `X-Touched-Courses` và `X-Auto-Tagged`.
- `drive-sync` trả `autoTaggedAs` mỗi file; panel hiện "đã phát hành v1.0.1"
  hoặc "chưa phát hành — cần đánh tag" dưới tên sheet.

**Khoá nào bị import chạm tới** — cần cho `autoTag`: sheet `courses` trả lời
trực tiếp; workbook chỉ có lesson thì lộ qua cột `courseId`; workbook chỉ có
keypoint thì **không lộ gì** vì `keypoint.schema.ts` không có `courseId` — chỗ
đó dùng `ContentSource.resolveCourseOfKeypoint` (đúng index
`(entityType, entityId)` đã dựng cho `coach`/`habit`).

---

## 9. Không làm (YAGNI)

Diff nội dung giữa hai tag (chỉ diff working-tree ↔ current) · version cho
skillset/roadmap toàn cục · thay đổi ở hddhistory-flutter · copy-on-write và logical
id (mô hình snapshot không cần). Ghi ngược tag vào working tree **không còn**
trong danh sách này: nó có sẵn miễn phí qua export-tag → import (mục 8c).

---

## 10. Rủi ro / chỗ dễ vỡ

1. **`habit-practice` derive từ exercise của keypoint** — chỗ dễ vỡ nhất, cần
   spec riêng trước khi sửa. Bảng `habit_practices` là override, không phải
   bảng join; đừng seed row join.
2. **`user-progress` phải tính % trên đúng version user đang đọc**, nếu không
   tỉ lệ hoàn thành sẽ sai — và nó là service dài, dùng cả `KeypointRepository`
   lẫn `LessonRepository` lẫn `LearningItemRepository`.
3. **Thêm `coach`/`habit` vào graph nghĩa là phải import module đúng chỗ.**
   Provider thiếu dependency trong module khai báo nó thì `tsc` và `nest build`
   đều không thấy, chỉ crash-loop lúc boot. `coach-di.check.ts` **không dùng
   được** (nó chết trong `mongodb/src/bson.ts` trước khi tới code app) → phải
   boot thật để kiểm.
4. **Đánh tag để lấy audio mới sẽ kéo theo mọi sửa chữ chưa xong.** Mitigation
   là banner + danh sách ở mục 4; không có cách nào chụp một phần cây.
5. **Tài khoản admin mở app sẽ thấy nội dung chưa tag** (hệ quả của quyết định
   5). Muốn thấy đúng cái user thật thấy thì truyền `?version=current`.
6. `saved-card` **đã** an toàn: `saved-card.service.ts:73` có
   `if (!keypoint) return null`, keypoint rụng khỏi tag thì card tự rụng êm.
   Cần kiểm tương tự cho `recently-viewed` và `search-history`.

---

## 11. Gate kiểm chứng

- `npm run build` trong `hddhistory-api/` — gate strict thật của CI
  (`tsconfig.build.json` bật `strict`, `tsconfig.json` thì không, nên
  `npx tsc --noEmit` cho pass rồi Jenkins vẫn fail implicit-any).
- Spec đơn lẻ: `resolveVersionId`, snapshot builder, `diffAgainstCurrent` (hàm
  thuần / repository mock). **Không chạy full suite** — jest vét hết RAM máy này.
- `npx tsc --noEmit` trong `hddhistory-admin/`.
- Boot thật một lần để bắt lỗi DI ở rủi ro 3.


---

## 12. Trạng thái (2026-09-07)

**Chặng 1 + chặng 2 CODE XONG**, chưa deploy, chưa chạy trên dữ liệu thật.
Chặng 3 (`coach`/`habit`) chưa làm.

### Chặng 1 — hạ tầng + đóng gói
- `courses/src/modules/course-version/`: 2 schema, 2 repository, `ContentSource`,
  `CourseVersionService`, controller, module, DTO, projections.
- `Course`: `currentVersionId` + `published` + 10 index `published.*`.
- Repository mới: `LessonRepository.findFullByIds`,
  `LearningItemRepository.findAllByKeypointIds`, `CourseRepository.findAllIds`,
  `CourseRepository.findVersionPointers`,
  `PublishedContentRepository.findCourseIdsByEntities`.
- Excel/Sheets: 5 hàm `build*ExportSheet` nhận `preloaded`; `?version=` trên
  export; `autoTag` + `X-Touched-Courses`/`X-Auto-Tagged` trên import;
  `autoTag` + `autoTaggedAs` trên drive-sync.

### Chặng 2 — đường đọc theo tag
Không phải luồn tham số qua controller nào: **8/9 service nội dung đã inject
`RequestService` sẵn** (chúng vốn đã request-scoped — đúng cái DI bleed trong
mục perf deferred), nên đọc header ngay từ `this.requestService.headers`.
`saved-card` là service duy nhất phải thêm (không có cron nào phụ thuộc nó).
`ContentSource` vẫn là singleton: nó nhận `versionId` làm tham số.

Đã chuyển:
- `course.service`: `findAll` (search trên `published.*` + overlay field biên
  tập), `findOne` (overlay), `findRoadmap` (roadmap + lesson brief + keypoint
  brief từ tag).
- `lesson.service`: `findOne` + `getKeypoints`.
- `keypoint.service`: `findOne` + learning items của nó.
- `learning-item.service`: `findOne`.
- `warm-up.service`: chọn bài trên bản đang sửa, **nội dung** từ tag.
- `saved-card.service`, và 3 chỗ tra title trong `user-progress.service`
  (my-courses, study journal, activity) — dùng đường đọc xuyên nhiều tag.
- `output-practice-conversation`: `AIConfig` của bài OUTPUT.

**Hai bẫy đã chặn** (cả hai đều là ghi ngược nằm trong đường đọc):
`findRoadmap` backfill node id, và `learning-item.findOne` backfill id câu hỏi
— chỉ chạy khi đọc bản đang sửa. Ghi khi đang phục vụ tag sẽ là ghi nội dung
đóng băng lên bản đang sửa của người khác.

**Projection phải khớp tuyệt đối.** `keypointBrief` bỏ `audio.text` (~8KB/
keypoint, từng chiếm ~95% payload roadmap) và `lessonBrief` chỉ giữ
`video.thumbnail`. Nếu đường đọc theo tag trả full document thì màn chính của
app phồng ~20 lần mà không có lỗi nào báo.

### Cố ý KHÔNG chuyển
- `user-video-lesson-activity`: chỉ đọc `{_id, courseId, type}` để xác thực bài
  video có tồn tại. Đây là đường GHI hoạt động; bắt nó theo tag thì một bài có
  trong bản đang sửa mà chưa có trong tag sẽ làm mất hoạt động của user.
- `keypoint.service.findAll` (list + search phân trang): app **không bao giờ**
  gọi `GET /courses-keypoints` (đã kiểm trong hddhistory-flutter: endpoint có khai
  nhưng không có chỗ dùng). Đây là surface của admin.
- `computeLevelKeypointIds` / `countKeypointsInLessons` /
  `filterMissingLessonsFromLevels`: chỉ được gọi từ đường ghi.

### Sửa lại một ước lượng trong thiết kế
Rủi ro 2 (mục 10) nói `user-progress` phải tính % trên đúng version kẻo sai số.
Đọc code thì **không có mẫu số nào đọc từ nội dung**: `UserProgress` tự mang
kết quả. Ba chỗ nó đọc nội dung chỉ là tra title để hiển thị. Nên phơi nhiễm
thật là *lộ title bản nháp trong danh sách tiến trình*, không phải sai số — và
đã xử lý.

### Chặng 3 — coach + habit
Nguyên tắc chia: **chữ thì theo tag, tra cấu trúc thì giữ bản đang sửa.**

Đã chuyển (đều là chữ user đọc hoặc nguyên liệu đưa cho Gemini):
- `coach-situation`: 2 chỗ đọc title/description keypoint để dựng cảnh.
- `coach-quiz`: title/description keypoint + theory/exercise làm nguyên liệu.
- `coach-session`: chip bài học của khoá, quiz item, 2 chỗ title keypoint, và
  theory/exercise cho phần summary — 5 chỗ.
- `habit-practice`: item của practice (chữ user làm bài), title keypoint, và
  bộ đề exercise.

`coach-situation`/`coach-quiz` phải thêm `RequestService`. Đã kiểm trước:
coach có một cron (`coach-plan-reminder.dispatcher.ts`) nhưng nó chỉ inject
`CoachPlanRepository`/`CoachPlanService`/`CoachConfigService`/
`NotificationDispatchService`/`NotificationTemplateService`/`UserRepository` —
không chỗ nào là situation/quiz/session, và scope chỉ lan theo cạnh inject nên
cron không bị ảnh hưởng. (`notification-dispatch.service.ts:105` có comment nói
rõ nó cố tình tránh `RequestService` để giữ singleton.)

**Cố ý KHÔNG chuyển ở chặng 3:**
- `habit-content-resolver` (cả 2 chỗ): chỉ đọc `courseId` + `keypoints[]` để
  xếp hạng "khoá nào dạy habit này nhiều nhất" cho rail. Không đọc chữ nào, và
  reverse query "lesson nào chứa keypoint này" không có tương đương rẻ trên
  `published_content`.
- 4/9 chỗ của `coach-session`: hai reverse query `findByKeypointIds` (xác định
  scope keypoint/lesson), một `findByIds` đọc `keypoints[]`, và một
  `findExercisesByKeypoints` chỉ lấy `_id` để ghi nhận check-in. Đều là cấu
  trúc/id, không phải chữ.
- `habit-practice.create` (đường ghi của admin, validate type của item).

**Filter của repository được nhân bản thành hàm thuần có test** —
`narratableItemsOf`, `exercisesWithQuestionsOf` (kể cả guard
`'questions.0': {$exists:true}`), `warmUpQuestionsOf`, `courseLessonChip`. Đây
là chỗ dễ trôi nhất nên nó bị pin bằng test, không để trong đầu.

### Chốt an toàn: không có khoá live mà thiếu tag
`ensureInitialTag(courseId)` — tên tag **cố định** `v1.0.0`, nuốt đúng lỗi
trùng khoá (`ConflictException` hoặc `E11000`) và ném lại mọi lỗi khác. Cố định
chứ không patch-bump như `autoTag` vì hai tick cron chồng nhau mà bump thì sẽ
đẻ ra cả v1.0.0 và v1.0.1.

Gọi từ hai chỗ:
- `course-publish.scheduler.ts` — đọc `findDueComingSoonIds()` TRƯỚC khi flip,
  vì `updateMany` chỉ trả về số lượng. Scheduler inject `CourseVersionService`
  được chính vì service đó là singleton (đây là lý do quyết định 6 quan trọng).
- `course.service.update` — đường publish thủ công từ dialog Edit Course, cắm
  vào cả hai điểm return.

`backfill` cũng dùng lại `ensureInitialTag` để quy tắc "đã có tag thì bỏ qua"
chỉ nằm một chỗ.

### Gate
- `npm run build` (strict) xanh. Nó bắt được 2 lỗi implicit-any mà
  `npx tsc --noEmit` cho qua (`skipLibCheck` trong `tsconfig.json` nằm NGOÀI
  `compilerOptions` nên bị bỏ qua; lọc `^src/`).
- `npx jest --runInBand src/modules/{courses,coach,habit}/` — **397 test pass**,
  trong đó `course-version` là **129 test / 8 spec**. Một suite **có sẵn** không
  chạy được: `week-recap.service.spec.ts` gọi `new WeekRecapService` 4 tham số
  trong khi service cần 7 — cả hai file đều không bị sửa trong working tree,
  mismatch đến từ commit `97b5d33` trên develop.
- DI: audit metadata tĩnh đọc từ `dist/` (không cần DB) — **14 module đều OK**:
  `CourseVersion`, `Course`, `Lesson`, `Keypoint`, `LearningItem`,
  `CourseImport`, `SavedCard`, `WarmUp`, `OutputPractice`, `UserProgress`,
  `CoachSituation`, `CoachQuiz`, `CoachSession`, `HabitPractice`.
  Audit đã self-test. Vẫn **chưa boot thật**.
- hddhistory-admin: `npx tsc --noEmit` xanh.

### 2026-09-08 — api-dev sập, đã tìm ra và sửa

Lần deploy đầu làm api-dev crash-loop. Nguyên nhân, lấy được bằng cách boot lại
tại máy (xem cách dựng bộ khung boot trong memory `hddhistory-api-local-boot-harness`):

```
Nest can't resolve dependencies of the OutputPracticeConversationService
(..., ?). Please make sure that the argument ContentSource at index [8] is
available in the OutputPracticeConversationModule context.
```

`OutputPracticeConversationService` được khai báo trong
`OutputPracticeConversationModule`, còn tôi cắm `CourseVersionModule` vào
`OutputPracticeModule` — module CHA. **Scope của provider tính theo module KHAI
BÁO nó**, nên import ở cha là vô hiệu. Sửa ở `1704dfc`.

Ba gate đều xanh khi push lần đầu và đều bỏ lọt lỗi này: `npx tsc --noEmit`,
`npm run build`, và audit tĩnh của tôi — audit lọt vì nó chỉ soi những module
tôi gọi tên, mà tôi gọi tên module cha.

Sau khi sửa, đã rà hai lớp:
- Với mỗi service đã sửa, tìm module nào thực sự khai báo nó trong `providers`
  rồi kiểm module đó có import `CourseVersionModule`: **13/13**, chỉ chỗ kia
  thiếu.
- Quét **96 module** trong `dist` (kể cả module lồng, đọc cả token `provide`
  của object provider, coi export của `@Global()` là ambient): không module nào
  còn thiếu dependency.

Boot lại chỉ còn dừng ở `ECONNREFUSED` của MySQL cổng chết — tức graph DI đã
dựng qua 24/24 module mà `app.module.ts` import trực tiếp trước `MysqlModule`.
14 module sau đó chưa boot tới được (máy không có Docker/mysqld/mongod), nhưng
không module nào trong số đó khai báo service tôi sửa, và chúng nằm trong 96
module đã quét.

Ghi thêm cho lần sau: production **không** bị ảnh hưởng — không commit nào của
đợt này từng lên `main`. Release `v1.6.7` (07/09 11:07, merge develop tại
`f59fb11`) xảy ra trước commit đầu tiên của đợt này 3 giờ 20 phút.

### 2026-09-08 — `?version=` thật ra chưa được nối, đã sửa

Mục 5 ghi "thêm query `?version=` cho các route đọc nội dung sẵn có" nhưng code
chưa làm: không controller nào đọc `@Query('version')`, và 6 chỗ gọi
`versionForCourse`/`versionForEntity`/`versionForKeypoint` đều không truyền
tham số thứ ba. `resolveVersionRequest` có xử lý nhánh đó và CÓ test, nhưng
không ai gọi nó với `requested` — nên test xanh mà tính năng không tồn tại.

Phát hiện bằng probe api-dev: request kiểu panel với `?version=rac` phải trả
400 và `?version=v9.9.9` phải trả 404, cả hai **trả 200**.

Còn một tầng nữa bên trong: `versionForCourse` cắt sớm bằng
`if (allowDraftFromHeaders(headers)) return null` TRƯỚC khi tới resolver, nên
kể cả nối controller thì nó vẫn tự nuốt tham số. Giờ chỉ cắt sớm khi **không**
có `?version=`.

Đã nối: `GET /courses/:id`, `/courses/:id/roadmap`, `/courses-lessons/:id`,
`/courses-keypoints/:id`, `/courses-learning-items/:id`. Thêm
`ContentSource.getCourseFields` vì `Course.published` chỉ là cache của tag đang
phát hành, xem lại tag khác phải đọc từ chính row đã đóng băng.

### Chưa làm
- **Chạy backfill** (`POST /courses/versions/backfill`) — việc của lúc deploy,
  và tới lúc đó mới đổi hành vi thật: hiện chưa khoá nào có tag nên **mọi đường
  đọc vẫn trả bản đang sửa y như trước**.
- **Boot thật.** Audit DI tĩnh không thay được nó: nó không dựng guard của
  controller, và không bắt được lỗi lúc chạy. Đây là khoảng trống kiểm chứng
  lớn nhất còn lại.
- Chưa xác minh trên thiết bị/dữ liệu thật: đánh tag → sửa nội dung → xác nhận
  app vẫn đọc tag cũ → đổi current → xác nhận app đổi theo.

---

## 9. So sánh phiên bản (2026-09-09)

Trang admin **So sánh phiên bản** (`/version-comparison`) đối chiếu các tag nội
dung của MỘT khoá: 7 chỉ số + 2 đường cong, có bản mốc do người xem chọn.

### 9.1 Gán event về tag: theo CỬA SỔ THỜI GIAN, không theo nhánh A/B

Đây là quyết định kiến trúc chính. Có đúng hai đường gán một event học tập về
một phiên bản:

| Đường | Phủ được | Vì sao không chọn / chọn |
|---|---|---|
| Theo nhánh A/B (`content_variant` + arms) | chỉ tag từng nằm trong một đợt | phần lớn tag không nằm trong đợt nào → cột "thấp nhất/cao nhất trong lịch sử khoá" luôn trống |
| **Theo cửa sổ thời gian** | **mọi tag** | event của khoá X lúc T thuộc tag đang live ở T; app không phải gửi thêm gì |

Nên có collection mới `course_version_activations`
(`schema/course-version-activation.schema.ts`): `{courseId, versionId, tag,
from, to|null}`. Ghi ở **một** choke point duy nhất —
`CourseVersionService.pointCourseAt` — nên mọi đường (`createTag` +
`setCurrent`, `setCurrent`, `ensureInitialTag`, `backfill`) đều được phủ.

Ba điều bắt buộc, đều có test:

- **Một tag có NHIỀU cửa sổ.** v1.0.0 → v1.0.1 → roll back v1.0.0 cho v1.0.0
  hai đoạn rời. Lấy `min(from)..max(to)` cho gọn sẽ nuốt trọn quãng của v1.0.1.
- **Đoạn trước đóng đúng mốc đoạn sau mở** (cùng một `now`) — hở một khe là
  event rơi vào đó biến mất khỏi mọi cột.
- **Trỏ lại đúng tag đang live thì không ghi gì**, nếu không sổ đầy đoạn dài 0s.

Không nhét `currentFrom/currentTo` vào `course_content_versions` vì bất biến
"hàng tag không bao giờ bị sửa sau insert" của collection đó là thứ giữ cho
một tag đã đóng băng thật sự đóng băng.

### 9.2 "Card" = keypoint

Artifact nguồn nói "12 bài / 106 card", "chuẩn hoá 8 card/bài" — đúng tỉ lệ
keypoint/lesson của HDDhistory. Nên cả hai đồ thị quy về `keypoint_id`, thứ app đã
đóng dấu sẵn trên event.

### 9.3 Độ sâu là một ĐẲNG THỨC, không phải xấp xỉ

```
TB theo người của (card đã đọc / tổng card)
  = (Σ theo card của số người đọc card đó) / (số người mở bài × tổng card)
```

vì hai vế đếm cùng một tập cặp (người, card). Nên chỉ cần một `$group` theo
`keypoint_id` — không cần biết từng người đọc tới đâu.

### 9.4 Bảy chỉ số và nguồn thật của chúng

| Chỉ số | Nguồn | Ghi chú |
|---|---|---|
| Thời gian xuất bản | cửa sổ đầu tiên | — |
| Thời gian đọc TB 1 card | `keypoint_read_scr_view` → `keypoint_complete_click`, cùng `sessionId`, trần 15′ | không có param duration; suy từ mốc thời gian |
| Thời gian đọc TB 1 bài | `keypoint_intro_scr_view` → `keypoint_complete_click`, nhóm theo `lesson_id`, trần 2h | như trên |
| Tỉ lệ hoàn thành bài học | Σ hoàn thành card cuối / Σ người mở bài | cộng tử/mẫu rồi mới chia |
| Tỉ lệ hoàn thành khoá học | điểm cuối đường giữ chân | mẫu số = người mở khoá |
| Đánh giá CSAT | `user_feedbacks.contentRating` theo `submittedAt` trong cửa sổ | xem giới hạn dưới |
| Số lượng báo lỗi | lượt `keypoint_menu_report_click` | lượt, không phải người |

### 9.5 Giới hạn — đọc số phải biết

1. **Sổ cửa sổ chỉ có từ khi tính năng này lên.** Quãng trước đó không gán được
   về tag nào; các bản cũ sẽ trống cho tới khi chúng được phát hành lại.
2. **CSAT thưa và lệch.** `user_feedbacks` **upsert theo `userId`**, mỗi người
   giữ nhiều nhất một slot mỗi loại, nên đây là "phản hồi gần nhất của mỗi
   người, lọc theo khoá" chứ không phải toàn bộ phản hồi. `contentRating = 0`
   (gửi mà không chấm sao) bị loại, nếu không mọi bản đều bị kéo về 0 như nhau.
3. **Hai chỉ số thời gian là SUY RA từ mốc event**, không phải đo trực tiếp —
   app không gửi param duration nào. Đã chặn 3 nguồn nhiễu (cùng phiên, phải có
   cả hai đầu, chặn trần) nhưng vẫn là ước lượng.
4. **Số lượng báo lỗi là số tuyệt đối**, không chuẩn hoá theo lượng người hay
   số ngày live — đọc kèm cỡ mẫu ở đầu cột.
5. **Mỗi bản dùng thứ tự bài của CHÍNH NÓ.** Bản gộp 12 bài xuống 10 thì "bài
   số 7" của hai bản là hai bài khác nhau; mỗi đường dừng ở bài cuối của bản đó
   (`connectNulls={false}`).

### 9.6 Màu

Palette 5 slot của trang là slot 1..5 bộ categorical đã validate của admin
(`VERSION_SERIES` trong `components/dashboard/dashboardTheme.ts`), KHÔNG phải
ramp một sắc của artifact nguồn: ramp đó fail ngưỡng mắt thường (ΔE 8.9 giữa
hai bậc liền kề) — người mắt bình thường cũng không phân biệt nổi hai đường,
mà đó đúng là việc của trang này. Slot màu lấy theo vị trí trong TOÀN BỘ danh
sách phiên bản, không theo danh sách đang tích, để bỏ tích một bản không sơn
lại các bản còn lại.

---

## 10. Phiên bản trong Google Sheet (2026-09-09)

Mọi workbook xuất ra giờ có sheet **`_VERSION`** đứng đầu — CHỈ ĐỌC.

### 10.1 Vì sao

Vòng làm việc thật là: mở sheet trên Drive → sửa → bấm sync. Nhưng sync **chỉ
ghi vào bản đang sửa**; người học vẫn đọc tag đang phát hành cho tới khi có
người đánh tag mới. API đã trả `X-Touched-Courses` và `X-Auto-Tagged` để nói
điều đó, nhưng **người làm việc trên Drive không bao giờ thấy HTTP header**.
Nên trạng thái "đã sửa nhưng chưa live" trước đây là hoàn toàn vô hình đúng ở
nơi người ta đang làm việc.

### 10.2 Nội dung sheet

| Dòng | Ý nghĩa |
|---|---|
| Khoá | tên khoá |
| Đang phát hành | tag `Course.currentVersionId` trỏ tới, hoặc "chưa có tag nào" |
| Nội dung trong file này | tag đã đóng băng, hoặc "bản đang sửa (nháp)" |
| Xuất lúc | mốc thời gian |
| **Tình trạng** | dòng duy nhất người ta thật sự đọc — xem 4 trạng thái dưới |
| Lần sync vừa rồi | *chỉ có khi* autoTag vừa đánh tag; VẮNG hẳn khi không, vì một ô trống cạnh nhãn "đã phát hành" đọc ra như đã phát hành |
| Lưu ý | sửa file chỉ ghi vào nháp; muốn live phải đánh tag |
| **Lịch sử phiên bản** | bảng 4 cột liệt kê **MỌI** tag của khoá, mới nhất trước: `Tag` / `Đánh lúc` / `Ghi chú` / `Trạng thái` |

Khối lịch sử là phần trả lời câu hỏi ĐẦU TIÊN của người mở sheet — không phải
"file này là bản nào" mà "khoá này có mấy bản, bản nào đang chạy". Không có nó
thì phải mở trang admin mới trả lời được, và thế là mất luôn lý do để sheet nói
về phiên bản.

Cột `Trạng thái` có **ba** giá trị chứ không hai, cộng dấu chỉ ra dòng nào là
nội dung trong file này:

| Giá trị | Nghĩa |
|---|---|
| `ĐANG PHÁT HÀNH` | `Course.currentVersionId` đang trỏ vào đây |
| `đã từng phát hành` | có hàng trong sổ cửa sổ |
| `chưa phát hành` | sổ đã phủ quãng đời của tag này mà không thấy hàng nào |
| `chưa rõ (đánh trước khi có sổ ghi phát hành)` | tag đánh TRƯỚC dòng đầu tiên của sổ |
| `· nội dung trong file này` | nối thêm vào dòng khớp với nội dung đang nằm trong file |

Trạng thái thứ tư là trạng thái **bắt buộc**: sổ `course_version_activations`
chỉ tồn tại từ khi mục 9 lên, nên với tag cũ hơn thì câu trả lời đúng là "không
biết". Gộp nó vào `chưa phát hành` là in một câu SAI về lịch sử khoá lên đúng
chỗ người ta tin nó nhất. Luật ba nhánh nằm ở `publishStateOf` trong
`course-version.service.ts`.

Bốn trạng thái, mỗi cái một câu khác nhau: file đúng bằng bản đang phát hành /
file là một tag KHÁC bản đang phát hành / file là nháp và người học vẫn đọc tag
X / khoá chưa có tag nào nên người học đọc trực tiếp bản sửa (mỗi lần sync là
đổi luôn nội dung họ thấy).

### 10.3 CHỈ ĐỌC — quyết định có chủ ý

Không có ô nào để điền tag. Một cái tag gõ vào spreadsheet mà phát hành được là
một cú phát hành do gõ nhầm. Phát hành vẫn qua trang Course → Phiên bản, hoặc
sync có bật autoTag.

### 10.4 Ba chỗ phải cẩn thận, đều có test

- **Import bỏ qua sheet này.** `getSheet` tra THEO TÊN và **không** có fallback
  về `worksheets[0]`; không chỗ nào trong repo dùng `workbook.worksheets[0]`
  (đã quét). Nên đặt `_VERSION` lên đầu là an toàn — có test khẳng định đọc
  sheet `courses` không bị lệch khi `_VERSION` đứng trước nó.
- **`runPass` làm rơi `_VERSION`.** Mỗi importer con trả về workbook chỉ chứa
  sheet nó biết. Đường sync sạch lỗi không sao (xuất mới hoàn toàn), nhưng
  đường CÓ LỖI ghi chính workbook đó lên Drive → `finish` đóng dấu lại
  (`restampVersionSheet`), đặt ở cuối vì ExcelJS không chèn được lên đầu và ở
  đường này `import_errors` mới là tab cần đọc trước.
- **`versionLabels` tách khỏi `listVersions`.** `listVersions` đọc cả bản đang
  sửa và băm lại toàn bộ nội dung để tính "có gì thay đổi chưa"; trả giá đó cho
  mỗi lần xuất workbook, và cho MỖI khoá trong một lần sync cả thư mục Drive,
  là quá đắt so với việc chỉ cần hai chuỗi ký tự.

### 10.5 `push-to-drive` nhận `?version=`

`POST /course-content-transfers/:courseId/push-to-drive?version=v1.0.1` đẩy nội
dung của một tag vào sheet thay vì bản đang sửa — xem lại hoặc khôi phục một
bản cũ ngay trên Drive, và `_VERSION` nói rõ đây là bản đóng băng nào. Trước
đây `?version=` chỉ có ở đường tải file, nên sheet trên Drive luôn là bản đang
sửa. **Chưa có nút trên admin** — nút "Đẩy lên Drive" hiện tại vẫn đẩy bản đang
sửa như cũ.

### 10.6 exceljs không gọi được từ spec

`excel-import.util.ts` dùng `import ExcelJS from 'exceljs'` (default import).
`tsconfig.build.json` bật `esModuleInterop` nên chạy thật thì đúng;
`tsconfig.json` — cái **ts-jest** đọc — chỉ bật `allowSyntheticDefaultImports`,
nên dưới jest nó biên dịch thành `require('exceljs').default` = `undefined` và
`createMultiSheetTemplateWorkbook` nổ ngay dòng `new ExcelJS.Workbook()`.
Không sửa tsconfig ở đây vì đổi cách biên dịch của cả repo. Spec nào cần
workbook thật thì dựng bằng `import * as ExcelJS` rồi gọi `getSheet`/`getRows`
— hai hàm đó nhận sẵn instance nên vẫn là code thật.
