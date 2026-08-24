import React, { useCallback, useEffect, useState } from "react";
import {
  Button,
  Chip,
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
} from "@mui/material";
import { PlusIcon, RotateCcwIcon } from "lucide-react";

import CommunitySanctionModal from "../../components/community/CommunitySanctionModal";
import { communityService } from "../../services/communityService";
import { ICommunitySanction } from "../../types/interface/community.interface";
import { useNotification } from "../../utils/hooks/useNotification";

const TAKE = 20;

const isActive = (sanction: ICommunitySanction) => {
  if (sanction.revokedAt) return false;
  if (!sanction.mutedUntil) return true;
  return new Date(sanction.mutedUntil).getTime() > Date.now();
};

const CommunitySanctionList: React.FC = () => {
  const { showSuccess, showError } = useNotification();

  const [sanctions, setSanctions] = useState<ICommunitySanction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [userId, setUserId] = useState("");
  const [modalOpen, setModalOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await communityService.getSanctions({
        page,
        take: TAKE,
        ...(userId.trim() ? { userId: userId.trim() } : {}),
      });
      setSanctions(res?.items ?? []);
      setTotalPages(res?.totalPages || 1);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? "Không tải được danh sách");
    } finally {
      setLoading(false);
    }
  }, [page, userId]);

  useEffect(() => {
    const timer = setTimeout(load, 300);
    return () => clearTimeout(timer);
  }, [load]);

  const handleCreate = async (payload: {
    userId: string;
    mutedUntil?: string;
    reason: string;
  }) => {
    setSaving(true);
    try {
      await communityService.createSanction(payload);
      showSuccess("Đã khoá quyền đăng");
      setModalOpen(false);
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Khoá thất bại");
    } finally {
      setSaving(false);
    }
  };

  const handleRevoke = async (sanction: ICommunitySanction) => {
    try {
      await communityService.revokeSanction(sanction._id);
      showSuccess("Đã mở khoá");
      load();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? "Mở khoá thất bại");
    }
  };

  return (
    <div className="p-6 space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold">Khoá quyền đăng</h1>
          <p className="text-sm text-gray-500">
            Mỗi lần khoá là một dòng riêng — mở khoá không xoá dòng đó, nên lịch
            sử vi phạm của một người vẫn đọc được ở đây.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <TextField
            size="small"
            placeholder="Lọc theo User ID"
            value={userId}
            onChange={(event) => setUserId(event.target.value)}
          />
          <Button
            variant="contained"
            color="warning"
            startIcon={<PlusIcon size={16} />}
            onClick={() => setModalOpen(true)}
          >
            Khoá người dùng
          </Button>
        </div>
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
              <TableCell>User ID</TableCell>
              <TableCell>Lý do</TableCell>
              <TableCell>Đến khi</TableCell>
              <TableCell>Khoá lúc</TableCell>
              <TableCell>Trạng thái</TableCell>
              <TableCell align="right" />
            </TableRow>
          </TableHead>
          <TableBody>
            {loading &&
              Array.from({ length: 4 }).map((_, index) => (
                <TableRow key={index}>
                  <TableCell colSpan={6}>
                    <Skeleton height={28} />
                  </TableCell>
                </TableRow>
              ))}

            {!loading && !sanctions.length && (
              <TableRow>
                <TableCell colSpan={6}>
                  <div className="py-8 text-center text-sm text-gray-500">
                    Chưa khoá ai cả.
                  </div>
                </TableCell>
              </TableRow>
            )}

            {!loading &&
              sanctions.map((sanction) => {
                const active = isActive(sanction);
                return (
                  <TableRow key={sanction._id} hover>
                    <TableCell>
                      <code className="text-xs">{sanction.userId}</code>
                    </TableCell>
                    <TableCell className="max-w-sm text-sm">
                      {sanction.reason}
                    </TableCell>
                    <TableCell className="text-sm">
                      {sanction.mutedUntil
                        ? new Date(sanction.mutedUntil).toLocaleString("vi-VN")
                        : "Vĩnh viễn"}
                    </TableCell>
                    <TableCell className="text-xs text-gray-500">
                      {new Date(sanction.createdAt).toLocaleString("vi-VN")}
                    </TableCell>
                    <TableCell>
                      <Chip
                        size="small"
                        label={
                          sanction.revokedAt
                            ? "Đã mở khoá"
                            : active
                            ? "Đang khoá"
                            : "Đã hết hạn"
                        }
                        color={active ? "warning" : "default"}
                      />
                    </TableCell>
                    <TableCell align="right">
                      {active && (
                        <Button
                          size="small"
                          startIcon={<RotateCcwIcon size={14} />}
                          onClick={() => handleRevoke(sanction)}
                        >
                          Mở khoá
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
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

      <CommunitySanctionModal
        open={modalOpen}
        saving={saving}
        onClose={() => setModalOpen(false)}
        onSubmit={handleCreate}
      />
    </div>
  );
};

export default CommunitySanctionList;
