import Link from 'next/link';

import { Notice, SectionHeader } from '@/components/section';
import { LogoutButton } from '@/components/logout-button';
import { request } from '@/lib/api';
import { getSessionUser } from '@/lib/session';

interface Me {
  _id?: string;
  name?: string;
  email?: string;
  avatar?: string;
  premium?: boolean;
}

export default async function ProfilePage() {
  const session = await getSessionUser();
  // Hồ sơ đầy đủ lấy từ API; cookie chỉ giữ đủ để dựng khung.
  const me = await request<Me>('/api/v1/users/me').catch(() => null);

  const name = me?.name || session?.name || '';
  const email = me?.email || session?.email || '';

  return (
    <div className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Hồ sơ
      </h1>

      <div className="mt-4 rounded-xl border border-hairline bg-surface p-4">
        <p className="text-lg font-semibold text-ink">{name || 'Người học'}</p>
        {email ? <p className="text-sm text-ink-muted">{email}</p> : null}
        {me === null ? (
          <p className="mt-2 text-sm text-ink-faint">
            Không tải được hồ sơ từ máy chủ — đang hiện thông tin lưu trong phiên.
          </p>
        ) : null}
      </div>

      <SectionHeader title="Học tập" />
      <Link
        href="/tien-do"
        className="flex items-center gap-3 rounded-xl border border-hairline bg-surface p-4 transition hover:border-brand-200"
      >
        <span className="flex-1">
          <span className="block font-semibold text-ink">Tiến độ</span>
          <span className="block text-sm text-ink-muted">
            Chuỗi ngày học, thành tích theo kỹ năng, nhật ký học tập
          </span>
        </span>
        <span aria-hidden className="text-brand-700">
          →
        </span>
      </Link>

      <SectionHeader title="Chưa có trên web" />
      <Notice>
        Mua gói, thông báo đẩy, bài tập nói (ghi âm) và widget màn hình chính chỉ
        chạy trên ứng dụng di động.
      </Notice>

      <div className="mt-6">
        <LogoutButton />
      </div>
    </div>
  );
}
