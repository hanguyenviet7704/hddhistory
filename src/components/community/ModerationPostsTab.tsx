import React, { useCallback, useEffect, useState } from "react";
import { Button, MenuItem, Pagination, Skeleton, TextField } from "@mui/material";
import {
  ChevronUpIcon,
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
  ICommunityTopic,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";
import CommunityContentCard from "./CommunityContentCard";
import PostCommentsPanel from "./PostCommentsPanel";
import { COMMUNITY_LANGS } from "./TranslationFields";
import ModerationReasonDialog from "./ModerationReasonDialog";

const TAKE = 20;

const ModerationPostsTab: React.FC = () => {
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
  const [topicId, setTopicId] = useState("");
  const [topics, setTopics] = useState<ICommunityTopic[]>([]);
  /// Set by clicking a name: everything this account wrote, which is how a
  /// pattern shows itself. Cleared from the chip above the list.
  const [author, setAuthor] = useState<{ id: string; name: string } | null>(
    null
  );
  const [hiding, setHiding] = useState<ICommunityAdminPost | null>(null);
  const [saving, setSaving] = useState(false);

  /// One thread open at a time: the panel is for reading a conversation, and
  /// three of them unfolded is the wall of text the tab was meant to replace.
  const [openThread, setOpenThread] = useState<string | null>(null);

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
        ...(topicId ? { topicId } : {}),
        ...(author ? { authorId: author.id } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setPosts(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách bài");
    } finally {
      setLoading(false);
    }
  }, [page, status, locale, topicId, author, search]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  // Filters change what page 1 even means, so reset the page with them rather
  // than leaving the operator on an empty page 4.
  useEffect(() => {
    setPage(1);
  }, [status, locale, topicId, author, search]);

  // The room list is small and never changes mid-session, so it is fetched once
  // rather than with every filter change.
  useEffect(() => {
    communityService
      .getTopics({ page: 1, take: 100 })
      .then((res) => setTopics(res?.items ?? []))
      // The picker is a convenience; the list below still works without it.
      .catch(() => undefined);
  }, []);

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
        <TextField
          select
          size="small"
          label="Phòng"
          value={topicId}
          onChange={(event) => setTopicId(event.target.value)}
          className="min-w-[200px]"
        >
          <MenuItem value="">Tất cả phòng</MenuItem>
          {topics.map((topic) => (
            <MenuItem key={topic._id} value={topic._id}>
              {getTranslationValue(topic.name, lang)}
            </MenuItem>
          ))}
        </TextField>
        {author && (
          <div className="flex items-center gap-2 rounded-md bg-indigo-50 px-3 py-1.5 text-xs text-indigo-700">
            Chỉ bài của <strong>{author.name}</strong>
            <Button size="small" onClick={() => setAuthor(null)}>
              Bỏ lọc
            </Button>
          </div>
        )}
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
            <div key={post.id}>
              <CommunityContentCard
                author={post.author}
                createdAt={post.createdAt}
                status={post.status}
                topicLabel={
                  post.topic
                    ? getTranslationValue(post.topic.name ?? undefined, lang)
                    : null
                }
                showRoomSlot
                onAuthorClick={() =>
                  setAuthor({
                    id: post.author.id,
                    name: post.author.name || "(tài khoản đã xoá)",
                  })
                }
                subject={post.subject}
                body={post.body}
                images={post.images}
                attachedCard={post.attachedCard}
                attachedCourseId={post.attachedCourseId}
                pinned={post.isPinned}
                flags={[
                  ...(post.locale ? [post.locale.toUpperCase()] : []),
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
                      color={openThread === post.id ? "primary" : "inherit"}
                      startIcon={
                        openThread === post.id ? (
                          <ChevronUpIcon size={15} />
                        ) : (
                          <MessageSquareIcon size={15} />
                        )
                      }
                      onClick={() =>
                        setOpenThread((prev) =>
                          prev === post.id ? null : post.id
                        )
                      }
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
              {openThread === post.id && (
                <PostCommentsPanel postId={post.id} />
              )}
            </div>
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
