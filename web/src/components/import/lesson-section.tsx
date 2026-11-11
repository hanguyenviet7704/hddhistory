import type { LessonSection } from '@/lib/user-lessons';

/**
 * Một thẻ của bài tự tạo.
 *
 * KHÔNG dùng `DocumentBody` dù hình dạng ánh xạ được (app ánh xạ thẻ →
 * document): chữ do model viết mang markup nhẹ — `<b>`, `<i>`, `<br>` và vài
 * entity HTML, đúng những gì prompt sinh bài cho phép và `KeypointRichText`
 * của app đọc — còn `DocumentBody` in chữ thô, nên sẽ hiện nguyên dấu ngoặc
 * nhọn ra màn hình. Class giữ y như `DocumentBody` để hai loại bài trông như
 * một. Không dùng `dangerouslySetInnerHTML`: chỉ nhận đúng ba thẻ, mọi thẻ
 * khác bị bỏ, nên chữ của model không bao giờ thành HTML thật.
 */
export function LessonSectionView({ section }: { section: LessonSection }) {
  return (
    <div>
      {section.title ? (
        <h3 className="mt-5 mb-1 text-lg font-bold text-brand-900 first:mt-0">
          <RichText source={section.title} />
        </h3>
      ) : null}
      {(section.blocks ?? []).map((block, index) =>
        !block.text ? null : block.type === 'heading' ? (
          <h3 key={index} className="mt-5 mb-1 text-lg font-bold text-brand-900 first:mt-0">
            <RichText source={block.text} />
          </h3>
        ) : (
          <p key={index} className="mt-2 leading-relaxed text-ink first:mt-0">
            <RichText source={block.text} />
          </p>
        ),
      )}
    </div>
  );
}

function decodeEntities(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&amp;/g, '&');
}

/** Tách chữ thành các đoạn đậm/nghiêng/xuống dòng — bản rút gọn của `KeypointRichText.runs`. */
export function RichText({ source }: { source: string }) {
  const nodes: React.ReactNode[] = [];
  let bold = 0;
  let italic = 0;
  let cursor = 0;
  const pattern = /<[^>]*>/g;
  let match: RegExpExecArray | null;

  const push = (raw: string) => {
    if (!raw) return;
    const text = decodeEntities(raw);
    const key = nodes.length;
    if (bold > 0 && italic > 0) nodes.push(<strong key={key}><em>{text}</em></strong>);
    else if (bold > 0) nodes.push(<strong key={key}>{text}</strong>);
    else if (italic > 0) nodes.push(<em key={key}>{text}</em>);
    else nodes.push(text);
  };

  while ((match = pattern.exec(source)) !== null) {
    push(source.slice(cursor, match.index));
    cursor = match.index + match[0].length;
    const tag = match[0].toLowerCase();
    if (tag === '<b>' || tag.startsWith('<b ') || tag.startsWith('<strong')) bold++;
    else if (tag === '</b>' || tag.startsWith('</strong')) bold = Math.max(0, bold - 1);
    else if (tag === '<i>' || tag.startsWith('<i ') || tag.startsWith('<em')) italic++;
    else if (tag === '</i>' || tag.startsWith('</em')) italic = Math.max(0, italic - 1);
    else if (tag.startsWith('<br') || tag.startsWith('</p') || tag.startsWith('</div')) {
      nodes.push(<br key={nodes.length} />);
    }
  }
  push(source.slice(cursor));
  return <>{nodes}</>;
}
