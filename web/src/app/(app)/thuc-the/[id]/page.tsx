import Link from 'next/link';
import { notFound } from 'next/navigation';

import { EntityTile, TypeBadge } from '@/components/entity-tile';
import { keypointHref, text } from '@/lib/content';
import {
  periodRange,
  relationLabel,
  TYPE_LABELS,
  type KgClaim,
  type KgEntityLesson,
  type KgRelation,
} from '@/lib/kg';
import {
  getEntityLessons,
  getEntityProfile,
  getRelatedEntities,
} from '@/lib/knowledge-graph';

export default async function EntityPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // Ba lời gọi độc lập chạy song song. Phần "có liên quan" và "bài học" là
  // phụ: hỏng thì giấu đi chứ không làm mất cả hồ sơ.
  const [profile, related, lessons] = await Promise.all([
    getEntityProfile(id),
    getRelatedEntities(id).catch(() => []),
    getEntityLessons(id).catch(() => [] as KgEntityLesson[]),
  ]);

  if (!profile) notFound();

  const claims = profile.claims ?? [];
  // Nguồn đã liệt kê ở cuối hồ sơ thì không nhắc lại ở từng quan hệ — chỉ
  // nguồn RIÊNG của quan hệ mới là thông tin thêm.
  const knownSourceIds = new Set(profile.sources.map((s) => s.id));
  const aliases = (profile.aliases ?? []).filter(
    // Tên chính thường đã chứa bí danh trong ngoặc ("Trần Hưng Đạo (Trần Quốc
    // Tuấn)") — đừng lặp lại nó ở dòng "còn gọi là".
    (alias) => !profile.name.includes(alias),
  );

  return (
    <article className="pt-6">
      <Link
        href="/tra-cuu"
        className="text-sm font-semibold text-brand-700 hover:underline"
      >
        ← Tra cứu
      </Link>

      <header className="mt-4">
        <h1 className="text-2xl font-bold tracking-tight text-brand-900">
          {profile.name}
        </h1>
        {aliases.length > 0 ? (
          <p className="mt-1 text-sm text-ink-muted">
            Còn gọi là {aliases.join(', ')}
          </p>
        ) : null}
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <TypeBadge type={profile.type} />
          {profile.date ? (
            <span className="rounded-full bg-surface-alt px-2 py-0.5 text-xs font-semibold text-ink-muted">
              {profile.date}
            </span>
          ) : null}
          {profile.period ? (
            <Link
              href={`/tra-cuu?thoi-ky=${encodeURIComponent(profile.period.id)}`}
              className="rounded-full bg-surface-alt px-2 py-0.5 text-xs font-semibold text-ink-muted transition hover:bg-brand-100"
            >
              {profile.period.name}
              {periodRange(profile.period)
                ? ` · ${periodRange(profile.period)}`
                : ''}
            </Link>
          ) : null}
        </div>
        {profile.description ? (
          <p className="mt-4 leading-relaxed text-ink">{profile.description}</p>
        ) : null}
        {profile.note ? (
          <p className="mt-3 rounded-xl bg-brand-50 p-3 text-sm leading-relaxed text-ink-muted">
            {profile.note}
          </p>
        ) : null}
      </header>

      <LessonSection lessons={lessons} />

      {/* "lãnh đạo · Trận Bạch Đằng": chủ ngữ là thực thể đang xem, nên nhãn
          quan hệ đứng trước. Ở chiều ngược lại thì tên đứng trước. */}
      <RelationSection
        title="Đã làm gì"
        relations={profile.outgoing}
        outgoing
        knownSourceIds={knownSourceIds}
      />
      <RelationSection
        title="Được nhắc tới"
        relations={profile.incoming}
        outgoing={false}
        subjectName={profile.name}
        knownSourceIds={knownSourceIds}
      />

      <ClaimSection claims={claims} />

      {related.length > 0 ? (
        <Section title="Có liên quan">
          <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
            {related.map((entity) => (
              <EntityTile
                key={entity.id}
                id={entity.id}
                type={entity.type}
                name={entity.name}
                date={entity.date}
                // Đường đi trên đồ thị thay cho mô tả: nó trả lời đúng câu hỏi
                // "sao cái này lại liên quan?", thứ mà mô tả không nói được.
                description={
                  entity.via.length
                    ? entity.via.map(relationLabel).join(' → ')
                    : entity.description
                }
                trailing={
                  <span className="shrink-0 self-start rounded-full bg-brand-50 px-2 py-0.5 text-xs font-semibold text-brand-700">
                    {entity.hops} bước
                  </span>
                }
              />
            ))}
          </ul>
        </Section>
      ) : null}

      {profile.samePeriod.length > 0 ? (
        <Section title="Cùng thời kỳ">
          <ul className="flex flex-wrap gap-2">
            {profile.samePeriod.map((entity) => (
              <li key={entity.id}>
                <Link
                  href={`/thuc-the/${encodeURIComponent(entity.id)}`}
                  className="inline-block rounded-full bg-surface-alt px-3 py-1.5 text-sm text-ink transition hover:bg-brand-100"
                >
                  {entity.name}
                  <span className="ml-1.5 text-xs text-ink-faint">
                    {TYPE_LABELS[entity.type]}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </Section>
      ) : null}

      {profile.sources.length > 0 ? (
        <Section title="Nguồn sử liệu">
          <ul className="space-y-1.5 text-sm text-ink-muted">
            {profile.sources.map((source) => (
              <li key={source.id}>
                {source.title}
                {source.note ? ` — ${source.note}` : ''}
              </li>
            ))}
          </ul>
        </Section>
      ) : null}
    </article>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="mt-7">
      <h2 className="mb-2 text-sm font-bold tracking-wide text-brand-900 uppercase">
        {title}
      </h2>
      {children}
    </section>
  );
}

/**
 * Quan hệ gom theo loại: "Lãnh đạo: A, B, C" đọc nhanh hơn ba dòng lặp lại
 * chữ "lãnh đạo". Mỗi quan hệ vẫn mang ghi chú và nguồn riêng của nó.
 */
function RelationSection({
  title,
  relations,
  outgoing,
  subjectName,
  knownSourceIds,
}: {
  title: string;
  relations: KgRelation[];
  outgoing: boolean;
  knownSourceIds: Set<string>;
  /** Tên thực thể đang xem — làm tân ngữ cho tiêu đề nhóm ở chiều ngược. */
  subjectName?: string;
}) {
  if (relations.length === 0) return null;

  const groups = new Map<string, KgRelation[]>();
  for (const relation of relations) {
    const list = groups.get(relation.relation) ?? [];
    list.push(relation);
    groups.set(relation.relation, list);
  }

  return (
    <Section title={title}>
      <div className="space-y-3">
        {[...groups.entries()].map(([type, items]) => (
          <div key={type}>
            <h3 className="mb-1 text-sm font-semibold text-ink-muted">
              {/* Chiều xuôi: "Lãnh đạo" + danh sách đối tượng. Chiều ngược:
                  "Phụng sự Nhà Trần" + danh sách những ai phụng sự. */}
              {outgoing
                ? capitalize(relationLabel(type))
                : `${capitalize(relationLabel(type))} ${subjectName ?? ''}`}
            </h3>
            <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
              {items.map((relation) => (
                <EntityTile
                  key={`${relation.relation}-${relation.entity.id}`}
                  id={relation.entity.id}
                  type={relation.entity.type}
                  name={relation.entity.name}
                  date={relation.entity.date}
                  description={
                    [
                      relation.entity.description,
                      relation.note ? `Ghi chú: ${relation.note}` : undefined,
                      extraSources(relation, knownSourceIds),
                    ]
                      .filter(Boolean)
                      .join(' · ') || undefined
                  }
                />
              ))}
            </ul>
          </div>
        ))}
      </div>
    </Section>
  );
}

/** Điều các nguồn sử chưa thống nhất — để người học thấy sử học có tranh luận. */
function ClaimSection({ claims }: { claims: KgClaim[] }) {
  if (claims.length === 0) return null;
  return (
    <Section title="Các nguồn chưa thống nhất">
      <ul className="space-y-3">
        {claims.map((claim) => (
          <li
            key={claim.id}
            className="rounded-xl border border-hairline bg-surface p-4"
          >
            <p className="font-semibold text-ink">{claim.description}</p>
            <ul className="mt-2 space-y-2">
              {claim.positions.map((position, index) => (
                <li
                  key={`${position.source.id}-${index}`}
                  className="border-l-2 border-brand-200 pl-3 text-sm"
                >
                  <span className="block font-semibold text-brand-700">
                    {position.source.title}
                  </span>
                  <span className="text-ink-muted">{position.text}</span>
                </li>
              ))}
            </ul>
          </li>
        ))}
      </ul>
    </Section>
  );
}

/** Bài học nhắc tới thực thể — lối từ tra cứu đi thẳng vào chỗ học. */
function LessonSection({ lessons }: { lessons: KgEntityLesson[] }) {
  if (lessons.length === 0) return null;
  return (
    <Section title="Học về chủ đề này">
      <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
        {lessons.map((lesson) => {
          const first = lesson.keypoints[0];
          return (
            <li key={lesson.lessonId}>
              <Link
                href={
                  first
                    ? keypointHref(first._id, lesson.lessonId)
                    : `/bai-hoc/${encodeURIComponent(lesson.lessonId)}`
                }
                className="flex items-center gap-3 px-4 py-3 transition hover:bg-brand-50"
              >
                <span className="min-w-0 flex-1">
                  <span className="block font-semibold text-ink">
                    {text(lesson.lessonTitle) || 'Bài học'}
                  </span>
                  <span className="block text-sm text-ink-muted">
                    {text(lesson.courseTitle)}
                    {lesson.keypoints.length > 1
                      ? ` · ${lesson.keypoints.length} phần nhắc tới`
                      : ''}
                  </span>
                </span>
                <span aria-hidden className="text-brand-700">
                  →
                </span>
              </Link>
            </li>
          );
        })}
      </ul>
    </Section>
  );
}

function extraSources(
  relation: KgRelation,
  known: Set<string>,
): string | undefined {
  const extra = (relation.sources ?? []).filter((s) => !known.has(s.id));
  return extra.length
    ? `Nguồn: ${extra.map((s) => s.title).join(', ')}`
    : undefined;
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}
