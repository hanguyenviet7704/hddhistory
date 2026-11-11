'use client';

import { useActionState, useState, useTransition } from 'react';

import { buttonClass, FormMessage, inputClass, SubmitButton } from '@/components/ui';
import {
  createRoomSuggestion,
  voteRoomSuggestion,
  type SuggestionState,
} from '@/lib/actions/community';
import type { RoomSuggestion } from '@/lib/community';

import { LIMITS } from './format';

/**
 * "Không thấy phòng bạn cần?" — form đề xuất phòng và các đề xuất đang mở.
 *
 * Danh sách vẽ thẳng từ props (trang dựng lại sau khi gửi đề xuất), chỉ phần
 * phiếu ủng hộ là trạng thái cục bộ.
 */
export function RoomSuggestions({
  suggestions,
  canPost,
}: {
  suggestions: RoomSuggestion[];
  canPost: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [state, formAction] = useActionState<SuggestionState | null, FormData>(
    createRoomSuggestion,
    null,
  );
  const [voted, setVoted] = useState<Record<string, RoomSuggestion>>({});
  const [voteError, setVoteError] = useState<string>();
  const [pending, startTransition] = useTransition();

  function vote(id: string) {
    setVoteError(undefined);
    startTransition(async () => {
      const result = await voteRoomSuggestion(id);
      if (!result.ok) {
        setVoteError(result.error);
        return;
      }
      setVoted((current) => ({ ...current, [id]: result.data }));
    });
  }

  return (
    <section className="mt-6 rounded-xl border border-brand-200 bg-brand-100/40 p-4">
      <h2 className="font-semibold text-brand-900">Không thấy phòng bạn cần?</h2>
      <p className="mt-1 text-sm text-ink-muted">
        Đề xuất một phòng mới — nếu đủ người quan tâm, HDDhistory sẽ mở phòng đó.
      </p>

      {!open ? (
        <button
          type="button"
          onClick={() => setOpen(true)}
          disabled={!canPost}
          className={`${buttonClass.secondary} mt-3`}
        >
          Đề xuất phòng mới
        </button>
      ) : (
        <form action={formAction} className="mt-3 space-y-3">
          <div>
            <label htmlFor="room-name" className="mb-1 block text-xs font-bold tracking-wide text-ink-muted">
              TÊN PHÒNG
            </label>
            <input
              id="room-name"
              name="name"
              required
              maxLength={LIMITS.roomName}
              placeholder="Ví dụ: Thời Tây Sơn"
              className={inputClass}
            />
          </div>
          <div>
            <label htmlFor="room-description" className="mb-1 block text-xs font-bold tracking-wide text-ink-muted">
              MÔ TẢ PHÒNG
            </label>
            <textarea
              id="room-description"
              name="description"
              rows={2}
              maxLength={LIMITS.roomDescription}
              placeholder="Phòng này dành cho ai, nói về chuyện gì?"
              className={inputClass}
            />
          </div>
          <div className="flex flex-wrap gap-2">
            <SubmitButton pendingLabel="Đang gửi…">Gửi đề xuất</SubmitButton>
            <button type="button" className={buttonClass.ghost} onClick={() => setOpen(false)}>
              Huỷ
            </button>
          </div>
        </form>
      )}
      <div className="mt-2">
        <FormMessage error={state?.error} success={state?.success} />
      </div>

      {suggestions.length > 0 ? (
        <>
          <h3 className="mt-5 text-xs font-bold tracking-wide text-brand-900 uppercase">
            Đề xuất đang được cân nhắc
          </h3>
          <ul className="mt-2 space-y-2">
            {suggestions.map((original) => {
              const item = voted[original.id] ?? original;
              return (
                <li
                  key={item.id}
                  className="flex items-start gap-3 rounded-xl border border-hairline bg-surface p-3"
                >
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-ink">{item.name}</p>
                    {item.description ? (
                      <p className="mt-0.5 text-sm text-ink-muted">{item.description}</p>
                    ) : null}
                    <p className="mt-1 text-xs text-ink-faint">
                      {item.voteCount ?? 0} người ủng hộ
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => vote(item.id)}
                    disabled={pending || item.hasVoted || !canPost}
                    aria-label={
                      item.hasVoted
                        ? `Đã ủng hộ phòng ${item.name}`
                        : `Ủng hộ phòng ${item.name}`
                    }
                    className={`shrink-0 rounded-full px-3 py-1.5 text-xs font-bold ${
                      item.hasVoted
                        ? 'border border-brand-200 text-brand-700'
                        : 'bg-brand text-white hover:bg-brand-700 disabled:opacity-60'
                    }`}
                  >
                    {item.hasVoted ? 'Đã ủng hộ' : '+ Ủng hộ'}
                  </button>
                </li>
              );
            })}
          </ul>
          <div className="mt-2">
            <FormMessage error={voteError} />
          </div>
        </>
      ) : null}
    </section>
  );
}
