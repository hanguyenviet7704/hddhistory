/**
 * Gắn ảnh public-domain từ Wikimedia vào từng thẻ trong
 * scripts/data/vn-history-curriculum.json.
 *
 * Chọn chủ đề cho mỗi thẻ: tên thực thể (entityIds → vn_history_seed.json),
 * không có thì titleVi của thẻ, không có nữa thì titleVi của bài. Ảnh lấy từ
 * ảnh đại diện bài viết vi.wikipedia, giấy phép kiểm ở Commons; chỉ giữ ảnh
 * public domain / CC0 (app không có chỗ ghi công nên CC BY* bị loại).
 *
 * Chạy lại được: thẻ đã có `image` thì bỏ qua; file JSON được ghi sau mỗi bài.
 *
 *   npm run fetch:card-images
 *   npm run fetch:card-images -- --limit=20     (chỉ thử 20 thẻ đầu chưa có ảnh)
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
  process.env.CARD_IMAGE_CACHE || path.join(os.tmpdir(), 'vn-history-card-image-cache.json');

const CONTACT = process.env.CARD_IMAGE_CONTACT || 'internal educational app';
const USER_AGENT = `HDDhistoryCardImageFetcher/1.0 (Vietnamese history learning app; ${CONTACT}) node-fetch`;
const MIN_INTERVAL_MS = 1100;
/** Một ảnh không xuất hiện quá số thẻ này trong cùng một bài. */
const MAX_REPEAT_PER_LESSON = 2;

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

interface Hit {
  file: string; // "File:Xxx.jpg"
  url: string;
  license: string;
  author?: string;
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
export function isPublicDomain(license: string | undefined, attributionRequired?: string): boolean {
  if (!license) return false;
  if (/^cc[\s-]by/i.test(license) || /\bsa\b|attribution/i.test(license)) return false;
  if (attributionRequired && attributionRequired.toLowerCase() === 'true') return false;
  return PD_RE.test(license.trim());
}

/** Commons gắn ?utm_source=... vào thumburl; bỏ đi cho URL sạch. */
const cleanUrl = (u: string) => u.replace(/\?utm_[^#]*$/, '');

const stripHtml = (s: string) =>
  s.replace(/<[^>]*>/g, '').replace(/&amp;/g, '&').replace(/&quot;/g, '"').replace(/&#0?39;/g, "'")
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/\s+/g, ' ').trim();

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

type Cache = { topics: Record<string, Hit | null>; files: Record<string, Omit<Hit, 'source'> | null> };
function loadCache(): Cache {
  try {
    return JSON.parse(fs.readFileSync(CACHE_FILE, 'utf-8'));
  } catch {
    return { topics: {}, files: {} };
  }
}
const cache = loadCache();
const saveCache = () => fs.writeFileSync(CACHE_FILE, JSON.stringify(cache));

async function commonsLicense(fileTitle: string): Promise<Omit<Hit, 'source'> | null> {
  if (fileTitle in cache.files) return cache.files[fileTitle];
  const url =
    'https://commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|extmetadata' +
    `&iiurlwidth=1200&format=json&titles=${encodeURIComponent(fileTitle)}`;
  const json = await getJson(url);
  const page: any = Object.values(json?.query?.pages ?? {})[0];
  const info = page?.imageinfo?.[0];
  let out: Omit<Hit, 'source'> | null = null;
  if (info) {
    const md = info.extmetadata ?? {};
    const license: string = md.LicenseShortName?.value ?? '';
    const imgUrl: string = info.thumburl || info.url;
    if (isPublicDomain(license, md.AttributionRequired?.value) && /^https:\/\//.test(imgUrl || '')) {
      const artist = md.Artist?.value ? stripHtml(md.Artist.value) : undefined;
      out = { file: page.title, url: cleanUrl(imgUrl), license, author: artist || undefined };
    }
  }
  cache.files[fileTitle] = out;
  return out;
}

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
      const c = await commonsLicense('File:' + name.replace(/_/g, ' '));
      if (c) {
        hit = {
          ...c,
          source: 'https://vi.wikipedia.org/wiki/' + encodeURIComponent(String(page.title).replace(/ /g, '_')),
        };
      }
    }
  } catch (e) {
    console.warn(`  ! lỗi khi tra "${topic}": ${(e as Error).message} (bỏ qua, không cache)`);
    return null;
  }
  cache.topics[topic] = hit;
  return hit;
}

async function main() {
  const limitArg = process.argv.find((a) => a.startsWith('--limit='));
  const limit = limitArg ? Number(limitArg.split('=')[1]) : Infinity;

  const text = fs.readFileSync(CURRICULUM_FILE, 'utf-8');
  const data = JSON.parse(text);
  // Cổng an toàn: serializer phải tái tạo đúng từng byte trước khi được phép ghi.
  assert.strictEqual(serialize(data) + '\n', text, 'serializer không tái tạo byte-identical file hiện tại');

  const idCount = (d: any) => {
    let nonEmpty = 0, empty = 0;
    d.skillsets.forEach((s: any) => s.courses.forEach((c: any) => c.lessons.forEach((l: any) =>
      l.keypoints.forEach((k: Card) => {
        if (Array.isArray(k.entityIds)) k.entityIds.length ? nonEmpty++ : empty++;
      }))));
    return { nonEmpty, empty };
  };
  const before = idCount(data);

  const seed = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const names = new Map<string, string>(seed.entities.map((e: any) => [e.id, e.name]));

  // Dữ liệu ghi từ lần chạy trước có thể còn ?utm_*.
  data.skillsets.forEach((s: any) => s.courses.forEach((c: any) => c.lessons.forEach((l: any) =>
    l.keypoints.forEach((k: Card) => { if (k.image) k.image = cleanUrl(k.image); }))));

  let processed = 0;
  const persist = () => {
    fs.writeFileSync(CURRICULUM_FILE, serialize(data) + '\n');
    saveCache();
  };

  outer: for (const s of data.skillsets) for (const c of s.courses) for (const l of c.lessons) {
    const used = new Map<string, number>(); // file → số thẻ đã dùng trong bài này
    (l.keypoints as Card[]).forEach((k) => k.image && k.imageFile && used.set(k.imageFile, (used.get(k.imageFile) ?? 0) + 1));
    let touched = false;

    for (const k of l.keypoints as Card[]) {
      if (k.image) continue;
      if (processed >= limit) break outer;
      processed++;

      const topics = k.entityIds?.length
        ? k.entityIds.map((id) => names.get(id)).filter((n): n is string => !!n)
        : [k.titleVi || l.titleVi];
      if (!topics.length) topics.push(k.titleVi || l.titleVi);

      const hits: { topic: string; hit: Hit }[] = [];
      for (const t of [...new Set(topics)]) {
        const hit = await lookupTopic(t);
        if (hit) hits.push({ topic: t, hit });
      }
      // Ưu tiên ảnh chưa dùng trong bài, rồi mới đến ảnh dùng lại (có trần).
      const pick =
        hits.find((h) => !used.has(h.hit.file)) ??
        hits.find((h) => (used.get(h.hit.file) ?? 0) < MAX_REPEAT_PER_LESSON);
      if (pick) {
        const h = pick.hit;
        k.image = h.url;
        k.imageFile = h.file;
        k.imageLicense = h.license;
        k.imageSource = h.source;
        if (h.author) k.imageAuthor = h.author;
        used.set(h.file, (used.get(h.file) ?? 0) + 1);
        touched = true;
      }
      console.log(`[${processed}] ${l.titleVi} / ${k.titleVi} -> ${pick ? `${pick.hit.file} (${pick.topic})` : 'không có ảnh PD'}`);
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
  const files = new Set<string>();
  reread.skillsets.forEach((s: any) => s.courses.forEach((c: any) => c.lessons.forEach((l: any) =>
    l.keypoints.forEach((k: Card) => { cards++; if (k.image) { withImage++; files.add(k.imageFile!); } }))));
  console.log(`Thẻ có ảnh: ${withImage}/${cards}; ảnh khác nhau: ${files.size}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
