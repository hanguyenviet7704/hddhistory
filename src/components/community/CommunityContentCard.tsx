import React, { useState } from "react";
import {
  BellIcon,
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
 * One piece of community content, drawn the way the app draws it.
 *
 * Replaces the seven-column table the three moderation tabs used to share. A
 * table forced the two things a moderator actually judges — the words and who
 * wrote them — into a 3-line clamp and a column of their own, so deciding
 * whether a post should stay up meant reconstructing it from fragments. Here
 * the row IS the post: same order as the feed (room chip, headline, author
 * line, body), same avatar palette, the whole text, the pictures, the attached
 * card. What a moderator reads is what the reader read.
 *
 * The moderation half lives at the edges rather than mixed in: status at the
 * top right, the counters and the actions along the bottom. Taken-down content
 * is greyed as a whole, so a list can be scanned for what is still live without
 * reading a single status chip.
 */
export interface CommunityContentCardProps {
  author?: ICommunityAuthor | null;
  createdAt: string;
  status: CommunityContentStatus;

  /** The room this was written in — part of the meta line, as the group is on Facebook. */
  topicLabel?: string | null;

  /** Draws the pinned strip above the header, and says why this row is first. */
  pinned?: boolean;
  subject?: string;
  body: string;
  images?: string[];
  attachedCard?: ICommunityAttachedCard | null;

  /** Short pills after the name: "đã ghim", "khoá bình luận", "vi". */
  flags?: string[];

  likeCount?: number;
  commentCount?: number;
  replyCount?: number;
  reportCount?: number;

  /** Why this is hidden, in words a moderator can act on. */
  note?: React.ReactNode;

  /** Anything above the card itself — the report's reason strip, say. */
  banner?: React.ReactNode;

  actions?: React.ReactNode;

  /** A reply sits indented under its parent, as in the thread. */
  indented?: boolean;
}

/** Past this the body is clamped and gets a toggle, so one long post cannot bury the rest of the queue. */
const LONG_BODY = 700;

const AUTHOR_BADGE: Partial<Record<CommunityAuthorType, string>> = {
  [CommunityAuthorType.OFFICIAL]: "Đội ngũ MeUp",
  [CommunityAuthorType.ANONYMOUS]: "Đăng ẩn danh",
};

const CommunityContentCard: React.FC<CommunityContentCardProps> = ({
  author,
  createdAt,
  status,
  topicLabel,
  pinned,
  subject,
  body,
  images,
  attachedCard,
  flags,
  likeCount,
  commentCount,
  replyCount,
  reportCount,
  note,
  banner,
  actions,
  indented,
}) => {
  const [expanded, setExpanded] = useState(false);
  const isLong = (body?.length ?? 0) > LONG_BODY;
  const isDown = status !== CommunityContentStatus.VISIBLE;
  const badge = author?.authorType ? AUTHOR_BADGE[author.authorType] : undefined;

  return (
    <div className={indented ? "pl-10" : undefined}>
      <article
        className={[
          "rounded-2xl border bg-white p-4 transition-colors",
          isDown ? "border-gray-200 bg-gray-50" : "border-gray-200",
        ].join(" ")}
      >
        {banner}

        {pinned && (
          // Above everything, the way Facebook labels a pinned post — and the
          // reason this row is at the top of the list rather than in date order.
          <div className="mb-2 flex items-center gap-1.5 border-b border-gray-100 pb-2 text-xs font-semibold text-indigo-600">
            <PinIcon size={13} /> Bài đã ghim
          </div>
        )}

        <div className="flex items-start justify-between gap-4">
          <div
            className={[
              "flex min-w-0 flex-1 items-start gap-3",
              isDown ? "opacity-60" : "",
            ].join(" ")}
          >
            <CommunityAvatarDisc author={author} size={indented ? 30 : 38} />
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-x-2 gap-y-1">
                <span className="text-sm font-semibold text-gray-900">
                  {author?.name || "(tài khoản đã xoá)"}
                </span>
                {badge && (
                  // Said out loud so a moderator never assumes the writer put
                  // their name to it — and so it stays obvious that a ban still
                  // has a target, because the id underneath is the real one.
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
              {/* Facebook's second line: where it was posted, then when. The
                  room leads because it is the context the words were written
                  in — the same order the app shows above the headline. */}
              <div className="mt-0.5 flex flex-wrap items-center gap-x-1.5 text-xs text-gray-500">
                {!!topicLabel && (
                  <>
                    <span className="font-medium text-indigo-600">
                      {topicLabel}
                    </span>
                    <span>·</span>
                  </>
                )}
                <span>{new Date(createdAt).toLocaleString("vi-VN")}</span>
                {author?.id && (
                  <>
                    <span>·</span>
                    <span className="text-gray-400">{author.id}</span>
                  </>
                )}
              </div>
            </div>
          </div>

          <div className="shrink-0">
            <CommunityStatusChip status={status} />
          </div>
        </div>

        <div
          className={[
            // Full width, not indented under the avatar: a post is read as a
            // block of writing, and Facebook, the app's own thread screen and
            // every other feed put the words under the header, not beside it.
            "mt-3",
            // Dimmed when it is off the feed, so a list can be scanned for what
            // is still live without reading a single status chip. The actions
            // below stay at full strength — the one thing you came to click
            // must not be the faintest thing on the card.
            isDown ? "opacity-60" : "",
          ].join(" ")}
        >
          {!!subject && (
            <h3 className="mb-1 text-[15px] font-semibold leading-snug text-gray-900">
              {subject}
            </h3>
          )}

          {!!body && (
            <p
              className={[
                "whitespace-pre-wrap text-sm leading-relaxed text-gray-700",
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

          {!!images?.length && (
            // One picture runs the width of the card, several go two-up — what
            // a feed does, and what makes a picture judgeable. As 96px
            // thumbnails they were too small to tell whether the content was
            // the problem, which is the only question being asked here.
            <div
              className={[
                "mt-3 grid gap-1.5 overflow-hidden rounded-xl",
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
                      images.length > 1 ? "h-52" : "max-h-[420px]",
                    ].join(" ")}
                  />
                </a>
              ))}
            </div>
          )}

          {attachedCard && (
            // The reader sees this as a dark card in the feed; keeping it dark
            // here is what makes it recognisable as "the thing they attached"
            // rather than another block of admin text.
            <div className="mt-3 max-w-md rounded-xl bg-[#211B40] px-3 py-2.5">
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

          {/* Facebook's summary line: what the readers did, sitting between the
              content and the buttons rather than in a column of its own. */}
          <div className="mt-3 flex flex-wrap items-center gap-4 text-xs text-gray-500">
            {likeCount !== undefined && (
              <span className="flex items-center gap-1">
                <HeartIcon size={13} /> {likeCount}
              </span>
            )}
            {commentCount !== undefined && (
              <span className="flex items-center gap-1">
                <MessageCircleIcon size={13} /> {commentCount}
              </span>
            )}
            {replyCount !== undefined && (
              <span className="flex items-center gap-1">
                <BellIcon size={13} /> {replyCount}
              </span>
            )}
            {/* Loud only when there is something to be loud about: a queue where
                every row shouts is a queue nobody triages. */}
            {!!reportCount && (
              <span className="flex items-center gap-1 font-semibold text-red-600">
                <FlagIcon size={13} /> {reportCount} báo cáo
              </span>
            )}
          </div>

          {note && <div className="mt-2 text-xs">{note}</div>}
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
