import Link from 'next/link';
import { notFound } from 'next/navigation';

import { DocumentBody } from '@/components/content-blocks';
import { CompleteKeypointForm } from '@/components/learning/complete-keypoint-form';
import { QuotaWall } from '@/components/learning/quota-wall';
import { SaveCardButton } from '@/components/learning/save-card-button';
import { ExerciseItem } from '@/components/practice/exercise-item';
import { Notice } from '@/components/section';
import { ApiError } from '@/lib/api';
import {
  getLesson,
  getRoadmap,
  keypointHref,
  roadmapStops,
  stopNeighbours,
  text,
  type LessonDetail,
  type MultiLang,
} from '@/lib/content';
import {
  getKeypoint,
  getKeypointAccess,
  getLearningItems,
  getSavedCardIds,
  resolveTakeaway,
  type LearningDocument,
  type LearningItem,
} from '@/lib/learning';

/** Nhãn tiếng Việt cho từng loại learning item. */
const TYPE_LABELS: Record<string, string> = {
  theory: 'Lý thuyết',
  exercise: 'Bài tập',
  roleplay: 'Đóng vai',
  video: 'Video',
};

/** Một chặng của trình đọc: một trang tài liệu, hoặc một khối bài tập. */
type Piece =
  | {
      kind: 'card';
      item: LearningItem;
      document: LearningDocument;
      first: boolean;
    }
  | { kind: 'exercise'; item: LearningItem };

export default async function KeypointPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  /**
   * `bai` = bài học chứa keypoint. Keypoint không tự biết mình thuộc bài nào
   * (API không trả và không có bộ lọc ngược), mà ghi tiến độ thì bắt buộc
   * phải có bài và khoá — nên mọi liên kết vào trình đọc mang theo nó.
   */
  searchParams: Promise<{ bai?: string }>;
}) {
  const { id } = await params;
  const { bai: lessonId } = await searchParams;

  let keypoint;
  try {
    keypoint = await getKeypoint(id);
  } catch (error) {
    if (error instanceof ApiError && error.status === 404) notFound();
    throw error;
  }

  const [items, access, lesson, savedCardIds] = await Promise.all([
    getLearningItems(id).then(
      (page) => page.items,
      () => null,
    ),
    getKeypointAccess(id),
    lessonId
      ? getLesson(lessonId).catch(() => null)
      : Promise.resolve<LessonDetail | null>(null),
    getSavedCardIds().catch(() => null),
  ]);

  const courseId = lesson?.courseId;
  const roadmap = courseId
    ? await getRoadmap(courseId).catch(() => null)
    : null;

  // Trước/sau theo lộ trình (sang được bài kế); không có lộ trình thì đi
  // trong phạm vi bài học.
  const stops = roadmapStops(roadmap);
  let { previous, next } = stopNeighbours(stops, id);
  if (!stops.length && lesson?.keypoints?.length) {
    const own = lesson.keypoints.map((k) => ({ lesson, keypoint: k }));
    ({ previous, next } = stopNeighbours(own, id));
  }
  const status = lesson?.keypoints?.find((k) => k._id === id)?.progess;

  // Dựng chặng đọc như app: theory thành từng thẻ một trang; phần tóm tắt ở
  // cuối gập vào thẻ tóm tắt thay vì lặp lại thành thẻ riêng.
  const takeaway = resolveTakeaway(items ?? []);
  const pieces: Piece[] = [];
  (items ?? []).forEach((item, index) => {
    if (takeaway.hidden.has(index)) return;
    if ((item.questions?.length ?? 0) > 0) {
      pieces.push({ kind: 'exercise', item });
      return;
    }
    (item.documents ?? []).forEach((document, docIndex) => {
      pieces.push({ kind: 'card', item, document, first: docIndex === 0 });
    });
  });

  // Hạn mức miễn phí: server nói thẻ cao nhất được đọc tới. Bài tập không
  // tính là thẻ (app đã bỏ luồng bài tập khỏi bộ thẻ), chỉ trang tài liệu.
  const cap = access?.cardCap ?? null;
  let cardIndex = -1;
  let walled = false;
  const visible = pieces.filter((piece) => {
    if (walled) return false;
    if (piece.kind === 'card') {
      cardIndex += 1;
      if (cap !== null && cardIndex > cap) {
        walled = true;
        return false;
      }
    }
    return true;
  });

  const recap: MultiLang | undefined =
    takeaway.text ?? keypoint.description ?? undefined;
  const recapText = text(recap);

  return (
    <article className="pt-5">
      {lesson ? (
        <Link
          href={`/bai-hoc/${encodeURIComponent(lesson._id)}`}
          className="text-sm font-semibold text-brand-700 hover:underline"
        >
          ← {text(lesson.title) || 'Bài học'}
        </Link>
      ) : null}

      <h1 className="mt-3 text-2xl font-bold tracking-tight text-brand-900">
        {text(keypoint.title) || 'Nội dung'}
      </h1>
      <p className="mt-1 text-sm text-ink-faint">
        {status === 'done' ? 'Đã xong' : 'Chưa xong'}
        {keypoint.estimateCompleTimeNumber
          ? ` · ~${keypoint.estimateCompleTimeNumber} phút`
          : ''}
      </p>
      {text(keypoint.description) ? (
        <p className="mt-3 leading-relaxed text-ink">
          {text(keypoint.description)}
        </p>
      ) : null}

      <div className="mt-6 space-y-4">
        {items === null ? (
          <Notice>Không tải được nội dung phần này.</Notice>
        ) : pieces.length === 0 ? (
          <Notice>Phần này chưa có nội dung.</Notice>
        ) : (
          visible.map((piece, index) =>
            piece.kind === 'card' ? (
              <section
                key={`${piece.item._id}-${piece.document.id ?? index}`}
                className="rounded-xl border border-hairline bg-surface p-4"
              >
                {piece.first ? (
                  <>
                    <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
                      {TYPE_LABELS[piece.item.type ?? ''] ?? 'Nội dung'}
                    </p>
                    {text(piece.item.title) ? (
                      <h2 className="mt-1 text-lg font-semibold text-ink">
                        {text(piece.item.title)}
                      </h2>
                    ) : null}
                  </>
                ) : null}
                <DocumentBody document={piece.document} />
              </section>
            ) : (
              <section
                key={piece.item._id}
                className="rounded-xl border border-hairline bg-surface p-4"
              >
                <p className="text-xs font-bold tracking-wide text-brand-700 uppercase">
                  {TYPE_LABELS[piece.item.type ?? ''] ?? 'Bài tập'}
                </p>
                {text(piece.item.title) ? (
                  <h2 className="mt-1 text-lg font-semibold text-ink">
                    {text(piece.item.title)}
                  </h2>
                ) : null}
                <ExerciseItem
                  item={piece.item}
                  context={{ courseId, lessonId: lesson?._id, keypointId: id }}
                />
              </section>
            ),
          )
        )}

        {walled ? <QuotaWall keypointId={id} /> : null}
      </div>

      {/* Thẻ tóm tắt và nút hoàn thành chỉ hiện khi đã đọc được tới cuối —
          sau bức tường hạn mức thì chưa có gì để tóm tắt hay hoàn thành. */}
      {!walled && items !== null && pieces.length > 0 ? (
        <>
          {recapText ? (
            <section className="mt-6 rounded-xl border border-brand-200 bg-brand-50 p-4">
              <div className="flex items-start justify-between gap-3">
                <h2 className="font-bold text-brand-900">Bỏ túi ngay</h2>
                {savedCardIds ? (
                  <SaveCardButton
                    card={{
                      keypointId: id,
                      lessonId: lesson?._id,
                      courseId,
                      recap,
                      recapText,
                    }}
                    saved={savedCardIds.includes(id)}
                  />
                ) : null}
              </div>
              <p className="mt-2 leading-relaxed whitespace-pre-line text-ink">
                {recapText}
              </p>
            </section>
          ) : null}

          <div className="mt-6">
            {lesson ? (
              <CompleteKeypointForm
                keypointId={id}
                lessonId={lesson._id}
                done={status === 'done'}
              />
            ) : (
              <Notice>
                Mở phần này từ lộ trình khoá học để lưu tiến độ học.
              </Notice>
            )}
          </div>
        </>
      ) : null}

      {previous || next ? (
        <nav
          aria-label="Chuyển phần học"
          className="mt-6 flex flex-wrap justify-between gap-3 text-sm"
        >
          {previous ? (
            <Link
              href={keypointHref(previous.keypoint._id, previous.lesson._id)}
              className="font-semibold text-brand-700 hover:underline"
            >
              ← {text(previous.keypoint.title) || 'Phần trước'}
            </Link>
          ) : (
            <span />
          )}
          {next ? (
            <Link
              href={keypointHref(next.keypoint._id, next.lesson._id)}
              className="text-right font-semibold text-brand-700 hover:underline"
            >
              {text(next.keypoint.title) || 'Phần sau'} →
            </Link>
          ) : null}
        </nav>
      ) : null}
    </article>
  );
}
