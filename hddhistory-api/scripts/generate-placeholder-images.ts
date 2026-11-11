/**
 * Sinh ảnh đại diện cho 12 thời kỳ (800×450, `public/history/<periodId>.png`),
 * dùng ở mọi chỗ khoá/bài chưa có ảnh thật: thẻ "Khoá học mới hôm nay" ở Home,
 * huy hiệu cấp độ roadmap, bìa bài.
 *
 * Mỗi thời kỳ một màu nền riêng, kèm tên và mốc năm. Không giả làm ảnh tư liệu
 * — đây là ảnh đồ hoạ, nhưng phải trông như được thiết kế chứ không như chỗ
 * trống quên thay ảnh:
 *   - nền: màu thời kỳ ở giữa, tối dần ra bốn góc (vignette) và về phía đáy;
 *   - hoạ tiết mặt trống đồng Đông Sơn đồng tâm (ngôi sao 14 cánh, vành vạch
 *     khắc, vành vòng tròn nhỏ) vẽ cùng tông, rất nhạt;
 *   - viền gạch kép mờ dần ở mép trên/dưới (không có cạnh dọc để ảnh bị cắt
 *     hai bên vẫn không lộ khung bị xén);
 *   - chữ có thứ bậc: dòng "THỜI KỲ 05" giãn chữ, tên thời kỳ đậm, gạch
 *     trang trí có hình thoi, mốc năm.
 *
 * Tương phản: chữ luôn trắng đặc. Mọi lớp phủ nằm sau chữ chỉ được làm nền TỐI
 * đi (tăng tương phản); riêng hoạ tiết sáng chỉ dùng cho màu nào vẫn giữ được
 * >= 4.5:1 sau khi phủ — `motifTone` tính việc đó và script dừng nếu một màu
 * nào tụt dưới ngưỡng.
 *
 * Sinh cục bộ (SVG → PNG qua sharp), không gọi dịch vụ ngoài, chạy được khi tắt
 * mạng. Tên file không đổi nên URL cũ vẫn trỏ đúng, không cần seed lại.
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
const CX = WIDTH / 2;
const CY = HEIGHT / 2;
/**
 * Thẻ "Khoá học mới hôm nay" ở Home cắt ảnh theo BoxFit.cover về khoảng 1.36:1
 * (≈ 612 px giữa của 800), nên chữ phải nằm gọn trong bề ngang đó, chừa lề.
 */
const MAX_TEXT_WIDTH = 560;
const NAME_FONT = 46;
const MIN_NAME_FONT = 30;
/** Ước lượng bề rộng trung bình của một ký tự Helvetica đậm theo cỡ chữ. */
const CHAR_WIDTH_RATIO = 0.6;
const FONT_FAMILY = 'Helvetica,Arial,sans-serif';
const MIN_CONTRAST = 4.5;

//* ---------------------------------------------------------------- màu sắc

type Rgb = [number, number, number];

function hexToRgb(hex: string): Rgb {
  const n = parseInt(hex.replace('#', ''), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

function mix(a: Rgb, b: Rgb, t: number): Rgb {
  return [0, 1, 2].map((i) => Math.round(a[i] * (1 - t) + b[i] * t)) as Rgb;
}

function luminance([r, g, b]: Rgb): number {
  const ch = (c: number) => {
    const s = c / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b);
}

function contrastWithWhite(c: Rgb): number {
  return 1.05 / (luminance(c) + 0.05);
}

const WHITE: Rgb = [255, 255, 255];
const LIGHT_MOTIF_OPACITY = 0.1;
const DARK_MOTIF_OPACITY = 0.2;

/**
 * Hoạ tiết vẽ bằng trắng mờ nếu nền phủ lớp đó vẫn đạt MIN_CONTRAST (+ biên
 * 0.1), ngược lại vẽ bằng đen mờ — nền tối đi thì tương phản chỉ tăng. Nhờ vậy
 * hoạ tiết có thể nằm cả dưới chữ mà không làm chữ khó đọc hơn.
 */
function motifTone(color: string): { stroke: string; opacity: number } {
  const lit = mix(hexToRgb(color), WHITE, LIGHT_MOTIF_OPACITY);
  return contrastWithWhite(lit) >= MIN_CONTRAST + 0.1
    ? { stroke: '#FFFFFF', opacity: LIGHT_MOTIF_OPACITY }
    : { stroke: '#000000', opacity: DARK_MOTIF_OPACITY };
}

/** Tương phản thấp nhất chữ trắng có thể gặp ở vùng chữ (nền + hoạ tiết). */
function worstTextContrast(color: string): number {
  const base = hexToRgb(color);
  const tone = motifTone(color);
  const covered =
    tone.stroke === '#FFFFFF' ? mix(base, WHITE, tone.opacity) : base;
  return contrastWithWhite(covered);
}

//* ------------------------------------------------------------------- chữ

function escapeXml(s: string): string {
  return s.replace(/[<>&'"]/g, (c) =>
    ({ '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&apos;', '"': '&quot;' }[c] ?? c),
  );
}

/** Dưới cỡ này thì thà xuống 2 dòng còn hơn ép tên thành 1 dòng chữ nhỏ. */
const ONE_LINE_MIN_FONT = 36;

/**
 * Ngắt tên thành tối đa 2 dòng. Vừa 1 dòng (kể cả khi phải thu chữ xuống
 * ONE_LINE_MIN_FONT) thì giữ 1 dòng. Không thì ngắt ở chỗ tự nhiên: trước
 * ngoặc đơn ("Nhà Nguyễn" / "(trước Pháp thuộc)"), sau gạch " – "; không có
 * thì cân bằng độ dài hai dòng.
 */
function wrapName(name: string): string[] {
  const fitsAt = (t: string, font: number) =>
    t.length * font * CHAR_WIDTH_RATIO <= MAX_TEXT_WIDTH;
  if (fitsAt(name, ONE_LINE_MIN_FONT)) return [name];

  const words = name.split(' ');
  const splits = words.slice(1).map((_, k) => {
    const i = k + 1;
    return {
      lines: [words.slice(0, i).join(' '), words.slice(i).join(' ')],
      natural: words[i].startsWith('(') || words[i - 1] === '–',
    };
  });
  const pool = splits.some((s) => s.natural)
    ? splits.filter((s) => s.natural)
    : splits;
  const gap = (s: { lines: string[] }) =>
    Math.abs(s.lines[0].length - s.lines[1].length);
  return pool.reduce((best, s) => (gap(s) < gap(best) ? s : best), pool[0])
    ?.lines ?? [name];
}

/** Cỡ chữ lớn nhất (<= NAME_FONT) để dòng dài nhất vừa khung, không dưới sàn. */
function fontFor(lines: string[]): number {
  const longest = Math.max(...lines.map((l) => l.length));
  const fit = Math.floor(MAX_TEXT_WIDTH / (longest * CHAR_WIDTH_RATIO));
  return Math.max(MIN_NAME_FONT, Math.min(NAME_FONT, fit));
}

//* ------------------------------------------------------- hoạ tiết trống đồng

const f = (n: number) => n.toFixed(1);

function ring(r: number, width: number): string {
  return `<circle cx="${CX}" cy="${CY}" r="${r}" fill="none" stroke-width="${width}"/>`;
}

/** Vành vạch khắc: các đoạn thẳng hướng tâm từ r1 tới r2, cách nhau `step` độ. */
function ticks(r1: number, r2: number, step: number, width: number): string {
  const parts: string[] = [];
  for (let a = 0; a < 360; a += step) {
    const rad = (a * Math.PI) / 180;
    const [c, s] = [Math.cos(rad), Math.sin(rad)];
    parts.push(
      `M${f(CX + r1 * c)} ${f(CY + r1 * s)}L${f(CX + r2 * c)} ${f(CY + r2 * s)}`,
    );
  }
  return `<path d="${parts.join('')}" fill="none" stroke-width="${width}"/>`;
}

/** Vành vòng tròn nhỏ tiếp tuyến — hoạ tiết quen thuộc trên mặt trống Đông Sơn. */
function circlets(r: number, count: number, size: number, width: number): string {
  const parts: string[] = [];
  for (let i = 0; i < count; i++) {
    const rad = (i * 2 * Math.PI) / count;
    parts.push(
      `<circle cx="${f(CX + r * Math.cos(rad))}" cy="${f(CY + r * Math.sin(rad))}" r="${size}" fill="none" stroke-width="${width}"/>`,
    );
  }
  return parts.join('');
}

/** Ngôi sao giữa mặt trống (trống Ngọc Lũ có 14 cánh). */
function star(points: number, inner: number, outer: number): string {
  const pts: string[] = [];
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 === 0 ? outer : inner;
    const rad = (i * Math.PI) / points - Math.PI / 2;
    pts.push(`${f(CX + r * Math.cos(rad))},${f(CY + r * Math.sin(rad))}`);
  }
  return `<polygon points="${pts.join(' ')}" stroke-width="1.5"/>`;
}

function drumMotif(color: string): string {
  const tone = motifTone(color);
  return `<g stroke="${tone.stroke}" fill="${tone.stroke}" opacity="${tone.opacity}">
    <g fill-opacity="0.35">${star(14, 22, 62)}</g>
    <g fill="none">
      ${ring(76, 2)}${ring(82, 1)}
      ${ticks(90, 108, 5, 1.5)}
      ${ring(116, 1)}
      ${circlets(132, 36, 8, 1.5)}
      ${ring(148, 1)}${ring(154, 2)}
      ${ticks(164, 184, 3, 1.2)}
      ${ring(192, 1)}
      ${ring(236, 2)}${ring(242, 1)}
      ${circlets(262, 60, 10, 1.5)}
      ${ring(282, 1)}
      ${ticks(292, 314, 2.5, 1.2)}
      ${ring(322, 2)}
      ${ring(372, 1)}${ring(378, 2)}
      ${ticks(388, 410, 2, 1.2)}
      ${ring(418, 1)}
    </g>
  </g>`;
}

//* -------------------------------------------------------------------- SVG

/**
 * Viền: hai gạch kép ở mép trên và mép dưới, mờ dần về hai đầu, giữa có hình
 * thoi. Cố ý không có cạnh dọc — mọi chỗ hiện ảnh đều cắt bớt hai bên
 * (BoxFit.cover), một khung chữ nhật sẽ lộ ra là bị xén.
 */
function frame(): string {
  const band = (y: number, dir: 1 | -1) => `
    <line x1="0" y1="${y}" x2="${WIDTH}" y2="${y}" stroke="url(#rule)" stroke-width="1.5"/>
    <line x1="0" y1="${y + dir * 6}" x2="${WIDTH}" y2="${y + dir * 6}" stroke="url(#rule)" stroke-width="0.8"/>
    <rect x="${CX - 4.5}" y="${y + dir * 3 - 4.5}" width="9" height="9" fill="#FFFFFF" fill-opacity="0.55"
        transform="rotate(45 ${CX} ${y + dir * 3})"/>`;
  return `<g>${band(20, 1)}${band(HEIGHT - 20, -1)}
  </g>`;
}

function svg(index: number, name: string, years: string, color: string): string {
  const lines = wrapName(name);
  const font = fontFor(lines);
  const lineHeight = Math.round(font * 1.18);

  // Khối chữ: overline → (khoảng) → tên → gạch trang trí → mốc năm, căn giữa dọc.
  const OVERLINE = 17;
  const YEARS = 25;
  const GAP_OVER = 22;
  const GAP_RULE = 22;
  const GAP_YEARS = 22;
  const blockH =
    OVERLINE + GAP_OVER + lines.length * lineHeight + GAP_RULE + GAP_YEARS + YEARS;
  const top = (HEIGHT - blockH) / 2;

  const overlineY = top + OVERLINE;
  const nameTop = overlineY + GAP_OVER;
  const nameLastBaseline = nameTop + font + (lines.length - 1) * lineHeight;
  const ruleY = nameLastBaseline + GAP_RULE;
  const yearsY = ruleY + GAP_YEARS + YEARS - 4;

  const overline = `THỜI KỲ ${String(index + 1).padStart(2, '0')}`;
  // Hai gạch ngắn hai bên dòng overline; ước lượng bề rộng chữ giãn cách.
  const overlineHalf = (overline.length * OVERLINE * 0.62 + overline.length * 4) / 2;
  const nameText = lines
    .map(
      (l, i) =>
        `<text x="${CX}" y="${f(nameTop + font + i * lineHeight)}" text-anchor="middle" fill="#FFFFFF"
        font-family="${FONT_FAMILY}" font-size="${font}" font-weight="bold">${escapeXml(l)}</text>`,
    )
    .join('\n    ');

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <defs>
    <radialGradient id="vignette" cx="50%" cy="46%" r="72%">
      <stop offset="0" stop-color="#000000" stop-opacity="0"/>
      <stop offset="0.55" stop-color="#000000" stop-opacity="0.08"/>
      <stop offset="1" stop-color="#000000" stop-opacity="0.42"/>
    </radialGradient>
    <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0.55" stop-color="#000000" stop-opacity="0"/>
      <stop offset="1" stop-color="#000000" stop-opacity="0.18"/>
    </linearGradient>
    <linearGradient id="rule" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="${WIDTH}" y2="0">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0"/>
      <stop offset="0.2" stop-color="#FFFFFF" stop-opacity="0.4"/>
      <stop offset="0.8" stop-color="#FFFFFF" stop-opacity="0.4"/>
      <stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
    <filter id="lift" x="-10%" y="-30%" width="120%" height="160%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feOffset dy="2" result="blur"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.35"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>

  <rect width="${WIDTH}" height="${HEIGHT}" fill="${color}"/>
  ${drumMotif(color)}
  <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#vignette)"/>
  <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#floor)"/>

  ${frame()}

  <g filter="url(#lift)">
    <g stroke="#FFFFFF" stroke-width="1.5" stroke-opacity="0.7">
      <line x1="${f(CX - overlineHalf - 46)}" y1="${f(overlineY - 6)}" x2="${f(CX - overlineHalf - 14)}" y2="${f(overlineY - 6)}"/>
      <line x1="${f(CX + overlineHalf + 14)}" y1="${f(overlineY - 6)}" x2="${f(CX + overlineHalf + 46)}" y2="${f(overlineY - 6)}"/>
    </g>
    <text x="${CX}" y="${f(overlineY)}" text-anchor="middle" fill="#FFFFFF"
        font-family="${FONT_FAMILY}" font-size="${OVERLINE}" font-weight="bold" letter-spacing="4">${escapeXml(overline)}</text>
    ${nameText}
    <g stroke="#FFFFFF" stroke-width="1.5" stroke-opacity="0.75">
      <line x1="${CX - 92}" y1="${f(ruleY)}" x2="${CX - 14}" y2="${f(ruleY)}"/>
      <line x1="${CX + 14}" y1="${f(ruleY)}" x2="${CX + 92}" y2="${f(ruleY)}"/>
    </g>
    <rect x="${CX - 5}" y="${f(ruleY - 5)}" width="10" height="10" fill="#FFFFFF" fill-opacity="0.85"
        transform="rotate(45 ${CX} ${f(ruleY)})"/>
    <text x="${CX}" y="${f(yearsY)}" text-anchor="middle" fill="#FFFFFF"
        font-family="${FONT_FAMILY}" font-size="${YEARS}" letter-spacing="1.5">${escapeXml(years)}</text>
  </g>
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

  const lowContrast = COLORS.map((c) => [c, worstTextContrast(c)] as const).filter(
    ([, ratio]) => ratio < MIN_CONTRAST,
  );
  if (lowContrast.length) {
    throw new Error(
      `Chữ trắng dưới ${MIN_CONTRAST}:1 trên: ${lowContrast
        .map(([c, r]) => `${c} (${r.toFixed(2)})`)
        .join(', ')}`,
    );
  }

  fs.mkdirSync(OUT_DIR, { recursive: true });

  // App dùng CachedNetworkImage (raster) nên chỉ ghi PNG; dọn .svg cũ để thư
  // mục không mang cả hai bản.
  for (const file of fs.readdirSync(OUT_DIR)) {
    if (file.endsWith('.svg')) fs.unlinkSync(path.join(OUT_DIR, file));
  }

  for (let i = 0; i < periods.length; i++) {
    const p = periods[i];
    const file = path.join(OUT_DIR, `${p.id}.png`);
    const markup = svg(i, p.name, `${p.start} – ${p.end}`, COLORS[i]);
    await sharp(Buffer.from(markup)).png().toFile(file);
    console.log(
      `Đã ghi ${file} (chữ trắng >= ${worstTextContrast(COLORS[i]).toFixed(2)}:1)`,
    );
  }
  console.log(`Xong ${periods.length} ảnh.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
