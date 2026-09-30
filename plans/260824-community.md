# Community (diễn đàn theo chủ đề) — 2026-08-24

Nguồn thiết kế: `HDDhistory - Community.html` (Claude Design canvas, 6 screens + lộ trình
được chia sẻ). Community là **tab nav thứ 5** của app.

## Quyết định đã chốt

| Chủ đề | Quyết định |
|--------|-----------|
| Phạm vi | Toàn bộ design một lần (6 screens + weekly question + save + ảnh + đính kèm khoá + notification) |
| Kiểm duyệt | **Hậu kiểm + report**. Đăng là hiện ngay; admin ẩn/xoá/khoá comment; bài bị report nổi lên queue ưu tiên |
| Ngôn ngữ | **Tách theo locale user**. Bài mang `locale` người đăng; feed chỉ hiện bài cùng locale. Tên/mô tả chủ đề dịch đủ 5 thứ tiếng (`ITranslation`) |
| Danh tính | Tên thật + avatar từ profile. ~~Guest (`user.anonymous`) đọc được, khi like/comment/đăng thì bật sheet đăng nhập~~ → **đổi 2026-09-07: guest ghi được như thành viên** (xem cuối file) |
| Notification | FCM push + inbox trong community. Feed refresh bằng pull-to-refresh, **không** dùng socket |
| Admin | Duyệt nội dung + queue report · CRUD chủ đề · đăng bài "Đội ngũ HDDhistory" + ghim · quản lý Câu hỏi của tuần |
| Xử lý user | Tạm khoá quyền đăng có thời hạn (7/30 ngày/vĩnh viễn) + lý do + lịch sử vi phạm |
| Kiến trúc | Một module `community`; weekly question là `post` có `type` → tái dùng feed/comment/report/moderation |
| Phân trang | Page-based (`paginateQuery`) theo quy ước repo + `anchorAt` để trang 2 không bị trôi |

Cố ý **không** làm: thông báo khi có like (tạo ồn, làm badge đỏ mất nghĩa);
sửa bài sau khi đăng (design không có affordance đó — chỉ có xoá bài của mình).

## Data model (MongoDB, prefix `community_`)

Tất cả extend `AbstractDocument` (`_id`, `createdAt`, `updatedAt`, `createdBy`, `updatedBy`).

### `community_topics`
`name: ITranslation`, `description: ITranslation`, `slug` (unique), `imageUrl`,
`sortOrder`, `isActive`, `stats: {<locale>: {followers, postsThisWeek}}` (Mixed).

Đếm theo locale vì feed lọc theo locale — đếm gộp thì user Hàn thấy "12.4k người"
mà feed trống. `postsThisWeek` tăng bằng `$inc`, cron thứ Hai 00:00 UTC zero lại.

### `community_posts`
`type: POST | WEEKLY_QUESTION`, `authorType: USER | OFFICIAL`, `authorId`,
`topicId?`, `locale`, `body`, `images: string[]` (≤4 R2 key), `attachedCourseId?`,
`status: VISIBLE | HIDDEN | DELETED`, `hiddenReason?`, `moderatedBy?`, `moderatedAt?`,
`isPinned`, `pinnedAt?`, `commentsLocked`, `likeCount`, `commentCount`, `saveCount`,
`reportCount`, `lastActivityAt`.

`WEEKLY_QUESTION` thêm: `weekly: {weekNumber, year, startsAt, endsAt}`,
`title: ITranslation`, `note: ITranslation`; `locale = null` → hiện cho mọi user,
render theo tiếng của họ.

Index: `{status, locale, createdAt:-1}` · `{topicId, status, locale, createdAt:-1}`
· `{authorId, createdAt:-1}` · `{type, 'weekly.endsAt':-1}` · `{status, reportCount:-1}`.

### `community_comments`
`postId`, `parentId?` (null = cấp 1; reply luôn trỏ về comment cấp 1 — đúng 2 cấp
như design), `replyToUserId?` (affordance `@tên`), `authorId`, `authorType`, `body`,
`status`, `likeCount`, `replyCount`, `reportCount`.

Index: `{postId, parentId, status, createdAt:-1}` · `{authorId, createdAt:-1}`.

### `community_reactions`
`targetType: POST | COMMENT`, `targetId`, `userId`, `kind: LIKE | SAVE`.
Unique `{targetType, targetId, userId, kind}` → bấm hai lần không nhân đôi.
Index `{userId, kind, createdAt:-1}` → danh sách "đã lưu" một query.

### `community_topic_follows`
`topicId`, `userId`, `locale` (copy từ user lúc follow, để đếm follower theo locale).
Unique `{topicId, userId}` · index `{userId}`.

### `community_reports`
`targetType`, `targetId`, `reporterId`, `reason` (SPAM / HARASSMENT / ADULT /
MISINFORMATION / PRIVACY / OTHER), `note?`, `status: PENDING | RESOLVED_HIDDEN |
RESOLVED_KEPT`, `resolvedBy?`, `resolvedAt?`.
Unique `{targetType, targetId, reporterId}` — một người báo một lần.
Index `{status, createdAt:-1}`.

### `community_hidden_items`
"Ẩn nội dung này" là hành động **riêng của từng user**, không phải kiểm duyệt:
`userId`, `targetType`, `targetId`. Unique cả ba. Feed loại ra bằng `$nin`.

### `community_sanctions`
`userId`, `mutedUntil` (null = vĩnh viễn), `reason`, `createdBy`, `revokedAt?`.
Collection riêng (không cắm cờ lên `users`) để giữ **lịch sử vi phạm**.
Sanction đang hiệu lực = `revokedAt: null` và (`mutedUntil: null` hoặc `> now`).

### `community_notifications`
`userId` (người nhận), `type: COMMENT_ON_POST | REPLY_TO_COMMENT | OFFICIAL_REPLY |
POST_HIDDEN | SANCTION_APPLIED`, `actorId?`, `postId?`, `commentId?`, `isRead`.
Index `{userId, createdAt:-1}` · `{userId, isRead}`.

## Nguyên tắc denormalize

- **Không** copy tên/avatar tác giả lên post/comment. Mỗi trang batch-fetch users
  bằng một `find({_id: {$in}})` — thêm 1 query/trang, đổi lại tên và avatar luôn
  đúng sau khi user sửa profile.
- **Có** denormalize counter (`likeCount`, `commentCount`, `saveCount`,
  `reportCount`, `replyCount`) vì đếm live cho từng bài trong feed là N query.
  Cập nhật bằng `$inc` cùng lúc với create/delete reaction.

## API surface (`/api/v1/community/...`)

### User-facing
| Method | Path | Ghi chú |
|--------|------|---------|
| GET | `/community/feed` | `?page&take&topicId&followingOnly&anchorAt`. Ghim lên đầu, weekly question chèn đầu trang 1 |
| GET | `/community/topics` | Đang theo dõi + tất cả, kèm `stats` theo locale user |
| GET | `/community/topics/:id` | Header chủ đề + `isFollowing` |
| POST | `/community/topics/:id/follow` · DELETE | Follow / bỏ follow |
| POST | `/community/posts` | Tạo bài (kiểm tra sanction trước) |
| GET | `/community/posts/:id` | Chi tiết + `isLiked`/`isSaved` |
| DELETE | `/community/posts/:id` | Xoá bài của mình (`status: DELETED`) |
| GET | `/community/posts/:id/comments` | 2 cấp, mới nhất trước (đúng thứ tự design) |
| POST | `/community/posts/:id/comments` | `{body, parentId?, replyToUserId?}` |
| DELETE | `/community/comments/:id` | Xoá comment của mình |
| POST | `/community/reactions` · DELETE | `{targetType, targetId, kind}` |
| GET | `/community/saved` | Bài đã lưu |
| POST | `/community/reports` | `{targetType, targetId, reason, note?}` |
| POST | `/community/hidden` | Ẩn nội dung này (chỉ với mình) |
| GET | `/community/weekly` | Câu hỏi tuần đang mở + số câu trả lời |
| GET | `/community/notifications` · POST `/read` | Inbox + đánh dấu đã đọc |
| GET | `/community/me/status` | `canPost`, sanction đang hiệu lực (để app hiện lý do + ngày mở lại) |

### Admin (`@Roles(UserRole.ADMIN)`)
| Method | Path | Ghi chú |
|--------|------|---------|
| GET | `/community/admin/posts` | Filter status/topic/locale/type/search, thấy cả HIDDEN |
| PATCH | `/community/admin/posts/:id` | `{status, hiddenReason, isPinned, commentsLocked}` |
| GET | `/community/admin/comments` | Tương tự cho comment |
| PATCH | `/community/admin/comments/:id` | Ẩn/hiện lại |
| GET | `/community/admin/reports` | Queue, mặc định PENDING, sort reportCount desc |
| PATCH | `/community/admin/reports/:id` | `{status}` → ẩn nội dung hoặc bỏ qua |
| GET/POST/PATCH/DELETE | `/community/admin/topics` | CRUD chủ đề |
| POST | `/community/admin/posts/official` | Đăng với tư cách Đội ngũ HDDhistory |
| GET/POST/PATCH | `/community/admin/weekly` | Lên lịch câu hỏi tuần |
| GET | `/community/admin/sanctions` · POST · DELETE | Khoá / mở khoá quyền đăng + lịch sử |

## Layering (bắt buộc theo `hddhistory-api/AGENTS.md`)

- Controller: chỉ route/guard/param mapping.
- Service: business logic — kiểm tra sanction, đếm `$inc`, tạo notification,
  batch-fetch author, quyết định visibility.
- Repository: **tầng duy nhất** chạm DB.

## Admin panel (`hddhistory-admin`)

Nhóm sidebar mới **Community**:
- `Kiểm duyệt` (`/community/moderation`) — tab Bài đăng / Comment / Báo cáo.
- `Chủ đề` (`/community/topics`) — CRUD, 5 tab ngôn ngữ cho name/description.
- `Câu hỏi của tuần` (`/community/weekly`) — lịch theo tuần, 5 ngôn ngữ.
- `Khoá quyền đăng` (`/community/sanctions`) — danh sách + lịch sử vi phạm.

## Flutter

Branch shell mới **index 6**, tab nav thứ 5 (`_tabToBranch = [0, 3, 5, 4, 6]`).
Feature `lib/src/community/` theo Clean Architecture: `domain` (entity, repository
interface, usecase) · `data` (dto, datasource Retrofit, repository impl, mapper) ·
`presentation` (pages, cubits, widgets).

Screens: `CommunityFeedPage` (tab Tất cả / Chủ đề) · `CommunityTopicPage` ·
`CommunityPostDetailPage` · `CommunityWeeklyPage` · `CommunityComposePage` ·
`CommunityNotificationsPage`. Card đính kèm khoá học mở `CourseRoadmapRoute` sẵn có.

l10n: thêm `assets/i18n/<locale>/community.yaml` cho **cả 5** locale, rồi `dart run slang`.

## Thứ tự giao hàng (4 lát verify được)

1. **API + admin: chủ đề & feed** — schema, topic CRUD, feed query, sidebar + trang chủ đề.
2. **API + flutter: bài & comment** — tạo/đọc bài, comment 2 cấp, like/save, tab nav thứ 5.
3. **Report + kiểm duyệt** — report, hidden items, sanction, trang kiểm duyệt admin.
4. **Weekly question + notification** — lịch câu hỏi tuần, inbox, FCM push.

## Kiểm chứng

Không chạy test suite trên máy này (hết RAM). Cổng kiểm tra:
`npx tsc --noEmit` **và** `npm run build` cho hddhistory-api (build bật `strict: true`,
tsc thì không — Jenkins fail ở implicit-any nếu chỉ chạy tsc), `npx tsc --noEmit`
cho hddhistory-admin, `flutter analyze` cho hddhistory-flutter.

---

## Đã làm (2026-08-24)

Cả 3 stack pass cổng kiểm tra: `npm run build` + eslint (hddhistory-api), `npx tsc --noEmit`
(hddhistory-admin), `flutter analyze` (hddhistory-flutter — 0 issue trong `lib/src/community`).

### hddhistory-api
- `src/modules/community/` — 9 schema + 9 repository + 8 service + 7 controller,
  gói trong **một** `CommunityModule` (folder vẫn lồng theo quy ước; lý do gộp
  module ghi trong docblock của `community.module.ts`).
- ~~`CommunityMemberGuard` — guest đọc được, nhưng đăng/comment/tim/follow/report
  thì 403 `COMMUNITY_LOGIN_REQUIRED`.~~ Gỡ 2026-09-07 (xem cuối file).
- `CommunityTopicStatsScheduler` — cron thứ Hai 00:00 UTC zero `postsThisWeek`.
- Push dùng `deeplink: hddhistory://community-post?postId=...` (key mà notification
  router của app đọc), copy 5 ngôn ngữ trong `community-notification.copy.ts`.
- Ngoài module: `@base/decorator/current-user.decorator.ts` (tránh service
  request-scoped trên đường nóng của feed) và `UserRepository.findIdentitiesByIds`.

### hddhistory-admin
- Nhóm sidebar **Community**: Kiểm duyệt (`/community/moderation`, 3 tab
  Báo cáo / Bài đăng / Bình luận) · Chủ đề · Câu hỏi của tuần · Khoá quyền đăng.
- `TranslationFields` hiện cả 5 locale cùng lúc (không dùng tab) + cột "Thiếu
  bản dịch" trong bảng chủ đề và bảng câu hỏi tuần.
- Đăng bài "Đội ngũ HDDhistory" + ghim ngay trên trang kiểm duyệt.

### hddhistory-flutter
- `lib/src/community/` — 1 library + part files: 14 model, 13 entity, retrofit
  api, repository + mapper, 16 usecase, 4 cubit, 7 page, 10 widget.
- Tab nav **thứ 5**: shell branch index 6, `_tabToBranch = [0, 3, 5, 4, 6]`,
  icon `assets/svg/common/nav_community.svg`.
- Deeplink: `hddhistory://community` và `hddhistory://community-post?postId=...`.
- l10n `community.yaml` cho **cả 5** locale.
- 2 token màu mới (`communityMuted`, `communityTopicHeading`); còn lại dùng token
  sẵn có.

## Chưa verify
- Chưa boot được graph DI của NestJS trên máy này (không có Mongo/MySQL local) —
  `nest build` không thấy lỗi DI. `CommunityModule` import `forwardRef(AuthModule)`
  đúng như tiền lệ `habit-practice.module.ts` nên rủi ro thấp, nhưng vẫn cần xem
  log lần deploy dev đầu tiên.
- Chưa chạy trên simulator: chưa có chủ đề nào trong DB nên feed sẽ rỗng. Cần
  tạo vài chủ đề trong admin trước khi test app.
- Chưa có test tự động (máy này không chạy được test suite).

---

# v2 — bản redesign "Confession" (2026-08-25)

Nguồn: `HDDhistory - Community.html` → **`Confession.html`** (9 màn, group mới
"Chia sẻ vào Confession"). Đây không phải thêm vài chi tiết — nó đổi cả tên
tính năng và **hai chỗ đổi ngữ nghĩa dữ liệu**, nên ghi lại rõ.

## Quyết định (người dùng chốt 2026-08-25)
| Câu hỏi | Chốt |
|---|---|
| Toggle "Ẩn danh" trong design vs quyết định cũ "tên thật" | **Làm ẩn danh** — `authorType: ANONYMOUS`, `authorId` vẫn lưu để kiểm duyệt/khoá được |
| Share ra IG/FB story | **Làm luôn** — hoá ra `CourseShareSheet` đã có sẵn, chỉ thêm nút "Đăng vào Confession" |

## Đổi ngữ nghĩa (đọc trước khi sửa tiếp)
1. **Nút thứ 3 trên thẻ bài = cái chuông, không phải bookmark.** Vẫn là reaction
   `SAVE` trong DB (không migrate dữ liệu cũ), nhưng ý nghĩa là *theo dõi thread*:
   tab "Đang theo dõi" giờ lọc **theo POST** (`followedOnly` → `includeIds`), không
   phải theo phòng. `followingOnly` (lọc theo topic) đã bỏ.
   → Màn "Đã lưu" và route của nó đã **xoá**: tab "Đang theo dõi" chính là nó.
   Repository/usecase `getSavedPosts` giữ lại (endpoint server vẫn có).
2. **Bài viết có tiêu đề riêng** — `subject: string` (plain text, ngôn ngữ người
   viết). KHÁC `title: ITranslation`, thứ chỉ dùng cho `WEEKLY_QUESTION`. Thẻ bài
   xếp lại: chip phòng → tiêu đề → dòng tác giả → thân bài thụt 37px.

## Thêm mới
### hddhistory-api
- `CommunityAuthorType.ANONYMOUS` + `authorService.pick(..., reveal)` — người đọc
  mất **cả tên và id** (leak id là ghép được 2 bài ẩn danh về một người); admin
  truyền `reveal: true` để có tài khoản thật.
- `attachedCard` — snapshot keypoint card (`keypointId/title/back/courseName`).
  Snapshot cố ý: feed đang 3 lookup/trang, thêm lookup sang module courses là 1
  query/bài; và keypoint bị sửa/ẩn sau đó không được làm trống bài của người ta.
- Thông báo: `LIKE_ON_POST` (gộp 1 dòng/bài qua `upsertLike` + `actorCount`, không
  push) và `COMMENT_ON_FOLLOWED_POST` (fan-out cho người bấm chuông, trừ tác giả
  và người vừa comment). `GET /notifications` giờ resolve luôn `actor`.
- Module mới `room-suggestion` — "Đề xuất phòng mới". Tên trùng (không phân biệt
  hoa thường, cùng locale) thì **biến thành phiếu ủng hộ** chứ không báo lỗi;
  `voterIds` + `voteCount` cập nhật bằng aggregation-pipeline update nên không lệch.
  Tối đa 3 đề xuất đang chờ / người.

### hddhistory-admin
- Sidebar đổi tên nhóm **Confession**, "Chủ đề" → **"Phòng"**, thêm
  **"Đề xuất phòng"** (`/community/room-suggestions`).
- Bảng kiểm duyệt: hiện `subject`, thẻ insight, và nhãn **"Đăng ẩn danh"** (kèm
  tên thật — ban phải có người để nhắm vào).
- Duyệt đề xuất = **gắn vào một phòng đã tạo**, không tự tạo phòng: một phòng cần
  tên đủ 5 ngôn ngữ + slug, thứ đề xuất viết tay không có.

### hddhistory-flutter
- Hub 3 tab: Tất cả / Đang theo dõi / Phòng (bỏ `_ScopeToggle` và nút bookmark).
- Tab Phòng: "Yêu thích" (row có dòng độ tươi) + "Khám phá phòng" (lưới 2 cột,
  tint theo id phòng nên không đổi màu khi list sắp lại) + CTA đề xuất phòng.
- Màn phòng: sticky bar (back + tiêu đề mờ dần qua 150px + **tim** thay nút
  "Tham gia" + `+` đăng trong phòng) rồi glass card của phòng cuộn theo feed.
  **Bỏ chip sort** — design mới không vẽ nữa.
- Viết bài: chip chọn phòng + dropdown, ô tiêu đề, **toggle Ẩn danh**, sheet
  "Đính kèm từ thư viện" (Khoá học / Card đã lưu), cap 2 đính kèm + toast.
- Thông báo: avatar + huy hiệu loại, câu có tên in đậm, "và N người khác".
- `CommunityComposeSeed` — bàn giao một lần từ share sheet sang composer. Không
  dùng route param vì payload là cả một card (tiêu đề + đoạn text).
- `CourseShareSheet` (đã có sẵn) thêm nút **Confession**; thêm
  `showCommunityInsightShareSheet` cho card insight (Confession + More).

## Chưa verify
- Chưa chạy trên máy/simulator sau redesign — cần build lại.
- Chưa test luồng ẩn danh end-to-end (cần deploy api-dev trước).
- Đề xuất phòng: chưa test trên dev, và chưa có phòng nào ở trạng thái APPROVED
  để xem cột "Đã mở phòng" trong admin.

## 2026-09-07 — Bỏ yêu cầu đăng nhập

Guest (`user.anonymous`) giờ **ghi được toàn bộ**: đăng/xoá bài, bình luận/xoá,
thả tim, báo cáo, theo dõi chủ đề, nhắn + thích trong phòng chat, đề xuất phòng
+ vote. Hiện tên đã nhập ở onboarding, và dùng được toggle Ẩn danh y như thành
viên.

Chỉ sửa API, **không đụng Flutter**: app đọc `canPost`/`requiresLogin` từ
`GET community/me/status` chứ không tự kiểm tra `user.anonymous`, nên mọi bản
đang cài tự mở khoá khi API lên. Cách lùi = revert commit này, app trở lại
đúng hành vi cũ.

- Gỡ `CommunityMemberGuard` (xoá file) khỏi 13 route ở 7 controller và khỏi
  providers của `community.module.ts`. Mã lỗi `COMMUNITY_LOGIN_REQUIRED` không
  còn được phát ra; app vẫn giữ nó trong `_selfHandledForbiddenCodes` như code
  chết vô hại.
- `CommunitySanctionService.statusFor` bỏ nhánh anonymous → mute là lý do duy
  nhất `canPost` còn false; `requiresLogin` luôn `false`.

Rủi ro đã chấp nhận (chốt với chủ sản phẩm): guest Android cài lại app là có
danh tính mới (`ANDROID_ID`) nên thoát mute — hậu kiểm + ẩn bài vẫn là tuyến
phòng thủ chính, không thêm rate-limit hay mute theo `deviceId`.
