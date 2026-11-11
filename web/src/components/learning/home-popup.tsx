'use client';

import { useEffect, useRef, useTransition } from 'react';

import { trackCampaign } from '@/lib/actions/learning';
import type { HomePopup } from '@/lib/content';

/** "Một lần mỗi phiên" của app ↔ một lần mỗi phiên trình duyệt ở web. */
const SESSION_KEY = 'hddhistory:home-popup-shown';

/**
 * Popup quảng bá trên trang chủ. Server quyết định CÓ hiện hay không (công
 * tắc, thị trường, người này đã bấm chiến dịch chưa); ở đây chỉ quyết định
 * KHI NÀO: một lần mỗi phiên, sau khi trang đã vẽ. Đóng nghĩa là "để sau" —
 * phiên sau popup lại hiện; chỉ bấm vào mới cho chiến dịch về hưu.
 */
export function HomePopupDialog({ popup }: { popup: HomePopup }) {
  const ref = useRef<HTMLDialogElement>(null);
  const [, startTransition] = useTransition();
  const key = popup.campaignKey ?? '';

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog || !popup.imageUrl) return;
    try {
      if (sessionStorage.getItem(SESSION_KEY) === key) return;
      sessionStorage.setItem(SESSION_KEY, key);
    } catch {
      // Không có sessionStorage (chế độ riêng tư chặn) thì vẫn hiện — tệ nhất
      // là hiện lại ở lần vào trang chủ sau.
    }
    dialog.showModal();
    startTransition(async () => {
      await trackCampaign('popup-impression', key);
    });
  }, [key, popup.imageUrl]);

  const href =
    popup.linkUrl && /^https?:\/\//i.test(popup.linkUrl) ? popup.linkUrl : null;

  function onActivate() {
    startTransition(async () => {
      await trackCampaign('popup-click', key);
    });
    ref.current?.close();
  }

  return (
    <dialog
      ref={ref}
      aria-label="Khuyến mãi"
      className="m-auto w-[min(28rem,calc(100%-2rem))] bg-transparent p-0 backdrop:bg-ink/60"
      onClick={(event) => {
        // Bấm ra ngoài ảnh (vào nền) cũng đóng, như app.
        if (event.target === ref.current) ref.current?.close();
      }}
    >
      <div className="flex flex-col items-end gap-3">
        <button
          type="button"
          onClick={() => ref.current?.close()}
          aria-label="Đóng"
          className="flex size-9 items-center justify-center rounded-full bg-surface text-ink shadow focus-visible:outline-2 focus-visible:outline-brand"
        >
          <span aria-hidden>✕</span>
        </button>
        {href ? (
          <a
            href={href}
            target="_blank"
            rel="noopener noreferrer"
            onClick={onActivate}
            className="block w-full"
          >
            <PopupImage src={popup.imageUrl ?? ''} />
          </a>
        ) : (
          // Không có liên kết thì bấm vẫn tính là "đã bấm" — app cũng ghi
          // click trước rồi mới xét có link để mở hay không.
          <button type="button" onClick={onActivate} className="block w-full">
            <PopupImage src={popup.imageUrl ?? ''} />
          </button>
        )}
      </div>
    </dialog>
  );
}

function PopupImage({ src }: { src: string }) {
  return (
    // Ảnh mang sẵn chữ của chiến dịch — `contain` để không cắt mất chữ.
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt="Khuyến mãi"
      className="w-full rounded-2xl object-contain"
    />
  );
}
