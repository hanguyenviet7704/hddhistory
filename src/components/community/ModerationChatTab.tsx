import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
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
  ICommunityAdminChatMessage,
  ICommunityChatRoom,
} from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";
import CommunityStatusChip from "./CommunityStatusChip";
import ModerationReasonDialog from "./ModerationReasonDialog";

const TAKE = 20;

/**
 * The group chat's moderation queue.
 *
 * Newest first and unfiltered by default is deliberate: a chat room is watched,
 * not audited. A moderator opens this to see what was just said, which is the
 * opposite of the reports queue — there is no "pending" state here, because a
 * chat line nobody reported is still the thing most likely to need taking down.
 */
const ModerationChatTab: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [messages, setMessages] = useState<ICommunityAdminChatMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<CommunityContentStatus | "">("");
  const [rooms, setRooms] = useState<ICommunityChatRoom[]>([]);
  const [room, setRoom] = useState("");
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState({ slug: "", name: "" });
  const [hiding, setHiding] = useState<ICommunityAdminChatMessage | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getChatMessages({
        page,
        take: TAKE,
        ...(status ? { status } : {}),
        ...(room ? { room } : {}),
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setMessages(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ?? "Không tải được tin nhắn trong nhóm"
      );
    } finally {
      setLoading(false);
    }
  }, [page, status, room, search]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  useEffect(() => {
    setPage(1);
  }, [status, room, search]);

  const loadRooms = useCallback(async () => {
    try {
      setRooms(await communityService.getChatRooms());
    } catch {
      // The picker is a convenience; the table below still works without it,
      // and a second red bar for it would bury the one that matters.
    }
  }, []);

  useEffect(() => {
    loadRooms();
  }, [loadRooms]);

  /**
   * Opens a room, or renames the one already on that slug.
   *
   * This is the only way to create one without a Mongo shell — the app opens
   * `hoi-ban-tron` by name, so an environment missing that row answers the chat
   * button with a 404 and nothing in the panel can fix it.
   */
  const saveRoom = async () => {
    const slug = form.slug.trim();
    const name = form.name.trim();
    if (!slug || !name) return;

    setSaving(true);
    try {
      await communityService.upsertChatRoom({ slug, name });
      showSuccess(`Đã lưu phòng "${name}"`);
      setCreating(false);
      setForm({ slug: "", name: "" });
      loadRooms();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Không lưu được phòng");
    } finally {
      setSaving(false);
    }
  };

  const act = async (
    message: ICommunityAdminChatMessage,
    payload: Parameters<typeof communityService.moderateChatMessage>[1],
    successMessage: string
  ) => {
    setSaving(true);
    try {
      await communityService.moderateChatMessage(message.id, payload);
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
          placeholder="Tìm trong nội dung tin nhắn"
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
        </TextField>
        <TextField
          select
          size="small"
          label="Phòng"
          value={room}
          onChange={(event) => setRoom(event.target.value)}
          className="min-w-[180px]"
        >
          <MenuItem value="">Tất cả</MenuItem>
          {rooms.map((item) => (
            <MenuItem key={item.id} value={item.slug}>
              {item.name}
            </MenuItem>
          ))}
        </TextField>
        <Button size="small" onClick={load} disabled={loading}>
          Tải lại
        </Button>
        <Button
          size="small"
          variant="outlined"
          onClick={() => setCreating(true)}
        >
          Tạo phòng
        </Button>
      </div>

      {rooms.length === 0 && !loading && (
        // Not an error — an environment nobody has opened a room on yet. Said
        // plainly, because the symptom on the phone (a 404 behind the chat
        // button) gives no hint that this is what is missing.
        <div className="rounded-md bg-amber-50 p-3 text-sm text-amber-800">
          Chưa có phòng chat nào. App mở phòng theo slug{" "}
          <code>hoi-ban-tron</code> — bấm "Tạo phòng" với đúng slug đó để nút
          chat trong app hết báo lỗi.
        </div>
      )}

      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      )}

      <Dialog
        open={creating}
        onClose={() => setCreating(false)}
        fullWidth
        maxWidth="xs"
      >
        <DialogTitle>Tạo / sửa phòng chat</DialogTitle>
        <DialogContent className="flex flex-col gap-4 pt-2">
          <TextField
            size="small"
            label="Slug"
            value={form.slug}
            onChange={(event) =>
              setForm((prev) => ({ ...prev, slug: event.target.value }))
            }
            helperText="Chữ thường, nối bằng dấu gạch. App đang mở: hoi-ban-tron"
          />
          <TextField
            size="small"
            label="Tên phòng"
            value={form.name}
            onChange={(event) =>
              setForm((prev) => ({ ...prev, name: event.target.value }))
            }
            helperText="Tên hiện trên đầu màn chat"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreating(false)}>Huỷ</Button>
          <Button
            variant="contained"
            onClick={saveRoom}
            disabled={saving || !form.slug.trim() || !form.name.trim()}
          >
            Lưu
          </Button>
        </DialogActions>
      </Dialog>

      <TableContainer component={Paper}>
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Nội dung</TableCell>
              <TableCell>Người gửi</TableCell>
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
                  <TableCell colSpan={6}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !messages.length && (
              <TableRow>
                <TableCell colSpan={6}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Không có tin nhắn nào khớp bộ lọc.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              messages.map((message) => (
                <TableRow key={message.id} hover>
                  <TableCell className="max-w-md">
                    <div className="whitespace-pre-wrap text-sm">
                      {message.body}
                    </div>
                    <div className="mt-1 text-xs text-gray-500">
                      {new Date(message.createdAt).toLocaleString("vi-VN")}
                    </div>
                    {message.hiddenReason && (
                      <div className="mt-1 text-xs text-amber-700">
                        Lý do ẩn: {message.hiddenReason}
                      </div>
                    )}
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <span className="text-sm">
                        {message.author?.name || "(tài khoản đã xoá)"}
                      </span>
                      {message.isModerator && (
                        <Chip size="small" label="Quản trị viên" color="primary" />
                      )}
                    </div>
                    <div className="text-xs text-gray-500">
                      {message.author?.id}
                    </div>
                  </TableCell>
                  <TableCell align="right">{message.likeCount}</TableCell>
                  <TableCell align="right">
                    {message.reportCount ? (
                      <span className="font-semibold text-red-600">
                        {message.reportCount}
                      </span>
                    ) : (
                      <span className="text-gray-400">0</span>
                    )}
                  </TableCell>
                  <TableCell>
                    <CommunityStatusChip status={message.status} />
                  </TableCell>
                  <TableCell align="right">
                    {message.status === CommunityContentStatus.VISIBLE ? (
                      <Tooltip title="Ẩn tin nhắn">
                        <Button
                          size="small"
                          color="warning"
                          disabled={saving}
                          onClick={() => setHiding(message)}
                        >
                          <EyeOffIcon size={15} />
                        </Button>
                      </Tooltip>
                    ) : (
                      message.status === CommunityContentStatus.HIDDEN && (
                        <Tooltip title="Hiện lại tin nhắn">
                          <Button
                            size="small"
                            disabled={saving}
                            onClick={() =>
                              act(
                                message,
                                { status: CommunityContentStatus.VISIBLE },
                                "Đã hiện lại tin nhắn"
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
        title="Ẩn tin nhắn này?"
        description="Tin nhắn sẽ biến khỏi phòng chat với mọi người. Bản ghi vẫn được giữ nên có thể hiện lại nếu đây là quyết định sai."
        saving={saving}
        onClose={() => setHiding(null)}
        onConfirm={(reason) =>
          hiding &&
          act(
            hiding,
            { status: CommunityContentStatus.HIDDEN, hiddenReason: reason },
            "Đã ẩn tin nhắn"
          )
        }
      />
    </div>
  );
};

export default ModerationChatTab;
