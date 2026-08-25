import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  MenuItem,
  Pagination,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Tooltip,
} from "@mui/material";
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
  CommunityAuthorType,
  CommunityContentStatus,
  CommunityPostType,
  ICommunityAdminPost,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import { getTranslationValue } from "../../utils/translation";
import CommunityStatusChip from "./CommunityStatusChip";
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

      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Nội dung</TableCell>
              <TableCell>Tác giả</TableCell>
              <TableCell>Chủ đề</TableCell>
              <TableCell align="right">Tương tác</TableCell>
              <TableCell align="right">Báo cáo</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right">Hành động</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 5 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={7}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !posts.length && (
              <TableRow>
                <TableCell colSpan={7}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Không có bài nào khớp bộ lọc.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              posts.map((post) => (
                <TableRow key={post.id} hover>
                  <TableCell className="max-w-md">
                    {!!post.subject && (
                      <div className="mb-0.5 line-clamp-2 text-sm font-semibold text-gray-900">
                        {post.subject}
                      </div>
                    )}
                    <div className="line-clamp-3 whitespace-pre-wrap text-sm">
                      {post.body}
                    </div>
                    {post.attachedCard && (
                      <div className="mt-1.5 rounded-lg bg-[#211B40] px-2.5 py-2">
                        <div className="line-clamp-1 text-xs font-semibold text-white">
                          {post.attachedCard.title}
                        </div>
                        <div className="line-clamp-2 text-[11px] leading-snug text-white/70">
                          {post.attachedCard.back}
                        </div>
                      </div>
                    )}
                    <div className="mt-1 flex items-center gap-2 text-xs text-gray-500">
                      <span>
                        {new Date(post.createdAt).toLocaleString("vi-VN")}
                      </span>
                      {post.locale && <span>· {post.locale.toUpperCase()}</span>}
                      {!!post.images?.length && (
                        <span>· {post.images.length} ảnh</span>
                      )}
                      {post.isPinned && (
                        <span className="text-indigo-600">· đã ghim</span>
                      )}
                      {post.commentsLocked && (
                        <span className="text-amber-700">· khoá bình luận</span>
                      )}
                    </div>
                    {post.hiddenReason && (
                      <div className="mt-1 text-xs text-amber-700">
                        Lý do ẩn: {post.hiddenReason}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      {post.author?.name || "(tài khoản đã xoá)"}
                    </div>
                    <div className="text-xs text-gray-500">
                      {post.author?.authorType === CommunityAuthorType.OFFICIAL
                        ? "Đội ngũ MeUp"
                        : post.author?.id}
                    </div>
                    {/* The reader saw no name here. Said out loud so a
                        moderator does not assume the writer put their name to
                        it — and so it is obvious the ban still has a target. */}
                    {post.author?.authorType ===
                      CommunityAuthorType.ANONYMOUS && (
                      <span className="mt-1 inline-block rounded bg-amber-100 px-1.5 py-0.5 text-[11px] font-semibold text-amber-800">
                        Đăng ẩn danh
                      </span>
                    )}
                  </TableCell>
                  <TableCell className="text-sm">
                    {post.topic
                      ? getTranslationValue(post.topic.name ?? undefined, lang)
                      : "—"}
                  </TableCell>
                  <TableCell align="right" className="text-xs">
                    {post.likeCount} tim
                    <br />
                    {post.commentCount} bình luận
                  </TableCell>
                  <TableCell align="right">
                    {post.reportCount ? (
                      <span className="font-semibold text-red-600">
                        {post.reportCount}
                      </span>
                    ) : (
                      <span className="text-gray-400">0</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <CommunityStatusChip status={post.status} />
                  </TableCell>
                  <TableCell align="right">
                    <div className="flex justify-end gap-1">
                      {post.status === CommunityContentStatus.VISIBLE ? (
                        <Tooltip title="Ẩn bài (kèm cả bình luận)">
                          <Button
                            size="small"
                            color="warning"
                            disabled={saving}
                            onClick={() => setHiding(post)}
                          >
                            <EyeOffIcon size={15} />
                          </Button>
                        </Tooltip>
                      ) : (
                        post.status === CommunityContentStatus.HIDDEN && (
                          <Tooltip title="Hiện lại bài">
                            <Button
                              size="small"
                              disabled={saving}
                              onClick={() =>
                                act(
                                  post,
                                  { status: CommunityContentStatus.VISIBLE },
                                  "Đã hiện lại bài"
                                )
                              }
                            >
                              <EyeIcon size={15} />
                            </Button>
                          </Tooltip>
                        )
                      )}
                      <Tooltip title={post.isPinned ? "Bỏ ghim" : "Ghim đầu feed"}>
                        <Button
                          size="small"
                          disabled={saving}
                          color={post.isPinned ? "primary" : "inherit"}
                          onClick={() =>
                            act(
                              post,
                              { isPinned: !post.isPinned },
                              post.isPinned ? "Đã bỏ ghim" : "Đã ghim bài"
                            )
                          }
                        >
                          <PinIcon size={15} />
                        </Button>
                      </Tooltip>
                      <Tooltip
                        title={
                          post.commentsLocked
                            ? "Mở lại bình luận"
                            : "Khoá bình luận"
                        }
                      >
                        <Button
                          size="small"
                          disabled={saving}
                          color={post.commentsLocked ? "warning" : "inherit"}
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
                          {post.commentsLocked ? (
                            <UnlockIcon size={15} />
                          ) : (
                            <LockIcon size={15} />
                          )}
                        </Button>
                      </Tooltip>
                      <Tooltip title="Xem bình luận của bài">
                        <Button
                          size="small"
                          color="inherit"
                          onClick={() => onViewComments(post.id)}
                        >
                          <MessageSquareIcon size={15} />
                        </Button>
                      </Tooltip>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

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
