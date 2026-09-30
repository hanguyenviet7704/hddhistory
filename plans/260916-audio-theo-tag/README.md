# Audio theo tag: kho clip khoá theo hash chữ (design, 2026-09-16)

Nguồn: brainstorm với owner 2026-09-16. Câu hỏi mở đầu của owner: *"khi version
của course xuất hiện thì version của audio thì sao?"* — cần **nhìn thấy** tag
nào có audio, tag nào thiếu thì dub bù được, và phân biệt "chữ có đổi nhưng
theory không đổi nên không cần dub lại".

Phạm vi: hddhistory-api + hddhistory-admin. **Không có phần việc nào ở hddhistory-flutter** —
hình dạng `keypoint.audio` trả về không đổi một byte.

---

## 0. Lỗi đang có (lý do đợt này không chỉ là một màn hình)

`plans/260907-course-content-versions/README.md` quyết định 3 viết: *"`audio`
**có** đóng băng"*. Trên thực tế chỉ **chuỗi URL** được đóng băng, còn **file
thì không**:

- Key R2 cố định theo keypoint + ngôn ngữ + số thứ tự thẻ:
  `voiceover/<kp>/<lang>/<index>.mp3` (`voiceover.service.ts:748`),
  `voiceover/<kp>/<lang>.mp3` (`:793`), `…-nextup.mp3` (`:834`),
  `voiceover/<kp>/<lang>/merged.mp3` (`voiceover-merge.service.ts:273`).
- Dub lại là PUT đè lên đúng key đó. `?v=<hash>` mà `appendVersion` gắn vào
  (`voiceover-merge.util.ts:101`) chỉ là cache-buster, **không chọn được bản
  nào trong R2**.

Ba hệ quả:

1. **Tag cũ tự đổi giọng.** v1.0.0 giữ URL `…/3.mp3?v=aaa` nhưng bytes ở path
   đó đã là bản v1.0.1. Nghe ra bản nào phụ thuộc edge cache — mà
   `Cache-Control: max-age=31536000, immutable` nên hai user cùng đọc v1.0.0
   có thể nghe hai bản khác nhau, và không có cách nào ép về bản cũ.
2. **Lệch thẻ chứ không chỉ lệch bản.** `segments[lang][i]` ăn theo **chỉ số
   thẻ**. Bản mới thêm/bớt/đảo một thẻ là `…/3.mp3` thành lời của thẻ khác.
   Không log nào bắt được.
3. **A/B nội dung thì lệch chắc chắn.** `course_content_experiments` cho hai
   tag chạy song song trên cùng `keypointId` → một path audio duy nhất cho hai
   bản chữ khác nhau. Nhánh dub sau đè nhánh dub trước.

Đợt này vá cả ba, vì cơ chế để **hiển thị** đúng và cơ chế để **lưu** đúng là
một.

---

## 1. Quyết định đã chốt (và vì sao)

1. **Audio tách khỏi tag, khớp theo hash chữ.** Tag giữ chữ; audio nằm trong
   kho riêng khoá theo `(keypointId, lang, kind, index, textHash)`. Dub một lần
   là **mọi tag có cùng đoạn chữ đều nghe được, kể cả tag cũ** — đó chính là
   "không đổi theory thì không cần dub lại", không phải một luật riêng phải
   viết thêm.
   Phương án bị loại: khoá audio theo `versionId` — bắt dub lại toàn bộ mỗi
   version, đúng thứ mà quyết định 1 của plan 260907 mua được bằng việc dùng
   chung `_id` (2.97M ký tự / 433 keypoint cho bản card-only).
2. **Ghép lúc ĐỌC, không ráp lúc đánh tag.** Tag không bao giờ bị sửa
   (`published_content` giữ nguyên append-only). Dub bù cho tag cũ có hiệu lực
   ngay. Giá phải trả: thêm một query gom lô trên đường đọc keypoint.
   Phương án bị loại: đóng băng URL vào snapshot lúc tạo tag — nhanh hơn khi
   đọc nhưng dub bù phải ghi lại rows của tag, và phải đẻ thêm luật "chỉ khi
   tag chưa từng phát hành".
3. **Đường dẫn R2 mang hash.** `…/<index>-<hash12>.mp3`. Hệ quả quan trọng cho
   migration: từ lúc không còn ai ghi vào đường dẫn cũ, **file cũ tự trở thành
   bất biến** → backfill chỉ chèn row trỏ vào URL đang có, **không copy một mp3
   nào**.
4. **Chặn phát hành khi tag thiếu audio.** Không phải cảnh báo, không phải tự
   dub. Owner chọn chặn.
5. **"Đủ" = cả 5 thứ tiếng** `vi/en/zh/ja/ko` (`VOICEOVER_LANGS`). Ô `none`
   (không có chữ để đọc) tính là đạt. Kho nội dung đang giữ đúng chuẩn này —
   433/433 keypoint đã dub đủ 5 — nên đây là siết lại thứ đã làm được, không
   phải dựng rào mới.
6. **Rollback không bị chặn.** `PUT :courseId/current-version` vừa là publish
   vừa là rollback. Chặn cứng nghĩa là lúc cháy nhà không lùi về tag cũ được.
   Chỉ chặn tag **chưa từng phát hành**; tag đã từng phục vụ user thì cho về.
   Cờ `everPublished` đã có sẵn, đọc từ `course_version_activations`
   (`course-version.service.ts:169`).
7. **`keypoint.audio` trên document sống giữ nguyên.** Job dub vẫn ghi nó như
   hôm nay, nên bản đang sửa và mọi đường đọc chưa chuyển đều không gãy trong
   lúc rollout. Kho clip là nguồn cho mọi câu hỏi "tag nào có gì".

---

## 2. Mô hình dữ liệu

Một collection mới. Không đụng schema nội dung hiện có.

### `keypoint_audio_clips` — append-only, bất biến

```
{ keypointId, lang, kind, index, textHash,
  url, durationMs?, cues?, voice, createdAt }

kind  ∈ 'card' | 'whole' | 'nextup' | 'merged'
index   số thứ tự thẻ với kind='card'; -1 cho ba loại còn lại
cues    chỉ có ở kind='merged' (IMergedAudioCue[])
```

- unique `(keypointId, lang, kind, index, textHash)`. Dub lại đúng hash đã có
  là **no-op**, không chèn row thứ hai.
- Index `(keypointId, lang)` cho việc gom lô lúc đọc.
- Row **không bao giờ update**. Muốn đổi giọng đọc thì `voice` nằm trong hash
  (xem dưới) nên nó là một row khác.
- `textHash` = đúng hàm băm đang dùng (`this.hash(text)` trong
  `voiceover.service.ts`), **cộng tên giọng**: hai bản dub khác narrator của
  cùng một câu là hai clip khác nhau, đúng như `voiceChanged` hiện đang xử lý.

### Đường dẫn R2 mới

| kind | key |
|------|-----|
| card | `voiceover/<kp>/<lang>/<index>-<hash12>.mp3` |
| whole | `voiceover/<kp>/<lang>-<hash12>.mp3` |
| nextup | `voiceover/<kp>/<lang>-nextup-<hash12>.mp3` |
| merged | `voiceover/<kp>/<lang>/merged-<hash12>.mp3` |

`appendVersion` giữ nguyên (URL vẫn có `?v=`) — giờ nó thừa về mặt đúng/sai
nhưng vô hại, và bỏ đi sẽ làm mọi URL đã lưu đổi hình dạng mà không được gì.

---

## 3. Đường đọc

`AudioResolver` (service mới, đặt trong `course-version/` vì nó chỉ phục vụ
đường đọc theo tag):

```
attach(keypointDocs, learningItemsOfSameVersion) → keypointDocs có audio đã ráp
```

1. Với mỗi keypoint, dựng lại lời đọc từng thẻ **từ learning item của chính
   tag đó** — dùng đúng `narration-text.util` + `buildText` đang có, không viết
   lại cách chia thẻ.
2. Băm → danh sách `(lang, kind, index, hash)`.
3. Một query `$in` gom **cả lô** vào `keypoint_audio_clips`.
4. Ráp vào `audio.segments / url / merged / nextUp`. Thiếu thì để rỗng — app
   đã chịu được rỗng qua `hasUsableAudio`.

Gắn vào `ContentSource.getKeypoint` và `getKeypointsByIds` ở **nhánh có
`versionId`**. Nhánh working tree giữ nguyên `keypoint.audio` như hôm nay.

`keypointBrief` (projection) chỉ giữ `audio.url` — resolver phải chạy **trước**
projection, nếu không brief theo tag sẽ trống audio.

**Cache:** một `Map` trong process khoá `(versionId, keypointId)`, TTL ngắn
(60s). Cùng một tag bị đọc đi đọc lại bởi mọi user đang học khoá đó.

---

## 4. Trạng thái theo tag

`getCourseStatus(courseId, versionId?)` — **cùng hàm tính 5 trạng thái đang
chạy** (`voiceover.service.ts:1100`), chỉ đổi đầu vào từ
`keypointRepository`/`learningItemRepository` sang `ContentSource`.

| trạng thái | nghĩa trong ngữ cảnh tag |
|---|---|
| `done` | chữ của tag này có clip khớp hash |
| `stale` | keypoint có audio nhưng không khớp chữ **của tag này** → vẫn là thiếu |
| `missing` | có chữ, chưa có clip nào |
| `failed` | lần dub gần nhất lỗi |
| `none` | không có chữ để đọc → tính là đạt |

API: `GET /courses/:courseId/versions/:tag/audio-coverage`.

**SỬA so với bản duyệt:** định thêm `?version=` vào
`GET voiceover/course/:courseId/status` cho khỏi đẻ endpoint. Không làm được:
hàm tính nằm trong `VoiceoverService`, mà `VoiceoverModule` import `CourseModule`
— import ngược `CourseVersionModule` vào đó là đóng vòng DI, đúng loại lỗi chỉ
lộ ra lúc boot. Nên phần tính theo tag thành `AudioCoverageService` nằm trong
`course-version`, và endpoint nằm cùng chỗ. Endpoint voiceover cũ giữ nguyên cho
bản đang sửa.

---

## 5. Chốt chặn phát hành

Hai cửa:

- `POST :courseId/versions` khi `setCurrent: true`
- `PUT :courseId/current-version`

Từ chối khi tag đích còn ô nào **không phải** `done`/`none`, **trừ** khi tag đó
`everPublished` (quyết định 6). Lỗi 400 liệt kê keypoint + ngôn ngữ thiếu, đủ
để người biên tập biết bấm dub cái gì.

---

## 6. Dub bù cho một tag

`POST voiceover/course/:courseId/generate?version=<tag>`:

- Đọc chữ **từ tag**, dub đúng những `(keypoint, lang, thẻ)` tag đó thiếu.
- Ghi clip mới vào kho. **Không** đụng `published_content`, **không** đụng
  `keypoint.audio` của bản đang sửa — dub theo chữ cũ tạo clip cho hash cũ,
  bản đang sửa có hash khác nên không thấy gì thay đổi.
- Dùng lại giọng mà các thẻ hàng xóm trong cùng keypoint đã đọc; ghi lại một
  thẻ bằng giọng khác là cách làm một keypoint nghe như hỏng trong khi mọi ô
  vẫn xanh. `synthesizeMp3` định tuyến nhà cung cấp theo tên giọng nên tiếng
  Việt đang dùng Vbee vẫn đi Vbee.

**SỬA so với bản duyệt — chỉ dub THẺ.** Không `whole`, không `nextup`, không
`merged`. Ba thứ đó đều cần máy móc trong `VoiceoverModule` (merge service,
budget guard), import vào đây là đóng vòng DI qua `CourseModule`. Thẻ là thứ
app phát; `merged` chỉ là tối ưu và app tự lùi về `segments` khi thiếu. Hệ quả
phải biết: **tag được dub bù sẽ không có file `merged` riêng**, nên phần chạy
chữ theo tiếng đọc của tag đó kém mượt hơn cho tới khi bản đang sửa trùng chữ
và một lần merge thường chạy qua. Nếu thấy cần, cách gỡ là tách phần merge ra
một module con không phụ thuộc `CourseModule`, giống `TtsModule` đã tách.

Endpoint: `POST /courses/:courseId/versions/:tag/dub-missing` (chạy nền) +
`GET /courses/versions/dub-status`. Trần 1500 thẻ một lần chạy.

---

## 7. Admin

- `CourseVersionsModal`: mỗi dòng tag thêm một chip — ✓ đủ audio / "thiếu N ô",
  bấm vào mở thẳng lưới của đúng tag đó.
- `VoiceoverStatusModal`: thêm ô chọn "Bản đang sửa / v1.0.1 / v1.0.0"; lưới
  keypoint × 5 ngôn ngữ giữ nguyên; nút "Dub phần thiếu của tag này".

---

## 8. Backfill + thứ tự lên

`scripts/backfill-audio-clips.ts` — duyệt keypoint, đọc `audio.hash` /
`segmentHash` / `merged.hash` + `nextUpHash` cùng URL đang có, chèn rows.
Idempotent (unique index đỡ đòn), chạy một lần mỗi môi trường. **Không copy
mp3.**

Thứ tự:

1. api: kho + ghi clip khi dub + đường dẫn có hash (chặng 1)
2. backfill trên dev, kiểm bằng probe
3. api: resolver + `?version=` + gate + dub-theo-tag (chặng 2)
4. admin (chặng 3)

**api phải lên trước admin.** `whitelist: true` không kèm `forbidNonWhitelisted`
nên admin gọi `?version=` vào api cũ sẽ bị **nuốt tham số âm thầm** và hiện
nhầm trạng thái của bản đang sửa — sai mà không có lỗi nào.

---

## 9. Không làm (YAGNI)

- Không dọn file R2 cũ đợt này. Kho clip biết row nào thuộc tag nào, nhưng
  "tag nào còn sống" là câu hỏi của một job dọn riêng — viết khi R2 thực sự
  phình, không phải bây giờ.
- Không bỏ `keypoint.audio`. Nó là mạng an toàn trong lúc rollout.
- Không đụng `learning-import` (`user_lesson` là collection riêng, không phải
  nội dung khoá, không có tag).
- Không cho chọn "ngôn ngữ bắt buộc theo từng khoá". Owner chọn cả 5.

---

## 10. Rủi ro

1. **Resolver chạy sau projection là trống audio.** `keypointBrief` giữ mỗi
   `audio.url`; ráp sai thứ tự là roadmap im tiếng mà không lỗi.
2. **Thêm một query trên đường đọc keypoint.** Phải đo trên dev trước khi lên
   prod; cache 60s là để chỗ này.
3. **Backfill chèn hash của bản đang sửa cho tag cũ.** `audio.hash` hiện tại là
   hash của **chữ hôm nay**. Tag cũ có chữ khác sẽ đúng ra là `missing` — đó là
   sự thật, không phải lỗi backfill, nhưng nó có nghĩa là **ngay sau backfill,
   vài tag cũ sẽ hiện thiếu audio**. Đừng hoảng, và đừng bật gate trước khi
   người biên tập kịp nhìn.
4. **Gate chặn cả `POST versions` với `setCurrent: true`** — đường mà backfill
   version (`versions/backfill`) đang dùng. Phải chừa cửa cho job không người
   lái, nếu không lần backfill sau sẽ chết giữa chừng.

---

## 11. Gate kiểm chứng

- Spec (jest, repository giả — **không chạy cả bộ test trên máy này**):
  resolver ráp đúng clip theo hash · status theo tag · gate chặn/không chặn
  rollback · backfill idempotent.
- `npm run build` trước khi push (tsconfig.build bật `strict`).
- Sau khi lên api-dev: probe bằng token ẩn danh, so cùng một keypoint đọc qua
  hai tag khác nhau phải ra hai bộ URL khác nhau khi chữ khác nhau, và **cùng
  một bộ** khi chữ giống nhau.

---

## 12. Trạng thái

- 2026-09-16: design chốt với owner (4 câu hỏi, xem mục 1).
- 2026-09-16: **chặng 1 + 2 + 3 xong, đã commit develop, CHƯA deploy, CHƯA
  chạy backfill.**
  - `3303128` kho clip + key R2 mang hash + ghi kho ở đường dub/merge + script
    backfill
  - `5b22a6d` AudioResolver (đọc theo tag) + AudioCoverageService + chốt chặn
    phát hành + tách `narration-text.util`
  - `531d5cc` dub bù theo tag (thẻ)
  - admin `e6a8b39` cột Audio trong bảng phiên bản
  - `e72fe41` lưới an toàn rollout + `POST /voiceover/backfill-clips`
  - `b482c02` backfill ghi bằng bulkWrite upsert
  - `aadb91d` backfill trả về `total` đếm thẳng từ collection
  - `082d65f` lưới an toàn chỉ nới khi kho rỗng TOÀN CỤC

- 2026-09-16 chiều: **đã lên api-dev, đã backfill, đã probe đạt.**
  - kho dev: 484 keypoint · 34.428 clip tìm thấy · **33.565 hàng** (863 chênh =
    cùng một câu ở hai thẻ trong một keypoint, gộp đúng)
  - coverage tag đã dub (`6a4f014c…` v1.0.0): **30/30 ô done** — chữ dựng lại từ
    learning item ĐÓNG BĂNG băm ra trùng khít hash đường dub đã lưu
  - đọc keypoint theo tag: 31/32 thẻ có tiếng, có `url` + `merged`; cụm audio
    trả về thiếu `audio.text` → chứng minh do resolver ráp chứ không phải bản
    đóng băng
  - chốt chặn: khoá chưa dub đọc ra `complete: false` → tag mới sẽ bị chặn
  - CHƯA thử publish thật (sẽ để lại tag rác trên dev); phần nối là một dòng
    đọc `coverage.complete`, có 2 spec phủ

### Hai lỗi chỉ probe mới bắt được

1. **`insertMany` nuốt cả lô mà không lỗi.** Backfill trả `found: 34428,
   inserted: 0` và HTTP 201. Một lô chứa hai hàng cùng danh tính làm
   `insertMany({ordered:false})` ném lỗi trùng khoá; đoạn bắt lỗi đọc hình dạng
   lỗi đó thành "không chèn được gì". Thực tế nó ĐÃ ghi 33.565 hàng — chỉ con số
   là sai, nên nhìn từ ngoài giống hệt "ghi không xuống". Bài học: đừng đếm
   bằng cách suy từ lỗi; `bulkWrite` upsert không có gì phải suy.
2. **Lưới an toàn nới nhầm đúng ca cần chặn.** "Kho không có clip nào cho khoá
   này" cũng chính là hình dạng của khoá chưa từng dub. Phải phân biệt bằng
   `countAll()` toàn kho.

### Còn mở

- Tag được dub bù không có file `merged` riêng (mục 6).
- Chưa deploy admin (chỉ mới push develop).
