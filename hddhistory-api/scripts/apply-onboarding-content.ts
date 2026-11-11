/**
 * Đổ nội dung onboarding cho HDDhistory qua API (KHÔNG ghi thẳng Mongo), để
 * DTO + validator của server thực sự chạy trên payload:
 *
 *   1. `PUT /api/v1/onboarding-taxonomy`  — nhánh / gói / nhãn (3 collection)
 *   2. `PUT /api/v1/onboarding-config`    — phần chữ 8 màn còn trống
 *   3. `PUT /api/v1/courses/:id`          — `onboardingLabelCodes` +
 *                                           `onboardingDesireCodes` từng khoá
 *
 * Dữ liệu nằm ở `scripts/data/onboarding-*.json` nên sửa nội dung không phải
 * sửa mã. Script **idempotent theo kiểu so-rồi-mới-ghi**: mỗi bước đọc trạng
 * thái hiện tại trước, chỉ PUT khi khác — chạy lần hai in đúng
 * `0 thay đổi` và không đụng vào `updatedAt` của bản ghi nào.
 *
 * Chạy:
 *   npm run apply:onboarding-content
 *   npm run apply:onboarding-content -- --dry-run   (chỉ so sánh, không ghi)
 *
 * Env (đều có mặc định cho máy local):
 *   API_BASE_URL, ONBOARDING_ADMIN_EMAIL, ONBOARDING_ADMIN_PASSWORD
 */
import * as fs from 'fs';
import * as path from 'path';

const BASE_URL = (process.env.API_BASE_URL ?? 'http://localhost:4000').replace(
  /\/+$/,
  '',
);
const EMAIL = process.env.ONBOARDING_ADMIN_EMAIL ?? 'admin@hddhistory.local';
const PASSWORD = process.env.ONBOARDING_ADMIN_PASSWORD ?? 'hddhistory@2026';
const DRY_RUN = process.argv.includes('--dry-run');
const DATA_DIR = path.join(__dirname, 'data');

type Json = any;

function readJson(file: string): Json {
  return JSON.parse(fs.readFileSync(path.join(DATA_DIR, file), 'utf-8'));
}

/** So sánh không phụ thuộc thứ tự khoá của object (mảng vẫn giữ thứ tự). */
function canon(value: Json): Json {
  if (Array.isArray(value)) return value.map(canon);
  if (value && typeof value === 'object') {
    return Object.keys(value)
      .sort()
      .reduce<Record<string, Json>>((acc, key) => {
        acc[key] = canon(value[key]);
        return acc;
      }, {});
  }
  return value;
}

const same = (a: Json, b: Json) =>
  JSON.stringify(canon(a)) === JSON.stringify(canon(b));

let token = '';

async function api(method: string, route: string, body?: Json): Promise<Json> {
  const res = await fetch(`${BASE_URL}/api/v1${route}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) {
    throw new Error(`${method} ${route} → ${res.status} ${text}`);
  }
  const parsed = text ? JSON.parse(text) : {};
  return parsed && typeof parsed === 'object' && 'data' in parsed
    ? parsed.data
    : parsed;
}

async function login(): Promise<void> {
  const data = await api('POST', '/users/login', {
    email: EMAIL,
    password: PASSWORD,
    device: { deviceId: 'seed-onboarding-content', deviceName: 'Seed Script' },
  });
  token = data?.token?.accessToken;
  if (!token) throw new Error('Không lấy được accessToken từ /users/login');
}

//* ------------------------------------------------------------------ taxonomy

/** Cùng mặc định với `normalizeTree` của service, để hai bên so được với nhau. */
function normalizeTree(tree: Json): Json {
  const up = (s: string) => (s ?? '').trim().toUpperCase();
  const byCode = (a: Json, b: Json) => String(a.code).localeCompare(b.code);
  return {
    branches: (tree.branches ?? [])
      .map((b: Json, i: number) => ({
        code: up(b.code),
        label: b.label ?? {},
        subtitle: b.subtitle ?? {},
        iconUrl: b.iconUrl ?? '',
        imageUrl: b.imageUrl ?? '',
        order: b.order ?? i + 1,
        isSelectable: b.isSelectable ?? true,
        categoryId: b.categoryId ?? null,
        isActive: b.isActive ?? true,
      }))
      .sort(byCode),
    packages: (tree.packages ?? [])
      .map((p: Json, i: number) => ({
        code: up(p.code),
        branchCode: up(p.branchCode),
        problemLabel: p.problemLabel ?? {},
        desireLabel: p.desireLabel ?? {},
        order: p.order ?? i + 1,
        isActive: p.isActive ?? true,
      }))
      .sort(byCode),
    labels: (tree.labels ?? [])
      .map((l: Json, i: number) => ({
        code: up(l.code),
        packageCode: up(l.packageCode),
        label: l.label ?? {},
        order: l.order ?? i + 1,
      }))
      .sort(byCode),
  };
}

async function applyTaxonomy(): Promise<boolean> {
  const desired = readJson('onboarding-taxonomy.json');
  const current = await api('GET', '/onboarding-taxonomy/admin');
  const unchanged = same(normalizeTree(current), normalizeTree(desired));
  console.log(
    `  taxonomy : ${desired.branches.length} nhánh, ${desired.packages.length} gói, ${desired.labels.length} nhãn — ${
      unchanged ? 'không đổi' : 'CẬP NHẬT'
    }`,
  );
  if (unchanged || DRY_RUN) return !unchanged;
  await api('PUT', '/onboarding-taxonomy', desired);
  return true;
}

//* -------------------------------------------------------------------- config

async function applyConfig(): Promise<boolean> {
  const desired = readJson('onboarding-config.json');
  const current = await api('GET', '/onboarding-config');
  const stale = Object.keys(desired).filter(
    section => !same(current?.[section], desired[section]),
  );
  console.log(
    `  config   : ${Object.keys(desired).length} mục — ${
      stale.length ? `CẬP NHẬT ${stale.join(', ')}` : 'không đổi'
    }`,
  );
  if (!stale.length || DRY_RUN) return Boolean(stale.length);
  await api(
    'PUT',
    '/onboarding-config',
    stale.reduce<Record<string, Json>>((acc, key) => {
      acc[key] = desired[key];
      return acc;
    }, {}),
  );
  return true;
}

//* ------------------------------------------------------------------- courses

/** Mọi mã nhãn/gói gắn lên khoá phải tồn tại trong cây — bắt sai từ trước khi ghi. */
function assertCodesExist(rows: Json[], tree: Json): void {
  const labels = new Set(tree.labels.map((l: Json) => l.code));
  const packages = new Set(tree.packages.map((p: Json) => p.code));
  const problems: string[] = [];
  for (const row of rows) {
    for (const code of row.labelCodes ?? [])
      if (!labels.has(code))
        problems.push(`${row.title}: nhãn ${code} không có trong taxonomy`);
    for (const code of row.desireCodes ?? [])
      if (!packages.has(code))
        problems.push(`${row.title}: gói ${code} không có trong taxonomy`);
  }
  const tagged = new Set(rows.flatMap((r: Json) => r.labelCodes ?? []));
  for (const label of tree.labels)
    if (!tagged.has(label.code))
      problems.push(`nhãn ${label.code} chưa gắn cho khoá nào`);
  if (problems.length)
    throw new Error(`Mapping khoá học không hợp lệ:\n - ${problems.join('\n - ')}`);
}

/**
 * Khớp khoá theo TIÊU ĐỀ, không theo `courseId` lưu trong file.
 *
 * `courseId` đổi mỗi khi collection `courses` bị seed lại — đã xảy ra thật: một
 * lần seed lại làm mọi id trong file này thành id chết, bước này 404 ở khoá đầu
 * tiên, và 32/32 khoá mất sạch nhãn onboarding mà không ai hay. Tiêu đề thì do
 * file nội dung quyết nên bền qua mọi lần seed. `courseId` trong file chỉ còn là
 * ghi chú, không được đọc.
 */
async function resolveCourseIds(rows: Json[]): Promise<Map<string, string>> {
  const key = (s: string) => (s ?? '').normalize('NFC').trim();
  const page = await api('GET', '/courses?page=1&take=500&isAll=true');
  const byTitle = new Map<string, string[]>();
  for (const c of page.items ?? []) {
    const t = key(c.title?.vi);
    byTitle.set(t, [...(byTitle.get(t) ?? []), String(c._id)]);
  }

  const resolved = new Map<string, string>();
  const problems: string[] = [];
  for (const row of rows) {
    const ids = byTitle.get(key(row.title)) ?? [];
    if (ids.length === 0) problems.push(`không có khoá nào tên "${row.title}"`);
    else if (ids.length > 1) problems.push(`${ids.length} khoá cùng tên "${row.title}" — không biết gắn nhãn vào khoá nào`);
    else resolved.set(row.title, ids[0]);
  }
  if (problems.length)
    throw new Error(`Không khớp được khoá theo tiêu đề:\n - ${problems.join('\n - ')}`);
  return resolved;
}

async function applyCourseLabels(): Promise<number> {
  const rows: Json[] = readJson('onboarding-course-labels.json');
  assertCodesExist(rows, readJson('onboarding-taxonomy.json'));
  const ids = await resolveCourseIds(rows);

  let changed = 0;
  for (const row of rows) {
    const courseId = ids.get(row.title);
    const course = await api('GET', `/courses/${courseId}`);
    const isSame =
      same([...(course.onboardingLabelCodes ?? [])].sort(), [
        ...row.labelCodes,
      ].sort()) &&
      same([...(course.onboardingDesireCodes ?? [])].sort(), [
        ...row.desireCodes,
      ].sort());
    if (isSame) continue;
    changed += 1;
    if (DRY_RUN) continue;
    await api('PUT', `/courses/${courseId}`, {
      onboardingLabelCodes: row.labelCodes,
      onboardingDesireCodes: row.desireCodes,
    });
  }
  console.log(
    `  courses  : ${rows.length} khoá — ${changed ? `CẬP NHẬT ${changed}` : 'không đổi'}`,
  );
  return changed;
}

//* ---------------------------------------------------------------------- main

async function main(): Promise<void> {
  console.log(
    `Đổ nội dung onboarding → ${BASE_URL}${DRY_RUN ? ' (dry-run)' : ''}`,
  );
  await login();
  const taxonomyChanged = await applyTaxonomy();
  const configChanged = await applyConfig();
  const coursesChanged = await applyCourseLabels();
  const total =
    (taxonomyChanged ? 1 : 0) + (configChanged ? 1 : 0) + coursesChanged;
  console.log(total === 0 ? 'Xong — 0 thay đổi.' : `Xong — ${total} thay đổi.`);
}

main().catch(err => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
