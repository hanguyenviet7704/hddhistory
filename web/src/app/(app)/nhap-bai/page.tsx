import Link from 'next/link';

import {
  FEATURE_OFF_BODY,
  FEATURE_OFF_TITLE,
} from '@/components/import/import-copy';
import { ImportForm } from '@/components/import/import-form';
import { Notice } from '@/components/section';
import {
  getImportJobs,
  getImportQuota,
  isJobRunning,
  type ImportQuota,
} from '@/lib/learning-import';

export default async function ImportLessonPage() {
  const [quota, jobs] = await Promise.all([
    getImportQuota().then(
      (q) => q,
      () => null,
    ),
    getImportJobs(1, 1).then(
      (page) => page.items,
      () => [],
    ),
  ]);

  // API chỉ cho chạy một lượt một lúc (409). Có lượt đang chạy thì dẫn thẳng
  // về màn chờ của nó thay vì để người dùng bấm "Tạo" rồi mới bị từ chối.
  const running = jobs.find(isJobRunning) ?? null;
  const featureOff = quota !== null && !quota.enabled;
  const outOfTickets = quota !== null && quota.remaining <= 0;

  return (
    <div className="pt-5">
      <Link
        href="/bai-cua-toi"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Bài tôi tạo
      </Link>

      <div className="mt-3 flex items-start justify-between gap-3">
        <h1 className="text-2xl font-bold tracking-tight text-brand-900">
          Tự tạo bài học của bạn
        </h1>
        {quota ? <QuotaPill quota={quota} /> : null}
      </div>
      <p className="mt-2 text-ink-muted">
        Từ bất cứ nội dung nào bạn thích - một video đã lưu, cuốn sách đang đọc,
        ghi chép trên lớp.
      </p>

      {featureOff ? (
        <div role="status" className="mt-5 rounded-xl border border-hairline bg-surface-alt p-4">
          <p className="font-semibold text-brand-900">{FEATURE_OFF_TITLE}</p>
          <p className="mt-1 text-sm text-ink-muted">
            {quota.disabledNote.trim() || FEATURE_OFF_BODY}
          </p>
        </div>
      ) : null}

      {running ? (
        <div className="mt-5 rounded-xl border border-brand-200 bg-brand-50 p-4">
          <p className="font-semibold text-brand-900">Đang tạo bài học</p>
          <p className="mt-1 text-sm text-ink-muted">
            Bạn đang có một bài đang được tạo. Đợi xong rồi tạo tiếp nhé.
          </p>
          <Link
            href={`/nhap-bai/${encodeURIComponent(running.id)}`}
            className="mt-2 inline-block text-sm font-semibold text-brand-700 hover:underline"
          >
            Xem tiến trình →
          </Link>
        </div>
      ) : null}

      {quota && outOfTickets && !featureOff ? (
        <div className="mt-5">
          <Notice>
            <span className="block font-semibold text-brand-900">
              Bạn đã hết lượt
            </span>
            {quota.isPremium
              ? quota.resetsAt
                ? `Có lại ${quota.limit} lượt vào ${formatWeekday(quota.resetsAt)}.`
                : 'Bạn đã dùng hết lượt tạo bài trong tuần này.'
              : `Premium cho bạn ${quota.premiumLimit} lượt mỗi tuần để tiếp tục tự tạo bài học. Nâng cấp trong ứng dụng HDDhistory.`}
          </Notice>
        </div>
      ) : null}

      {quota === null ? (
        <p className="mt-4 text-sm text-ink-faint">
          Chưa tải được số lượt còn lại — máy chủ vẫn sẽ kiểm tra khi bạn tạo.
        </p>
      ) : null}

      <ImportForm
        disabled={featureOff || running !== null || (outOfTickets && quota !== null)}
      />

      <section className="mt-8 rounded-xl border border-hairline bg-surface p-4">
        <h2 className="text-sm font-bold tracking-wide text-brand-900 uppercase">
          Cách hoạt động
        </h2>
        <ol className="mt-2 list-decimal space-y-1 pl-5 text-sm text-ink-muted">
          <li>Dán link YouTube hoặc chọn một file PDF.</li>
          <li>Chúng tôi chia thành keypoint và bài luyện ngắn.</li>
          <li>
            Tìm lại trong{' '}
            <Link href="/bai-cua-toi" className="font-semibold text-brand-700 hover:underline">
              Bài tôi tạo
            </Link>
            , sẵn sàng để học.
          </li>
        </ol>
      </section>
    </div>
  );
}

/** "Còn 1/1 lượt" — con số người dùng cần thấy TRƯỚC khi tiêu một lượt. */
function QuotaPill({ quota }: { quota: ImportQuota }) {
  return (
    <div className="shrink-0 text-right">
      <span className="inline-block rounded-full bg-brand-100 px-3 py-1 text-sm font-semibold text-brand-900">
        Còn {quota.remaining}/{quota.limit} lượt
      </span>
      {!quota.isPremium ? (
        <p className="mt-1 max-w-[12rem] text-xs text-ink-faint">
          Premium cho bạn {quota.premiumLimit} lượt mỗi tuần.
        </p>
      ) : null}
    </div>
  );
}

/** Ngày hồi lượt luôn là đầu tuần, nên nói THỨ như app (`EEEE`) chứ không nói ngày. */
function formatWeekday(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString('vi-VN', {
    weekday: 'long',
    timeZone: 'Asia/Ho_Chi_Minh',
  });
}
