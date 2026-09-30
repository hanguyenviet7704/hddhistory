import { ApiError } from '@/lib/api';
import { searchEntities } from '@/lib/knowledge-graph';
import type { KgEntitySummary } from '@/lib/kg';
import { EntityTile } from '@/components/entity-tile';
import { SearchField } from '@/components/search-field';

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q = '' } = await searchParams;

  let results: KgEntitySummary[];
  let failure: string | null = null;
  try {
    results = await searchEntities(q);
  } catch (error) {
    // Hỏng API là chuyện thường gặp ở máy cá nhân (chưa bật server, Neo4j
    // chưa lên). Nói thẳng lỗi ra màn hình thay vì để trang trắng — người đang
    // dựng demo cần biết phải bật cái gì.
    failure = error instanceof ApiError ? error.message : String(error);
    results = [];
  }

  return (
    <div className="pt-6">
      <h1 className="text-2xl font-bold tracking-tight text-brand-900">
        Tra cứu lịch sử
      </h1>
      <p className="mt-1 mb-5 text-sm text-ink-muted">
        Gõ tên một nhân vật, sự kiện, triều đại hay địa danh. Không dấu vẫn ra —
        &ldquo;tran hung dao&rdquo; tìm được &ldquo;Trần Hưng Đạo&rdquo;.
      </p>

      <SearchField
        initialQuery={q}
        basePath="/tra-cuu"
        label="Tìm nhân vật, sự kiện, địa danh"
        placeholder="Tìm nhân vật, sự kiện, địa danh…"
      />

      {failure ? (
        <p className="mt-6 rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
          Không tải được dữ liệu. {failure}
        </p>
      ) : results.length === 0 ? (
        <p className="mt-6 rounded-xl border border-hairline bg-surface p-4 text-sm text-ink-muted">
          Không tìm thấy thực thể nào khớp với &ldquo;{q}&rdquo;. Thử một tên
          khác, hoặc bỏ dấu.
        </p>
      ) : (
        <>
          <p className="mt-6 mb-1 text-xs font-semibold tracking-wide text-ink-faint uppercase">
            {results.length} kết quả
          </p>
          <ul className="divide-y divide-hairline rounded-xl border border-hairline bg-surface">
            {results.map((entity) => (
              <EntityTile key={entity.id} {...entity} />
            ))}
          </ul>
        </>
      )}
    </div>
  );
}
