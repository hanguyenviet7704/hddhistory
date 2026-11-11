import Link from 'next/link';
import { notFound } from 'next/navigation';

import { JobProgress } from '@/components/import/job-progress';
import { Notice } from '@/components/section';
import { ApiError } from '@/lib/api';
import { getImportJob, type ImportJob } from '@/lib/learning-import';

export default async function ImportGeneratingPage({
  params,
}: {
  params: Promise<{ jobId: string }>;
}) {
  const { jobId } = await params;
  // Id sai định dạng làm API trả 500 (CastError của Mongoose) thay vì 404 —
  // chặn trước để người dùng thấy "không tìm thấy" chứ không phải "máy chủ lỗi".
  if (!/^[0-9a-f]{24}$/i.test(jobId)) notFound();

  let job: ImportJob;
  try {
    job = await getImportJob(jobId);
  } catch (error) {
    // API chỉ trả job của chính người gọi; job của người khác cũng là 404.
    if (error instanceof ApiError && error.status === 404) {
      notFound();
    }
    return (
      <div className="pt-5">
        <Notice>
          Không tải được tiến trình tạo bài.{' '}
          {error instanceof Error ? error.message : ''}
        </Notice>
      </div>
    );
  }

  return (
    <div className="pt-5">
      <Link
        href="/bai-cua-toi"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Bài tôi tạo
      </Link>
      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        Đang tạo bài học
      </h1>
      {job.sourceLabel ? (
        <p className="mt-1 truncate text-sm text-ink-muted">
          {job.sourceType === 'pdf' ? 'PDF' : 'YouTube'} · {job.sourceLabel}
        </p>
      ) : null}
      {/* key: một job khác (điều hướng giữa hai màn chờ) phải bắt đầu poll lại từ đầu. */}
      <JobProgress key={job.id} initial={job} />
    </div>
  );
}
