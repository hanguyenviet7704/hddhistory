/**
 * Tạo một user dev để `POST /api/v1/auth/dev-login` có cái mà đăng nhập.
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
