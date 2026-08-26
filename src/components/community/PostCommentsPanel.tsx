import React, { useCallback, useEffect, useMemo, useState } from "react";
import { Button, Skeleton } from "@mui/material";
import { EyeIcon, EyeOffIcon } from "lucide-react";

import { communityService } from "../../services/communityService";
import {
  CommunityContentStatus,
  ICommunityAdminComment,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import CommunityContentCard from "./CommunityContentCard";
import ModerationReasonDialog from "./ModerationReasonDialog";

/** One post's thread, so the whole queue is not paginated for one long thread. */
const TAKE = 50;

interface Props {
  postId: string;
}

/**
 * A post's comments, opened underneath the post itself.
 *
 * This replaced a whole tab. Comments were their own list with their own
 * filters, which meant judging a reply — the thing most often reported — with
 * the post it answers on another screen. A comment is only ever offensive, or
 * fine, IN a conversation; reading it out of one is reading a different comment.
 *
 * Every status is loaded, not just the visible ones: the panel is opened to see
 * what a thread looks like, and a hidden line missing from it makes the thread
 * read as if nothing was ever taken down.
 */
const PostCommentsPanel: React.FC<Props> = ({ postId }) => {
  const { showSuccess, showError } = useNotification();

  const [comments, setComments] = useState<ICommunityAdminComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hiding, setHiding] = useState<ICommunityAdminComment | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getComments({ postId, page: 1, take: TAKE });
      setComments(res?.items ?? []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được bình luận");
    } finally {
      setLoading(false);
    }
  }, [postId]);

  useEffect(() => {
    load();
  }, [load]);

  /**
   * Top-level comments oldest-first, each followed by its own replies.
   *
   * The endpoint answers newest-first and flat, which is right for a queue and
   * wrong for a thread: laid out that way an answer appears above the line it
   * answers.
   */
  const thread = useMemo(() => {
    const byTime = (a: ICommunityAdminComment, b: ICommunityAdminComment) =>
      new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();

    const parents = comments.filter((row) => !row.parentId).sort(byTime);
    const replies = comments.filter((row) => row.parentId).sort(byTime);

    const rows: ICommunityAdminComment[] = [];
    for (const parent of parents) {
      rows.push(parent);
      rows.push(...replies.filter((reply) => reply.parentId === parent.id));
    }

    // A reply whose parent is outside this page still has to be shown — losing
    // it would hide exactly the line someone reported.
    const orphans = replies.filter(
      (reply) => !parents.some((parent) => parent.id === reply.parentId)
    );

    return [...rows, ...orphans];
  }, [comments]);

  const act = async (
    comment: ICommunityAdminComment,
    payload: Parameters<typeof communityService.moderateComment>[1],
    successMessage: string
  ) => {
    setSaving(true);
    try {
      await communityService.moderateComment(comment.id, payload);
      showSuccess(successMessage);
      setHiding(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không thực hiện được");
    } finally {
      setSaving(false);
    }
  };

  return (
    // Indented and on a tinted ground, so it reads as belonging to the post
    // above rather than as the next card in the list.
    <div className="ml-6 mt-1 space-y-2 rounded-b-2xl border-l-2 border-indigo-100 bg-gray-50/70 py-3 pl-4 pr-3">
      {loading && <Skeleton variant="rounded" height={72} />}

      {!loading && error && (
        <div className="flex items-center gap-3 text-sm text-red-700">
          {error}
          <Button size="small" onClick={load}>
            Thử lại
          </Button>
        </div>
      )}

      {!loading && !error && !thread.length && (
        <div className="py-2 text-sm text-gray-500">Bài này chưa có bình luận.</div>
      )}

      {!loading &&
        thread.map((comment) => (
          <CommunityContentCard
            key={comment.id}
            author={comment.author}
            createdAt={comment.createdAt}
            status={comment.status}
            body={comment.body}
            indented={!!comment.parentId}
            flags={comment.parentId ? ["Trả lời"] : undefined}
            likeCount={comment.likeCount}
            replyCount={comment.parentId ? undefined : comment.replyCount}
            reportCount={comment.reportCount}
            note={
              comment.hiddenWithPost ? (
                <span className="text-amber-700">
                  Ẩn theo bài đăng — hiện lại bài sẽ hiện lại bình luận này
                </span>
              ) : comment.hiddenByReports ? (
                <span className="text-red-700">
                  Tự ẩn do {comment.reportCount} báo cáo — chờ bạn xác nhận ở tab
                  Báo cáo (giữ lại = hiện lại)
                </span>
              ) : comment.hiddenReason ? (
                <span className="text-amber-700">
                  Lý do ẩn: {comment.hiddenReason}
                </span>
              ) : null
            }
            actions={
              comment.status === CommunityContentStatus.VISIBLE ? (
                <Button
                  size="small"
                  variant="outlined"
                  color="warning"
                  startIcon={<EyeOffIcon size={15} />}
                  disabled={saving}
                  onClick={() => setHiding(comment)}
                >
                  Ẩn bình luận
                </Button>
              ) : (
                comment.status === CommunityContentStatus.HIDDEN && (
                  <Button
                    size="small"
                    variant="outlined"
                    startIcon={<EyeIcon size={15} />}
                    disabled={saving}
                    onClick={() =>
                      act(
                        comment,
                        { status: CommunityContentStatus.VISIBLE },
                        "Đã hiện lại bình luận"
                      )
                    }
                  >
                    Hiện lại
                  </Button>
                )
              )
            }
          />
        ))}

      <ModerationReasonDialog
        open={!!hiding}
        title="Ẩn bình luận này?"
        description="Bình luận sẽ biến khỏi thread và tác giả nhận được thông báo kèm lý do bên dưới."
        saving={saving}
        onClose={() => setHiding(null)}
        onConfirm={(reason) =>
          hiding &&
          act(
            hiding,
            { status: CommunityContentStatus.HIDDEN, hiddenReason: reason },
            "Đã ẩn bình luận"
          )
        }
      />
    </div>
  );
};

export default PostCommentsPanel;
