import Link from 'next/link';

import { AvatarEditor } from '@/components/account/avatar-editor';
import { NameForm } from '@/components/account/name-form';
import { Notice } from '@/components/section';
import { getMe } from '@/lib/account';
import { getSessionUser } from '@/lib/session';

/**
 * Sửa hồ sơ — đúng phạm vi màn `ProfileInfoRoute` của app: tên và ảnh đại
 * diện. Tuổi/giới tính có trong API nhưng app chỉ hỏi lúc onboarding, không cho
 * sửa ở đây, nên web cũng không.
 */
export default async function ProfileInfoPage() {
  const [session, me] = await Promise.all([
    getSessionUser(),
    getMe().catch(() => null),
  ]);

  return (
    <div className="pt-5">
      <Link
        href="/ho-so"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Hồ sơ
      </Link>
      <h1 className="mt-2 text-2xl font-bold tracking-tight text-brand-900">
        Thông tin cá nhân
      </h1>

      {me === null ? (
        <div className="mt-4">
          <Notice>Không tải được hồ sơ. Tải lại trang để thử lại.</Notice>
        </div>
      ) : (
        <div className="mt-4 space-y-6 rounded-xl border border-hairline bg-surface p-4">
          <AvatarEditor avatar={me.avatar} name={me.name || session?.name} />
          <NameForm
            name={me.name || session?.name || ''}
            email={me.email || session?.email || ''}
          />
        </div>
      )}
    </div>
  );
}
