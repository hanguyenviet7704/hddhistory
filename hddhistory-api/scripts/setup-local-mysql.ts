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
 * GIỚI HẠN: schema dựng ra khớp production về BẢNG và CỘT, nhưng KHÔNG khớp
 * về mọi INDEX có tên. Ba migration (`AddPurchaseLogicSaleId`,
 * `AddPurchaseEnteredCode`, `AddPurchasePaywallExperiment`) tạo các index đặt
 * tên riêng (`IDX_iap_purchases_logic_sale_id`, `IDX_iap_purchases_entered_code`,
 * `IDX_iap_purchases_paywall_experiment`) mà `purchase.entity.ts` không khai
 * báo bằng `@Index` — `synchronize` vì vậy không dựng lại chúng. Đây là giới
 * hạn được chấp nhận: các index đó chỉ ảnh hưởng hiệu năng trên bảng payment
 * mà máy dev này không truy vấn, và database local chỉ tồn tại để app boot
 * được, không phải bản sao chính xác của production.
 *
 * PHÁ HUỶ: `dropSchema: true` xoá sạch database trước khi dựng lại. Chỉ chạy
 * trên MySQL local. Script chặn theo hai lớp: (1) MYSQL_HOST phải là
 * localhost/127.0.0.1, và (2) phải tự tay đặt `CONFIRM_DROP_LOCAL_DB=1` — lớp
 * host một mình không đủ, vì `ssh -L 3306:prod-db:3306` hay
 * `kubectl port-forward` có thể đặt một database production thật đằng sau
 * đúng chuỗi "localhost" đó mà không cảnh báo gì.
 *
 * Chạy: CONFIRM_DROP_LOCAL_DB=1 npm run setup:local-mysql
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

  const port = process.env.MYSQL_PORT;
  const database = process.env.MYSQL_DB;
  console.log(
    `Chuẩn bị XOÁ SẠCH và dựng lại: host=${host} port=${port} database=${database}`,
  );

  if (process.env.CONFIRM_DROP_LOCAL_DB !== '1') {
    throw new Error(
      'MYSQL_HOST là localhost không đủ để đảm bảo an toàn — một tunnel SSH ' +
        '(ssh -L 3306:prod-db:3306) hoặc kubectl port-forward có thể đặt một ' +
        'database production thật đằng sau đúng chuỗi "localhost" này. ' +
        `Xác nhận rõ ràng bạn muốn xoá sạch host=${host} port=${port} ` +
        `database=${database} bằng cách chạy lại với ` +
        'CONFIRM_DROP_LOCAL_DB=1, ví dụ: ' +
        'CONFIRM_DROP_LOCAL_DB=1 npm run setup:local-mysql. Dừng.',
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
