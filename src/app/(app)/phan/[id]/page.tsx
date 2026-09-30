import { notFound } from 'next/navigation';

import { DocumentBody } from '@/components/content-blocks';
import { Notice } from '@/components/section';
import { ApiError } from '@/lib/api';
import { text } from '@/lib/content';
import {
  getKeypoint,
  getLearningItems,
  type LearningItem,
} from '@/lib/learning';

/** Nhãn tiếng Việt cho từng loại learning item. */
const TYPE_LABELS: Record<string, string> = {
  theory: 'Lý thuyết',
  exercise: 'Bài tập',
  roleplay: 'Đóng vai',
  video: 'Video',
};

export default async function KeypointPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  let keypoint;
  try {
    keypoint = await getKeypoint(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  const items = await getLearningItems(id).then(
    (page) => page.items,
    () => null,
  );

  return (
    <article className="pt-5">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        {text(keypoint.title) || 'Nội dung'}
      </h1>
      {keypoint.estimateCompleTimeNumber ? (
        <p className="mt-1 text-sm text-ink-faint">
          ~{keypoint.estimateCompleTimeNumber} phút
        </p>
      ) : null}
      {text(keypoint.description) ? (
        <p className="mt-3 leading-relaxed text-ink">
          {text(keypoint.description)}
        </p>
      ) : null}

      <div className="mt-6 space-y-6">
        {items === null ? (
          <Notice>Không tải được nội dung phần này.</Notice>
        ) : items.length === 0 ? (
          <Notice>Phần này chưa có nội dung.</Notice>
        ) : (
          items.map((item) => <ItemBlock key={item._id} item={item} />)
        )}
      </div>
    </article>
  );
}

function ItemBlock({ item }: { item: LearningItem }) {
  const label = TYPE_LABELS[item.type ?? ''] ?? 'Nội dung';
  const documents = item.documents ?? [];
  const questionCount = item.questions?.length ?? 0;

  return (
    <section className="rounded-xl border border-hairline bg-surface p-4">
      <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
        {label}
      </p>
      {text(item.title) ? (
        <h2 className="mt-1 text-lg font-semibold text-ink">
          {text(item.title)}
        </h2>
      ) : null}

      {documents.map((document, index) => (
        <DocumentBody key={document.id ?? index} document={document} />
      ))}

      {/* Bài tập và đóng vai cần chấm điểm, ghi âm và luồng trả lời riêng —
          web mới chỉ đọc được nội dung, nên nói rõ thay vì hiện một khối
          trống không giải thích gì. */}
      {documents.length === 0 && questionCount > 0 ? (
        <p className="mt-2 text-sm text-ink-muted">
          Phần này có {questionCount} câu hỏi. Làm bài trên ứng dụng di động.
        </p>
      ) : null}
      {documents.length === 0 && questionCount === 0 ? (
        <p className="mt-2 text-sm text-ink-faint">
          Nội dung này chỉ có trên ứng dụng di động.
        </p>
      ) : null}
    </section>
  );
}
