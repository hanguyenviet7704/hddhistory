# Stack local độc lập + nội dung lịch sử Việt Nam — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dựng môi trường dev chạy hoàn toàn cục bộ (không cần VPN, không cần server dev) và đổ vào đó 12 skillset lịch sử Việt Nam theo trục biên niên với ~560 keypoint nội dung thật.

**Architecture:** Docker chỉ chạy Mongo + MySQL; API chạy `npm run start:dev` trên host cổng 4000. Rào Firebase được gỡ bằng một nhánh no-op có chặn `production`. Nội dung nằm trong một file JSON tách khỏi code, đi qua một validator thuần và một builder thuần (cả hai dưới `src/` để jest chạy được), rồi mới tới script ghi Mongo.

**Tech Stack:** NestJS 9, Mongoose, TypeORM (MySQL), ts-node, Jest 29 + ts-jest, Docker Compose, Flutter (dart-define-from-file).

**Spec:** `plans/260928-local-stack-vn-history/design.md`

## Global Constraints

- Nhánh làm việc: `develop`. Commit thẳng, mỗi task một commit.
- **Cây thư mục đang bẩn — 19 file WIP từ session khác.** Chỉ `git add` đúng path mình chạm. Cấm `git add <thư mục>`, cấm `git stash`, cấm `git checkout --`/`git restore`.
- Commit: `type: subject`, chữ thường, tiếng Việt. `type` ∈ feature, fix, refactor, style, docs, test, chore, perf.
- **Không chạy full test suite** (máy hết RAM). Chỉ chạy file chỉ định: `npm test -- <path>`.
- **`npm run build` là cổng CI thật** (`tsconfig.build.json` bật `strict: true`). `npx tsc --noEmit` dùng config lỏng nên không đủ — chạy trước khi commit code TypeScript.

  **Nhưng build KHÔNG thể pass sạch trong cây này.** Có sẵn 3 lỗi TypeScript trong `src/modules/community/src/modules/bot/repository/community-bot-queue.repository.ts` — WIP chưa commit của session khác, không thuộc phạm vi plan này và **không được sửa**. Nên cổng là "không có lỗi nào trong file mà plan này chạm", kiểm bằng:

  ```bash
  npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
    | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
  ```

  Kết quả phải in ra **đúng một dòng**: `src/modules/community/src/modules/bot/repository/community-bot-queue.repository.ts`. Thêm bất kỳ file nào khác là lỗi do task này gây ra — sửa trước khi commit.

- **Đừng chạy `npm run lint`.** Script này hardcode glob toàn repo và bật `--fix`, nên truyền đường dẫn vào *không* thu hẹp phạm vi — nó sẽ tự sửa cả file WIP của session khác (đã xảy ra thật ở Task 1). Lint file của mình bằng: `npx eslint <các file vừa sửa> --fix`.
- Jest đặt `rootDir: src` → **mọi file `*.spec.ts` phải nằm dưới `src/`**. Logic muốn test được không đặt ở `scripts/`.
- `resolveJsonModule` **không bật** → không `import x from './y.json'`. Đọc JSON bằng `fs.readFileSync` + `JSON.parse`, theo tiền lệ `scripts/seed-knowledge-graph.ts:105`.
- Seeder Mongo trong repo này **cố ý không ghi đè** bản ghi đã có, để giữ chỉnh sửa của admin. Idempotency = chèn-nếu-thiếu, không phải upsert.
- Nội dung chỉ điền `title.vi` / `description.vi`. Các locale khác bỏ trống.
- `.env` là file gitignore — sửa nhưng không commit.
- **Không bao giờ commit `package.json`.** Thêm dòng `"scripts"` của bạn vào working tree để `npm run` dùng được, nhưng **để nó chưa commit**. Lý do: file này đang mang WIP chưa commit của session khác, mà `git add package.json` thì stage nguyên file kể cả phần của họ. Thao tác "gỡ dòng của họ ra, commit, rồi khôi phục" đã được thử ở Task 2–4 và **đã làm mất WIP của họ một lần** — đừng lặp lại. Commit đúng file script, bỏ qua package.json.
- **Không bao giờ commit `swagger-spec.json`.** Nó là artifact sinh tự động, và mỗi lần API boot lại là nó bị ghi đè (boot đầu tiên ở Task 2 đã tạo diff +23k dòng). Nó là file tracked nên sẽ luôn hiện `M` trong `git status` từ đây trở đi — bỏ qua, đừng stage.

## Review Focus

Năm thứ spec ngụ ý nhưng dễ rơi khỏi test của từng task:

1. **Chạy seeder lần thứ hai** — phải không nhân bản và không đè lên bản ghi admin đã sửa. *Test ở Task 7.*
2. **`periodId` trong curriculum không khớp `vn_history_seed.json`** — phải chết lúc validate, không phải lúc app hiển thị sai thời kỳ. *Test ở Task 6.*
3. **Curriculum thiếu field hoặc rỗng** (`title.vi` rỗng, lesson không có keypoint) — validator phải bắt và nêu đúng đường dẫn tới chỗ hỏng, chứ không ghi nửa chừng vào Mongo. *Test ở Task 6.*
4. **Mongo chưa sẵn sàng khi chạy seeder** — báo lỗi rõ và thoát khác 0, không treo vô hạn. *Test ở Task 8.*
5. **Một thời kỳ thiếu ảnh placeholder** — course/lesson nhận `image` rỗng làm vỡ layout app. Builder phải đảm bảo mọi node đều có `image`. *Test ở Task 7.*

---

# Phase 1 — Stack chạy được

### Task 1: Gỡ rào Firebase

**Files:**
- Create: `src/base/config/firebase-credential.ts`
- Create: `src/base/config/firebase-credential.spec.ts`
- Modify: `src/base/config/firebase.ts:9-15`

**Interfaces:**
- Consumes: không có.
- Produces: `isPlaceholderServiceAccount(sa: unknown): boolean`, `shouldStubFirebase(sa: unknown, nodeEnv: string | undefined): boolean` — Task 2 dựa vào việc API boot được.

- [ ] **Step 1: Viết test thất bại**

Tạo `src/base/config/firebase-credential.spec.ts`:

```typescript
import {
  isPlaceholderServiceAccount,
  shouldStubFirebase,
} from './firebase-credential';

const PLACEHOLDER = {
  type: 'service_account',
  project_id: '',
  private_key: '',
  client_email: '',
};

const REAL = {
  type: 'service_account',
  project_id: 'hddhistory-dev',
  private_key: '-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n',
  client_email: 'sa@meup-dev.iam.gserviceaccount.com',
};

describe('isPlaceholderServiceAccount', () => {
  it('nhận ra file mẫu trong repo là placeholder', () => {
    expect(isPlaceholderServiceAccount(PLACEHOLDER)).toBe(true);
  });

  it('nhận ra service account thật', () => {
    expect(isPlaceholderServiceAccount(REAL)).toBe(false);
  });

  it('coi project_id chỉ có khoảng trắng là placeholder', () => {
    expect(isPlaceholderServiceAccount({ ...REAL, project_id: '   ' })).toBe(true);
  });

  it('coi thiếu private_key là placeholder dù có project_id', () => {
    expect(isPlaceholderServiceAccount({ ...REAL, private_key: '' })).toBe(true);
  });

  it('không nổ khi nhận null hoặc thứ không phải object', () => {
    expect(isPlaceholderServiceAccount(null)).toBe(true);
    expect(isPlaceholderServiceAccount('nope')).toBe(true);
  });
});

describe('shouldStubFirebase', () => {
  it('stub khi placeholder và không phải production', () => {
    expect(shouldStubFirebase(PLACEHOLDER, 'development')).toBe(true);
  });

  it('KHÔNG stub ở production dù credential là placeholder', () => {
    expect(shouldStubFirebase(PLACEHOLDER, 'production')).toBe(false);
  });

  it('KHÔNG stub khi credential thật', () => {
    expect(shouldStubFirebase(REAL, 'development')).toBe(false);
  });

  it('stub khi NODE_ENV không được đặt và credential là placeholder', () => {
    expect(shouldStubFirebase(PLACEHOLDER, undefined)).toBe(true);
  });
});
```

- [ ] **Step 2: Chạy test, xác nhận nó thất bại**

Run: `npm test -- src/base/config/firebase-credential.spec.ts`
Expected: FAIL — `Cannot find module './firebase-credential'`.

- [ ] **Step 3: Viết implementation tối thiểu**

Tạo `src/base/config/firebase-credential.ts`:

```typescript
import * as admin from 'firebase-admin';

/**
 * `google-service.json` trong repo là file mẫu với mọi trường để rỗng. Nếu đưa
 * thẳng vào `admin.credential.cert()` thì nó ném lỗi ngay trong constructor của
 * FirebaseService, kéo sập mọi module chạm tới AuthModule — tức là gần như cả
 * app, trước khi Nest kịp wire xong. Đó là lý do API không boot được trên máy
 * cá nhân nếu không có credential thật.
 *
 * Hai hàm dưới đây tách riêng phần quyết định để test được mà không cần đụng
 * tới firebase-admin.
 */

/** Các trường mà thiếu một cái là `credential.cert()` chắc chắn ném lỗi. */
const REQUIRED_FIELDS = ['project_id', 'private_key', 'client_email'] as const;

export function isPlaceholderServiceAccount(sa: unknown): boolean {
  if (!sa || typeof sa !== 'object') return true;
  const record = sa as Record<string, unknown>;
  return REQUIRED_FIELDS.some((field) => {
    const value = record[field];
    return typeof value !== 'string' || value.trim() === '';
  });
}

/**
 * Hai điều kiện chứ không phải một: placeholder là dấu hiệu máy dev, còn chặn
 * `production` đảm bảo môi trường thật không bao giờ im lặng chạy với Firebase
 * giả — ở đó thiếu credential phải là lỗi ồn ào, không phải tính năng tắt lặng lẽ.
 */
export function shouldStubFirebase(
  sa: unknown,
  nodeEnv: string | undefined,
): boolean {
  if (nodeEnv === 'production') return false;
  return isPlaceholderServiceAccount(sa);
}

/**
 * Chỉ cần *dựng được* và trả về các service rỗng — không có lời gọi Firebase
 * nào chạy qua đây ở máy dev. Mỗi method ném lỗi có tên rõ ràng, để nếu sau này
 * một luồng nào đó thật sự cần Firebase thì lỗi chỉ thẳng vào chỗ gọi thay vì
 * im lặng trả undefined. Ép kiểu vì đây cố ý không phải app thật.
 *
 * Danh sách method phải phủ ĐÚNG những gì firebase.ts gọi trên `this.firebaseApp`,
 * kể cả các chuỗi xuống dòng (`this.firebaseApp\n  .messaging()`) mà grep một dòng
 * dễ bỏ sót, cộng với method mà bên gọi dùng trên object `remoteConfig()` trả về.
 * Thiếu một cái là ném `TypeError: ... is not a function` thay vì lỗi có tên —
 * và `subscribeToTopic` nằm trên đường đăng nhập của app, nên thiếu nó là 500
 * không rõ nguyên nhân ngay lúc login.
 */
export function createNoopFirebaseApp(): admin.app.App {
  const reject = (method: string) => async () => {
    throw new Error(`Firebase đang ở chế độ no-op, không gọi được ${method}`);
  };
  return {
    name: 'noop',
    auth: () => ({ verifyIdToken: reject('auth().verifyIdToken') }),
    messaging: () => ({
      // firebase.ts:107
      sendEachForMulticast: reject('messaging().sendEachForMulticast'),
      // firebase.ts:190-192
      send: reject('messaging().send'),
      // firebase.ts:205-207 — auth.service.ts subscribeTopicByToken
      subscribeToTopic: reject('messaging().subscribeToTopic'),
      // firebase.ts:229-231 — auth.service.ts unsubscribeTopicByToken
      unsubscribeFromTopic: reject('messaging().unsubscribeFromTopic'),
    }),
    remoteConfig: () => ({
      // paywall-config.repository.ts:88
      getTemplate: reject('remoteConfig().getTemplate'),
      // paywall-config.repository.ts:112
      publishTemplate: reject('remoteConfig().publishTemplate'),
    }),
  } as unknown as admin.app.App;
}
```

- [ ] **Step 4: Chạy test, xác nhận nó pass**

Run: `npm test -- src/base/config/firebase-credential.spec.ts`
Expected: PASS, 9 test.

- [ ] **Step 5: Nối vào FirebaseService**

Sửa `src/base/config/firebase.ts`. Thay constructor hiện tại (dòng 9–15) bằng:

```typescript
  constructor() {
    const serviceAccount = require('../../../google-service.json');

    if (shouldStubFirebase(serviceAccount, process.env.NODE_ENV)) {
      this.logger.warn(
        'google-service.json là placeholder — Firebase chạy ở chế độ no-op. ' +
          'Push notification và Remote Config sẽ không hoạt động. ' +
          'Chỉ dành cho máy dev; ở production thiếu credential vẫn là lỗi.',
      );
      this.firebaseApp = createNoopFirebaseApp();
      return;
    }

    this.firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
```

Thêm import ở đầu file:

```typescript
import {
  createNoopFirebaseApp,
  shouldStubFirebase,
} from './firebase-credential';
```

`createNoopFirebaseApp` đã được định nghĩa sẵn ở Step 3, không cần thêm gì vào
`firebase-credential.ts` nữa.

Sau khi sửa, chạy `npx eslint src/base/config/firebase.ts src/base/config/firebase-credential.ts --fix`
để ESLint xếp lại thứ tự import. **Không dùng `npm run lint`** — xem Global Constraints.

- [ ] **Step 6: Build strict để chắc không vỡ cổng CI**

Run:
```bash
npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
  | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
```
Expected: in ra đúng một dòng — `src/.../community-bot-queue.repository.ts` (lỗi có sẵn của session khác). Bất kỳ file nào khác xuất hiện là do task này gây ra.

- [ ] **Step 7: Commit**

```bash
git add src/base/config/firebase-credential.ts src/base/config/firebase-credential.spec.ts src/base/config/firebase.ts
git commit -m "feat: firebase chạy no-op khi google-service.json là placeholder, chặn ở production"
```

---

### Task 2: Dựng DB local, tạo schema MySQL, cho API boot

**Files:**
- Create: `scripts/setup-local-mysql.ts`
- Modify: `package.json` (thêm `setup:local-mysql`)
- Modify: `.env` (không commit — file gitignore)

**Interfaces:**
- Consumes: Task 1 (FirebaseService dựng được không cần credential thật).
- Produces: API chạy ở `http://localhost:4000`, Mongo ở 27017, MySQL ở 3306 với 11 bảng — mọi task sau dựa vào đây.

**Bối cảnh đã được kiểm chứng trước khi viết task này.** Bốn điều dưới đây đều đã đo trên máy, không phải phỏng đoán:

1. **Cổng 4000, không phải 3000.** Cổng 3000 đang bị `hddhistory-web` (Next.js dev server của project khác) chiếm và đang có phiên duyệt sống. 4000 trống và là default sẵn trong `src/main.ts:67`.

2. **Chạy `node dist/main.js`, KHÔNG dùng `nest start --watch`.** Chế độ watch của `@nestjs/cli` (tsc-watch, không webpack) chỉ spawn `node dist/main.js` khi số lỗi biên dịch bằng 0. Cây này có sẵn 3 lỗi TS trong WIP của session khác, nên watch biên dịch xong rồi đứng im vĩnh viễn, không bao giờ khởi động app. Ngược lại `npm run build` vẫn *xuất* `dist/` vì `noEmitOnError` không được đặt, và `src/modules/community/src/modules/bot/` không được file tracked nào import nên output hỏng của nó không bao giờ được nạp.

3. **`.env` không được chứa key rỗng.** `configuration.ts` validate bằng Joi với `Joi.string().optional()` — cho phép *vắng mặt* nhưng không cho chuỗi rỗng. `GEMINI_TIMEOUT_MS=` để trống làm app chết ngay lúc khởi tạo config. Bỏ hẳn dòng đó, đừng đặt giá trị giả.

4. **12 migration KHÔNG tự dựng được schema.** Chúng chỉ `ALTER TABLE` các bảng vốn được dựng tay trên server dev/prod (xem comment `mysql.module.ts:22-24`). Trên MySQL rỗng, migration đầu tiên chết vì `Table 'ai_tutor.iap_purchases' doesn't exist`. Đây là lý do task này cần script mới ở Step 2.

- [ ] **Step 1: Xác nhận hai container DB còn sống**

Run: `docker ps --format '{{.Names}}\t{{.Status}}'`
Expected: `meup_mongo` và `meup_mysql` đều Up. Nếu thiếu: `docker compose -f docker-compose.local.yml up -d`, chờ ~30s cho MySQL 8 khởi tạo.

- [ ] **Step 2: Viết script dựng schema MySQL**

Tạo `scripts/setup-local-mysql.ts`:

```typescript
/**
 * Dựng schema MySQL cho máy dev từ ĐỊNH NGHĨA ENTITY, rồi đóng dấu toàn bộ
 * migration là đã chạy.
 *
 * Vì sao cần: 12 migration trong src/migrations chỉ ALTER các bảng vốn được
 * dựng tay trên server (xem mysql.module.ts:22-24 — repo này không có hệ
 * migration cho tới gần đây). Trên một MySQL rỗng, migration đầu tiên chết ngay
 * vì `Table 'ai_tutor.iap_purchases' doesn't exist`, và app không boot được.
 *
 * Cách làm: để TypeORM `synchronize` dựng 11 bảng theo hình dạng entity hiện
 * tại — vốn ĐÃ bao gồm mọi cột mà 12 migration kia thêm vào — rồi ghi thẳng 12
 * dòng vào `typeorm_migrations`. Nhờ vậy `migrationsRun: true` lúc app boot
 * thấy không còn gì để chạy, thay vì thử ALTER những cột đã tồn tại.
 *
 * PHÁ HUỶ: `dropSchema: true` xoá sạch database trước khi dựng lại. Chỉ chạy
 * trên MySQL local. Script tự chặn nếu MYSQL_HOST không phải localhost.
 *
 * Chạy: npm run setup:local-mysql
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import { DataSource } from 'typeorm';

async function main() {
  const host = process.env.MYSQL_HOST;
  if (host !== 'localhost' && host !== '127.0.0.1') {
    throw new Error(
      `Script này xoá sạch database và chỉ dành cho máy local, nhưng MYSQL_HOST="${host}". Dừng.`,
    );
  }

  const root = process.cwd();
  const ds = new DataSource({
    type: 'mysql',
    host,
    port: Number(process.env.MYSQL_PORT),
    username: process.env.MYSQL_USERNAME,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DB,
    entities: [path.join(root, 'src/**/*.entity.ts')],
    dropSchema: true,
    synchronize: true,
    migrationsRun: false,
    logging: false,
  });

  await ds.initialize();
  const tables = await ds.query('SHOW TABLES');
  console.log(`Đã dựng ${tables.length} bảng từ entity.`);

  await ds.query(
    'CREATE TABLE IF NOT EXISTS typeorm_migrations ' +
      '(id INT AUTO_INCREMENT PRIMARY KEY, timestamp BIGINT NOT NULL, name VARCHAR(255) NOT NULL)',
  );

  const dir = path.join(root, 'src/migrations');
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.ts')).sort();
  for (const f of files) {
    const src = fs.readFileSync(path.join(dir, f), 'utf-8');
    const cls = src.match(/export class (\w+)/)?.[1];
    if (!cls) throw new Error(`Không tìm thấy tên class trong ${f}`);
    const ts = cls.match(/(\d+)$/)?.[1];
    if (!ts) throw new Error(`Tên class ${cls} không kết thúc bằng timestamp`);
    await ds.query(
      'INSERT INTO typeorm_migrations (timestamp, name) VALUES (?, ?)',
      [ts, cls],
    );
  }

  const [{ n }] = await ds.query('SELECT COUNT(*) AS n FROM typeorm_migrations');
  console.log(`Đã đóng dấu ${n} migration. Xong.`);
  await ds.destroy();
}

main().catch((e) => {
  console.error('Dựng schema MySQL thất bại:', e.message);
  process.exit(1);
});
```

- [ ] **Step 3: Thêm lệnh vào package.json**

Trong khối `"scripts"`:

```json
    "setup:local-mysql": "ts-node -r tsconfig-paths/register scripts/setup-local-mysql.ts",
```

`-r tsconfig-paths/register` là bắt buộc: các entity import qua alias `@base/*`, thiếu nó script chết với `Cannot find module '@base/database/mysql/abstract.entity'`.

- [ ] **Step 4: Trỏ `.env` về local**

Sửa `.env`:

```
PORT=4000
MONGODB_URI=mongodb://admin:PGmnyFWTr9XyAvDX@localhost:27017/ai-tutor?authSource=admin

#MYSQL
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USERNAME=root
MYSQL_PASSWORD=localroot
MYSQL_DB=ai_tutor
```

Và **xoá mọi dòng có dạng `KEY=` không giá trị** (`sed -i '' '/^[A-Z_]*=$/d' .env`) — xem bối cảnh điểm 3.

Giá trị cũ để khôi phục khi quay lại mạng nội bộ: `MYSQL_HOST=192.168.10.35`, `MYSQL_PORT=33003`, `MYSQL_USERNAME=admin`, `MYSQL_PASSWORD=PGmnyFWTr9XyAvDX`; `MONGODB_URI` dùng host `meup_mongo`; `PORT=3000`.

- [ ] **Step 5: Dựng schema**

Run: `npm run setup:local-mysql`
Expected: `Đã dựng 11 bảng từ entity.` rồi `Đã đóng dấu 12 migration. Xong.`

- [ ] **Step 6: Build và chạy API nền**

```bash
npm run build 2>&1 | tail -2
kill $(lsof -t -iTCP:4098 -sTCP:LISTEN) 2>/dev/null || true
pkill -f "node dist/main.js" 2>/dev/null || true
node dist/main.js > /tmp/hddhistory-api.log 2>&1 &
```

`npm run build` sẽ báo `Found 3 error(s)` và thoát khác 0 — đúng như dự kiến, đó là WIP của session khác. Điều cần kiểm là `dist/main.js` có được xuất ra không (`ls -la dist/main.js`), không phải exit code.

Chờ bằng vòng lặp, đừng đoán theo thời gian:

```bash
until grep -qE "Application is running|Error:|EADDRINUSE|Unable to connect" /tmp/hddhistory-api.log; do sleep 1; done
grep -E "Application is running|no-op" /tmp/hddhistory-api.log
```

Expected: dòng cảnh báo Firebase no-op của Task 1, rồi `Application is running on: 4000`.

- [ ] **Step 7: Xác nhận migration và route**

```bash
docker exec meup_mysql mysql -uroot -plocalroot ai_tutor -e 'SELECT COUNT(*) AS n FROM typeorm_migrations'
curl -s -o /dev/null -w 'skillsets: %{http_code}\n' http://localhost:4000/api/v1/skillsets
curl -s -o /dev/null -w 'kg: %{http_code}\n' http://localhost:4000/api/v1/knowledge-graph/entities
```

Expected: `n = 12`; cả hai route trả `401` (route tồn tại, AuthGuard sống). `404` nghĩa là module chưa wire; `000` nghĩa là API chưa chạy.

- [ ] **Step 8: Commit**

Chỉ commit script và package.json. `.env` nằm trong `.gitignore`, không commit.

```bash
git add scripts/setup-local-mysql.ts package.json
git commit -m "feat: script dựng schema mysql local từ entity, đóng dấu migration"
```

---

### Task 3: User test để đăng nhập được

**Files:**
- Create: `scripts/seed-dev-user.ts`
- Modify: `package.json` (thêm script `seed:dev-user`)

**Interfaces:**
- Consumes: Task 2 (Mongo chạy).
- Produces: user `dev@hddhistory.local` trong Mongo; `POST /api/v1/users/dev-login` dùng được ở Task 12.

- [ ] **Step 1: Xác nhận đường dẫn file enum**

Run: `ls src/modules/user/src/modules/auth/enum/`
Expected: có `user.enum.ts` chứa `UserRole` và `UserStatus`. Nếu tên file khác, sửa đường dẫn import ở Step 2 cho khớp.

Giá trị enum đã được kiểm sẵn: `UserStatus.ACTIVE = 'ACTIVE'`, `UserRole.USER = 'USER'` — **viết hoa**. Import enum thay vì viết chuỗi tay, để đổi enum sau này là lỗi biên dịch chứ không phải lỗi runtime lúc seed.

- [ ] **Step 2: Viết seeder**

Tạo `scripts/seed-dev-user.ts`:

```typescript
/**
 * Tạo một user dev để `POST /api/v1/users/dev-login` có cái mà đăng nhập.
 *
 * `devLogin` tra user theo email và ném NotFoundException nếu không thấy
 * (auth.service.ts:672), nên DB local rỗng thì không có đường nào vào app.
 *
 * Idempotent: đã có thì bỏ qua, không ghi đè — giống các seeder Mongo khác
 * trong thư mục này, để chỉnh sửa tay trên bản ghi không bị mất.
 *
 * Chạy: npm run seed:dev-user
 */
import 'dotenv/config';
import mongoose from 'mongoose';

import {
  UserRole,
  UserStatus,
} from '../src/modules/user/src/modules/auth/enum/user.enum';
import { UserSchema } from '../src/modules/user/src/modules/auth/schema/user.schema';

const EMAIL = 'dev@hddhistory.local';

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');

  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
  const User = mongoose.model('User', UserSchema);

  const existing = await User.findOne({ email: EMAIL });
  if (existing) {
    console.log(`Đã có ${EMAIL} (${existing._id}) — bỏ qua.`);
  } else {
    const created = await User.create({
      email: EMAIL,
      name: 'Dev HDDhistory',
      // Enum VIẾT HOA trong user.enum.ts — 'active'/'user' chữ thường sẽ trượt
      // validation của Mongoose. Đã kiểm tận file enum, đừng đoán theo thói quen.
      status: UserStatus.ACTIVE,
      role: UserRole.USER,
      // `alowNull` trong schema là lỗi chính tả của `allowNull`, mà Mongoose vốn
      // không có option nào tên vậy — nên password không thực sự bắt buộc. Vẫn
      // điền để bản ghi không kỳ dị; dev-login không kiểm password.
      password: 'dev-local-not-a-real-password',
    });
    console.log(`Đã tạo ${EMAIL} (${created._id}).`);
  }

  await mongoose.disconnect();
}

main().catch((e) => {
  console.error('Seed user dev thất bại:', e.message);
  process.exit(1);
});
```

Nếu Step 1 cho thấy schema bắt buộc thêm trường nào (ví dụ `deviceId`, `password`), bổ sung vào `User.create` cho khớp — đừng để Mongoose ném lỗi validation.

- [ ] **Step 3: Thêm lệnh vào package.json**

Trong khối `"scripts"`, thêm sau `"seed:knowledge-graph"`:

```json
    "seed:dev-user": "ts-node scripts/seed-dev-user.ts",
```

- [ ] **Step 4: Chạy seeder**

Run: `npm run seed:dev-user`
Expected: in `Đã tạo dev@hddhistory.local (...)`.

- [ ] **Step 5: Chạy lại để chứng minh idempotent**

Run: `npm run seed:dev-user`
Expected: in `Đã có dev@hddhistory.local (...) — bỏ qua.` với **cùng id** như Step 4.

- [ ] **Step 6: Xác nhận đăng nhập được**

Run:
```bash
curl -s -X POST http://localhost:4000/api/v1/users/dev-login \
  -H 'Content-Type: application/json' \
  -d '{"email":"dev@hddhistory.local","deviceId":"dev-local-001"}'
```
Expected: JSON có `accessToken` và `refreshToken`. Lưu token lại để dùng ở Task 8 và 12.

- [ ] **Step 7: Commit**

```bash
git add scripts/seed-dev-user.ts package.json
git commit -m "feat: seeder user dev để dev-login chạy được trên máy cá nhân"
```

---

### Task 4: Ảnh placeholder theo thời kỳ

**Files:**
- Create: `scripts/generate-placeholder-images.ts`
- Create: `public/history/` (sinh ra lúc chạy, không commit ảnh)
- Modify: `package.json` (thêm `gen:placeholder-images`)
- Modify: `.gitignore` (bỏ qua `public/history/`)

**Interfaces:**
- Consumes: Task 2 (API phục vụ `public/` ở tiền tố `/static/`, xem `src/main.ts:26-27`).
- Produces: 12 file `public/history/<periodId>.svg`, truy cập qua `http://localhost:4000/static/history/<periodId>.svg`. Task 6 và 7 dùng đúng đường dẫn này.

- [ ] **Step 1: Viết script sinh ảnh**

Tạo `scripts/generate-placeholder-images.ts`:

```typescript
/**
 * Sinh ảnh placeholder cho 12 thời kỳ, mỗi thời kỳ một nền màu riêng kèm tên và
 * mốc năm.
 *
 * Sinh cục bộ chứ không gọi dịch vụ placeholder ngoài: mục tiêu của cả đợt này
 * là chạy được khi tắt mạng. Ảnh cố ý trông như placeholder — không giả vờ là
 * ảnh tư liệu thật, để lúc duyệt app không ai nhầm.
 *
 * Chạy: npm run gen:placeholder-images
 */
import * as fs from 'fs';
import * as path from 'path';

const SEED_FILE = path.join(
  process.cwd(),
  'src/modules/knowledge-graph/data/vn_history_seed.json',
);
const OUT_DIR = path.join(process.cwd(), 'public/history');

/** 12 màu tách biệt nhau, đủ tương phản với chữ trắng. */
const COLORS = [
  '#6D4C41', '#455A64', '#5D4037', '#1565C0', '#AD1457', '#4527A0',
  '#00695C', '#EF6C00', '#C62828', '#283593', '#37474F', '#2E7D32',
];

function escapeXml(s: string): string {
  return s.replace(/[<>&'"]/g, (c) =>
    ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c]),
  );
}

function svg(name: string, years: string, color: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="800" height="450" viewBox="0 0 800 450">
  <rect width="800" height="450" fill="${color}"/>
  <text x="400" y="210" text-anchor="middle" fill="#FFFFFF"
        font-family="Helvetica,Arial,sans-serif" font-size="44" font-weight="bold">${escapeXml(name)}</text>
  <text x="400" y="266" text-anchor="middle" fill="#FFFFFFCC"
        font-family="Helvetica,Arial,sans-serif" font-size="26">${escapeXml(years)}</text>
</svg>
`;
}

function main() {
  const seed = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const periods: Array<{ id: string; name: string; start: string; end: string }> =
    seed.periods;

  if (periods.length !== 12) {
    throw new Error(`Chờ 12 thời kỳ, thấy ${periods.length}`);
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });
  periods.forEach((p, i) => {
    const file = path.join(OUT_DIR, `${p.id}.svg`);
    fs.writeFileSync(file, svg(p.name, `${p.start} – ${p.end}`, COLORS[i]), 'utf-8');
    console.log(`Đã ghi ${file}`);
  });
  console.log(`Xong ${periods.length} ảnh.`);
}

main();
```

- [ ] **Step 2: Thêm lệnh vào package.json**

```json
    "gen:placeholder-images": "ts-node scripts/generate-placeholder-images.ts",
```

- [ ] **Step 3: Chạy và xác nhận đủ 12 file**

Run: `npm run gen:placeholder-images && ls public/history | wc -l`
Expected: `12`.

- [ ] **Step 4: Xác nhận API phục vụ được ảnh**

Run: `curl -s -o /dev/null -w '%{http_code} %{content_type}\n' http://localhost:4000/static/history/p04_ly.svg`
Expected: `200 image/svg+xml`.

Nếu `404`: kiểm `src/main.ts:26-27` xem tiền tố `/static/` còn đúng không.

- [ ] **Step 5: Bỏ qua ảnh sinh ra trong git**

Thêm vào `.gitignore`:

```
public/history/
```

Ảnh sinh lại được từ script trong vài giây; commit 12 file SVG chỉ làm nhiễu diff.

- [ ] **Step 6: Commit**

```bash
git add scripts/generate-placeholder-images.ts package.json .gitignore
git commit -m "feat: sinh ảnh placeholder 12 thời kỳ lịch sử, phục vụ qua /static"
```

---

### Task 5: Trỏ app Flutter vào API local

**Files:**
- Create: `/Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter/.env/.env.dev.local`

**Interfaces:**
- Consumes: Task 2 (API ở cổng 4000), Task 3 (đăng nhập được).
- Produces: bản build app nối vào local — Task 12 dùng để kiểm cuối.

- [ ] **Step 1: Tạo file env**

Tạo `.env/.env.dev.local`, chép từ `.env.dev.kglocal` và đổi hai dòng đầu:

```
API_BASE_URL=http://localhost:4000
SOCKET_BASE_URL=ws://localhost:4000
AI_SERVICE_BASE_URL=https://voice-dev.meup.training
API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzQ3Njc0MDAwLCJleHAiOjE5MDU0NDA0MDB9.YacqKUxi1QTKsk7mCzDkAEM-ViLy-r75blGYalGPs2M
CONNECT_TIMEOUT=30000
RECEIVE_TIMEOUT=30000
APP_ENVIRONMENT=dev
```

`SOCKET_BASE_URL` phải đổi theo, nếu không socket vẫn lén ra server dev trong khi REST đã về local.

- [ ] **Step 2: Build và chạy trên simulator**

Run:
```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter && \
/Users/nguyenvietha/development/flutter/bin/flutter run \
  --flavor dev -t lib/main_dev.dart \
  --dart-define-from-file=.env/.env.dev.local \
  -d 786F04EA-41A8-4799-815C-887801F48BDC
```

`flutter` không nằm trên `PATH` ở shell không-login, và cwd reset giữa các lệnh — nên `cd` phải đi cùng lệnh build. Không dùng `--dart-define` rời.

- [ ] **Step 3: Xác nhận app gọi đúng local**

Đọc log API (`/tmp/hddhistory-api.log`) trong lúc app khởi động.
Expected: thấy request từ app tới. Nếu log trống, app vẫn đang trỏ chỗ khác — kiểm lại `--dart-define-from-file` có đúng file không.

- [ ] **Step 4: Commit**

```bash
cd /Users/nguyenvietha/Source/HDDhistory/hddhistory-flutter
git add .env/.env.dev.local
git commit -m "chore: file env trỏ app vào API local cổng 4000"
```

Lưu ý: đây là repo **hddhistory-flutter**, khác repo của các task trước. Kiểm `git branch --show-current` ra `develop` trước khi commit.

---

# Phase 2 — Nội dung lịch sử

### Task 6: Kiểu dữ liệu và validator cho curriculum

**Files:**
- Create: `src/base/seed/curriculum/curriculum.types.ts`
- Create: `src/base/seed/curriculum/curriculum.validator.ts`
- Create: `src/base/seed/curriculum/curriculum.validator.spec.ts`

**Interfaces:**
- Consumes: `src/modules/knowledge-graph/data/vn_history_seed.json` (12 `periods`, 176 `entities`).
- Produces:
  - `interface CurriculumFile { skillsets: CurriculumSkillset[] }`
  - `interface CurriculumSkillset { periodId: string; courses: CurriculumCourse[] }`
  - `interface CurriculumCourse { titleVi: string; descriptionVi: string; lessons: CurriculumLesson[] }`
  - `interface CurriculumLesson { titleVi: string; descriptionVi: string; keypoints: CurriculumKeypoint[] }`
  - `interface CurriculumKeypoint { titleVi: string; descriptionVi: string; entityIds?: string[] }`
  - `validateCurriculum(file: unknown, seed: SeedRef): string[]` — trả danh sách lỗi, rỗng nghĩa là hợp lệ.
  - `interface SeedRef { periodIds: Set<string>; entityIds: Set<string> }`

  Task 7 và 8 dùng đúng các tên này.

- [ ] **Step 1: Viết test thất bại**

Tạo `src/base/seed/curriculum/curriculum.validator.spec.ts`:

```typescript
import { validateCurriculum, SeedRef } from './curriculum.validator';
import { CurriculumFile } from './curriculum.types';

const SEED: SeedRef = {
  periodIds: new Set(['p04_ly', 'p05_tran']),
  entityIds: new Set(['ly_thuong_kiet', 'tran_hung_dao']),
};

function keypoint(i: number) {
  return {
    titleVi: `Ý chính ${i}`,
    descriptionVi: 'x'.repeat(120),
    entityIds: ['ly_thuong_kiet'],
  };
}

function lesson(i: number) {
  return {
    titleVi: `Bài ${i}`,
    descriptionVi: 'Mô tả bài học đủ dài để qua kiểm tra.',
    keypoints: [keypoint(1), keypoint(2), keypoint(3)],
  };
}

function valid(): CurriculumFile {
  return {
    skillsets: [
      {
        periodId: 'p04_ly',
        courses: [
          {
            titleVi: 'Dời đô về Thăng Long',
            descriptionVi: 'Mô tả khoá học đủ dài để qua kiểm tra.',
            lessons: [lesson(1), lesson(2), lesson(3), lesson(4), lesson(5)],
          },
        ],
      },
    ],
  };
}

describe('validateCurriculum', () => {
  it('không báo lỗi với dữ liệu hợp lệ', () => {
    expect(validateCurriculum(valid(), SEED)).toEqual([]);
  });

  it('bắt periodId không có trong vn_history_seed.json', () => {
    const f = valid();
    f.skillsets[0].periodId = 'p99_khong_co';
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('p99_khong_co');
    expect(errors[0]).toContain('skillsets[0]');
  });

  it('bắt entityId không có trong seed', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[0].entityIds = ['nguoi_bia'];
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('nguoi_bia');
  });

  it('bắt title rỗng và nêu đúng đường dẫn tới chỗ hỏng', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[1].titleVi = '   ';
    const errors = validateCurriculum(f, SEED);
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('skillsets[0].courses[0].lessons[0].keypoints[1]');
  });

  it('bắt bài học có ít hơn 3 keypoint', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints = [keypoint(1)];
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('keypoint'))).toBe(true);
  });

  it('bắt keypoint quá ngắn — dấu hiệu nội dung bỏ dở', () => {
    const f = valid();
    f.skillsets[0].courses[0].lessons[0].keypoints[0].descriptionVi = 'Ngắn quá.';
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('ngắn'))).toBe(true);
  });

  it('bắt hai khoá trùng tên trong cùng một thời kỳ', () => {
    const f = valid();
    f.skillsets[0].courses.push({ ...f.skillsets[0].courses[0] });
    const errors = validateCurriculum(f, SEED);
    expect(errors.some((e) => e.includes('trùng'))).toBe(true);
  });

  it('gom mọi lỗi chứ không dừng ở lỗi đầu tiên', () => {
    const f = valid();
    f.skillsets[0].periodId = 'p99_khong_co';
    f.skillsets[0].courses[0].titleVi = '';
    expect(validateCurriculum(f, SEED).length).toBeGreaterThanOrEqual(2);
  });
});
```

- [ ] **Step 2: Chạy test, xác nhận thất bại**

Run: `npm test -- src/base/seed/curriculum/curriculum.validator.spec.ts`
Expected: FAIL — `Cannot find module './curriculum.validator'`.

- [ ] **Step 3: Viết types**

Tạo `src/base/seed/curriculum/curriculum.types.ts`:

```typescript
/**
 * Cây nội dung dùng để seed: Skillset → Course → Lesson → Keypoint.
 *
 * Chỉ mang tiếng Việt (`...Vi`). Builder mới là chỗ bọc thành `ITranslation`
 * của app — tách vậy để file nội dung người biên tập đọc/sửa gọn hơn.
 */

export interface CurriculumKeypoint {
  titleVi: string;
  descriptionVi: string;
  /** id thực thể trong vn_history_seed.json, dùng để đối chiếu, không bắt buộc. */
  entityIds?: string[];
}

export interface CurriculumLesson {
  titleVi: string;
  descriptionVi: string;
  keypoints: CurriculumKeypoint[];
}

export interface CurriculumCourse {
  titleVi: string;
  descriptionVi: string;
  lessons: CurriculumLesson[];
}

export interface CurriculumSkillset {
  /** khớp `periods[].id` trong vn_history_seed.json */
  periodId: string;
  courses: CurriculumCourse[];
}

export interface CurriculumFile {
  skillsets: CurriculumSkillset[];
}
```

- [ ] **Step 4: Viết validator**

Tạo `src/base/seed/curriculum/curriculum.validator.ts`:

```typescript
import {
  CurriculumCourse,
  CurriculumFile,
  CurriculumLesson,
} from './curriculum.types';

export interface SeedRef {
  periodIds: Set<string>;
  entityIds: Set<string>;
}

/** Ngưỡng bắt nội dung bỏ dở, không phải chuẩn văn phong. */
const MIN_KEYPOINT_CHARS = 80;
const MIN_KEYPOINTS_PER_LESSON = 3;
const MAX_KEYPOINTS_PER_LESSON = 4;

function blank(s: unknown): boolean {
  return typeof s !== 'string' || s.trim() === '';
}

/**
 * Gom *mọi* lỗi rồi mới trả về, cố ý không dừng ở lỗi đầu. Với ~560 keypoint,
 * sửa từng lỗi một rồi chạy lại là không dùng được.
 */
export function validateCurriculum(file: unknown, seed: SeedRef): string[] {
  const errors: string[] = [];
  const f = file as CurriculumFile;

  if (!f || !Array.isArray(f.skillsets)) {
    return ['File curriculum phải có mảng `skillsets`.'];
  }

  f.skillsets.forEach((s, si) => {
    const at = `skillsets[${si}]`;

    if (!seed.periodIds.has(s.periodId)) {
      errors.push(`${at}: periodId "${s.periodId}" không có trong vn_history_seed.json`);
    }
    if (!Array.isArray(s.courses) || s.courses.length === 0) {
      errors.push(`${at}: thời kỳ không có khoá nào`);
      return;
    }

    const courseTitles = new Set<string>();
    s.courses.forEach((c, ci) => {
      validateCourse(c, `${at}.courses[${ci}]`, seed, errors);
      const key = (c.titleVi || '').trim();
      if (key && courseTitles.has(key)) {
        errors.push(`${at}.courses[${ci}]: tên khoá "${key}" bị trùng trong cùng thời kỳ`);
      }
      courseTitles.add(key);
    });
  });

  return errors;
}

function validateCourse(
  c: CurriculumCourse,
  at: string,
  seed: SeedRef,
  errors: string[],
): void {
  if (blank(c.titleVi)) errors.push(`${at}: thiếu titleVi`);
  if (blank(c.descriptionVi)) errors.push(`${at}: thiếu descriptionVi`);

  if (!Array.isArray(c.lessons) || c.lessons.length === 0) {
    errors.push(`${at}: khoá không có bài nào`);
    return;
  }
  c.lessons.forEach((l, li) => validateLesson(l, `${at}.lessons[${li}]`, seed, errors));
}

function validateLesson(
  l: CurriculumLesson,
  at: string,
  seed: SeedRef,
  errors: string[],
): void {
  if (blank(l.titleVi)) errors.push(`${at}: thiếu titleVi`);
  if (blank(l.descriptionVi)) errors.push(`${at}: thiếu descriptionVi`);

  if (!Array.isArray(l.keypoints)) {
    errors.push(`${at}: thiếu mảng keypoints`);
    return;
  }
  if (
    l.keypoints.length < MIN_KEYPOINTS_PER_LESSON ||
    l.keypoints.length > MAX_KEYPOINTS_PER_LESSON
  ) {
    errors.push(
      `${at}: có ${l.keypoints.length} keypoint, phải trong khoảng ` +
        `${MIN_KEYPOINTS_PER_LESSON}–${MAX_KEYPOINTS_PER_LESSON}`,
    );
  }

  l.keypoints.forEach((k, ki) => {
    const kat = `${at}.keypoints[${ki}]`;
    if (blank(k.titleVi)) errors.push(`${kat}: thiếu titleVi`);
    if (blank(k.descriptionVi)) {
      errors.push(`${kat}: thiếu descriptionVi`);
    } else if (k.descriptionVi.trim().length < MIN_KEYPOINT_CHARS) {
      errors.push(
        `${kat}: nội dung ngắn (${k.descriptionVi.trim().length} ký tự, ` +
          `tối thiểu ${MIN_KEYPOINT_CHARS}) — có vẻ bỏ dở`,
      );
    }
    (k.entityIds ?? []).forEach((id) => {
      if (!seed.entityIds.has(id)) {
        errors.push(`${kat}: entityId "${id}" không có trong vn_history_seed.json`);
      }
    });
  });
}
```

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `npm test -- src/base/seed/curriculum/curriculum.validator.spec.ts`
Expected: PASS, 8 test.

- [ ] **Step 6: Build strict**

Run:
```bash
npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
  | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
```
Expected: in ra đúng một dòng — `src/.../community-bot-queue.repository.ts` (lỗi có sẵn của session khác). Bất kỳ file nào khác xuất hiện là do task này gây ra.

- [ ] **Step 7: Commit**

```bash
git add src/base/seed/curriculum/curriculum.types.ts src/base/seed/curriculum/curriculum.validator.ts src/base/seed/curriculum/curriculum.validator.spec.ts
git commit -m "feat: kiểu dữ liệu và validator cho cây nội dung lịch sử"
```

---

### Task 7: Builder thuần — curriculum thành document Mongo

**Files:**
- Create: `src/base/seed/curriculum/curriculum.builder.ts`
- Create: `src/base/seed/curriculum/curriculum.builder.spec.ts`

**Interfaces:**
- Consumes: `CurriculumFile` từ Task 6.
- Produces: `buildSeedPlan(file: CurriculumFile, periods: PeriodRef[]): SeedPlan` với
  - `interface PeriodRef { id: string; name: string; start: string; end: string }`
  - `interface SeedPlan { skillsets: SkillsetDoc[]; courses: CourseDoc[]; lessons: LessonDoc[]; keypoints: KeypointDoc[] }`
  - Mỗi doc mang `_localKey` để Task 8 khớp bản ghi đã có mà không cần ObjectId.

  Task 8 dùng đúng các tên này.

- [ ] **Step 1: Viết test thất bại**

Tạo `src/base/seed/curriculum/curriculum.builder.spec.ts`:

```typescript
import { buildSeedPlan, PeriodRef } from './curriculum.builder';
import { CurriculumFile } from './curriculum.types';

const PERIODS: PeriodRef[] = [
  { id: 'p04_ly', name: 'Nhà Lý', start: '1009', end: '1225' },
  { id: 'p05_tran', name: 'Nhà Trần', start: '1225', end: '1400' },
];

const FILE: CurriculumFile = {
  skillsets: [
    {
      periodId: 'p05_tran',
      courses: [
        {
          titleVi: 'Ba lần chống Mông–Nguyên',
          descriptionVi: 'Mô tả khoá.',
          lessons: [
            {
              titleVi: 'Lần thứ nhất, 1258',
              descriptionVi: 'Mô tả bài.',
              keypoints: [
                { titleVi: 'Đông Bộ Đầu', descriptionVi: 'x'.repeat(100) },
                { titleVi: 'Rút khỏi Thăng Long', descriptionVi: 'y'.repeat(100) },
                { titleVi: 'Kết cục', descriptionVi: 'z'.repeat(100) },
              ],
            },
          ],
        },
      ],
    },
    {
      periodId: 'p04_ly',
      courses: [
        {
          titleVi: 'Dời đô về Thăng Long',
          descriptionVi: 'Mô tả khoá.',
          lessons: [
            {
              titleVi: 'Chiếu dời đô',
              descriptionVi: 'Mô tả bài.',
              keypoints: [
                { titleVi: 'Lý do dời đô', descriptionVi: 'a'.repeat(100) },
                { titleVi: 'Đại La', descriptionVi: 'b'.repeat(100) },
                { titleVi: 'Hệ quả', descriptionVi: 'c'.repeat(100) },
              ],
            },
          ],
        },
      ],
    },
  ],
};

describe('buildSeedPlan', () => {
  it('xếp skillset theo thứ tự thời gian của periods, không theo thứ tự trong file', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.skillsets.map((s) => s.title.vi)).toEqual(['Nhà Lý', 'Nhà Trần']);
    expect(plan.skillsets.map((s) => s.index)).toEqual([0, 1]);
  });

  it('đặt tên skillset và mô tả từ periods, kèm mốc năm', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    const ly = plan.skillsets.find((s) => s.title.vi === 'Nhà Lý');
    expect(ly.description.vi).toContain('1009');
    expect(ly.description.vi).toContain('1225');
  });

  it('chỉ điền locale vi, không bịa các locale khác', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(Object.keys(plan.skillsets[0].title)).toEqual(['vi']);
    expect(Object.keys(plan.keypoints[0].title)).toEqual(['vi']);
  });

  it('gán ảnh placeholder theo thời kỳ cho mọi node', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.skillsets[0].image).toBe('/static/history/p04_ly.svg');
    plan.courses.forEach((c) => expect(c.image).toMatch(/^\/static\/history\/p\d{2}_/));
    plan.lessons.forEach((l) => expect(l.image).toMatch(/^\/static\/history\/p\d{2}_/));
    plan.keypoints.forEach((k) => expect(k.image).toMatch(/^\/static\/history\/p\d{2}_/));
  });

  it('nối course về đúng skillset và lesson về đúng course qua _localKey', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    const course = plan.courses.find((c) => c.title.vi === 'Dời đô về Thăng Long');
    expect(course.skillsetLocalKey).toBe('p04_ly');
    const lesson = plan.lessons.find((l) => l.title.vi === 'Chiếu dời đô');
    expect(lesson.courseLocalKey).toBe(course._localKey);
  });

  it('gắn tag phân biệt cho keypoint, đủ để khớp idempotent dù trùng tên', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    plan.keypoints.forEach((k) => {
      expect(k.tag).toContain('vn-history');
      expect(k.tag).toContain(k._localKey);
    });
    const keys = plan.keypoints.map((k) => k._localKey);
    expect(new Set(keys).size).toBe(keys.length);
  });

  it('phân biệt được hai keypoint trùng tên ở hai bài khác nhau', () => {
    const dup: CurriculumFile = {
      skillsets: [
        {
          periodId: 'p04_ly',
          courses: [
            {
              titleVi: 'Khoá A',
              descriptionVi: 'Mô tả.',
              lessons: [
                {
                  titleVi: 'Bài 1',
                  descriptionVi: 'Mô tả.',
                  keypoints: [
                    { titleVi: 'Hệ quả', descriptionVi: 'a'.repeat(100) },
                    { titleVi: 'Bối cảnh', descriptionVi: 'b'.repeat(100) },
                    { titleVi: 'Diễn biến', descriptionVi: 'c'.repeat(100) },
                  ],
                },
                {
                  titleVi: 'Bài 2',
                  descriptionVi: 'Mô tả.',
                  keypoints: [
                    { titleVi: 'Hệ quả', descriptionVi: 'd'.repeat(100) },
                    { titleVi: 'Bối cảnh', descriptionVi: 'e'.repeat(100) },
                    { titleVi: 'Diễn biến', descriptionVi: 'f'.repeat(100) },
                  ],
                },
              ],
            },
          ],
        },
      ],
    };
    const plan = buildSeedPlan(dup, PERIODS);
    const keys = plan.keypoints.map((k) => k._localKey);
    expect(keys).toHaveLength(6);
    expect(new Set(keys).size).toBe(6);
  });

  it('đặt numberOfLesson đúng số bài của khoá', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    plan.courses.forEach((c) => {
      const n = plan.lessons.filter((l) => l.courseLocalKey === c._localKey).length;
      expect(c.numberOfLesson).toBe(n);
    });
  });

  it('đánh index liên tục từ 0 cho lesson trong khoá và keypoint trong bài', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.lessons.every((l) => l.index === 0)).toBe(true);
    const kps = plan.keypoints.filter((k) => k.lessonLocalKey === plan.lessons[0]._localKey);
    expect(kps.map((k) => k.index)).toEqual([0, 1, 2]);
  });

  it('dùng status published để app thấy được ngay', () => {
    const plan = buildSeedPlan(FILE, PERIODS);
    expect(plan.skillsets[0].status).toBe('published');
    expect(plan.courses[0].status).toBe('published');
    expect(plan.lessons[0].status).toBe('published');
  });

  it('ném lỗi khi periodId không có trong periods thay vì sinh ảnh sai', () => {
    const bad: CurriculumFile = {
      skillsets: [{ periodId: 'p99_khong_co', courses: [] }],
    };
    expect(() => buildSeedPlan(bad, PERIODS)).toThrow('p99_khong_co');
  });
});
```

- [ ] **Step 2: Chạy test, xác nhận thất bại**

Run: `npm test -- src/base/seed/curriculum/curriculum.builder.spec.ts`
Expected: FAIL — `Cannot find module './curriculum.builder'`.

- [ ] **Step 3: Viết builder**

Tạo `src/base/seed/curriculum/curriculum.builder.ts`:

```typescript
import { CurriculumFile } from './curriculum.types';

export interface PeriodRef {
  id: string;
  name: string;
  start: string;
  end: string;
}

/** Chỉ tiếng Việt — quyết định của spec, các locale khác cố ý bỏ trống. */
interface ViOnly {
  vi: string;
}

export interface SkillsetDoc {
  _localKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
}

export interface CourseDoc {
  _localKey: string;
  skillsetLocalKey: string;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
  numberOfLesson: number;
}

export interface LessonDoc {
  _localKey: string;
  courseLocalKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  status: string;
  image: string;
}

export interface KeypointDoc {
  _localKey: string;
  lessonLocalKey: string;
  index: number;
  title: ViOnly;
  description: ViOnly;
  image: string;
  /**
   * Keypoint là collection phẳng — schema không có lessonId hay courseId. Nên
   * khớp idempotent theo (title, index) sẽ gộp nhầm hai keypoint cùng tên ở hai
   * bài khác nhau, mà "Hệ quả" hay "Bối cảnh" thì chắc chắn lặp lại trong 560
   * keypoint. `tag` là trường duy nhất có sẵn để mang khoá phân biệt, nên
   * `_localKey` (đã đủ điều kiện: thời kỳ::khoá::bài::keypoint) đi vào đây.
   */
  tag: string[];
}

export interface SeedPlan {
  skillsets: SkillsetDoc[];
  courses: CourseDoc[];
  lessons: LessonDoc[];
  keypoints: KeypointDoc[];
}

function imageFor(periodId: string): string {
  return `/static/history/${periodId}.svg`;
}

/**
 * Thuần: cùng đầu vào cho cùng đầu ra, không đụng Mongo và không sinh ObjectId.
 * Quan hệ cha–con đi qua `_localKey` để Task 8 tự quyết id khi ghi, và để test
 * được mà không cần database.
 *
 * Thứ tự skillset bám `periods` chứ không bám thứ tự trong file nội dung: người
 * biên tập thêm thời kỳ theo lô nào cũng được, trục thời gian trong app vẫn đúng.
 */
export function buildSeedPlan(
  file: CurriculumFile,
  periods: PeriodRef[],
): SeedPlan {
  const byId = new Map(periods.map((p) => [p.id, p]));
  const order = new Map(periods.map((p, i) => [p.id, i]));

  const plan: SeedPlan = { skillsets: [], courses: [], lessons: [], keypoints: [] };

  const sorted = [...file.skillsets].sort(
    (a, b) => (order.get(a.periodId) ?? 0) - (order.get(b.periodId) ?? 0),
  );

  sorted.forEach((s) => {
    const period = byId.get(s.periodId);
    if (!period) {
      throw new Error(
        `periodId "${s.periodId}" không có trong vn_history_seed.json`,
      );
    }

    const image = imageFor(period.id);
    plan.skillsets.push({
      _localKey: period.id,
      index: order.get(period.id),
      title: { vi: period.name },
      description: { vi: `${period.name} (${period.start} – ${period.end})` },
      status: 'published',
      image,
    });

    s.courses.forEach((c) => {
      const courseKey = `${period.id}::${c.titleVi}`;
      plan.courses.push({
        _localKey: courseKey,
        skillsetLocalKey: period.id,
        title: { vi: c.titleVi },
        description: { vi: c.descriptionVi },
        status: 'published',
        image,
        numberOfLesson: c.lessons.length,
      });

      c.lessons.forEach((l, li) => {
        const lessonKey = `${courseKey}::${l.titleVi}`;
        plan.lessons.push({
          _localKey: lessonKey,
          courseLocalKey: courseKey,
          index: li,
          title: { vi: l.titleVi },
          description: { vi: l.descriptionVi },
          status: 'published',
          image,
        });

        l.keypoints.forEach((k, ki) => {
          const keypointKey = `${lessonKey}::${k.titleVi}`;
          plan.keypoints.push({
            _localKey: keypointKey,
            lessonLocalKey: lessonKey,
            index: ki,
            title: { vi: k.titleVi },
            description: { vi: k.descriptionVi },
            image,
            tag: ['vn-history', keypointKey],
          });
        });
      });
    });
  });

  return plan;
}
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `npm test -- src/base/seed/curriculum/curriculum.builder.spec.ts`
Expected: PASS, 11 test.

- [ ] **Step 5: Build strict**

Run:
```bash
npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
  | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
```
Expected: in ra đúng một dòng — `src/.../community-bot-queue.repository.ts` (lỗi có sẵn của session khác). Bất kỳ file nào khác xuất hiện là do task này gây ra.

- [ ] **Step 6: Commit**

```bash
git add src/base/seed/curriculum/curriculum.builder.ts src/base/seed/curriculum/curriculum.builder.spec.ts
git commit -m "feat: builder thuần dựng cây skillset/course/lesson/keypoint từ curriculum"
```

---

### Task 8: Script seed ghi vào Mongo

**Files:**
- Create: `scripts/seed-vn-history.ts`
- Create: `scripts/data/vn-history-curriculum.json` (khung 12 thời kỳ, nội dung đổ ở Task 9–12)
- Modify: `package.json` (thêm `seed:vn-history`)

**Interfaces:**
- Consumes: `validateCurriculum`, `SeedRef` (Task 6); `buildSeedPlan`, `SeedPlan` (Task 7).
- Produces: dữ liệu trong Mongo; `npm run seed:vn-history` và cờ `--dry-run`.

- [ ] **Step 1: Tạo file curriculum khung**

Tạo `scripts/data/vn-history-curriculum.json` với **một** thời kỳ đã đủ nội dung để chạy thử đường ống. Dùng `p04_ly`, một khoá, một bài, ba keypoint — nội dung thật, không phải chữ giả:

```json
{
  "skillsets": [
    {
      "periodId": "p04_ly",
      "courses": [
        {
          "titleVi": "Dời đô về Thăng Long",
          "descriptionVi": "Vì sao nhà Lý rời bỏ Hoa Lư, và quyết định ấy định hình trung tâm chính trị Việt Nam suốt nghìn năm sau như thế nào.",
          "lessons": [
            {
              "titleVi": "Chiếu dời đô năm 1010",
              "descriptionVi": "Lý do, lập luận và hệ quả của việc dời đô từ Hoa Lư ra Đại La.",
              "keypoints": [
                {
                  "titleVi": "Hoa Lư đã hết vai trò",
                  "descriptionVi": "Hoa Lư được Đinh Bộ Lĩnh chọn làm kinh đô vì địa thế núi non hiểm trở, hợp với một triều đình vừa dựng nước còn phải lo phòng thủ. Đến đầu thế kỷ XI, khi chính quyền đã ổn định, chính cái thế hiểm ấy trở thành trở ngại: lòng chảo chật hẹp, đường thuỷ bộ khó mở, không đủ chỗ cho một kinh đô cần giao thương và quản lý vùng đồng bằng rộng lớn.",
                  "entityIds": ["hoa_lu"]
                },
                {
                  "titleVi": "Lập luận trong Chiếu dời đô",
                  "descriptionVi": "Năm 1010, Lý Thái Tổ ban Chiếu dời đô, nêu rõ Đại La ở vào nơi trung tâm trời đất, thế rồng cuộn hổ ngồi, đất rộng mà bằng phẳng, dân cư không khổ vì ngập lụt, muôn vật phong phú tốt tươi. Văn bản lập luận bằng địa lợi và sinh kế của dân chứ không chỉ bằng điềm trời, và đó là điểm khiến giới sử học xem nó như một quyết định hành chính có cân nhắc.",
                  "entityIds": ["ly_thai_to", "chieu_doi_do"]
                },
                {
                  "titleVi": "Từ Đại La thành Thăng Long",
                  "descriptionVi": "Sau khi dời đến, thành Đại La được đổi tên là Thăng Long. Việc chuyển trung tâm quyền lực ra giữa đồng bằng sông Hồng đặt nền cho một đô thị vừa là trung tâm hành chính vừa là đầu mối giao thương, và trừ vài giai đoạn gián đoạn, vùng đất này giữ vai trò kinh đô hoặc thủ đô liên tục cho tới ngày nay.",
                  "entityIds": ["thang_long"]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

**Trước khi ghi file, kiểm các `entityIds` có thật:**

```bash
python3 -c "
import json
d=json.load(open('src/modules/knowledge-graph/data/vn_history_seed.json'))
ids={e['id'] for e in d['entities']}
for x in ['hoa_lu','ly_thai_to','chieu_doi_do','thang_long']:
    print(x, x in ids)
"
```

Cái nào in `False` thì bỏ khỏi `entityIds` hoặc thay bằng id đúng — `entityIds` là tuỳ chọn, thà bỏ trống còn hơn trỏ sai.

- [ ] **Step 2: Viết script seed**

Tạo `scripts/seed-vn-history.ts`:

```typescript
/**
 * Đổ cây nội dung lịch sử Việt Nam vào Mongo: Skillset → Course → Lesson →
 * Keypoint.
 *
 * Idempotent theo kiểu *chèn-nếu-thiếu*, cố ý KHÔNG ghi đè bản ghi đã có —
 * giống các seeder Mongo khác trong thư mục này, để chỉnh sửa của admin không
 * bị một lần chạy seed xoá mất. Muốn nội dung mới thắng thì xoá bản ghi cũ rồi
 * chạy lại.
 *
 * Chạy:
 *   npm run seed:vn-history
 *   npm run seed:vn-history -- --dry-run    (chỉ validate và in thống kê)
 *
 * Đọc MONGODB_URI từ env/.env
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import mongoose from 'mongoose';

import { buildSeedPlan, PeriodRef } from '../src/base/seed/curriculum/curriculum.builder';
import { validateCurriculum, SeedRef } from '../src/base/seed/curriculum/curriculum.validator';

import { CourseSchema } from '../src/modules/courses/src/modules/course/schema/course.schema';
import { KeypointSchema } from '../src/modules/courses/src/modules/keypoint/schema/keypoint.schema';
import { LessonSchema } from '../src/modules/courses/src/modules/lesson/schema/lesson.schema';
import { SkillsetSchema } from '../src/modules/courses/src/modules/skillset/schema/skillset.schema';

const CURRICULUM_FILE = path.join(process.cwd(), 'scripts/data/vn-history-curriculum.json');
const SEED_FILE = path.join(
  process.cwd(),
  'src/modules/knowledge-graph/data/vn_history_seed.json',
);

async function main() {
  const dryRun = process.argv.includes('--dry-run');

  const seedRaw = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const periods: PeriodRef[] = seedRaw.periods;
  const ref: SeedRef = {
    periodIds: new Set(periods.map((p) => p.id)),
    entityIds: new Set(seedRaw.entities.map((e: { id: string }) => e.id)),
  };

  const curriculum = JSON.parse(fs.readFileSync(CURRICULUM_FILE, 'utf-8'));

  const errors = validateCurriculum(curriculum, ref);
  if (errors.length) {
    console.error(`Curriculum có ${errors.length} lỗi:`);
    errors.forEach((e) => console.error(`  - ${e}`));
    process.exit(1);
  }

  const plan = buildSeedPlan(curriculum, periods);
  console.log(
    `Dự kiến: ${plan.skillsets.length} skillset, ${plan.courses.length} khoá, ` +
      `${plan.lessons.length} bài, ${plan.keypoints.length} keypoint.`,
  );

  if (dryRun) {
    console.log('--dry-run: không ghi gì vào Mongo.');
    return;
  }

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');

  // Chờ tối đa 5 giây rồi báo lỗi, thay vì treo vô hạn khi quên bật Docker.
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });

  const Skillset = mongoose.model('Skillset', SkillsetSchema);
  const Course = mongoose.model('Course', CourseSchema);
  const Lesson = mongoose.model('Lesson', LessonSchema);
  const Keypoint = mongoose.model('Keypoint', KeypointSchema);

  const skillsetIds = new Map<string, string>();
  let created = 0;
  let skipped = 0;

  for (const s of plan.skillsets) {
    const found = await Skillset.findOne({ 'title.vi': s.title.vi });
    if (found) {
      skillsetIds.set(s._localKey, String(found._id));
      skipped++;
      continue;
    }
    const doc = await Skillset.create({
      index: s.index,
      title: s.title,
      description: s.description,
      status: s.status,
      image: s.image,
    });
    skillsetIds.set(s._localKey, String(doc._id));
    created++;
  }

  const courseIds = new Map<string, string>();
  for (const c of plan.courses) {
    const skillsetId = skillsetIds.get(c.skillsetLocalKey);
    const found = await Course.findOne({ 'title.vi': c.title.vi, skillsetId });
    if (found) {
      courseIds.set(c._localKey, String(found._id));
      skipped++;
      continue;
    }
    const doc = await Course.create({
      title: c.title,
      description: c.description,
      status: c.status,
      image: c.image,
      skillsetId,
      numberOfLesson: c.numberOfLesson,
    });
    courseIds.set(c._localKey, String(doc._id));
    created++;
  }

  // Keypoint được tạo trước lesson: Lesson.keypoints là mảng id (lesson.schema.ts),
  // nên phải có id keypoint rồi mới ghi được lesson.
  const keypointIdsByLesson = new Map<string, string[]>();
  for (const k of plan.keypoints) {
    // Khớp theo tag chứ không theo (title, index): collection keypoint phẳng,
    // không có lessonId, nên hai bài cùng có keypoint tên "Hệ quả" ở vị trí 0
    // sẽ bị gộp làm một nếu khớp bằng tiêu đề.
    const found = await Keypoint.findOne({ tag: k._localKey });
    let id: string;
    if (found) {
      id = String(found._id);
      skipped++;
    } else {
      const doc = await Keypoint.create({
        title: k.title,
        description: k.description,
        image: k.image,
        index: k.index,
        tag: k.tag,
      });
      id = String(doc._id);
      created++;
    }
    const list = keypointIdsByLesson.get(k.lessonLocalKey) ?? [];
    list.push(id);
    keypointIdsByLesson.set(k.lessonLocalKey, list);
  }

  for (const l of plan.lessons) {
    const courseId = courseIds.get(l.courseLocalKey);
    const found = await Lesson.findOne({ 'title.vi': l.title.vi, courseId });
    if (found) {
      skipped++;
      continue;
    }
    await Lesson.create({
      courseId,
      title: l.title,
      description: l.description,
      status: l.status,
      image: l.image,
      index: l.index,
      keypoints: keypointIdsByLesson.get(l._localKey) ?? [],
    });
    created++;
  }

  console.log(`Xong. Tạo mới ${created}, bỏ qua vì đã có ${skipped}.`);
  await mongoose.disconnect();
}

main().catch((e) => {
  console.error('Seed nội dung lịch sử thất bại:', e.message);
  process.exit(1);
});
```

- [ ] **Step 3: Thêm lệnh vào package.json**

```json
    "seed:vn-history": "ts-node scripts/seed-vn-history.ts",
```

- [ ] **Step 4: Chạy dry-run trước**

Run: `npm run seed:vn-history -- --dry-run`
Expected: `Dự kiến: 1 skillset, 1 khoá, 1 bài, 3 keypoint.` và không ghi gì.

- [ ] **Step 5: Kiểm hành vi khi Mongo chưa bật (Review Focus #4)**

Run:
```bash
docker stop meup_mongo
npm run seed:vn-history; echo "exit=$?"
docker start meup_mongo
```
Expected: báo lỗi kết nối rõ ràng trong vòng ~5 giây và `exit=1`. Không treo.

Chờ vài giây cho Mongo sẵn sàng lại trước khi sang Step 6.

- [ ] **Step 6: Chạy thật**

Run: `npm run seed:vn-history`
Expected: `Xong. Tạo mới 6, bỏ qua vì đã có 0.` (1 skillset + 1 khoá + 3 keypoint + 1 bài).

- [ ] **Step 7: Chạy lại để chứng minh idempotent (Review Focus #1)**

Run: `npm run seed:vn-history`
Expected: `Tạo mới 0, bỏ qua vì đã có 6.`

Rồi đếm trong Mongo để chắc không nhân bản:

```bash
docker exec meup_mongo mongosh -u admin -p PGmnyFWTr9XyAvDX --authenticationDatabase admin hddhistory-api --quiet --eval '
  ["skillsets","courses","lessons","keypoints"].forEach(c =>
    print(c + ": " + db.getCollection(c).countDocuments()))'
```
Expected: `skillsets: 1, courses: 1, lessons: 1, keypoints: 3`.

Nếu tên collection khác (Mongoose số nhiều hoá tự động), lấy tên thật bằng `db.getCollectionNames()`.

- [ ] **Step 8: Chứng minh không ghi đè chỉnh sửa admin (Review Focus #1)**

```bash
docker exec meup_mongo mongosh -u admin -p PGmnyFWTr9XyAvDX --authenticationDatabase admin hddhistory-api --quiet --eval '
  db.skillsets.updateOne({}, {$set: {"description.vi": "ADMIN SỬA TAY"}})'
npm run seed:vn-history
docker exec meup_mongo mongosh -u admin -p PGmnyFWTr9XyAvDX --authenticationDatabase admin hddhistory-api --quiet --eval '
  print(db.skillsets.findOne().description.vi)'
```
Expected: vẫn in `ADMIN SỬA TAY`. Nếu bị ghi đè là seeder sai hợp đồng — sửa trước khi đi tiếp.

- [ ] **Step 9: Build strict và commit**

Run:
```bash
npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
  | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
```
Expected: in ra đúng một dòng — `src/.../community-bot-queue.repository.ts` (lỗi có sẵn của session khác). Bất kỳ file nào khác xuất hiện là do task này gây ra.

```bash
git add scripts/seed-vn-history.ts scripts/data/vn-history-curriculum.json package.json
git commit -m "feat: seeder nội dung lịch sử vào mongo, chèn-nếu-thiếu không ghi đè"
```

---

### Task 9–12: Biên soạn nội dung 12 thời kỳ

Bốn task cùng một hình dạng, khác nhau ở thời kỳ phụ trách. Làm theo lô để hỏng thì hỏng một lô chứ không hỏng cả mẻ.

| Task | Thời kỳ | Khoá |
|---|---|---|
| 9  | `p01_hongbang`, `p02_bacthuoc`, `p03_ngo_dinh_tienle` | 2 + 3 + 3 = 8 |
| 10 | `p04_ly`, `p05_tran`, `p06_ho_thuocminh_lamson` | 3 + 3 + 3 = 9 (khoá "Dời đô về Thăng Long" đã có từ Task 8, mở rộng thêm bài) |
| 11 | `p07_leso`, `p08_trinhnguyen`, `p09_tayson` | 2 + 3 + 2 = 7 |
| 12 | `p10_nguyen`, `p11_phapthuoc`, `p12_hiendai` | 2 + 3 + 3 = 8 |

Tổng: 32 khoá, mỗi khoá 5 bài, mỗi bài 3–4 keypoint → ~160 bài, ~560 keypoint.

Tên 32 khoá, chốt ở spec — chép lại đây để không phải tra chéo:

| periodId | Khoá |
|---|---|
| `p01_hongbang` | Truyền thuyết dựng nước · Âu Lạc và An Dương Vương |
| `p02_bacthuoc` | Ách đô hộ phương Bắc · Hai Bà Trưng và Bà Triệu · Từ Lý Bí đến Ngô Quyền |
| `p03_ngo_dinh_tienle` | Buổi đầu tự chủ · Đinh Bộ Lĩnh thống nhất · Lê Hoàn chống Tống |
| `p04_ly` | Dời đô về Thăng Long · Lý Thường Kiệt chống Tống · Văn hoá và Phật giáo thời Lý |
| `p05_tran` | Nhà Trần thay nhà Lý · Ba lần chống Mông–Nguyên · Trúc Lâm và chữ Nôm |
| `p06_ho_thuocminh_lamson` | Hồ Quý Ly và cải cách · Hai mươi năm thuộc Minh · Khởi nghĩa Lam Sơn |
| `p07_leso` | Lê Thái Tổ dựng triều · Lê Thánh Tông và luật Hồng Đức |
| `p08_trinhnguyen` | Mạc Đăng Dung và Nam–Bắc triều · Đàng Trong – Đàng Ngoài · Nam tiến mở cõi |
| `p09_tayson` | Ba anh em Tây Sơn · Quang Trung đại phá quân Thanh |
| `p10_nguyen` | Gia Long thống nhất · Minh Mạng và bộ máy nhà nước |
| `p11_phapthuoc` | Pháp xâm lược · Cần Vương và các phong trào yêu nước · Tới Cách mạng tháng Tám |
| `p12_hiendai` | Kháng chiến chống Pháp 1945–1954 · Giai đoạn 1954–1975 · Thống nhất và Đổi mới |

**Files (cả 4 task):**
- Modify: `scripts/data/vn-history-curriculum.json`

**Interfaces:**
- Consumes: `CurriculumFile` (Task 6), đường ống seed (Task 8).
- Produces: nội dung; không có API mới.

Các bước dưới đây lặp lại nguyên văn cho mỗi task, chỉ thay danh sách thời kỳ.

- [ ] **Step 1: Đọc thực thể của các thời kỳ phụ trách**

```bash
python3 -c "
import json
d=json.load(open('src/modules/knowledge-graph/data/vn_history_seed.json'))
want={'<periodId1>','<periodId2>','<periodId3>'}
for e in d['entities']:
    if e.get('period_id') in want:
        print(e['period_id'], '|', e['id'], '|', e['type'], '|', e['name'])
        if e.get('note'): print('      note:', e['note'])
"
```

Đây là nguồn sự thật cho tên riêng, niên đại và quan hệ. **Không bịa thực thể mới.**

- [ ] **Step 2: Soạn nội dung và thêm vào curriculum**

Thêm các phần tử `skillsets` mới vào `scripts/data/vn-history-curriculum.json`. Ràng buộc biên tập, lấy từ spec:

- Mỗi khoá 5 bài; mỗi bài 3–4 keypoint; mỗi `descriptionVi` của keypoint 80–400 ký tự, một ý trọn vẹn.
- `entityIds` chỉ trỏ vào id có thật trong seed. Không chắc thì bỏ trống.
- **`p01_hongbang` và phần đầu `p02_bacthuoc` là huyền sử.** Viết "theo truyền thuyết", "theo *Đại Việt sử ký toàn thư*". Không nêu như sự thật xác quyết. Trường `note` của thực thể trong seed đã đánh dấu sẵn chỗ nào cần dè dặt.
- **`p12_hiendai` viết ở mức sự kiện và mốc thời gian**: ai, ở đâu, khi nào, hệ quả trực tiếp. Không đưa đánh giá chính trị vào nội dung học.
- Chỉ tiếng Việt.

- [ ] **Step 3: Validate trước khi đụng tới Mongo**

Run: `npm run seed:vn-history -- --dry-run`
Expected: không lỗi, và số đếm khớp lô vừa thêm.

Validator gom mọi lỗi kèm đường dẫn kiểu `skillsets[3].courses[1].lessons[2].keypoints[0]` — sửa hết rồi mới đi tiếp.

- [ ] **Step 4: Seed**

Run: `npm run seed:vn-history`
Expected: `Tạo mới` bằng đúng số node mới của lô; các lô trước nằm ở `bỏ qua vì đã có`.

- [ ] **Step 5: Kiểm qua API**

```bash
TOKEN=$(curl -s -X POST http://localhost:4000/api/v1/users/dev-login \
  -H 'Content-Type: application/json' \
  -d '{"email":"dev@hddhistory.local","deviceId":"dev-local-001"}' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["data"]["accessToken"])')
curl -s http://localhost:4000/api/v1/skillsets -H "Authorization: Bearer $TOKEN" \
  | python3 -m json.tool | head -40
```
Expected: các skillset của lô này xuất hiện, đúng thứ tự thời gian.

Nếu đường dẫn tới `accessToken` trong JSON khác (có `ResponseInterceptor` bọc), chỉnh lệnh `python3` cho khớp hình dạng thật.

- [ ] **Step 6: Commit**

```bash
git add scripts/data/vn-history-curriculum.json
git commit -m "feat: nội dung lịch sử <tên các thời kỳ của lô>"
```

---

### Task 13: Kiểm chứng toàn bộ

**Files:** không sửa file nào. Task này chỉ chạy và đọc kết quả.

**Interfaces:**
- Consumes: mọi task trước.

- [ ] **Step 1: Đếm cuối cùng trong Mongo**

```bash
docker exec meup_mongo mongosh -u admin -p PGmnyFWTr9XyAvDX --authenticationDatabase admin hddhistory-api --quiet --eval '
  ["skillsets","courses","lessons","keypoints"].forEach(c =>
    print(c + ": " + db.getCollection(c).countDocuments()))'
```
Expected: `skillsets: 12`, `courses: 32`, `lessons: ~160`, `keypoints: ~560`.

Lệch so với dự kiến thì đối chiếu `npm run seed:vn-history -- --dry-run` xem lệch ở lô nào.

- [ ] **Step 2: Chạy lại toàn bộ seeder, xác nhận không nhân bản**

Run: `npm run seed:vn-history && npm run seed:dev-user`
Expected: `Tạo mới 0`. Đếm lại như Step 1 — số không đổi.

- [ ] **Step 3: Chạy lại các unit test đã viết**

```bash
npm test -- src/base/config/firebase-credential.spec.ts
npm test -- src/base/seed/curriculum/curriculum.validator.spec.ts
npm test -- src/base/seed/curriculum/curriculum.builder.spec.ts
```
Expected: cả ba PASS. **Không chạy `npm test` trần** — full suite làm máy này hết RAM.

- [ ] **Step 4: Build strict**

Run:
```bash
npm run build 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "error TS" \
  | sed 's/:[0-9]*:[0-9]* - error.*//' | sort -u
```
Expected: in ra đúng một dòng — `src/.../community-bot-queue.repository.ts` (lỗi có sẵn của session khác). Bất kỳ file nào khác xuất hiện là do task này gây ra.

- [ ] **Step 5: Kiểm trên simulator**

Chạy app bằng lệnh ở Task 5 Step 2, rồi đi qua:
1. Đăng nhập bằng user dev.
2. Mở danh sách skillset — thấy 12 thời kỳ theo đúng thứ tự thời gian.
3. Vào một thời kỳ → thấy các khoá.
4. Vào một khoá → thấy 5 bài.
5. Mở một bài → **đọc được nội dung keypoint thật**.
6. Ảnh placeholder hiện đúng màu và tên thời kỳ.

Chụp màn hình bước 2 và bước 5 làm bằng chứng.

Nếu app kẹt ở màn onboarding trước khi tới được danh sách: đó là rủi ro đã ghi trong spec. Đọc `/tmp/hddhistory-api.log` xem endpoint nào trả rỗng, seed thêm onboarding config, và ghi bổ sung vào plan này.

- [ ] **Step 6: Xác nhận không quét nhầm WIP của session khác vào commit**

Plan sinh 10 commit trong repo `hddhistory-api` (Task 1, 3, 4, 6, 7, 8, 9, 10, 11, 12) và 1 commit trong repo `hddhistory-flutter` (Task 5). Task 2 và 13 không commit gì.

Run: `git log --stat -10 | grep -E '^ ' | sort -u`
Expected: chỉ thấy các file liệt kê trong plan này. Nếu có file lạ (`community/bot`, schema user, `package-lock.json`…) thì một commit đã quét nhầm WIP của người khác — báo ngay, đừng tự ý sửa lịch sử.
