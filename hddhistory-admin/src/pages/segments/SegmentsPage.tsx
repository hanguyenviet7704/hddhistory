import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  IconButton,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tooltip,
} from "@mui/material";
import {
  BarChart3Icon,
  PencilIcon,
  PlusIcon,
  RefreshCwIcon,
  TrashIcon,
} from "lucide-react";

import SegmentCriteriaSummary from "../../components/segments/SegmentCriteriaSummary";
import SegmentFormDialog from "../../components/segments/SegmentFormDialog";
import SegmentOverlapSection from "../../components/segments/SegmentOverlapSection";
import SegmentStatsDrawer from "../../components/segments/SegmentStatsDrawer";
import { segmentService } from "../../services/segmentService";
import {
  ISegment,
  SegmentPayload,
  SegmentStats,
} from "../../types/interface/segment.interface";
import { useNotification } from "../../utils/hooks/useNotification";

/**
 * Audience segments: named, criteria-based user groups used to target the
 * Home banner and Home popup. Membership is always computed live (never a
 * stored list), so "Số user hiện tại" is opt-in per row rather than fetched
 * for the whole table on load.
 */
const SegmentsPage: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [segments, setSegments] = useState<ISegment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<ISegment | null>(null);
  const [saving, setSaving] = useState(false);

  const [deleting, setDeleting] = useState<ISegment | null>(null);
  const [deletingBusy, setDeletingBusy] = useState(false);

  const [statsById, setStatsById] = useState<Record<string, SegmentStats>>({});
  const [countingIds, setCountingIds] = useState<Set<string>>(new Set());
  const [statsDrawerSegment, setStatsDrawerSegment] = useState<ISegment | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await segmentService.list();
      setSegments(res.data ?? []);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách phân khúc");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const fetchStats = useCallback(
    async (id: string) => {
      setCountingIds((prev) => new Set(prev).add(id));
      try {
        const res = await segmentService.stats(id);
        setStatsById((prev) => ({ ...prev, [id]: res.data }));
      } catch (err: any) {
        showError(err?.response?.data?.message ?? "Không đếm được số user");
      } finally {
        setCountingIds((prev) => {
          const next = new Set(prev);
          next.delete(id);
          return next;
        });
      }
    },
    [showError],
  );

  const openCreate = () => {
    setEditing(null);
    setFormOpen(true);
  };

  const openEdit = (segment: ISegment) => {
    setEditing(segment);
    setFormOpen(true);
  };

  const openStats = (segment: ISegment) => {
    setStatsDrawerSegment(segment);
    fetchStats(segment._id);
  };

  const handleSubmit = async (payload: SegmentPayload) => {
    setSaving(true);
    try {
      if (editing) {
        await segmentService.update(editing._id, payload);
        showSuccess("Đã lưu phân khúc");
      } else {
        await segmentService.create(payload);
        showSuccess("Đã tạo phân khúc");
      }
      setFormOpen(false);
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
    setDeletingBusy(true);
    try {
      await segmentService.remove(deleting._id);
      showSuccess("Đã xoá phân khúc");
      setDeleting(null);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Xoá thất bại");
    } finally {
      setDeletingBusy(false);
    }
  };

  return (
    <div className="p-6">
      <header className="mb-5 flex items-start justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold">Phân khúc user (Segments)</h1>
          <p className="mt-1 max-w-2xl text-sm text-gray-500">
            Nhóm user theo tiêu chí (thời gian dùng app, ngôn ngữ, quốc gia,
            thiết bị, loại tài khoản...) để nhắm mục tiêu banner và popup Home.
            Số user luôn được tính trực tiếp khi bấm "Đếm" — không lưu sẵn danh
            sách thành viên.
          </p>
        </div>
        <Button variant="contained" startIcon={<PlusIcon size={16} />} onClick={openCreate}>
          Tạo phân khúc
        </Button>
      </header>

      {error && (
        <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
          <Button size="small" className="ml-3" onClick={load}>
            Thử lại
          </Button>
        </p>
      )}

      <TableContainer component={Paper} variant="outlined" className="overflow-x-auto">
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Tên</TableCell>
              <TableCell>Tiêu chí</TableCell>
              <TableCell>Tạo lúc</TableCell>
              <TableCell width={160}>Số user hiện tại</TableCell>
              <TableCell align="right" width={140} />
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

            {!loading && segments.length === 0 && (
              <TableRow>
                <TableCell colSpan={5}>
                  <div className="py-10 text-center text-sm text-gray-500">
                    Chưa có phân khúc nào — tạo phân khúc đầu tiên để bắt đầu
                    nhắm mục tiêu banner/popup theo đối tượng cụ thể.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              segments.map((segment) => {
                const stats = statsById[segment._id];
                const isCounting = countingIds.has(segment._id);
                return (
                  <TableRow key={segment._id} hover>
                    <TableCell className="font-medium">{segment.name}</TableCell>
                    <TableCell>
                      <SegmentCriteriaSummary criteria={segment.criteria} />
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-sm text-gray-600">
                      {new Date(segment.createdAt).toLocaleDateString("vi-VN")}
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1.5">
                        {stats ? (
                          <span className="font-semibold tabular-nums">
                            {stats.count.toLocaleString("vi-VN")}
                          </span>
                        ) : (
                          <span className="text-sm text-gray-400">Chưa đếm</span>
                        )}
                        <Tooltip title="Đếm số user hiện tại (tính trực tiếp, có thể chậm)">
                          <span>
                            <IconButton
                              size="small"
                              onClick={() => fetchStats(segment._id)}
                              disabled={isCounting}
                              aria-label={`Đếm số user của ${segment.name}`}
                            >
                              {isCounting ? (
                                <CircularProgress size={14} />
                              ) : (
                                <RefreshCwIcon size={14} />
                              )}
                            </IconButton>
                          </span>
                        </Tooltip>
                      </div>
                    </TableCell>
                    <TableCell align="right">
                      <div className="flex justify-end gap-1">
                        <Tooltip title="Xem thống kê tăng trưởng">
                          <IconButton
                            size="small"
                            onClick={() => openStats(segment)}
                            aria-label={`Thống kê ${segment.name}`}
                          >
                            <BarChart3Icon size={16} />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Sửa">
                          <IconButton
                            size="small"
                            onClick={() => openEdit(segment)}
                            aria-label={`Sửa ${segment.name}`}
                          >
                            <PencilIcon size={16} />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Xoá">
                          <IconButton
                            size="small"
                            onClick={() => setDeleting(segment)}
                            aria-label={`Xoá ${segment.name}`}
                            className="text-red-600"
                          >
                            <TrashIcon size={16} />
                          </IconButton>
                        </Tooltip>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
          </TableBody>
        </Table>
      </TableContainer>

      <div className="mt-8">
        <SegmentOverlapSection segments={segments} />
      </div>

      <SegmentFormDialog
        open={formOpen}
        segment={editing}
        saving={saving}
        onClose={() => {
          setFormOpen(false);
          setEditing(null);
        }}
        onSubmit={handleSubmit}
      />

      <SegmentStatsDrawer
        segment={statsDrawerSegment}
        stats={statsDrawerSegment ? statsById[statsDrawerSegment._id] : undefined}
        loading={statsDrawerSegment ? countingIds.has(statsDrawerSegment._id) : false}
        onRefresh={fetchStats}
        onClose={() => setStatsDrawerSegment(null)}
      />

      <Dialog open={Boolean(deleting)} onClose={() => setDeleting(null)}>
        <DialogTitle>Xoá phân khúc?</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Phân khúc "{deleting?.name}" sẽ bị xoá cùng lịch sử snapshot.
            Banner/popup đang nhắm tới phân khúc này sẽ không lỗi — chỉ nới
            phạm vi nhắm mục tiêu (id không tồn tại đơn giản là không khớp ai
            nữa).
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleting(null)} disabled={deletingBusy}>
            Huỷ
          </Button>
          <Button color="error" variant="contained" onClick={handleDelete} disabled={deletingBusy}>
            {deletingBusy ? "Đang xoá..." : "Xoá"}
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  );
};

export default SegmentsPage;
