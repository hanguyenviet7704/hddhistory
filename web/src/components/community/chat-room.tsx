'use client';

import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
  useTransition,
} from 'react';

import { buttonClass, FormMessage, inputClass } from '@/components/ui';
import {
  loadChatContext,
  loadOlderChat,
  pollChat,
  sendChatMessage,
  toggleChatLike,
} from '@/lib/actions/community';
import type { ChatGuide, ChatMessage, ChatPage } from '@/lib/community';

import { Avatar, OfficialBadge } from './author';
import { authorName, formatClock, formatDate, LIMITS } from './format';
import { ItemMenu } from './item-menu';
import { HeartIcon } from './post-card';

/**
 * App poll phòng mỗi 6 giây (`CommunityChatCubit._pollInterval`); web làm y
 * vậy bằng server action, và chỉ khi tab đang hiện — một tab nằm nền không có
 * ai đọc, poll nó chỉ tốn lượt gọi API.
 */
const POLL_MS = 6000;

function byTime(a: ChatMessage, b: ChatMessage) {
  return (a.createdAt ?? '').localeCompare(b.createdAt ?? '');
}

/** Gộp theo id, bản mới đè bản cũ (số tim, ghim), xếp cũ → mới để vẽ từ trên xuống. */
function merge(current: ChatMessage[], incoming: ChatMessage[]) {
  const map = new Map(current.map((message) => [message.id, message]));
  for (const message of incoming) map.set(message.id, { ...map.get(message.id), ...message });
  return [...map.values()].sort(byTime);
}

function dayKey(iso?: string) {
  return iso ? formatDate(iso) : '';
}

export function ChatRoom({
  room,
  initial,
  guide,
  canSend,
  closedReason,
}: {
  room: string;
  initial: ChatPage | null;
  guide: ChatGuide | null;
  canSend: boolean;
  closedReason?: string;
}) {
  const [messages, setMessages] = useState<ChatMessage[]>(() =>
    [...(initial?.items ?? [])].sort(byTime),
  );
  const [pinned, setPinned] = useState<ChatMessage[]>(initial?.pinned ?? []);
  const [olderPage, setOlderPage] = useState(1);
  const [hasOlder, setHasOlder] = useState((initial?.totalPages ?? 1) > 1);
  // 'context' = đang xem một khúc lịch sử quanh tin ghim; poll không gộp vào
  // nữa cho tới khi người đọc về lại tin mới nhất.
  const [mode, setModeState] = useState<'live' | 'context'>('live');
  const [highlight, setHighlight] = useState<string | null>(null);
  const [replyTo, setReplyTo] = useState<ChatMessage | null>(null);
  const [draft, setDraft] = useState('');
  const [error, setError] = useState<string | undefined>(
    initial ? undefined : 'Không tải được tin nhắn. Đang thử lại…',
  );
  const [sending, startSending] = useTransition();
  const [loadingOlder, startOlder] = useTransition();
  const [, startPoll] = useTransition();

  const listRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const stickToBottom = useRef(true);
  const keepOffset = useRef<number | null>(null);
  const polling = useRef(false);
  // Bản sao của `mode` cho các nhịp poll đang bay: chúng đọc sau `await`, khi
  // closure đã cũ. Cập nhật cùng lúc với state để không có khe nào poll gộp
  // tin mới vào một khúc lịch sử.
  const modeRef = useRef<'live' | 'context'>('live');
  const setMode = useCallback((next: 'live' | 'context') => {
    modeRef.current = next;
    setModeState(next);
  }, []);

  // ---------------------------------------------------------------- poll

  const poll = useCallback(() => {
    if (polling.current || document.visibilityState !== 'visible') return;
    if (modeRef.current !== 'live') return;
    polling.current = true;
    startPoll(async () => {
      const result = await pollChat(room);
      polling.current = false;
      if (!result.ok) return; // Một nhịp hỏng thì nhịp sau thử lại — không làm phiền.
      if (modeRef.current !== 'live') return;
      setError((current) => (current?.startsWith('Không tải được tin') ? undefined : current));
      setMessages((current) => merge(current, result.data.items ?? []));
      setPinned(result.data.pinned ?? []);
    });
  }, [room]);

  useEffect(() => {
    const timer = window.setInterval(poll, POLL_MS);
    function onVisible() {
      if (document.visibilityState === 'visible') poll();
    }
    document.addEventListener('visibilitychange', onVisible);
    if (!initial) poll();
    return () => {
      window.clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, [poll, initial]);

  // ---------------------------------------------------------------- cuộn

  useLayoutEffect(() => {
    const list = listRef.current;
    if (!list) return;
    if (keepOffset.current !== null) {
      // Vừa chèn tin cũ lên trên: giữ nguyên chỗ đang đọc thay vì nhảy.
      list.scrollTop = list.scrollHeight - keepOffset.current;
      keepOffset.current = null;
    } else if (stickToBottom.current) {
      list.scrollTop = list.scrollHeight;
    }
  }, [messages]);

  useEffect(() => {
    if (!highlight) return;
    document.getElementById(`tin-${highlight}`)?.scrollIntoView({ block: 'center' });
    const timer = window.setTimeout(() => setHighlight(null), 1900);
    return () => window.clearTimeout(timer);
  }, [highlight]);

  function onScroll() {
    const list = listRef.current;
    if (!list) return;
    stickToBottom.current = list.scrollHeight - list.scrollTop - list.clientHeight < 80;
  }

  // ---------------------------------------------------------------- thao tác

  function loadOlder() {
    const list = listRef.current;
    startOlder(async () => {
      if (mode === 'context') {
        // Khúc lịch sử không có số trang: hỏi khúc quanh tin cũ nhất đang có.
        const oldest = messages[0];
        if (!oldest) return;
        const result = await loadChatContext(room, oldest.id);
        if (!result.ok) {
          setError(result.error);
          return;
        }
        if (list) keepOffset.current = list.scrollHeight - list.scrollTop;
        setMessages((current) => merge(current, result.data.items));
        setHasOlder(result.data.hasOlder);
        return;
      }
      const result = await loadOlderChat(room, olderPage + 1);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      if (list) keepOffset.current = list.scrollHeight - list.scrollTop;
      setMessages((current) => merge(current, result.data.items ?? []));
      setOlderPage(result.data.currentPage || olderPage + 1);
      setHasOlder((result.data.currentPage || olderPage + 1) < (result.data.totalPages || 1));
    });
  }

  function jumpTo(messageId: string) {
    if (messages.some((message) => message.id === messageId)) {
      setHighlight(messageId);
      return;
    }
    // Tin ghim có thể nằm cách hàng trăm tin — không có gì để cuộn tới, nên
    // thay cả danh sách bằng khúc lịch sử quanh nó (như app).
    startOlder(async () => {
      const result = await loadChatContext(room, messageId);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      stickToBottom.current = false;
      setMessages([...result.data.items].sort(byTime));
      setHasOlder(result.data.hasOlder);
      setMode(result.data.hasNewer ? 'context' : 'live');
      setHighlight(result.data.anchorId);
    });
  }

  function backToLatest() {
    startOlder(async () => {
      const result = await pollChat(room);
      if (!result.ok) {
        setError(result.error);
        return;
      }
      stickToBottom.current = true;
      setMessages([...(result.data.items ?? [])].sort(byTime));
      setPinned(result.data.pinned ?? []);
      setOlderPage(1);
      setHasOlder((result.data.totalPages ?? 1) > 1);
      setMode('live');
    });
  }

  function send(event?: React.FormEvent) {
    event?.preventDefault();
    const body = draft.trim();
    if (!body || sending) return;
    const quoting = replyTo;
    setError(undefined);
    startSending(async () => {
      const result = await sendChatMessage({ room, body, replyToId: quoting?.id });
      if (!result.ok) {
        setError(result.error);
        return;
      }
      // API trả tin vừa gửi với `replyTo.isRemoved = true` dù tin gốc vẫn còn
      // (nó không tra tin được trích ở nhánh gửi) — vá bằng chính tin đang
      // trích; nhịp poll sau sẽ thay bằng bản đúng của máy chủ.
      const sent: ChatMessage =
        quoting && result.data.replyTo
          ? {
              ...result.data,
              replyTo: {
                id: quoting.id,
                author: quoting.author,
                body: quoting.body,
                isRemoved: false,
              },
            }
          : result.data;
      setDraft('');
      setReplyTo(null);
      stickToBottom.current = true;
      if (modeRef.current === 'context') {
        backToLatest();
      } else {
        setMessages((current) => merge(current, [sent]));
      }
    });
  }

  function toggleLike(message: ChatMessage) {
    const next = !message.isLiked;
    const optimistic = {
      isLiked: next,
      likeCount: Math.max(0, (message.likeCount ?? 0) + (next ? 1 : -1)),
    };
    setMessages((current) =>
      current.map((m) => (m.id === message.id ? { ...m, ...optimistic } : m)),
    );
    startPoll(async () => {
      const result = await toggleChatLike(message.id);
      setMessages((current) =>
        current.map((m) =>
          m.id === message.id
            ? result.ok
              ? { ...m, ...result.data }
              : { ...m, isLiked: message.isLiked, likeCount: message.likeCount }
            : m,
        ),
      );
      if (!result.ok) setError(result.error);
    });
  }

  function startReply(message: ChatMessage) {
    setReplyTo(message);
    inputRef.current?.focus();
  }

  // ---------------------------------------------------------------- vẽ

  const pins = [...pinned].sort((a, b) =>
    (b.pinnedAt ?? '').localeCompare(a.pinnedAt ?? ''),
  );
  const pinnedIds = new Set(pins.map((message) => message.id));

  return (
    <div className="flex flex-col gap-3">
      {guide ? <GuidePanel guide={guide} onStarter={canSend ? setDraft : undefined} /> : null}

      {pins.length > 0 ? (
        <div className="rounded-xl border border-brand-200 bg-brand-50 p-3 text-sm">
          <button
            type="button"
            onClick={() => jumpTo(pins[0].id)}
            className="block w-full text-left"
          >
            <span className="block text-xs font-bold text-brand-700">
              Tới tin nhắn đã ghim
            </span>
            <span className="line-clamp-1 text-ink">
              <strong className="font-semibold">{authorName(pins[0].author)}:</strong>{' '}
              {pins[0].body}
            </span>
          </button>
          {pins.length > 1 ? (
            <details className="mt-2">
              <summary className="cursor-pointer text-xs font-semibold text-brand-700">
                {pins.length} tin nhắn đã ghim
              </summary>
              <ul className="mt-1 space-y-1">
                {pins.map((message) => (
                  <li key={message.id}>
                    <button
                      type="button"
                      onClick={() => jumpTo(message.id)}
                      className="line-clamp-1 w-full rounded px-1 py-0.5 text-left hover:bg-brand-100"
                    >
                      <strong className="font-semibold">{authorName(message.author)}:</strong>{' '}
                      {message.body}
                    </button>
                  </li>
                ))}
              </ul>
            </details>
          ) : null}
        </div>
      ) : null}

      <div
        ref={listRef}
        onScroll={onScroll}
        role="log"
        aria-live="polite"
        aria-label="Tin nhắn trong phòng"
        className="h-[60dvh] min-h-72 overflow-y-auto rounded-xl border border-hairline bg-surface p-3"
      >
        {hasOlder ? (
          <div className="mb-3 text-center">
            <button
              type="button"
              onClick={loadOlder}
              disabled={loadingOlder}
              className={buttonClass.ghost}
            >
              {loadingOlder ? 'Đang tải…' : 'Xem tin cũ hơn'}
            </button>
          </div>
        ) : null}

        {messages.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center text-center">
            <p className="font-semibold text-brand-900">Chưa có ai nhắn gì</p>
            <p className="mt-1 text-sm text-ink-muted">Mở lời trước đi — một câu cũng được.</p>
          </div>
        ) : (
          <ol className="space-y-3">
            {messages.map((message, index) => {
              const day = dayKey(message.createdAt);
              const showDay = index === 0 || day !== dayKey(messages[index - 1].createdAt);
              return (
                <li key={message.id}>
                  {showDay ? (
                    <p className="my-2 text-center text-xs font-semibold text-ink-faint" suppressHydrationWarning>
                      {day === formatDate(new Date().toISOString()) ? 'Hôm nay' : day}
                    </p>
                  ) : null}
                  <Bubble
                    message={{ ...message, isPinned: message.isPinned || pinnedIds.has(message.id) }}
                    highlighted={highlight === message.id}
                    canReply={canSend}
                    onLike={() => toggleLike(message)}
                    onReply={() => startReply(message)}
                    onQuote={(id) => jumpTo(id)}
                  />
                </li>
              );
            })}
          </ol>
        )}
      </div>

      {mode === 'context' ? (
        <div className="text-center">
          <button type="button" onClick={backToLatest} className={buttonClass.secondary}>
            Tin mới nhất ↓
          </button>
        </div>
      ) : null}

      {canSend ? (
        <form onSubmit={send} className="rounded-xl border border-hairline bg-surface p-3">
          {replyTo ? (
            <div className="mb-2 flex items-start gap-2 border-l-2 border-brand pl-2 text-xs">
              <p className="min-w-0 flex-1 text-ink-muted">
                Đang trả lời <strong className="text-brand-900">{authorName(replyTo.author)}</strong>
                <span className="line-clamp-1">{replyTo.body}</span>
              </p>
              <button
                type="button"
                onClick={() => setReplyTo(null)}
                className="font-semibold text-brand-700 hover:underline"
              >
                Huỷ
              </button>
            </div>
          ) : null}
          <div className="flex items-end gap-2">
            <label htmlFor="chat-input" className="sr-only">
              Nhắn vào nhóm
            </label>
            <textarea
              id="chat-input"
              ref={inputRef}
              value={draft}
              onChange={(event) => setDraft(event.target.value)}
              onKeyDown={(event) => {
                // Enter gửi, Shift+Enter xuống dòng — thói quen của mọi ô chat.
                if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) {
                  event.preventDefault();
                  send();
                }
              }}
              rows={1}
              maxLength={LIMITS.chat}
              placeholder="Nhắn vào nhóm…"
              className={`${inputClass} max-h-40 min-h-12 resize-y py-2.5`}
            />
            <button
              type="submit"
              disabled={sending || !draft.trim()}
              className={`${buttonClass.primary} shrink-0 px-4`}
            >
              {sending ? 'Đang gửi…' : 'Gửi'}
            </button>
          </div>
        </form>
      ) : closedReason ? (
        <p className="rounded-xl border border-hairline bg-surface-alt p-3 text-sm text-ink-muted">
          {closedReason}
        </p>
      ) : null}
      <FormMessage error={error} />
    </div>
  );
}

function Bubble({
  message,
  highlighted,
  canReply,
  onLike,
  onReply,
  onQuote,
}: {
  message: ChatMessage;
  highlighted: boolean;
  canReply: boolean;
  onLike: () => void;
  onReply: () => void;
  onQuote: (id: string) => void;
}) {
  const mine = Boolean(message.isMine);
  const moderator = message.isModerator || message.author?.authorType === 'OFFICIAL';
  return (
    <div
      id={`tin-${message.id}`}
      className={`flex gap-2 ${mine ? 'flex-row-reverse' : ''}`}
    >
      {!mine ? <Avatar author={message.author} size="sm" /> : null}
      <div className={`flex max-w-[85%] flex-col ${mine ? 'items-end' : 'items-start'}`}>
        {!mine ? (
          <p className="mb-0.5 flex items-center gap-1.5 text-xs font-semibold text-brand-900">
            {authorName(message.author)}
            {message.author?.authorType === 'OFFICIAL' ? <OfficialBadge /> : null}
            {message.isModerator && message.author?.authorType !== 'OFFICIAL' ? (
              <span className="text-[10px] font-bold text-brand-700 uppercase">Quản trị viên</span>
            ) : null}
          </p>
        ) : null}
        <div
          className={`rounded-2xl px-3 py-2 text-sm transition ${
            mine ? 'bg-brand text-white' : moderator ? 'bg-brand-100 text-ink' : 'bg-surface-alt text-ink'
          } ${highlighted ? 'ring-2 ring-brand-300' : ''} ${message.isPinned ? 'shadow-[0_0_0_2px] shadow-brand-200' : ''}`}
        >
          {message.replyTo ? (
            <button
              type="button"
              onClick={() => !message.replyTo?.isRemoved && onQuote(message.replyTo!.id)}
              className={`mb-1 block w-full border-l-2 pl-2 text-left text-xs ${
                mine ? 'border-white/70 text-white/90' : 'border-brand text-ink-muted'
              }`}
            >
              {message.replyTo.isRemoved ? (
                <em>Tin nhắn đã bị gỡ</em>
              ) : (
                <>
                  <strong className="font-semibold">{authorName(message.replyTo.author)}</strong>
                  <span className="line-clamp-2">{message.replyTo.body}</span>
                </>
              )}
            </button>
          ) : null}
          <p className="whitespace-pre-line break-words">{message.body}</p>
        </div>
        <div className="mt-0.5 flex items-center gap-1 text-[11px] text-ink-faint">
          {message.isPinned ? <span className="font-semibold text-brand-700">Đã ghim ·</span> : null}
          <time dateTime={message.createdAt} suppressHydrationWarning>
            {formatClock(message.createdAt)}
          </time>
          {mine && message.isSeen ? <span>· Đã xem</span> : null}
          <button
            type="button"
            onClick={onLike}
            aria-pressed={Boolean(message.isLiked)}
            aria-label={message.isLiked ? 'Bỏ thích tin nhắn' : 'Thích tin nhắn'}
            className={`ml-1 inline-flex items-center gap-0.5 rounded px-1 py-0.5 hover:bg-surface-alt ${
              message.isLiked ? 'text-red-700' : ''
            }`}
          >
            <HeartIcon filled={Boolean(message.isLiked)} />
            {message.likeCount ? message.likeCount : null}
          </button>
          {canReply ? (
            <button
              type="button"
              onClick={onReply}
              className="rounded px-1 py-0.5 font-semibold hover:bg-surface-alt hover:text-brand-700"
            >
              Trả lời
            </button>
          ) : null}
          {!mine ? (
            <ItemMenu
              targetType="CHAT_MESSAGE"
              targetId={message.id}
              isMine={false}
              noun="tin nhắn"
              canHide={false}
              align="left"
            />
          ) : null}
        </div>
      </div>
    </div>
  );
}

function GuidePanel({
  guide,
  onStarter,
}: {
  guide: ChatGuide;
  onStarter?: (text: string) => void;
}) {
  return (
    <details className="rounded-xl border border-hairline bg-surface p-3 text-sm">
      <summary className="cursor-pointer font-semibold text-brand-900">
        {guide.title || 'Hướng dẫn & nội quy nhóm'}
      </summary>
      {guide.intro ? <p className="mt-2 text-ink-muted">{guide.intro}</p> : null}
      {guide.dos?.length ? (
        <>
          <p className="mt-3 text-xs font-bold text-emerald-700 uppercase">Nên</p>
          <ul className="mt-1 list-disc space-y-0.5 pl-5 text-ink">
            {guide.dos.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        </>
      ) : null}
      {guide.donts?.length ? (
        <>
          <p className="mt-3 text-xs font-bold text-red-700 uppercase">Không</p>
          <ul className="mt-1 list-disc space-y-0.5 pl-5 text-ink">
            {guide.donts.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        </>
      ) : null}
      {guide.starters?.length ? (
        <>
          <p className="mt-3 text-xs font-bold text-brand-700">Chưa biết nói gì? Hãy thử:</p>
          <ul className="mt-1 flex flex-wrap gap-2">
            {guide.starters.map((line) =>
              onStarter ? (
                <li key={line}>
                  <button
                    type="button"
                    onClick={() => onStarter(line)}
                    className="rounded-full border border-brand-200 px-3 py-1 text-xs text-brand-900 hover:bg-brand-50"
                  >
                    {line}
                  </button>
                </li>
              ) : (
                <li key={line} className="rounded-full border border-hairline px-3 py-1 text-xs text-ink-muted">
                  {line}
                </li>
              ),
            )}
          </ul>
        </>
      ) : null}
    </details>
  );
}
