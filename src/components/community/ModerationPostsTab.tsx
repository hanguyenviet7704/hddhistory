import React, { useCallback, useEffect, useState } from "react";
import { Button, MenuItem, Pagination, Skeleton, TextField } from "@mui/material";
import {
  EyeIcon,
  EyeOffIcon,
  LockIcon,
  MessageSquareIcon,
  PinIcon,
  UnlockIcon,
} from "lucide-react";
import { useSelector } from "react-redux";

import { communityService } from "../../services/communityService";
import { RootState } from "../../store";
import {
  CommunityContentStatus,
  CommunityPostType,
  ICommunityAdminPost,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";
import CommunityContentCard from "./CommunityContentCard";
import { COMMUNITY_LANGS } from "./TranslationFields";
import ModerationReasonDialog from "./ModerationReasonDialog";

const TAKE = 20;

interface Props {
  /** Jumps to the comments tab scoped to one post. */
  onViewComments: (postId: string) => void;
}

const ModerationPostsTab: React.FC<Props> = ({ onViewComments }) => {
  const { showSuccess, showError } = useNotification();
  const lang = useSelector((state: RootState) => state.lang.code);

  const [posts, setPosts] = useState<ICommunityAdminPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<CommunityContentStatus | "">(
    CommunityContentStatus.VISIBLE
  );
  const [locale, setLocale] = useState("");
  const [hiding, setHiding] = useState<ICommunityAdminPost | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getPosts({
        page,
        take: TAKE,
        type: CommunityPostType.POST,
        ...(status ? { status } : {}),
        ...(locale ? { locale } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setPosts(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách bài");
    } finally {
      setLoading(false);
    }
  }, [page, status, locale, search]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  // Filters change what page 1 even means, so reset the page with them rather
  // than leaving the operator on an empty page 4.
  useEffect(() => {
    setPage(1);
  }, [status, locale, search]);

  const act = async (
    post: ICommunityAdminPost,
    payload: Parameters<typeof communityService.moderatePost>[1],
    successMessage: string
  ) => {
    setSaving(true);
    try {
      await communityService.moderatePost(post.id, payload);
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
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <TextField
          size="small"
          placeholder="Tìm trong nội dung bài"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          className="min-w-[240px]"
        />
        <TextField
          select
          size="small"
          label="Trạng thái"
          value={status}
          onChange={(event) =>
            setStatus(event.target.value as CommunityContentStatus | "")
          }
          className="min-w-[160px]"
        >
          <MenuItem value="">Tất cả</MenuItem>
          <MenuItem value={CommunityContentStatus.VISIBLE}>Đang hiện</MenuItem>
          <MenuItem value={CommunityContentStatus.HIDDEN}>Đã ẩn</MenuItem>
          <MenuItem value={CommunityContentStatus.DELETED}>
            Tác giả đã xoá
          </MenuItem>
        </TextField>
        <TextField
          select
          size="small"
          label="Ngôn ngữ"
          value={locale}
          onChange={(event) => setLocale(event.target.value)}
          className="min-w-[140px]"
        >
          <MenuItem value="">Tất cả</MenuItem>
          {COMMUNITY_LANGS.map(({ code, label }) => (
            <MenuItem key={code} value={code}>
              {label}
            </MenuItem>
          ))}
        </TextField>
      </div>

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <div className="space-y-3">
        {loading &&
          Array.from({ length: 3 }).map((_, index) => (
            <Skeleton key={index} variant="rounded" height={168} />
          ))}

        {!loading && !posts.length && (
          <div className="rounded-2xl border border-dashed border-gray-300 py-12 text-center text-sm text-gray-500">
            Không có bài nào khớp bộ lọc.
          </div>
        )}

        {!loading &&
          posts.map((post) => (
            <CommunityContentCard
              key={post.id}
              author={post.author}
              createdAt={post.createdAt}
              status={post.status}
              topicLabel={
                post.topic
                  ? getTranslationValue(post.topic.name ?? undefined, lang)
                  : null
              }
              subject={post.subject}
              body={post.body}
              images={post.images}
              attachedCard={post.attachedCard}
              flags={[
                ...(post.locale ? [post.locale.toUpperCase()] : []),
                ...(post.isPinned ? ["Đã ghim"] : []),
                ...(post.commentsLocked ? ["Khoá bình luận"] : []),
              ]}
              likeCount={post.likeCount}
              commentCount={post.commentCount}
              reportCount={post.reportCount}
              note={
                post.hiddenByReports ? (
                  <span className="text-red-700">
                    Tự ẩn do {post.reportCount} báo cáo — chờ bạn xác nhận ở tab
                    Báo cáo (giữ lại = hiện lại bài)
                  </span>
                ) : post.hiddenReason ? (
                  <span className="text-amber-700">
                    Lý do ẩn: {post.hiddenReason}
                  </span>
                ) : null
              }
              actions={
                <>
                  <Button
                    size="small"
                    startIcon={<MessageSquareIcon size={15} />}
                    onClick={() => onViewComments(post.id)}
                  >
                    Bình luận ({post.commentCount})
                  </Button>
                  <Button
                    size="small"
                    color={post.commentsLocked ? "warning" : "inherit"}
                    startIcon={
                      post.commentsLocked ? (
                        <UnlockIcon size={15} />
                      ) : (
                        <LockIcon size={15} />
                      )
                    }
                    disabled={saving}
                    onClick={() =>
                      act(
                        post,
                        { commentsLocked: !post.commentsLocked },
                        post.commentsLocked
                          ? "Đã mở lại bình luận"
                          : "Đã khoá bình luận"
                      )
                    }
                  >
                    {post.commentsLocked ? "Mở bình luận" : "Khoá bình luận"}
                  </Button>
                  <Button
                    size="small"
                    color={post.isPinned ? "primary" : "inherit"}
                    startIcon={<PinIcon size={15} />}
                    disabled={saving}
                    onClick={() =>
                      act(
                        post,
                        { isPinned: !post.isPinned },
                        post.isPinned ? "Đã bỏ ghim" : "Đã ghim bài"
                      )
                    }
                  >
                    {post.isPinned ? "Bỏ ghim" : "Ghim"}
                  </Button>
                  {post.status === CommunityContentStatus.VISIBLE ? (
                    <Button
                      size="small"
                      variant="outlined"
                      color="warning"
                      startIcon={<EyeOffIcon size={15} />}
                      disabled={saving}
                      onClick={() => setHiding(post)}
                    >
                      Ẩn bài
                    </Button>
                  ) : (
                    post.status === CommunityContentStatus.HIDDEN && (
                      <Button
                        size="small"
                        variant="outlined"
                        startIcon={<EyeIcon size={15} />}
                        disabled={saving}
                        onClick={() =>
                          act(
                            post,
                            { status: CommunityContentStatus.VISIBLE },
                            "Đã hiện lại bài"
                          )
                        }
                      >
                        Hiện lại
                      </Button>
                    )
                  )}
                </>
              }
            />
          ))}
      </div>

      {totalPages > 1 && (
        <div className="flex justify-end">
          <Pagination
            page={page}
            count={totalPages}
            onChange={(_, next) => setPage(next)}
          />
        </div>
      )}

      <ModerationReasonDialog
        open={!!hiding}
        title="Ẩn bài này?"
        description="Bài sẽ biến khỏi feed, toàn bộ bình luận của bài cũng bị ẩn theo, và tác giả nhận được thông báo kèm lý do bên dưới. Mọi báo cáo đang chờ về bài này sẽ được đóng lại."
        saving={saving}
        onClose={() => setHiding(null)}
        onConfirm={(reason) =>
          hiding &&
          act(
            hiding,
            { status: CommunityContentStatus.HIDDEN, hiddenReason: reason },
            "Đã ẩn bài"
          )
        }
      />
    </div>
  );
};

export default ModerationPostsTab;
