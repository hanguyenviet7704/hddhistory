import { SectionHeader } from '@/components/section';
import { text, type BadgeProgress } from '@/lib/content';

/** Huy hiệu từng cấp độ: sáng lên khi học xong mọi keypoint của cấp đó. */
export function Badges({
  badges,
  title = 'Huy hiệu',
}: {
  badges: BadgeProgress[];
  title?: string;
}) {
  if (badges.length === 0) return null;
  return (
    <section>
      <SectionHeader title={title} />
      <ul className="grid gap-3 sm:grid-cols-2">
        {badges.map((badge, index) => {
          const total = badge.totalKeypoints ?? 0;
          const done = badge.completedKeypoints ?? 0;
          return (
            <li
              key={badge.level ?? index}
              className="flex items-center gap-3 rounded-xl border border-hairline bg-surface p-3"
            >
              {badge.lightBadge ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={badge.lightBadge}
                  alt=""
                  className={`size-12 shrink-0 rounded-full object-cover ${
                    badge.isCompleted ? '' : 'opacity-40 grayscale'
                  }`}
                />
              ) : null}
              <div className="min-w-0">
                <p className="font-semibold text-ink">
                  {text(badge.titleBadge) || 'Huy hiệu'}
                </p>
                <p className="text-sm text-ink-muted">
                  {badge.isCompleted
                    ? 'Đã đạt huy hiệu'
                    : `${done}/${total} phần`}
                </p>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
