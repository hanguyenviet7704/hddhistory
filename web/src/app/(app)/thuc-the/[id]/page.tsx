import Link from 'next/link';
import { notFound } from 'next/navigation';

import { EntityTile, TypeBadge } from '@/components/entity-tile';
import { getEntityProfile, getRelatedEntities } from '@/lib/knowledge-graph';
import {
  periodRange,
  relationLabel,
  TYPE_LABELS,
  type KgRelation,
} from '@/lib/kg';

export default async function EntityPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  // Hồ sơ và danh sách liên quan chạy song song: hai lời gọi độc lập nhau, nối
  // tiếp chỉ nhân đôi thời gian chờ mà không đổi lại được gì.
  const [profile, related] = await Promise.all([
    getEntityProfile(id),
    // Phần "có liên quan" là phụ; hỏng thì giấu đi chứ không làm mất cả hồ sơ.
    getRelatedEntities(id).catch(() => []),
  ]);

  if (!profile) notFound();

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
        <div className="mt-2 flex flex-wrap items-center gap-2">
          <TypeBadge type={profile.type} />
          {profile.period ? (
            <span className="rounded-full bg-surface-alt px-2 py-0.5 text-xs font-semibold text-ink-muted">
              {profile.period.name}
              {periodRange(profile.period)
                ? ` · ${periodRange(profile.period)}`
                : ''}
            </span>
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

      {/* "lãnh đạo · Trận Bạch Đằng": chủ ngữ là nhân vật đang xem, nên nhãn
          quan hệ đứng trước. Ở chiều ngược lại thì tên đứng trước. */}
      <RelationSection
        title="Đã làm gì"
        relations={profile.outgoing}
        labelFirst
      />
      <RelationSection
        title="Được nhắc tới"
        relations={profile.incoming}
        labelFirst={false}
      />

      {related.length > 0 ? (
        <Section title="Có liên quan">
          <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
            {related.map((entity) => (
              <EntityTile
                key={entity.id}
                id={entity.id}
                type={entity.type}
                name={entity.name}
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

function RelationSection({
  title,
  relations,
  labelFirst,
}: {
  title: string;
  relations: KgRelation[];
  labelFirst: boolean;
}) {
  if (relations.length === 0) return null;
  return (
    <Section title={title}>
      <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
        {relations.map((relation) => (
          <EntityTile
            key={`${relation.relation}-${relation.entity.id}`}
            id={relation.entity.id}
            type={relation.entity.type}
            name={
              labelFirst
                ? `${relationLabel(relation.relation)} · ${relation.entity.name}`
                : `${relation.entity.name} · ${relationLabel(relation.relation)}`
            }
            description={relation.entity.description}
          />
        ))}
      </ul>
    </Section>
  );
}
