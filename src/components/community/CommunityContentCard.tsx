import React, { useState } from "react";
import {
  BellIcon,
  BookOpenIcon,
  FlagIcon,
  HeartIcon,
  MessageCircleIcon,
  PinIcon,
} from "lucide-react";

import {
  CommunityAuthorType,
  CommunityContentStatus,
  ICommunityAttachedCard,
  ICommunityAuthor,
} from "../../types/interface/community.interface";
import CommunityAvatarDisc from "./CommunityAvatarDisc";
import CommunityStatusChip from "./CommunityStatusChip";

/**
 * One piece of community content, laid out as the app lays it out.
 *
 * The order is the Flutter card's own, widget for widget: room chip, headline,
 * then the author line, then everything else indented to line up with the NAME
 * rather than with the card edge. That indent is what makes a thread read as
 * one block hanging off one person, and it is the detail that made the panel
 * look like a different product from the phone.
 *
 * The moderation half lives at the edges rather than mixed in: status at the top
 * right, the counters where the app puts them, the actions in a bar below a
 * divider. Taken-down content is greyed as a whole, so a list can be scanned for
 * what is still live without reading a single status chip.
 */
export interface CommunityContentCardProps {
  author?: ICommunityAuthor | null;
  createdAt: string;
  status: CommunityContentStatus;

  /** The room, as the chip above the headline — the app's `_TopicChip`. */
  topicLabel?: string | null;

  /**
   * Keep the room's place even when there is none.
   *
   * A post CAN be written without picking a room — both composers allow it — so
   * a blank where the room goes is ambiguous: a moderator cannot tell "no room"
   * from "the panel failed to show it". Comments and chat lines have no room at
   * all, so they leave the slot off entirely.
   */
  showRoomSlot?: boolean;

  /** Draws the pinned strip, and says why this row is first. */
  pinned?: boolean;

  subject?: string;
  body: string;
  images?: string[];
  attachedCard?: ICommunityAttachedCard | null;

  /** A shared course — the app draws a cover card; here it is a link to the editor. */
  attachedCourseId?: string | null;

  /** Short pills after the name: "Khoá bình luận", "VI", "Trả lời". */
  flags?: string[];

  likeCount?: number;
  commentCount?: number;

  /** The bell — readers following this thread. */
  saveCount?: number;
  replyCount?: number;
  reportCount?: number;

  /** Why this is hidden, in words a moderator can act on. */
  note?: React.ReactNode;

  /** Anything above the card itself — the report's reason strip, say. */
  banner?: React.ReactNode;

  actions?: React.ReactNode;

  /**
   * Filters the list down to this author.
   *
   * The one moderation move the app has no equivalent for: judging a single post
   * tells you whether it is bad, and the author's other twenty tell you whether
   * you are looking at a person having a bad day or at a spammer.
   */
  onAuthorClick?: () => void;

  /** A reply sits indented under its parent, as in the thread. */
  indented?: boolean;
}

/** Past this the body is clamped and gets a toggle, so one long post cannot bury the rest of the queue. */
const LONG_BODY = 700;

/** Avatar width plus its gap — the app's `CommunityBylineRow.indent`. */
const BODY_INDENT = 37;

const AUTHOR_BADGE: Partial<Record<CommunityAuthorType, string>> = {
  [CommunityAuthorType.OFFICIAL]: "Đội ngũ MeUp",
  [CommunityAuthorType.ANONYMOUS]: "Đăng ẩn danh",
};

/**
 * "3 giờ trước", the way the app writes it.
 *
 * Deliberately coarse, and deliberately NOT the whole story: the exact stamp
 * stays on the `title` attribute, because a moderator sometimes does need the
 * minute and a reader never does.
 */
const relativeTime = (iso: string) => {
  const elapsed = Date.now() - new Date(iso).getTime();
  const minutes = Math.floor(elapsed / 60000);
  if (minutes < 1) return "Vừa xong";
  if (minutes < 60) return `${minutes} phút trước`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} giờ trước`;

  const days = Math.floor(hours / 24);
  if (days === 1) return "Hôm qua";
  if (days < 7) return `${days} ngày trước`;

  return `${Math.floor(days / 7)} tuần trước`;
};

const CommunityContentCard: React.FC<CommunityContentCardProps> = ({
  author,
  createdAt,
  status,
  topicLabel,
  showRoomSlot,
  pinned,
  subject,
  body,
  images,
  attachedCard,
  attachedCourseId,
  flags,
  likeCount,
  commentCount,
  saveCount,
  replyCount,
  reportCount,
  note,
  banner,
  actions,
  onAuthorClick,
  indented,
}) => {
  const [expanded, setExpanded] = useState(false);
  const isLong = (body?.length ?? 0) > LONG_BODY;
  const isDown = status !== CommunityContentStatus.VISIBLE;
  const badge = author?.authorType ? AUTHOR_BADGE[author.authorType] : undefined;
  const stamp = new Date(createdAt).toLocaleString("vi-VN");

  return (
    <div className={indented ? "pl-10" : undefined}>
      <article
        className={[
          // 18px radius and a hairline border, the app card's own.
          "rounded-[18px] border border-gray-200 p-4",
          isDown ? "bg-gray-50" : "bg-white",
        ].join(" ")}
      >
        {pinned && (
          <div className="mb-2 flex items-center gap-1.5 border-b border-gray-100 pb-2 text-xs font-semibold text-indigo-600">
            <PinIcon size={13} /> Bài đã ghim
          </div>
        )}

        {banner}

        <div className={isDown ? "opacity-60" : undefined}>
          <div className="flex items-start justify-between gap-4">
            <div className="min-w-0 flex-1">
              {topicLabel ? (
                <span className="mb-2 inline-block rounded-full bg-[#F4F3FD] px-2.5 py-1 text-[11px] font-bold text-[#7A69E8]">
                  {topicLabel}
                </span>
              ) : (
                showRoomSlot && (
                  <span className="mb-2 inline-block rounded-full bg-gray-100 px-2.5 py-1 text-[11px] font-medium italic text-gray-400">
                    Không có phòng
                  </span>
                )
              )}

              {!!subject && (
                <h3 className="mb-2 text-base font-bold leading-[1.3] text-gray-900">
                  {subject}
                </h3>
              )}

              {/* The app's byline: a 30px disc, then the name and the age of the
                  post as one quiet run of text. */}
              <div className="flex items-center gap-[7px]">
                <CommunityAvatarDisc author={author} size={indented ? 26 : 30} />
                <div className="flex min-w-0 flex-wrap items-center gap-x-1.5 gap-y-1">
                  {onAuthorClick ? (
                    <button
                      type="button"
                      onClick={onAuthorClick}
                      className="text-[13.5px] font-bold text-[#3A4250] hover:text-indigo-600 hover:underline"
                    >
                      {author?.name || "(tài khoản đã xoá)"}
                    </button>
                  ) : (
                    <span className="text-[13.5px] font-bold text-[#3A4250]">
                      {author?.name || "(tài khoản đã xoá)"}
                    </span>
                  )}
                  <span
                    className="text-[11px] font-semibold text-gray-400"
                    title={stamp}
                  >
                    · {relativeTime(createdAt)}
                  </span>
                  {badge && (
                    // Said out loud so a moderator never assumes the writer put
                    // their name to it — and so it stays obvious that a ban
                    // still has a target, because the id below is the real one.
                    <span className="rounded bg-amber-100 px-1.5 py-0.5 text-[11px] font-semibold text-amber-800">
                      {badge}
                    </span>
                  )}
                  {flags?.map((flag) => (
                    <span
                      key={flag}
                      className="rounded bg-gray-100 px-1.5 py-0.5 text-[11px] font-medium text-gray-600"
                    >
                      {flag}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            <div className="shrink-0">
              <CommunityStatusChip status={status} />
            </div>
          </div>

          {/* Everything below the name lines up WITH the name, not with the card
              edge — the app's `_bodyIndent`. */}
          <div style={{ paddingLeft: BODY_INDENT }} className="mt-0.5">
            {!!body && (
              <p
                className={[
                  "whitespace-pre-wrap text-sm leading-[1.55] text-gray-600",
                  isLong && !expanded ? "line-clamp-6" : "",
                ].join(" ")}
              >
                {body}
              </p>
            )}

            {isLong && (
              <button
                type="button"
                className="mt-1 text-xs font-semibold text-indigo-600 hover:underline"
                onClick={() => setExpanded((prev) => !prev)}
              >
                {expanded ? "Thu gọn" : "Xem thêm"}
              </button>
            )}

            {attachedCard && (
              // The reader sees this as a dark card in the feed; keeping it dark
              // here is what makes it recognisable as "the thing they attached"
              // rather than another block of admin text.
              <div className="mt-3 max-w-md rounded-[14px] bg-[#211B40] px-3 py-2.5">
                <div className="text-xs font-semibold text-white">
                  {attachedCard.title}
                </div>
                <div className="mt-0.5 text-[11px] leading-snug text-white/70">
                  {attachedCard.back}
                </div>
                {!!attachedCard.courseName && (
                  <div className="mt-1 text-[10px] uppercase tracking-wide text-white/50">
                    {attachedCard.courseName}
                  </div>
                )}
              </div>
            )}

            {!!attachedCourseId && (
              // A link rather than a rendered cover: the panel would have to
              // fetch the course to draw one, and what a moderator needs from it
              // is a way THERE, not a picture of it.
              <a
                href={`/course/${attachedCourseId}`}
                target="_blank"
                rel="noreferrer"
                className="mt-3 flex max-w-md items-center gap-2 rounded-[14px] border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-700 hover:border-indigo-300 hover:text-indigo-700"
              >
                <BookOpenIcon size={14} />
                Đính kèm khoá học — mở trang khoá
              </a>
            )}

            {!!images?.length && (
              // The app draws one 150-tall picture across the card's width;
              // several go two-up here so a post with four is still one glance.
              <div
                className={[
                  "mt-3 grid gap-1.5 overflow-hidden rounded-[14px]",
                  images.length > 1 ? "grid-cols-2" : "grid-cols-1",
                ].join(" ")}
              >
                {images.map((url) => (
                  <a key={url} href={url} target="_blank" rel="noreferrer">
                    <img
                      src={url}
                      alt=""
                      className={[
                        "w-full border border-gray-200 object-cover",
                        images.length > 1 ? "h-48" : "max-h-[360px]",
                      ].join(" ")}
                    />
                  </a>
                ))}
              </div>
            )}

            {/* The app's action row, in the app's order: heart, bubble, bell —
                plus the one counter the reader never sees. */}
            <div className="mt-2.5 flex flex-wrap items-center gap-5 text-[12.5px] font-medium text-gray-500">
              {likeCount !== undefined && (
                <span className="flex items-center gap-1.5" title="Lượt tim">
                  <HeartIcon size={16} /> {likeCount}
                </span>
              )}
              {commentCount !== undefined && (
                <span className="flex items-center gap-1.5" title="Bình luận">
                  <MessageCircleIcon size={16} /> {commentCount}
                </span>
              )}
              {saveCount !== undefined && (
                <span
                  className="flex items-center gap-1.5"
                  title="Người theo dõi thread"
                >
                  <BellIcon size={16} /> {saveCount}
                </span>
              )}
              {replyCount !== undefined && (
                <span className="flex items-center gap-1.5" title="Trả lời">
                  <MessageCircleIcon size={16} /> {replyCount}
                </span>
              )}
              {/* Loud only when there is something to be loud about: a queue
                  where every row shouts is a queue nobody triages. */}
              {!!reportCount && (
                <span className="flex items-center gap-1.5 font-semibold text-red-600">
                  <FlagIcon size={15} /> {reportCount} báo cáo
                </span>
              )}
            </div>

            {note && <div className="mt-2 text-xs">{note}</div>}
          </div>
        </div>

        {actions && (
          <div className="mt-3 flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 pt-3">
            {actions}
          </div>
        )}
      </article>
    </div>
  );
};

export default CommunityContentCard;
