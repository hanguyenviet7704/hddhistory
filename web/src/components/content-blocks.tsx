import { text } from '@/lib/content';
import type { ContentBlock, LearningDocument } from '@/lib/learning';

/**
 * Vẽ một khối nội dung theo `type`.
 *
 * Khối lạ (server thêm kiểu mới, app cũ chưa biết) rơi về đoạn văn thường nếu
 * có chữ, còn không thì bỏ qua — thà thiếu một khối còn hơn vỡ cả bài học.
 */
function Block({ block }: { block: ContentBlock }) {
  const content = text(block.data?.content);
  const url = text(block.data?.url);

  switch (block.type) {
    case 'title':
      return content ? (
        <h3 className="mt-5 mb-1 text-lg font-bold text-brand-900">
          {content}
        </h3>
      ) : null;

    case 'caption':
      return content ? (
        <p className="mt-1 text-sm text-ink-faint italic">{content}</p>
      ) : null;

    case 'image':
      return url ? (
        // Ảnh từ CDN của API, tên miền không cố định — dùng <img> thường thay
        // vì next/image để khỏi phải khai báo trước từng remotePattern.
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={url}
          alt={content || ''}
          className="mt-3 w-full rounded-xl border border-hairline"
        />
      ) : null;

    case 'video':
      return url ? (
        <video
          controls
          preload="metadata"
          poster={block.data?.thumbnail || undefined}
          className="mt-3 w-full rounded-xl border border-hairline"
        >
          <source src={url} />
        </video>
      ) : null;

    case 'audio':
      return url ? (
        <audio controls preload="metadata" className="mt-3 w-full">
          <source src={url} />
        </audio>
      ) : null;

    case 'explanation':
      return content ? (
        <div className="mt-3 rounded-xl bg-brand-50 p-3 text-sm leading-relaxed text-ink-muted">
          {content}
        </div>
      ) : null;

    case 'text':
    default:
      return content ? (
        <p className="mt-2 leading-relaxed text-ink">{content}</p>
      ) : null;
  }
}

export function DocumentBody({ document }: { document: LearningDocument }) {
  const bubble = text(document.speechBubble);
  return (
    <div>
      {bubble ? (
        <p className="mb-2 rounded-xl bg-surface-alt px-3 py-2 text-sm text-ink-muted">
          {bubble}
        </p>
      ) : null}
      {(document.document ?? []).map((block, index) => (
        <Block key={block._id ?? index} block={block} />
      ))}
    </div>
  );
}
