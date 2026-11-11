'use client';

import { useEffect, useRef, useState, useTransition } from 'react';

import { trackCampaign } from '@/lib/actions/learning';
import type { BannerSlide } from '@/lib/content';

/**
 * Chỉ mở liên kết web. Liên kết của admin có thể là deep link `hddhistory://`
 * vào màn hình của app — web không có màn tương ứng chắc chắn, nên ảnh vẫn
 * hiện nhưng không bấm được, thay vì dẫn tới một trang lỗi.
 */
function webLink(url?: string): string | null {
  return url && /^https?:\/\//i.test(url) ? url : null;
}

/**
 * Banner quảng bá trên trang chủ: một hoặc nhiều slide, cuộn ngang.
 *
 * Mỗi slide báo "đã hiện" một lần khi nó thực sự lọt vào khung nhìn (như app
 * bắn impression khi slide được hiển thị), và báo "đã bấm" khi bấm vào.
 */
export function HomeBannerCarousel({ slides }: { slides: BannerSlide[] }) {
  if (slides.length === 0) return null;
  return (
    <section aria-label="Khuyến mãi" className="mt-4">
      <ul className="flex snap-x snap-mandatory gap-3 overflow-x-auto pb-1">
        {slides.map((slide) => (
          <Slide
            key={slide.campaignKey}
            slide={slide}
            only={slides.length === 1}
          />
        ))}
      </ul>
    </section>
  );
}

function Slide({ slide, only }: { slide: BannerSlide; only: boolean }) {
  const ref = useRef<HTMLLIElement>(null);
  const [, startTransition] = useTransition();
  const [seen, setSeen] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node || seen) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries.some((entry) => entry.isIntersecting)) {
          setSeen(true);
          observer.disconnect();
          startTransition(async () => {
            await trackCampaign('banner-impression', slide.campaignKey);
          });
        }
      },
      { threshold: 0.5 },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [seen, slide.campaignKey]);

  const href = webLink(slide.linkUrl);
  const image = (
    // Ảnh từ CDN của API, tên miền không cố định — dùng <img> thường.
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={slide.imageUrl}
      alt="Khuyến mãi"
      className="w-full rounded-xl border border-hairline object-cover"
    />
  );

  return (
    <li
      ref={ref}
      className={`shrink-0 snap-start ${only ? 'w-full' : 'w-[85%] sm:w-[70%]'}`}
    >
      {href ? (
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          onClick={() => {
            startTransition(async () => {
              await trackCampaign('banner-click', slide.campaignKey);
            });
          }}
          className="block rounded-xl focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand"
        >
          {image}
        </a>
      ) : (
        image
      )}
    </li>
  );
}
