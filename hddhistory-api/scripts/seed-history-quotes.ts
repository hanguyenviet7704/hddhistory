/**
 * Đổ câu trích lịch sử Việt Nam vào collection `quotes`, để
 * `GET /api/v1/courses-quotes/random` có dữ liệu thay vì 404 — khi 404 app rơi
 * về câu dự phòng đóng gói sẵn (một câu tâm lý học còn sót từ sản phẩm cũ).
 *
 * Dữ liệu ở `scripts/data/history-quotes.json`. Schema `Quote` không có trường
 * tác giả/nguồn, nên nguồn nằm ngay trong `content.vi`, sau dấu gạch ngang dài
 * (" — Nguyễn Trãi, Bình Ngô đại cáo"). Không tự thêm dấu ngoặc kép: widget
 * `HomeQuote` bên Flutter đã tự bọc “…”.
 *
 * Idempotent theo kiểu *chèn-nếu-thiếu*, khớp theo `content.vi`: câu đã có thì
 * bỏ qua, KHÔNG ghi đè (giữ nguyên chỉnh sửa của admin), nên chạy lần hai tạo
 * đúng 0 bản ghi. Sửa chữ một câu trong JSON rồi chạy lại sẽ tạo câu mới bên
 * cạnh câu cũ — muốn thay thì xoá câu cũ ở admin trước.
 *
 * Script ghi thẳng Mongo nên không xoá được cache của `QuoteRepository` (pool
 * câu trích sống 5 phút trong bộ nhớ API): API thấy câu mới sau tối đa 5 phút,
 * hoặc ngay khi khởi động lại.
 *
 * Chạy:
 *   npm run seed:history-quotes
 *   npm run seed:history-quotes -- --dry-run   (chỉ kiểm dữ liệu, không ghi)
 *
 * Đọc MONGODB_URI từ env/.env
 */
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';

import mongoose from 'mongoose';

import { QuoteSchema } from '../src/modules/courses/src/modules/quotes/schema/quote.schema';

const DATA_FILE = path.join(process.cwd(), 'scripts/data/history-quotes.json');

/** Đủ ngắn để đọc trên điện thoại, tính cả phần nguồn. */
const MAX_LENGTH = 200;
const ATTRIBUTION_SEPARATOR = ' — ';

interface HistoryQuotesFile {
  backgroundColor: string;
  textColor: string;
  quotes: string[];
}

function validate(data: HistoryQuotesFile): string[] {
  const errors: string[] = [];
  const hex = /^#[0-9A-Fa-f]{6}$/;
  if (!hex.test(data.backgroundColor ?? ''))
    errors.push(`backgroundColor không phải mã #RRGGBB: ${data.backgroundColor}`);
  if (!hex.test(data.textColor ?? ''))
    errors.push(`textColor không phải mã #RRGGBB: ${data.textColor}`);
  if (!Array.isArray(data.quotes) || !data.quotes.length)
    errors.push('quotes rỗng');

  const seen = new Set<string>();
  (data.quotes ?? []).forEach((raw, i) => {
    const label = `#${i + 1}`;
    const text = typeof raw === 'string' ? raw : '';
    if (text !== text.trim()) errors.push(`${label}: thừa khoảng trắng đầu/cuối`);
    const at = text.lastIndexOf(ATTRIBUTION_SEPARATOR);
    if (at <= 0 || !text.slice(at + ATTRIBUTION_SEPARATOR.length).trim())
      errors.push(`${label}: thiếu nguồn sau "${ATTRIBUTION_SEPARATOR.trim()}"`);
    if ([...text].length > MAX_LENGTH)
      errors.push(`${label}: dài ${[...text].length} ký tự (tối đa ${MAX_LENGTH})`);
    if (/^["“”'‘]|["“”'’]$/.test(text))
      errors.push(`${label}: đừng tự thêm dấu ngoặc kép, app đã bọc sẵn`);
    if (seen.has(text)) errors.push(`${label}: trùng câu phía trên`);
    seen.add(text);
  });
  return errors;
}

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const data: HistoryQuotesFile = JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8'));

  const errors = validate(data);
  if (errors.length) {
    console.error(`history-quotes.json có ${errors.length} lỗi:`);
    errors.forEach((e) => console.error(`  - ${e}`));
    process.exit(1);
  }
  console.log(`Dữ liệu: ${data.quotes.length} câu trích.`);

  if (dryRun) {
    console.log('--dry-run: không ghi gì vào Mongo.');
    return;
  }

  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong .env');

  // Chờ tối đa 5 giây rồi báo lỗi, thay vì treo vô hạn khi quên bật Docker.
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });

  const Quote = mongoose.model('Quote', QuoteSchema);

  let created = 0;
  let skipped = 0;
  for (const text of data.quotes) {
    const found = await Quote.exists({ 'content.vi': text });
    if (found) {
      skipped++;
      continue;
    }
    await Quote.create({
      content: { vi: text },
      backgroundColor: data.backgroundColor,
      textColor: data.textColor,
    });
    created++;
  }

  const total = await Quote.countDocuments({});
  console.log(
    `Xong. Tạo mới ${created}, bỏ qua vì đã có ${skipped}. Collection quotes hiện có ${total} câu.`,
  );
  await mongoose.disconnect();
}

main().catch(async (e) => {
  console.error('Seed câu trích lịch sử thất bại:', e.message);
  await mongoose.disconnect().catch(() => undefined);
  process.exit(1);
});
