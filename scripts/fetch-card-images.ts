/**
 * Gắn ảnh minh hoạ từ Wikimedia Commons vào từng thẻ trong
 * scripts/data/vn-history-curriculum.json.
 *
 * Giấy phép chấp nhận: public domain, CC0, CC BY, CC BY-SA (kiểm ở Commons,
 * `extmetadata.LicenseShortName`). Mọi giấy phép khác (fair use, non-free, NC,
 * ND, không có trường giấy phép) bị loại. Vì CC BY* buộc ghi công, mỗi ảnh nhận
 * đủ `imageAuthor` (nếu biết), `imageLicense`, `imageFile`, `imageSource`; builder
 * đọc chúng để sinh khối `caption` ngay sau khối ảnh.
 *
 * Chọn chủ đề cho thẻ (KHÔNG chọn "cái nào có ảnh thì lấy"):
 *  1. Thẻ có nhiều entityIds -> thực thể có tên (hoặc biến thể đặc trưng của tên)
 *     xuất hiện trong titleVi, rồi tới descriptionVi; không khớp thì lấy thực thể đầu.
 *  2. Chủ đề đã chọn không có ảnh đạt chuẩn -> thẻ để TRỐNG ảnh. Không bao giờ
 *     rơi sang thực thể khác (đó là nguồn gốc của ảnh Lê Duẩn trên thẻ Hồ Chí Minh).
 *  3. Một file ảnh dùng tối đa MAX_REPEAT_GLOBAL thẻ trong cả file; quá trần thì
 *     thẻ sau không có ảnh chứ không lấy ảnh thay.
 *  Thẻ không có entityIds không có chủ đề đáng tin nên không gắn ảnh.
 *
 * Chạy lại được: mặc định giữ ảnh đã gắn (và tính vào trần), chỉ điền thẻ còn
 * thiếu; file JSON được ghi sau mỗi bài. `--reset` xoá mọi trường image* rồi làm lại.
 *
 *   npm run fetch:card-images -- --reset
 *   npm run fetch:card-images                   (tiếp tục)
 *   npm run fetch:card-images -- --limit=20     (chỉ xử lý 20 thẻ đầu chưa có ảnh)
 *
 * Biến môi trường: CARD_IMAGE_CONTACT (thông tin liên hệ đưa vào User-Agent),
 * CARD_IMAGE_CACHE (đường dẫn file cache tra cứu, mặc định trong thư mục tmp).
 */
import * as assert from 'assert';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';

const CURRICULUM_FILE = path.join(process.cwd(), 'scripts/data/vn-history-curriculum.json');
const SEED_FILE = path.join(process.cwd(), 'src/modules/knowledge-graph/data/vn_history_seed.json');
const CACHE_FILE =
  process.env.CARD_IMAGE_CACHE || path.join(os.tmpdir(), 'vn-history-card-image-cache-v2.json');

const CONTACT = process.env.CARD_IMAGE_CONTACT || 'internal educational app';
const USER_AGENT = `HDDhistoryCardImageFetcher/2.0 (Vietnamese history learning app; ${CONTACT}) node-fetch`;
const MIN_INTERVAL_MS = 1100;
/** Một file ảnh không xuất hiện quá số thẻ này trong cả file. */
export const MAX_REPEAT_GLOBAL = 4;
/** Và không quá số thẻ này trong cùng một bài (tránh hai thẻ liền nhau cùng ảnh). */
const MAX_REPEAT_PER_LESSON = 2;
const IMAGE_FIELDS = ['image', 'imageFile', 'imageLicense', 'imageSource', 'imageAuthor'] as const;

interface Card {
  titleVi: string;
  descriptionVi: string;
  entityIds?: string[];
  image?: string;
  imageFile?: string;
  imageLicense?: string;
  imageSource?: string;
  imageAuthor?: string;
}

interface FileInfo {
  file: string; // "File:Xxx.jpg"
  url: string;
  license: string;
  attributionRequired?: string;
  author?: string;
}
interface Hit extends FileInfo {
  source: string;
}

/** Đúng định dạng file hiện tại: indent 2, mảng chuỗi nằm trên một dòng. */
export function serialize(v: unknown, ind = 0): string {
  const p = '  '.repeat(ind);
  if (Array.isArray(v)) {
    if (v.every((x) => typeof x === 'string')) {
      return '[' + v.map((x) => JSON.stringify(x)).join(', ') + ']';
    }
    return '[\n' + v.map((x) => p + '  ' + serialize(x, ind + 1)).join(',\n') + '\n' + p + ']';
  }
  if (v && typeof v === 'object') {
    return (
      '{\n' +
      Object.entries(v as Record<string, unknown>)
        .map(([k, x]) => p + '  ' + JSON.stringify(k) + ': ' + serialize(x, ind + 1))
        .join(',\n') +
      '\n' + p + '}'
    );
  }
  return JSON.stringify(v);
}

const PD_RE = /^(public domain|pd([-\s]|$)|cc0|cc-zero|no restrictions)/i;
const CC_BY_RE = /^cc[-\s]by(-sa)?[-\s]\d(\.\d)?(\s+[a-z]{2,3})?$/i;
/** Public domain, CC0, CC BY, CC BY-SA. Loại NC/ND, GFDL, fair use, thiếu giấy phép. */
export function isAcceptedLicense(license: string | undefined): boolean {
  const l = (license ?? '').trim();
  if (!l) return false;
  return PD_RE.test(l) || CC_BY_RE.test(l);
}

/** Commons gắn ?utm_source=... vào thumburl; bỏ đi cho URL sạch. */
const cleanUrl = (u: string) => u.replace(/\?utm_[^#]*$/, '');

const ENTITIES: Record<string, string> = { amp: '&', quot: '"', lt: '<', gt: '>', nbsp: ' ', apos: "'" };
/** Bỏ thẻ HTML (Commons hay trả `<a href=...>Tên</a>`), giải mã entity, gọn khoảng trắng. */
export function stripHtml(s: string): string {
  return s
    .replace(/<[^>]*>/g, '')
    .replace(/&#x([0-9a-f]+);/gi, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (_, d) => String.fromCodePoint(Number(d)))
    .replace(/&([a-z]+);/gi, (m, n) => ENTITIES[n.toLowerCase()] ?? m)
    .replace(/\s+/g, ' ')
    .trim();
}

/** Tác giả dùng được để ghi công; chuỗi "Unknown author" của Commons coi như không biết. */
export function cleanAuthor(raw: string | undefined): string | undefined {
  if (!raw) return undefined;
  const a = stripHtml(raw);
  if (!a || /^(unknown|anonymous|not specified|n\/a)/i.test(a)) return undefined;
  return a.length > 140 ? a.slice(0, 137).trimEnd() + '...' : a;
}

// ---- Chọn chủ đề theo nội dung thẻ ------------------------------------------

const GENERIC_PREFIX = /^(vua|chúa|nhà|khởi nghĩa|cuộc khởi nghĩa|chiến thắng|trận|hiệp định|cuộc)\s+/i;

/** Tên đầy đủ, tên bỏ ngoặc, nội dung ngoặc, từng vế "A / B", và tên bỏ tiền tố chung. */
export function nameVariants(name: string): string[] {
  const out = new Set<string>();
  const add = (v: string) => {
    const t = v.normalize('NFC').trim();
    if (t.length >= 3) out.add(t);
  };
  add(name);
  const base = name.replace(/\([^)]*\)/g, ' ').replace(/\s+/g, ' ').trim();
  add(base);
  for (const m of name.matchAll(/\(([^)]*)\)/g)) m[1].split(/\s*[\/,;]\s*/).forEach(add);
  base.split(/\s*[\/;]\s*/).forEach(add);
  for (const v of [...out]) {
    const stripped = v.replace(GENERIC_PREFIX, '');
    if (stripped !== v && stripped.split(/\s+/).length >= 2) add(stripped);
  }
  return [...out];
}

const escapeRe = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
function findPos(text: string, variants: string[]): number {
  let best = -1;
  for (const v of variants) {
    const re = new RegExp(`(?<![\\p{L}\\p{N}])${escapeRe(v)}(?![\\p{L}\\p{N}])`, 'iu');
    const m = re.exec(text);
    if (m && (best < 0 || m.index < best)) best = m.index;
  }
  return best;
}

/**
 * Thực thể được chọn cho thẻ: khớp trong titleVi trước, rồi descriptionVi (vị trí
 * xuất hiện sớm nhất thắng), không khớp thì thực thể đầu tiên.
 */
export function pickEntity(
  card: { titleVi: string; descriptionVi: string; entityIds?: string[] },
  names: Map<string, string>,
): { id: string; name: string } | null {
  const cands = (card.entityIds ?? [])
    .map((id) => ({ id, name: names.get(id) }))
    .filter((c): c is { id: string; name: string } => !!c.name);
  if (!cands.length) return null;
  const title = card.titleVi.normalize('NFC');
  const desc = card.descriptionVi.normalize('NFC');
  let best: { c: { id: string; name: string }; tier: number; pos: number } | null = null;
  for (const c of cands) {
    const v = nameVariants(c.name);
    const tp = findPos(title, v);
    const dp = tp < 0 ? findPos(desc, v) : -1;
    const tier = tp >= 0 ? 0 : dp >= 0 ? 1 : 2;
    if (tier === 2) continue;
    const pos = tier === 0 ? tp : dp;
    if (!best || tier < best.tier || (tier === best.tier && pos < best.pos)) best = { c, tier, pos };
  }
  return best ? best.c : cands[0];
}

/**
 * Ảnh đại diện của một bài Wikipedia có thể chính là ảnh của thực thể khác (bài
 * "Tô Định" dùng tranh Hai Bà Trưng). Nếu tên file nêu tên một thực thể KHÁC và
 * không nêu tên thực thể đang chọn thì đó là ảnh của người/việc khác: loại.
 * Trả về tên thực thể khác đó, hoặc null nếu file không vướng.
 */
export function foreignSubject(
  file: string,
  chosen: { id: string; name: string },
  allNames: Map<string, string>,
): string | null {
  const f = file.replace(/^File:/i, '').replace(/[_]/g, ' ').normalize('NFC');
  if (findPos(f, nameVariants(chosen.name)) >= 0) return null;
  for (const [id, name] of allNames) {
    if (id === chosen.id) continue;
    if (findPos(f, nameVariants(name)) >= 0) return name;
  }
  return null;
}

/** Tên bài Wikipedia thử theo thứ tự cho MỘT thực thể (cùng thực thể, không phải thực thể khác). */
export function topicCandidates(name: string): string[] {
  const base = name.replace(/\([^)]*\)/g, ' ').replace(/\s+/g, ' ').trim();
  return [...new Set([base, name, ...[...name.matchAll(/\(([^)]*)\)/g)].map((m) => m[1].trim())])].filter(Boolean);
}

let lastRequest = 0;
async function getJson(url: string): Promise<any> {
  for (let attempt = 0; attempt < 4; attempt++) {
    const wait = lastRequest + MIN_INTERVAL_MS - Date.now();
    if (wait > 0) await new Promise((r) => setTimeout(r, wait));
    lastRequest = Date.now();
    try {
      const res = await fetch(url, { headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' } });
      if (res.status === 429 || res.status >= 500) {
        await new Promise((r) => setTimeout(r, 5000 * (attempt + 1)));
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      if (attempt === 3) throw e;
      await new Promise((r) => setTimeout(r, 3000 * (attempt + 1)));
    }
  }
  throw new Error('retries exhausted');
}

type Cache = { topics: Record<string, Hit | null>; files: Record<string, FileInfo | null> };
function loadCache(): Cache {
  try {
    return JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8'));
  } catch {
    return { topics: {}, files: {} };
  }
}
const cache = loadCache();
const saveCache = () => fs.writeFileSync(CACHE_FILE, JSON.stringify(cache));

/** Cache lưu thông tin thô của file; việc chấp nhận giấy phép quyết ở nơi dùng. */
async function commonsInfo(fileTitle: string): Promise<FileInfo | null> {
  if (fileTitle in cache.files) return cache.files[fileTitle];
  const url =
    'https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|extmetadata' +
    `&iiurlwidth=1200&format=json&titles=${encodeURIComponent(fileTitle)}`;
  const json = await getJson(url);
  const page: any = Object.values(json?.query?.pages ?? {})[0];
  const info = page?.imageinfo?.[0];
  let out: FileInfo | null = null;
  if (info) {
    const md = info.extmetadata ?? {};
    const imgUrl: string = info.thumburl || info.url;
    if (/^https:\/\//.test(imgUrl || '')) {
      out = {
        file: page.title,
        url: cleanUrl(imgUrl),
        license: String(md.LicenseShortName?.value ?? '').trim(),
        attributionRequired: md.AttributionRequired?.value,
        author: cleanAuthor(md.Artist?.value),
      };
    }
  }
  cache.files[fileTitle] = out;
  return out;
}

const RASTER_RE = /\.(jpe?g|png|webp)$/i;

async function lookupTopic(topic: string): Promise<Hit | null> {
  if (topic in cache.topics) return cache.topics[topic];
  let hit: Hit | null = null;
  try {
    const url =
      'https://vi.wikipedia.org/w/api.php?action=query&prop=pageimages|pageprops&piprop=original|name' +
      `&ppprop=disambiguation&redirects=1&format=json&titles=${encodeURIComponent(topic)}`;
    const json = await getJson(url);
    const page: any = Object.values(json?.query?.pages ?? {})[0];
    const isDisambig = page?.pageprops && 'disambiguation' in page.pageprops;
    if (page && !('missing' in page) && !isDisambig && (page.pageimage || page.original?.source)) {
      let name: string = page.pageimage;
      if (!name) name = decodeURIComponent(String(page.original.source).split('/').pop() ?? '');
      if (RASTER_RE.test(name)) {
        const c = await commonsInfo('File:' + name.replace(/_/g, ' '));
        if (c && isAcceptedLicense(c.license)) {
          hit = {
            ...c,
            source: 'https://vi.wikipedia.org/wiki/' + encodeURIComponent(String(page.title).replace(/ /g, '_')),
          };
        }
      }
    }
  } catch (e) {
    console.warn(`  ! lỗi khi tra "${topic}": ${(e as Error).message} (bỏ qua, không cache)`);
    return null;
  }
  cache.topics[topic] = hit;
  return hit;
}

const forEachCard = (d: any, fn: (k: Card, l: any) => void) =>
  d.skillsets.forEach((s: any) => s.courses.forEach((c: any) => c.lessons.forEach((l: any) =>
    l.keypoints.forEach((k: Card) => fn(k, l)))));

async function main() {
  const limitArg = process.argv.find((a) => a.startsWith('--limit='));
  const limit = limitArg ? Number(limitArg.split('=')[1]) : Infinity;
  const reset = process.argv.includes('--reset');

  const text = fs.readFileSync(CURRICULUM_FILE, 'utf-8');
  const data = JSON.parse(text);
  // Cổng an toàn: serializer phải tái tạo đúng từng byte trước khi được phép ghi.
  assert.strictEqual(serialize(data) + '\n', text, 'serializer không tái tạo byte-identical file hiện tại');

  const idCount = (d: any) => {
    let nonEmpty = 0, empty = 0;
    forEachCard(d, (k) => {
      if (Array.isArray(k.entityIds)) k.entityIds.length ? nonEmpty++ : empty++;
    });
    return { nonEmpty, empty };
  };
  const before = idCount(data);

  const seed = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const names = new Map<string, string>(seed.entities.map((e: any) => [e.id, e.name]));

  if (reset) {
    // Giấy phép chấp nhận đã đổi; giữ ảnh cũ là giữ luôn các ảnh sai.
    forEachCard(data, (k) => IMAGE_FIELDS.forEach((f) => delete (k as any)[f]));
    console.log('Đã xoá mọi trường image* — làm lại từ đầu.');
  } else {
    forEachCard(data, (k) => { if (k.image) k.image = cleanUrl(k.image); });
  }

  // Số thẻ đang dùng mỗi file trong cả file (tính cả ảnh giữ lại khi chạy tiếp).
  const globalUse = new Map<string, number>();
  forEachCard(data, (k) => k.image && k.imageFile && globalUse.set(k.imageFile, (globalUse.get(k.imageFile) ?? 0) + 1));

  let processed = 0;
  const persist = () => {
    fs.writeFileSync(CURRICULUM_FILE, serialize(data) + '\n');
    saveCache();
  };

  outer: for (const s of data.skillsets) for (const c of s.courses) for (const l of c.lessons) {
    const used = new Map<string, number>();
    (l.keypoints as Card[]).forEach((k) => k.image && k.imageFile && used.set(k.imageFile, (used.get(k.imageFile) ?? 0) + 1));
    let touched = false;

    for (const k of l.keypoints as Card[]) {
      if (k.image) continue;
      if (processed >= limit) break outer;
      processed++;

      const ent = pickEntity(k, names);
      let hit: Hit | null = null;
      let why = 'không có entityIds';
      if (ent) {
        for (const t of topicCandidates(ent.name)) {
          hit = await lookupTopic(t);
          if (hit) break;
        }
        why = hit ? '' : `"${ent.name}" không có ảnh đạt chuẩn`;
      }
      const foreign = hit && ent ? foreignSubject(hit.file, ent, names) : null;
      if (hit && foreign) {
        why = `${hit.file} là ảnh của "${foreign}", không phải "${ent!.name}"`;
        hit = null;
      } else if (hit && (globalUse.get(hit.file) ?? 0) >= MAX_REPEAT_GLOBAL) {
        why = `${hit.file} đã đủ ${MAX_REPEAT_GLOBAL} thẻ`;
        hit = null;
      } else if (hit && (used.get(hit.file) ?? 0) >= MAX_REPEAT_PER_LESSON) {
        why = `${hit.file} đã dùng ${MAX_REPEAT_PER_LESSON} lần trong bài`;
        hit = null;
      }
      if (hit) {
        k.image = hit.url;
        k.imageFile = hit.file;
        k.imageLicense = hit.license;
        k.imageSource = hit.source;
        if (hit.author) k.imageAuthor = hit.author;
        used.set(hit.file, (used.get(hit.file) ?? 0) + 1);
        globalUse.set(hit.file, (globalUse.get(hit.file) ?? 0) + 1);
        touched = true;
      }
      console.log(`[${processed}] ${l.titleVi} / ${k.titleVi} -> ${hit ? `${hit.file} [${hit.license}] (${ent!.name})` : 'không ảnh: ' + why}`);
    }
    if (touched) persist();
  }
  persist();

  // Đọc lại và so sánh sâu với bộ nhớ, rồi kiểm số entityIds.
  const reread = JSON.parse(fs.readFileSync(CURRICULUM_FILE, 'utf-8'));
  assert.deepStrictEqual(reread, data, 'file sau khi ghi khác dữ liệu trong bộ nhớ');
  const after = idCount(reread);
  assert.deepStrictEqual(after, before, `entityIds thay đổi: ${JSON.stringify(before)} -> ${JSON.stringify(after)}`);
  console.log(`entityIds không rỗng: ${after.nonEmpty}, mảng rỗng: ${after.empty}`);

  let cards = 0, withImage = 0;
  const uses = new Map<string, number>();
  forEachCard(reread, (k) => {
    cards++;
    if (k.image) { withImage++; uses.set(k.imageFile!, (uses.get(k.imageFile!) ?? 0) + 1); }
  });
  console.log(`Thẻ có ảnh: ${withImage}/${cards}; ảnh khác nhau: ${uses.size}; dùng lại nhiều nhất: ${Math.max(0, ...uses.values())}`);
}

if (require.main === module) {
  main().catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
