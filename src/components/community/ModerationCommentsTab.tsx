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
import { EyeIcon, EyeOffIcon } from "lucide-react";

import { communityService } from "../../services/communityService";
import {
  CommunityContentStatus,
  ICommunityAdminComment,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import CommunityStatusChip from "./CommunityStatusChip";
import ModerationReasonDialog from "./ModerationReasonDialog";

const TAKE = 20;

interface Props {
  /** Set when arriving from a post row — scopes the list to that thread. */
  postId?: string;
  onClearPostFilter?: () => void;
}

const ModerationCommentsTab: React.FC<Props> = ({
  postId,
  onClearPostFilter,
}) => {
  const { showSuccess, showError } = useNotification();

  const [comments, setComments] = useState<ICommunityAdminComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<CommunityContentStatus | "">(
    CommunityContentStatus.VISIBLE
  );
  const [hiding, setHiding] = useState<ICommunityAdminComment | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getComments({
        page,
        take: TAKE,
        ...(status ? { status } : {}),
        ...(postId ? { postId } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setComments(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được danh sách bình luận"
      );
    } finally {
      setLoading(false);
    }
  }, [page, status, postId, search]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  useEffect(() => {
    setPage(1);
  }, [status, postId, search]);

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
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <TextField
          size="small"
          placeholder="Tìm trong nội dung bình luận"
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
        {postId && (
          <div className="flex items-center gap-2 rounded-md bg-indigo-50 px-3 py-1.5 text-xs text-indigo-700">
            Đang xem bình luận của một bài
            <Button size="small" onClick={onClearPostFilter}>
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

      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Nội dung</TableCell>
              <TableCell>Tác giả</TableCell>
              <TableCell>Cấp</TableCell>
              <TableCell align="right">Tim</TableCell>
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

            {!loading && !comments.length && (
              <TableRow>
                <TableCell colSpan={7}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Không có bình luận nào khớp bộ lọc.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              comments.map((comment) => (
                <TableRow key={comment.id} hover>
                  <TableCell className="max-w-md">
                    <div className="whitespace-pre-wrap text-sm">
                      {comment.body}
                    </div>
                    <div className="mt-1 text-xs text-gray-500">
                      {new Date(comment.createdAt).toLocaleString("vi-VN")}
                    </div>
                    {comment.hiddenWithPost ? (
                      <div className="mt-1 text-xs text-amber-700">
                        Ẩn theo bài đăng — hiện lại bài sẽ hiện lại bình luận này
                      </div>
                    ) : comment.hiddenByReports ? (
                      <div className="mt-1 text-xs text-red-700">
                        Tự ẩn do {comment.reportCount} báo cáo — chờ bạn xác nhận
                        ở tab Báo cáo (giữ lại = hiện lại)
                      </div>
                    ) : (
                      comment.hiddenReason && (
                        <div className="mt-1 text-xs text-amber-700">
                          Lý do ẩn: {comment.hiddenReason}
                        </div>
                      )
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="text-sm">
                      {comment.author?.name || "(tài khoản đã xoá)"}
                    </div>
                    <div className="text-xs text-gray-500">
                      {comment.author?.id}
                    </div>
                  </TableCell>
                  <TableCell className="text-xs">
                    {comment.parentId ? "Trả lời" : "Bình luận"}
                    {!comment.parentId && comment.replyCount > 0 && (
                      <div className="text-gray-500">
                        {comment.replyCount} trả lời
                      </div>
                    )}
                  </TableCell>
                  <TableCell align="right">{comment.likeCount}</TableCell>
                  <TableCell align="right">
                    {comment.reportCount ? (
                      <span className="font-semibold text-red-600">
                        {comment.reportCount}
                      </span>
                    ) : (
                      <span className="text-gray-400">0</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <CommunityStatusChip status={comment.status} />
                  </TableCell>
                  <TableCell align="right">
                    {comment.status === CommunityContentStatus.VISIBLE ? (
                      <Tooltip title="Ẩn bình luận">
                        <Button
                          size="small"
                          color="warning"
                          disabled={saving}
                          onClick={() => setHiding(comment)}
                        >
                          <EyeOffIcon size={15} />
                        </Button>
                      </Tooltip>
                    ) : (
                      comment.status === CommunityContentStatus.HIDDEN && (
                        <Tooltip title="Hiện lại bình luận">
                          <Button
                            size="small"
                            disabled={saving}
                            onClick={() =>
                              act(
                                comment,
                                { status: CommunityContentStatus.VISIBLE },
                                "Đã hiện lại bình luận"
                              )
                            }
                          >
                            <EyeIcon size={15} />
                          </Button>
                        </Tooltip>
                      )
                    )}
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
        title="Ẩn bình luận này?"
        description="Bình luận sẽ biến khỏi thread. Nếu đây là bình luận cấp 1, các trả lời bên dưới vẫn còn — ẩn riêng nếu cần. Mọi báo cáo đang chờ về bình luận này sẽ được đóng lại."
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

export default ModerationCommentsTab;
