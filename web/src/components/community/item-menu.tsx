'use client';

import { useEffect, useId, useRef, useState, useTransition } from 'react';

import { buttonClass, FormMessage, inputClass } from '@/components/ui';
import type { ActionResult } from '@/lib/action-result';
import { hideItem, reportItem } from '@/lib/actions/community';

import { LIMITS, REPORT_REASONS, type ReportReason } from './format';

type Mode = 'menu' | 'report' | 'delete' | 'reported';

/**
 * Menu "⋯" của bài viết / bình luận / tin nhắn, theo `community_post_menu_sheet`:
 * nội dung của mình thì chỉ có Xoá; của người khác thì Ẩn và Báo cáo.
 *
 * Mở thành một khung ngay dưới nút chứ không phải hộp thoại toàn màn hình: báo
 * cáo chỉ là chọn một lý do, và giữ ngữ cảnh của nội dung đang báo cáo trước
 * mắt giúp người đọc chọn đúng.
 */
export function ItemMenu({
  targetType,
  targetId,
  isMine,
  noun,
  canHide = true,
  onDelete,
  onDone,
  align = 'right',
}: {
  targetType: 'POST' | 'COMMENT' | 'CHAT_MESSAGE';
  targetId: string;
  isMine: boolean;
  /** "bài viết", "bình luận", "tin nhắn" — chen vào nhãn các nút. */
  noun: string;
  /** Chat không có "ẩn với mình" — API không lọc tin đã ẩn ra khỏi phòng. */
  canHide?: boolean;
  onDelete?: () => Promise<ActionResult<unknown>>;
  onDone?: (what: 'hidden' | 'deleted') => void;
  /** Mép neo khung: tin chat bên trái màn hình cần mở sang phải để khỏi tràn. */
  align?: 'left' | 'right';
}) {
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<Mode>('menu');
  const [reason, setReason] = useState<ReportReason | null>(null);
  const [note, setNote] = useState('');
  const [error, setError] = useState<string>();
  const [pending, startTransition] = useTransition();
  const panelId = useId();
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onKey(event: KeyboardEvent) {
      if (event.key === 'Escape') setOpen(false);
    }
    function onClick(event: MouseEvent) {
      if (!rootRef.current?.contains(event.target as Node)) setOpen(false);
    }
    document.addEventListener('keydown', onKey);
    document.addEventListener('mousedown', onClick);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('mousedown', onClick);
    };
  }, [open]);

  function toggle() {
    setOpen((value) => !value);
    setMode('menu');
    setError(undefined);
  }

  function hide() {
    if (targetType === 'CHAT_MESSAGE') return;
    startTransition(async () => {
      const result = await hideItem(targetType, targetId);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setOpen(false);
      onDone?.('hidden');
    });
  }

  function remove() {
    if (!onDelete) return;
    startTransition(async () => {
      const result = await onDelete();
      if (!result.ok) {
        setError(result.error);
        return;
      }
      setOpen(false);
      onDone?.('deleted');
    });
  }

  function report(event: React.FormEvent) {
    event.preventDefault();
    if (!reason) {
      setError('Chọn một lý do.');
      return;
    }
    startTransition(async () => {
      const result = await reportItem({ targetType, targetId, reason, note });
      if (!result.ok) {
        setError(result.error || 'Chưa gửi được báo cáo. Thử lại nhé.');
        return;
      }
      setError(undefined);
      setMode('reported');
    });
  }

  const item =
    'block w-full rounded-lg px-3 py-2 text-left text-sm font-medium text-ink hover:bg-surface-alt disabled:opacity-60';

  return (
    <div ref={rootRef} className="relative">
      <button
        type="button"
        onClick={toggle}
        aria-expanded={open}
        aria-controls={panelId}
        aria-label={`Tuỳ chọn cho ${noun}`}
        className="flex size-8 items-center justify-center rounded-full text-ink-faint hover:bg-surface-alt hover:text-ink focus-visible:ring-2 focus-visible:ring-brand/40 focus-visible:outline-none"
      >
        <svg viewBox="0 0 20 20" className="size-5" fill="currentColor" aria-hidden>
          <circle cx="4" cy="10" r="1.6" />
          <circle cx="10" cy="10" r="1.6" />
          <circle cx="16" cy="10" r="1.6" />
        </svg>
      </button>

      {open ? (
        <div
          id={panelId}
          className={`absolute ${align === 'left' ? 'left-0' : 'right-0'} z-20 mt-1 w-72 max-w-[calc(100vw-2rem)] rounded-xl border border-hairline bg-surface p-2 shadow-lg`}
        >
          {mode === 'menu' ? (
            <div className="space-y-0.5">
              {isMine ? (
                onDelete ? (
                  <button
                    type="button"
                    className={`${item} text-red-700`}
                    onClick={() => setMode('delete')}
                  >
                    Xoá {noun}
                  </button>
                ) : (
                  <p className="px-3 py-2 text-sm text-ink-faint">
                    Đây là {noun} của bạn.
                  </p>
                )
              ) : (
                <>
                  {canHide ? (
                    <button
                      type="button"
                      className={item}
                      onClick={hide}
                      disabled={pending}
                    >
                      Ẩn nội dung này
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className={item}
                    onClick={() => setMode('report')}
                  >
                    Báo cáo {noun}
                  </button>
                </>
              )}
            </div>
          ) : null}

          {mode === 'delete' ? (
            <div className="p-2">
              <p className="text-sm text-ink">
                Xoá {noun} này? Không hoàn tác được.
              </p>
              <div className="mt-3 flex gap-2">
                <button
                  type="button"
                  className={`${buttonClass.danger} px-3 py-1.5 text-sm`}
                  onClick={remove}
                  disabled={pending}
                >
                  {pending ? 'Đang xoá…' : 'Xoá'}
                </button>
                <button
                  type="button"
                  className={buttonClass.ghost}
                  onClick={() => setMode('menu')}
                >
                  Huỷ
                </button>
              </div>
            </div>
          ) : null}

          {mode === 'report' ? (
            <form onSubmit={report} className="p-2">
              <fieldset>
                <legend className="text-sm font-bold text-brand-900">
                  Báo cáo nội dung này
                </legend>
                <p className="mt-0.5 text-xs text-ink-faint">
                  Đội ngũ HDDhistory sẽ xem và quyết định. Nội dung không tự
                  động bị ẩn.
                </p>
                <div className="mt-2 space-y-1">
                  {REPORT_REASONS.map((option) => (
                    <label
                      key={option.value}
                      className="flex cursor-pointer items-center gap-2 rounded-lg px-1 py-1 text-sm text-ink hover:bg-surface-alt"
                    >
                      <input
                        type="radio"
                        name="reason"
                        value={option.value}
                        checked={reason === option.value}
                        onChange={() => setReason(option.value)}
                        className="accent-brand"
                      />
                      {option.label}
                    </label>
                  ))}
                </div>
              </fieldset>
              <label className="mt-2 block text-xs text-ink-muted">
                Ghi chú (không bắt buộc)
                <textarea
                  value={note}
                  onChange={(event) => setNote(event.target.value)}
                  maxLength={LIMITS.reportNote}
                  rows={2}
                  className={`${inputClass} mt-1 px-3 py-2 text-sm`}
                />
              </label>
              <div className="mt-2 flex gap-2">
                <button
                  type="submit"
                  className={`${buttonClass.primary} px-3 py-1.5 text-sm`}
                  disabled={pending}
                >
                  {pending ? 'Đang gửi…' : 'Gửi báo cáo'}
                </button>
                <button
                  type="button"
                  className={buttonClass.ghost}
                  onClick={() => setMode('menu')}
                >
                  Huỷ
                </button>
              </div>
            </form>
          ) : null}

          {mode === 'reported' ? (
            <p role="status" className="p-2 text-sm font-medium text-emerald-700">
              Cảm ơn bạn. Đội ngũ HDDhistory sẽ xem lại.
            </p>
          ) : null}

          {error ? (
            <div className="px-2 pb-1">
              <FormMessage error={error} />
            </div>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
