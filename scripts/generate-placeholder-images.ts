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
import sharp = require('sharp');

const SEED_FILE = path.join(
  process.cwd(),
  'src/modules/knowledge-graph/data/vn_history_seed.json',
);
const OUT_DIR = path.join(process.cwd(), 'public/history');

/**
 * 12 màu khác hẳn nhau về sắc độ, đều đạt tương phản >= 4.5:1 với chữ trắng
 * (mục đích của ảnh là nhìn lướt phân biệt được 12 thời kỳ).
 */
const COLORS = [
  '#6D4C41', // nâu
  '#455A64', // xám xanh
  '#1565C0', // xanh dương
  '#AD1457', // hồng đậm
  '#4527A0', // tím
  '#00695C', // xanh ngọc
  '#C62828', // đỏ
  '#212121', // xám than
  '#2E7D32', // xanh lá
  '#827717', // ô liu
  '#B34700', // cam cháy
  '#00838F', // xanh lơ
];

const WIDTH = 800;
const HEIGHT = 450;
/** Chừa lề hai bên; chữ rộng tối đa bằng ngần này. */
const MAX_TEXT_WIDTH = WIDTH - 80;
const NAME_FONT = 44;
const MIN_NAME_FONT = 30;
/** Ước lượng bề rộng trung bình của một ký tự Helvetica đậm theo cỡ chữ. */
const CHAR_WIDTH_RATIO = 0.6;

function escapeXml(s: string): string {
  return s.replace(/[<>&'"]/g, (c) =>
    ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c]),
  );
}

/** Ngắt tên thành tối đa 2 dòng, cân bằng độ dài, ưu tiên ngắt sau " – ". */
function wrapName(name: string): string[] {
  const fits = (t: string) =>
    t.length * NAME_FONT * CHAR_WIDTH_RATIO <= MAX_TEXT_WIDTH;
  if (fits(name)) return [name];

  const words = name.split(' ');
  let best: string[] = [name];
  let bestGap = Infinity;
  for (let i = 1; i < words.length; i++) {
    const a = words.slice(0, i).join(' ');
    const b = words.slice(i).join(' ');
    const gap = Math.abs(a.length - b.length);
    if (gap < bestGap) {
      bestGap = gap;
      best = [a, b];
    }
  }
  return best;
}

/** Cỡ chữ lớn nhất (<= NAME_FONT) để dòng dài nhất vừa khung, không dưới sàn. */
function fontFor(lines: string[]): number {
  const longest = Math.max(...lines.map((l) => l.length));
  const fit = Math.floor(MAX_TEXT_WIDTH / (longest * CHAR_WIDTH_RATIO));
  return Math.max(MIN_NAME_FONT, Math.min(NAME_FONT, fit));
}

function svg(name: string, years: string, color: string): string {
  const lines = wrapName(name);
  const font = fontFor(lines);
  const lineHeight = Math.round(font * 1.2);
  // Khối chữ (các dòng tên + dòng năm) căn giữa theo chiều dọc.
  const blockH = lines.length * lineHeight + 20 + 26;
  const top = (HEIGHT - blockH) / 2;
  const nameText = lines
    .map(
      (l, i) =>
        `<text x="${WIDTH / 2}" y="${top + font + i * lineHeight}" text-anchor="middle" fill="#FFFFFF"
        font-family="Helvetica,Arial,sans-serif" font-size="${font}" font-weight="bold">${escapeXml(l)}</text>`,
    )
    .join('\n  ');
  const yearY = top + lines.length * lineHeight + 20 + 20;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <rect width="${WIDTH}" height="${HEIGHT}" fill="${color}"/>
  ${nameText}
  <text x="${WIDTH / 2}" y="${yearY}" text-anchor="middle" fill="#FFFFFF"
        font-family="Helvetica,Arial,sans-serif" font-size="26">${escapeXml(years)}</text>
</svg>
`;
}

async function main() {
  const seed = JSON.parse(fs.readFileSync(SEED_FILE, 'utf-8'));
  const periods: Array<{ id: string; name: string; start: string; end: string }> =
    seed.periods;

  if (periods.length !== 12) {
    throw new Error(`Chờ 12 thời kỳ, thấy ${periods.length}`);
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });

  // App dùng CachedNetworkImage (raster) nên chỉ ghi PNG; dọn .svg cũ để thư
  // mục không mang cả hai bản.
  for (const f of fs.readdirSync(OUT_DIR)) {
    if (f.endsWith('.svg')) fs.unlinkSync(path.join(OUT_DIR, f));
  }

  for (let i = 0; i < periods.length; i++) {
    const p = periods[i];
    const file = path.join(OUT_DIR, `${p.id}.png`);
    const markup = svg(p.name, `${p.start} – ${p.end}`, COLORS[i]);
    await sharp(Buffer.from(markup)).png().toFile(file);
    console.log(`Đã ghi ${file}`);
  }
  console.log(`Xong ${periods.length} ảnh.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
main();
