import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
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
  BarChart3Icon,
  CopyIcon,
  PencilIcon,
  PlusIcon,
  TrashIcon,
} from "lucide-react";

import DownloadLinkModal from "../../components/download-links/DownloadLinkModal";
import DownloadLinkStats from "../../components/download-links/DownloadLinkStats";
import {
  buildDownloadLinkUrl,
  downloadLinkService,
} from "../../services/downloadLinkService";
import {
  DownloadLinkPayload,
  IDownloadLink,
} from "../../types/interface/download-link.interface";
import { useNotification } from "../../utils/hooks/useNotification";

const DownloadLinkList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [links, setLinks] = useState<IDownloadLink[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<IDownloadLink | null>(null);
  const [saving, setSaving] = useState(false);

  const [statsFor, setStatsFor] = useState<IDownloadLink | null>(null);
  const [deleting, setDeleting] = useState<IDownloadLink | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await downloadLinkService.getList({
        take: 100,
        ...(search.trim() ? { search: search.trim() } : {}),
      });
      setLinks(res.data?.items ?? []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách link");
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => {
    // Debounced so typing in the search box does not fire a request per key.
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  const handleSubmit = async (payload: DownloadLinkPayload) => {
    setSaving(true);
    try {
      if (editing) {
        await downloadLinkService.update(editing.id, payload);
        showSuccess("Đã lưu link");
      } else {
        await downloadLinkService.create(payload);
        showSuccess("Đã tạo link");
      }
      setModalOpen(false);
      setEditing(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Lưu thất bại");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!deleting) return;
    try {
      await downloadLinkService.remove(deleting.id);
      showSuccess("Đã xoá link");
      setDeleting(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Xoá thất bại");
    }
  };

  const copy = async (link: IDownloadLink) => {
    try {
      await navigator.clipboard.writeText(buildDownloadLinkUrl(link.slug));
      showSuccess("Đã copy link");
    } catch {
      showError("Trình duyệt chặn copy — bấm vào link rồi copy tay");
    }
  };

  return (
    <div className="p-6">
      <header className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold">Link tải app</h1>
          <p className="mt-1 max-w-2xl text-sm text-gray-500">
            Mỗi link đẩy người dùng sang đúng cửa hàng theo thiết bị và đếm
            lượt bấm. Click được ghi ở phía server nên trình chặn quảng cáo
            không làm sai số.
          </p>
        </div>
        <Button
          variant="contained"
          startIcon={<PlusIcon size={16} />}
          onClick={() => {
            setEditing(null);
            setModalOpen(true);
          }}
        >
          Tạo link
        </Button>
      </header>

      <TextField
        size="small"
        placeholder="Tìm theo tên hoặc slug"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="mb-4 w-80"
      />

      {error && (
        <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </p>
      )}

      <TableContainer component={Paper} variant="outlined">
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Tên</TableCell>
              <TableCell>Link</TableCell>
              <TableCell align="right">Click</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right" width={140}>

              </TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 3 }).map((_, i) => (
                <TableRow key={i}>
                  <TableCell colSpan={5}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && links.length === 0 && (
              <TableRow>
                <TableCell colSpan={5}>
                  <div className="py-10 text-center text-sm text-gray-500">
                    {search
                      ? "Không có link nào khớp."
                      : "Chưa có link nào. Bấm “Tạo link” để bắt đầu."}
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              links.map((link) => (
                <TableRow key={link.id} hover>
                  <TableCell>
                    <div className="font-medium">{link.name}</div>
                    {link.description && (
                      <div className="text-xs text-gray-500">
                        {link.description}
                      </div>
                    )}
                  </TableCell>

                  <TableCell>
                    <code className="text-xs text-gray-700">
                      /r/{link.slug}
                    </code>
                  </TableCell>

                  <TableCell align="right" className="tabular-nums">
                    {link.totalClicks ?? 0}
                  </TableCell>

                  <TableCell>
                    <span
                      className={`rounded px-2 py-0.5 text-xs ${
                        link.isActive
                          ? "bg-green-100 text-green-700"
                          : "bg-gray-100 text-gray-600"
                      }`}
                    >
                      {link.isActive ? "Đang chạy" : "Đã tắt"}
                    </span>
                  </TableCell>

                  <TableCell align="right">
                    <div className="flex justify-end gap-1">
                      <Tooltip title="Copy link">
                        <button
                          className="rounded p-1.5 hover:bg-gray-100"
                          onClick={() => copy(link)}
                          aria-label={`Copy link ${link.slug}`}
                        >
                          <CopyIcon size={16} />
                        </button>
                      </Tooltip>
                      <Tooltip title="Xem thống kê">
                        <button
                          className="rounded p-1.5 hover:bg-gray-100"
                          onClick={() => setStatsFor(link)}
                          aria-label={`Thống kê ${link.slug}`}
                        >
                          <BarChart3Icon size={16} />
                        </button>
                      </Tooltip>
                      <Tooltip title="Sửa">
                        <button
                          className="rounded p-1.5 hover:bg-gray-100"
                          onClick={() => {
                            setEditing(link);
                            setModalOpen(true);
                          }}
                          aria-label={`Sửa ${link.slug}`}
                        >
                          <PencilIcon size={16} />
                        </button>
                      </Tooltip>
                      <Tooltip title="Xoá">
                        <button
                          className="rounded p-1.5 text-red-600 hover:bg-red-50"
                          onClick={() => setDeleting(link)}
                          aria-label={`Xoá ${link.slug}`}
                        >
                          <TrashIcon size={16} />
                        </button>
                      </Tooltip>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
      </TableContainer>

      <DownloadLinkModal
        open={modalOpen}
        link={editing}
        saving={saving}
        onClose={() => {
          setModalOpen(false);
          setEditing(null);
        }}
        onSubmit={handleSubmit}
      />

      <DownloadLinkStats link={statsFor} onClose={() => setStatsFor(null)} />

      <Dialog open={Boolean(deleting)} onClose={() => setDeleting(null)}>
        <DialogTitle>Xoá link?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Link <code>/r/{deleting?.slug}</code> sẽ ngừng hoạt động và người
            bấm vào sẽ về trang tải app chung. Lịch sử click vẫn được giữ.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleting(null)}>Huỷ</Button>
          <Button color="error" variant="contained" onClick={handleDelete}>
            Xoá
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default DownloadLinkList;
