import Link from 'next/link';

import { EntityTile } from '@/components/entity-tile';
import { SearchField } from '@/components/search-field';
import { ApiError } from '@/lib/api';
import {
  ENTITY_TYPES,
  TYPE_COLORS,
  TYPE_LABELS,
  matchedAlias,
  periodRange,
  type KgEntitySummary,
  type KgOverview,
} from '@/lib/kg';
import { getOverview, searchEntities } from '@/lib/knowledge-graph';

type Params = { q?: string; loai?: string; 'thoi-ky'?: string };

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<Params>;
}) {
  const params = await searchParams;
  const q = typeof params.q === 'string' ? params.q : '';
  // Tham số URL gõ tay được: loại lạ thì bỏ qua thay vì để API trả 400.
  const type = ENTITY_TYPES.find((t) => t === params.loai);
  const periodId =
    typeof params['thoi-ky'] === 'string' ? params['thoi-ky'] : undefined;
  const browsing = Boolean(q.trim() || type || periodId);

  // Mục lục luôn tải (rẻ, cache 5 phút): cần cho chip thời kỳ ở cả hai chế độ.
  const [overview, results] = await Promise.all([
    getOverview().catch(() => null),
    browsing
      ? // Duyệt một thời kỳ/loại thì lấy trọn (trần 300 của API); tìm theo
        // chữ thì 50 kết quả đầu là đủ — kết quả xa hơn hiếm khi đúng ý.
        searchEntities(q, { type, periodId }, q.trim() ? 50 : 300).catch(
          (error: unknown) =>
            error instanceof ApiError ? error : new ApiError(String(error), 0),
        )
      : Promise.resolve(null),
  ]);

  const period = overview?.periods.find((p) => p.id === periodId);

  return (
    <div className="pt-6">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Tra cứu lịch sử
      </h1>
      <p className="mt-1 mb-5 text-sm text-ink-muted">
        Gõ tên một nhân vật, sự kiện, triều đại hay địa danh — cả tên gọi khác
        như &ldquo;Đức Thánh Trần&rdquo;. Không dấu vẫn ra.
      </p>

      <SearchField
        initialQuery={q}
        basePath="/tra-cuu"
        label="Tìm nhân vật, sự kiện, địa danh"
        placeholder="Tìm nhân vật, sự kiện, địa danh…"
      />

      <TypeChips current={type} params={params} overview={overview} />

      {!browsing ? (
        overview ? (
          <Overview overview={overview} />
        ) : (
          <Notice>
            Không tải được đồ thị tri thức. Kiểm tra API và Neo4j đã chạy chưa.
          </Notice>
        )
      ) : results instanceof Error ? (
        <Notice>Không tải được dữ liệu. {results.message}</Notice>
      ) : (
        <Results
          q={q}
          results={results ?? []}
          filterLabel={[period?.name, type ? TYPE_LABELS[type] : undefined]
            .filter(Boolean)
            .join(' · ')}
        />
      )}
    </div>
  );
}

/** Đổi một tham số, giữ các tham số còn lại — để lọc loại không làm mất từ khoá. */
function hrefWith(params: Params, key: keyof Params, value?: string) {
  const search = new URLSearchParams();
  for (const [k, v] of Object.entries(params)) {
    if (typeof v === 'string' && v && k !== key) search.set(k, v);
  }
  if (value) search.set(key, value);
  return search.size ? `/tra-cuu?${search.toString()}` : '/tra-cuu';
}

function TypeChips({
  current,
  params,
  overview,
}: {
  current?: string;
  params: Params;
  overview: KgOverview | null;
}) {
  const chip = (active: boolean) =>
    `inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm transition ${
      active
        ? 'bg-brand-900 font-semibold text-brand-50'
        : 'bg-surface-alt text-ink hover:bg-brand-100'
    }`;
  return (
    <nav aria-label="Lọc theo loại" className="mt-4">
      <ul className="flex flex-wrap gap-2">
        <li>
          <Link
            href={hrefWith(params, 'loai')}
            aria-current={!current ? 'page' : undefined}
            className={chip(!current)}
          >
            Tất cả
          </Link>
        </li>
        {ENTITY_TYPES.map((t) => (
          <li key={t}>
            <Link
              href={hrefWith(params, 'loai', t)}
              aria-current={current === t ? 'page' : undefined}
              className={chip(current === t)}
            >
              <span
                aria-hidden
                className="inline-block size-2 rounded-full"
                style={{ backgroundColor: TYPE_COLORS[t] }}
              />
              {TYPE_LABELS[t]}
              {overview?.totals.byType[t] ? (
                <span className="text-xs opacity-70">
                  {overview.totals.byType[t]}
                </span>
              ) : null}
            </Link>
          </li>
        ))}
      </ul>
    </nav>
  );
}

/**
 * Trang đầu khi chưa gõ gì: quy mô đồ thị và dòng thời gian các thời kỳ — để
 * người học duyệt được TOÀN BỘ dữ liệu chứ không phải đoán tên mà gõ.
 */
function Overview({ overview }: { overview: KgOverview }) {
  const { totals } = overview;
  return (
    <>
      <p className="mt-6 text-sm text-ink-muted">
        Đồ thị đang có{' '}
        <strong className="text-ink">{totals.entities}</strong> nhân vật, sự
        kiện, triều đại và địa danh, nối với nhau bằng{' '}
        <strong className="text-ink">{totals.relations}</strong> quan hệ
        {totals.claims ? (
          <>
            {' '}
            và <strong className="text-ink">{totals.claims}</strong> điểm các
            nguồn sử chưa thống nhất
          </>
        ) : null}
        .
      </p>

      <h2 className="mt-7 mb-2 text-sm font-bold tracking-wide text-brand-900 uppercase">
        Theo thời kỳ
      </h2>
      <ol className="relative space-y-2 border-l-2 border-brand-200 pl-4">
        {overview.periods.map((p) => (
          <li key={p.id} className="relative">
            <span
              aria-hidden
              className="absolute top-4 -left-[23px] size-3 rounded-full border-2 border-brand-50 bg-brand"
            />
            <Link
              href={`/tra-cuu?thoi-ky=${encodeURIComponent(p.id)}`}
              className="flex items-center gap-3 rounded-xl border border-hairline bg-surface px-4 py-3 transition hover:border-brand-200 hover:bg-brand-50"
            >
              <span className="min-w-0 flex-1">
                <span className="block font-semibold text-ink">{p.name}</span>
                {periodRange(p) ? (
                  <span className="block text-sm text-ink-muted">
                    {periodRange(p)}
                  </span>
                ) : null}
              </span>
              <span className="shrink-0 text-sm text-ink-faint">
                {p.entityCount} mục
              </span>
              <span aria-hidden className="text-brand-700">
                →
              </span>
            </Link>
          </li>
        ))}
      </ol>
    </>
  );
}

function Results({
  q,
  results,
  filterLabel,
}: {
  q: string;
  results: KgEntitySummary[];
  filterLabel: string;
}) {
  if (results.length === 0) {
    return (
      <Notice>
        {q.trim()
          ? `Không tìm thấy gì khớp với “${q}”${filterLabel ? ` trong ${filterLabel}` : ''}. Thử một tên khác, hoặc bỏ bớt bộ lọc.`
          : 'Chưa có mục nào trong phần này.'}
      </Notice>
    );
  }
  return (
    <>
      <p className="mt-6 mb-1 text-xs font-semibold tracking-wide text-ink-faint uppercase">
        {results.length} kết quả{filterLabel ? ` · ${filterLabel}` : ''}
      </p>
      <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
        {results.map((entity) => (
          <EntityTile
            key={entity.id}
            {...entity}
            // Khớp qua bí danh thì nói rõ, kẻo người học thấy "Trần Hưng Đạo"
            // khi gõ "Đức Thánh Trần" mà không hiểu vì sao.
            aliasHint={matchedAlias(entity, q)}
          />
        ))}
      </ul>
    </>
  );
}

function Notice({ children }: { children: React.ReactNode }) {
  return (
    <p className="mt-6 rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
      {children}
    </p>
  );
}
