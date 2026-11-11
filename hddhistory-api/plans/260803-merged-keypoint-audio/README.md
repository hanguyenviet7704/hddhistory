# Audio keypoint liền mạch: 1 file merge + cue map, resume đúng card đúng giây

**Ngày:** 2026-08-03 · **Stack:** hddhistory-api + hddhistory-flutter

## Vấn đề

Người dùng nghe bài ngoài nền (lock screen) bị **giật cục theo từng đoạn**:

1. Mỗi card của keypoint là một clip audio riêng vài giây
   (`keypoint.audio.segments[lang][i]`). Mỗi lần chuyển card app
   `pause → setAudioSource mới → fetch mạng` — không cache, không preload
   (`lesson_audio_cubit.dart:250-311`, `lesson_audio_handler.dart:66-96`).
   Ranh giới card nào cũng khựng.
2. Lock screen nhận một `MediaItem` mới cho **từng card** → hiện track ~8 giây
   reset liên tục, tua/seek chỉ trong phạm vi một card. Chế độ queue liền
   (`playRestOfKeypoint`) chỉ kích hoạt khi deck bị chặn **và** app đã ở nền.
3. **Không có resume**: không lưu card index lẫn giây audio ở đâu
   (`keypoint_card_cubit.dart:495-497` ghi rõ product call cũ: vào lại đọc từ
   đầu). Live Activity deeplink chỉ resume tới mức keypoint.
4. **Card đầu hay lỗi khi keypoint có exercise**: cách đánh số clip được viết
   hai lần và phải khớp tuyệt đối — backend `voiceover.service.ts:202-216`
   (exercise → 1 segment/câu hỏi, còn lại 1 segment/document, **không loại trừ
   video item**) vs Flutter `keypoint_cards_builder.dart:55-105` (chỉ theory
   được cộng số, tin rằng backend bỏ video ra). Client còn chèn item exercise
   tổng hợp (`isPlayingSubQuestions`, `lesson_cubit.dart:204-222`). Lệch một
   item là mọi clip phía sau phát nhầm audio card hàng xóm.

## Quyết định

- **Backend ghép sẵn 1 file audio cho mỗi keypoint × ngôn ngữ** từ chính các
  clip per-card đã dub, kèm **cue map mang danh tính card** — không phải số
  thứ tự. Client phát đúng một file: gapless tuyệt đối, lock screen một track
  dài chuẩn, seek toàn bài.
- **Cue map là chuẩn duy nhất** cho việc card nào ứng với đoạn nào → xoá tận
  gốc lớp số học hai phía đang gây lỗi card đầu.
- **Resume theo `(keypointId, positionMs)`**, áp dụng khi app bị kill/ra nền
  rồi quay lại (qua Live Activity / roadmap "Tiếp tục"). Chủ động mở lại
  keypoint đã hoàn thành từ roadmap vẫn đọc từ đầu (giữ product call cũ).
- KHÔNG dùng lại file cả-keypoint sẵn có (`audio.url`): file đó là một lần TTS
  riêng, timeline không khớp tổng các clip lẻ nên không suy ra cue được.
  Concat từ chính các clip lẻ thì offset = cộng dồn duration từng clip —
  khớp theo cấu tạo.

## Thiết kế — hddhistory-api

### Schema (Mongo, additive — app build cũ bỏ qua)

```
keypoint.audio.merged[lang] = {
  url: string,          // file R2 đã concat
  durationMs: number,
  hash: string,         // sha256 của chuỗi (segmentHash các clip theory, theo thứ tự)
  cues: [{
    learningItemId: string,
    documentIndex: number, // index trong item.documents
    startMs: number,
    durMs: number,         // 0 nếu card không có audio (chỉ ảnh)
  }],
}
```

- **Chỉ ghép clip của theory documents** — đúng luật `narratableClips` phía
  app: không bao giờ đọc to câu hỏi exercise. Video/roleplay/exercise không
  vào file merge (nhưng card theory không audio vẫn có cue `durMs: 0` để deck
  map đủ).
- `hash` để merge idempotent: dub lại một card → hash đổi → merge lại; không
  đổi → bỏ qua.

### Bước merge trong pipeline voiceover

- Chạy sau khi tất cả segment theory của một lang có URL (cuối
  `generateForKeypoint` per-lang, cùng chỗ `segmentUrls` hoàn tất).
- Tải các clip theory từ R2 về tmp → `ffprobe` lấy duration từng clip (nguồn
  của `cues`) → `ffmpeg -f concat -c copy` (cùng codec msedge-tts, không
  re-encode) → upload R2 → ghi `merged[lang]`.
- Thêm `ffmpeg` vào `Dockerfile` (apk). Merge lỗi → log + giữ nguyên
  `segments` (client tự fallback), không fail job dub.

### Backfill

- Endpoint admin `POST /voiceover/merge-all` (+ `GET /voiceover/merge-all/status`),
  fire-and-forget như job dub hiện có: quét mọi keypoint đã có `segments`,
  merge những lang thiếu/`hash` lệch. Idempotent, chạy lại được sau deploy.
  Chọn endpoint thay vì script ts-node vì dev hosted dùng Mongo khác máy local
  — thao tác qua API + bearer token là đường vận hành chuẩn của môi trường này.

## Thiết kế — hddhistory-flutter

### Model/entity

- `KeypointAudioModel`/`Entity` thêm `merged` (map lang → `{url, durationMs,
  cues[]}`), resolve locale cùng fallback chain với `segments`
  (`keypoint_audio_entity.dart:26-49`).

### Phát merged (có `merged[locale]` → chế độ mới; không có → giữ nguyên
đường per-card cũ)

- `LessonAudioHandler.loadMergedKeypoint(...)`: **một** `setAudioSource` cho
  cả keypoint, **một** `MediaItem` duration thật → lock screen một track dài,
  scrubber + ±10s hoạt động trên cả bài. `SeekHandler` sẵn có.
- Sync hai chiều, player là nguồn sự thật về vị trí đọc:
  - **Player → deck**: position vượt `cue[i].startMs + durMs` → nếu card kế
    đã nằm sau mép sống thì `viewCard`; nếu đang ở mép sống thì
    `TheoryCubit.nextDocument()` (đúng nhánh completion handler per-clip hiện
    tại — đây là chỗ tiến độ bài nhích). Lookup card bằng
    `learningItemId + documentIndex`, không số học. Foreground gặp gate
    (paywall cap, `canContinue` false) → pause đúng
    tại ranh giới cue; ở nền thì đọc tiếp (giữ hành vi `playRestOfKeypoint`),
    quay lại app reveal tới card đang đọc bằng cơ chế
    `isAheadOfDeck`/`_followNarrationToClip` sẵn có (đổi đơn vị clip → cue).
  - **Deck → player**: swipe / chạm pip → `seek(cue.startMs)`.
  - Cue `durMs: 0`: card không có tiếng — position không bao giờ rơi vào nó;
    khi voice dẫn deck thì lướt qua, khi người đọc tự xem thì không phát gì
    (như hiện tại).
- Cuối file (cue cuối kết thúc) → giữ nguyên chuỗi
  `nextDocument → completeCurrentKeypoint` hiện có.

### Resume

- Record persist (HydratedCubit mới, gọn): `{courseId, keypointId,
  positionMs, updatedAt}` — ghi throttle ~5s khi đang phát + khi
  pause/ra nền; xoá khi complete keypoint.
- Mở app lại (kể cả bị kill) → Live Activity / roadmap "Tiếp tục" →
  `startKeypointLesson` như hiện tại; sau khi items + merged load, nếu record
  khớp `keypointId` → reveal deck tới card của position, `seek(positionMs)`,
  phát tiếp (entry mode 'audio' hiện tại vốn autoplay).
- Mở keypoint **đã hoàn thành** từ roadmap: không áp record → đọc từ đầu.

## Thứ tự triển khai

1. hddhistory-api: schema + merge step + backfill script → deploy dev → chạy
   backfill → spot-check bằng `db-query`/Swagger.
2. hddhistory-flutter: model + merged playback + resume → `flutter analyze` +
   unit test cue lookup/resume → sim-test + máy thật (lock screen chỉ xem
   được trên device thật).
3. API đi trước (additive, an toàn); app phát hiện tính năng bằng sự tồn tại
   của `merged[locale].url`.

## Đã cân nhắc và loại

- **Chỉ sửa client (queue + LockCachingAudioSource)**: hết phần lớn giật
  nhưng còn micro-gap giữa các file, duration lock screen chỉ hiện dần, và
  giữ nguyên nguồn bug đánh số hai phía. Loại vì không đạt "như một video".
- **Dùng `audio.url` sẵn có làm file dài**: không có cue map và timeline
  không khớp các clip lẻ. Loại.
- **Sửa số học per-card ở đường cũ (video-item mismatch)**: sau backfill
  đường cũ gần như không còn chạy; không sửa riêng (YAGNI). Nếu backfill vì
  lý do gì chưa phủ hết, bug cũ vẫn như hiện trạng — không tệ hơn.

## Rollout checklist (API)

1. Merge branch → develop → deploy dev qua Jenkins (`/deploy-api`).
2. `POST /api/v1/voiceover/merge-all` (bearer admin) trên dev.
3. Poll `GET /api/v1/voiceover/merge-all/status` đến `state: done`;
   `failed` phải ≈ 0, xem `lastErrors` nếu không.
4. Spot-check 2-3 keypoint (db-query, read-only): `audio.merged.vi.url`
   tồn tại, `cues` phủ đúng số theory documents, `durationMs` ≈ tổng durMs.
5. Chỉ sau đó mới ship app (Phase 2) — app tự fallback khi thiếu `merged`.

## Kiểm thử

- hddhistory-api: `npx tsc --noEmit`; spec đơn vị cho hàm dựng cue (offset cộng
  dồn, card durMs 0, hash idempotent) nếu tiện — test culture hiện thin.
- hddhistory-flutter: unit test cho cue lookup + resume record; `flutter analyze`;
  xác minh hành vi trên simulator (sync card, gate, resume) và máy thật
  (lock screen, background).
